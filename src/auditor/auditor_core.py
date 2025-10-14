"""Core utilities and shared infrastructure for the EnvAuditor tools."""
from __future__ import annotations

import datetime as _dt
import hashlib
import json
import os
import shutil
import tempfile
import textwrap
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

REPORT_WRAP_WIDTH = 110
MAX_LOG_BYTES = 10 * 1024 * 1024
MAX_LOG_FILES = 7
RESERVED_WINDOWS_NAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *{f"COM{i}" for i in range(1, 10)},
    *{f"LPT{i}" for i in range(1, 10)},
}
INVALID_WINDOWS_CHARS = set('<>:"|?*')

DEFAULT_WELL_KNOWN = {
    "ALLUSERSPROFILE",
    "APPDATA",
    "CLIENTNAME",
    "CommonProgramFiles",
    "CommonProgramFiles(x86)",
    "CommonProgramW6432",
    "COMPUTERNAME",
    "ComSpec",
    "DriverData",
    "HOMEDRIVE",
    "HOMEPATH",
    "LOCALAPPDATA",
    "LOGONSERVER",
    "NUMBER_OF_PROCESSORS",
    "OneDrive",
    "OneDriveConsumer",
    "OS",
    "Path",
    "PATHEXT",
    "PROCESSOR_ARCHITECTURE",
    "PROCESSOR_IDENTIFIER",
    "PROCESSOR_LEVEL",
    "PROCESSOR_REVISION",
    "ProgramData",
    "ProgramFiles",
    "ProgramFiles(x86)",
    "ProgramW6432",
    "PROMPT",
    "PUBLIC",
    "SystemDrive",
    "SystemRoot",
    "TEMP",
    "TMP",
    "USERDOMAIN",
    "USERDOMAIN_ROAMINGPROFILE",
    "USERNAME",
    "USERPROFILE",
    "windir",
    "PSModulePath",
    "ChocolateyInstall",
    "ChocolateyLastPathUpdate",
    "POSH_THEMES_PATH",
}
DEFAULT_ESSENTIAL = {
    "SystemRoot",
    "ComSpec",
    "Path",
    "TEMP",
    "TMP",
    "USERPROFILE",
    "PSModulePath",
}


@dataclass(frozen=True)
class RuntimePaths:
    """Resolved directories rooted at the canonical ROOT."""

    root: Path
    out_dir: Path
    logs_dir: Path
    backups_dir: Path


@dataclass(frozen=True)
class RuntimeContext:
    """Holds per-run metadata used across CLI and GUI components."""

    paths: RuntimePaths
    run_id: str
    logger: "StructuredLogWriter"


class StructuredLogWriter:
    """Append-only JSONL logger with simple size-based rotation."""

    def __init__(self, log_path: Path, run_id: str) -> None:
        self._log_path = log_path
        self._log_path.parent.mkdir(parents=True, exist_ok=True)
        self._run_id = run_id

    def log_event(
        self,
        *,
        level: str,
        event: str,
        op_id: str,
        message: str,
        context: Optional[Dict[str, Any]] = None,
        result: Optional[Dict[str, Any]] = None,
        duration_ms: Optional[float] = None,
        bytes_count: Optional[int] = None,
    ) -> None:
        payload: Dict[str, Any] = {
            "timestamp_utc": _dt.datetime.utcnow().replace(tzinfo=_dt.timezone.utc).isoformat().replace("+00:00", "Z"),
            "level": level.upper(),
            "event": event,
            "run_id": self._run_id,
            "op_id": op_id,
            "context": context or {},
            "result": result or {},
            "message": message,
        }
        if duration_ms is not None:
            payload["duration_ms"] = round(float(duration_ms), 3)
        if bytes_count is not None:
            payload["bytes"] = int(bytes_count)
        record = json.dumps(payload, ensure_ascii=False)
        self._rotate_if_needed(len(record) + 1)
        with self._log_path.open("a", encoding="utf-8") as handle:
            handle.write(record + "\n")

    def _rotate_if_needed(self, pending_bytes: int) -> None:
        if not self._log_path.exists():
            return
        current_size = self._log_path.stat().st_size
        if current_size + pending_bytes < MAX_LOG_BYTES:
            return
        for index in range(MAX_LOG_FILES - 1, 0, -1):
            older = self._log_path.with_suffix(self._log_path.suffix + f".{index}")
            newer = self._log_path.with_suffix(self._log_path.suffix + f".{index + 1}")
            if older.exists():
                if index + 1 > MAX_LOG_FILES:
                    older.unlink()
                else:
                    older.replace(newer)
        rotated = self._log_path.with_suffix(self._log_path.suffix + ".1")
        self._log_path.replace(rotated)


def _validate_component(component: str) -> None:
    stripped = component.strip()
    if stripped != component:
        raise ValueError("Components must not contain leading or trailing spaces")
    if component.endswith("."):
        raise ValueError("Components must not end with a dot")
    upper = component.upper()
    if upper in RESERVED_WINDOWS_NAMES:
        raise ValueError(f"Component '{component}' is reserved on Windows")
    if any(char in INVALID_WINDOWS_CHARS for char in component):
        raise ValueError(f"Component '{component}' contains invalid characters")


def _reject_symlinks(path: Path, root: Path) -> None:
    for parent in path.parents:
        if parent == root:
            break
        if parent.exists() and parent.is_symlink():
            raise ValueError("Symlinks in the path hierarchy are not permitted")


def ensure_within_root(candidate: Path, root: Path) -> Path:
    """Normalize the candidate path and ensure it remains under ROOT."""
    candidate = candidate.expanduser()
    if not candidate.is_absolute():
        candidate = root / candidate
    resolved_root = root.resolve(strict=False)
    resolved_path = candidate.resolve(strict=False)
    try:
        relative = resolved_path.relative_to(resolved_root)
    except ValueError as exc:
        raise ValueError("Target path escapes the configured ROOT") from exc
    for component in relative.parts:
        _validate_component(component)
    _reject_symlinks(resolved_path, resolved_root)
    return resolved_path


def compute_sha256_from_bytes(data: bytes) -> str:
    digest = hashlib.sha256()
    digest.update(data)
    return digest.hexdigest()


def atomic_write_text(
    *,
    content: str,
    target: Path,
    root: Path,
    logger: StructuredLogWriter,
    op_id: str,
) -> Dict[str, Any]:
    """Write *content* to *target* atomically, creating backups and hashes."""
    target = ensure_within_root(target, root)
    target.parent.mkdir(parents=True, exist_ok=True)
    backup_path: Optional[Path] = None
    if target.exists():
        timestamp = _dt.datetime.utcnow().strftime("%y%m%d%H%M")
        backup_root = root / "00.Backups" / timestamp
        backup_root.mkdir(parents=True, exist_ok=True)
        relative = target.relative_to(root)
        backup_path = backup_root / relative
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, backup_path)
        logger.log_event(
            level="info",
            event="file.backup",
            op_id=op_id,
            message="Created backup before overwrite",
            context={"source": str(target)},
            result={"backup_path": str(backup_path)},
        )
    bytes_payload = content.encode("utf-8")
    sha256_expected = compute_sha256_from_bytes(bytes_payload)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=str(target.parent), delete=False) as handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())
        temp_path = Path(handle.name)
    temp_path.replace(target)
    with target.open("rb") as handle:
        sha256_actual = compute_sha256_from_bytes(handle.read())
    if sha256_actual != sha256_expected:
        raise IOError("SHA-256 verification failed after atomic write")
    bytes_count = len(bytes_payload)
    logger.log_event(
        level="info",
        event="file.write",
        op_id=op_id,
        message="Atomic write completed",
        context={"path": str(target)},
        result={"sha256": sha256_actual},
        bytes_count=bytes_count,
    )
    result: Dict[str, Any] = {
        "path": str(target),
        "bytes": bytes_count,
        "sha256": sha256_actual,
    }
    if backup_path is not None:
        result["backup_path"] = str(backup_path)
    return result


def resolve_root() -> Path:
    root_override = os.environ.get("ENV_AUDITOR_ROOT")
    if root_override:
        candidate = Path(root_override)
    else:
        candidate = Path.cwd()
    resolved = candidate.expanduser().resolve(strict=False)
    resolved.mkdir(parents=True, exist_ok=True)
    for child in ("out", "logs", "00.Backups"):
        (resolved / child).mkdir(parents=True, exist_ok=True)
    return resolved


def create_runtime_context() -> RuntimeContext:
    root = resolve_root()
    paths = RuntimePaths(
        root=root,
        out_dir=root / "out",
        logs_dir=root / "logs",
        backups_dir=root / "00.Backups",
    )
    run_id = uuid.uuid4().hex
    logger = StructuredLogWriter(paths.logs_dir / "actions.jsonl", run_id)
    logger.log_event(
        level="info",
        event="session.start",
        op_id=uuid.uuid4().hex,
        message="Runtime context initialized",
        context={"root": str(paths.root)},
    )
    return RuntimeContext(paths=paths, run_id=run_id, logger=logger)


def generate_op_id() -> str:
    return uuid.uuid4().hex


def safe_expandvars(value: str) -> str:
    """Expand environment variables without throwing."""
    try:
        return os.path.expandvars(value)
    except Exception:
        return value


def _load_config_candidates(explicit_path: Optional[Path] = None) -> Iterable[Path]:
    if explicit_path:
        yield explicit_path
    env_override = os.environ.get("ENV_AUDITOR_CONFIG")
    if env_override:
        yield Path(env_override)
    cwd_candidate = Path.cwd() / "config" / "env_auditor.config.json"
    yield cwd_candidate
    module_dir = Path(__file__).resolve().parent
    yield module_dir / "env_auditor.config.json"
    yield module_dir.parent / "config" / "env_auditor.config.json"


def load_configuration(config_path: Optional[str] = None) -> Tuple[set[str], set[str]]:
    explicit = Path(config_path) if config_path else None
    for candidate in _load_config_candidates(explicit):
        if candidate.is_file():
            try:
                with candidate.open("r", encoding="utf-8") as handle:
                    payload = json.load(handle)
                well_known = set(payload.get("well_known", DEFAULT_WELL_KNOWN))
                essential = set(payload.get("essential", DEFAULT_ESSENTIAL))
                return well_known, essential
            except (OSError, json.JSONDecodeError):
                continue
    return set(DEFAULT_WELL_KNOWN), set(DEFAULT_ESSENTIAL)


@dataclass
class AuditOptions:
    include_env: bool = True
    include_path: bool = True
    include_psmodule: bool = True
    include_custom: bool = True
    include_diagnostics: bool = True


class EnvironmentAuditor:
    def __init__(self, config_path: Optional[str] = None) -> None:
        self.well_known, self.essential = load_configuration(config_path)

    def run(self, options: AuditOptions) -> Dict[str, Any]:
        env_map = dict(os.environ)
        env_items = sorted(env_map.items(), key=lambda item: item[0].lower())
        generated_at = _dt.datetime.utcnow().replace(tzinfo=_dt.timezone.utc).isoformat().replace("+00:00", "Z")
        report: Dict[str, Any] = {
            "generated_at": generated_at,
            "summary": {
                "environment_variable_count": len(env_items),
            },
        }
        diagnostics: List[Dict[str, str]] = []
        if options.include_env:
            report["environment_variables"] = [
                {"name": name, "value": value}
                for name, value in env_items
            ]
        if options.include_path:
            path_section = self._build_path_section(env_map.get("Path", ""))
            report["path_entries"] = path_section["entries"]
            report["path_duplicates"] = path_section["duplicates"]
            report["summary"].update(
                {
                    "path_entry_count": len(path_section["entries"]),
                    "path_duplicate_count": len(path_section["duplicates"]),
                    "path_missing_targets": path_section["missing"],
                    "path_access_denied": path_section["access_denied"],
                }
            )
            diagnostics.extend(path_section["diagnostics"])
        else:
            entries = self._split_entries(env_map.get("Path", ""))
            report["summary"].update(
                {
                    "path_entry_count": len(entries),
                    "path_duplicate_count": 0,
                    "path_missing_targets": 0,
                    "path_access_denied": 0,
                }
            )
        if options.include_psmodule:
            psmodule_entries = self._split_entries(env_map.get("PSModulePath", ""))
            detailed_entries = []
            for index, entry in enumerate(psmodule_entries):
                expanded = safe_expandvars(entry)
                status = self._determine_status(expanded)
                detailed_entries.append(
                    {
                        "index": index + 1,
                        "raw": entry,
                        "expanded": expanded,
                        "exists": os.path.exists(expanded),
                        "status": status,
                    }
                )
                if status == "missing":
                    diagnostics.append(
                        {
                            "level": "warning",
                            "message": f"PSModulePath entry does not exist or is inaccessible: {entry}",
                        }
                    )
            report["psmodule_entries"] = detailed_entries
            report["summary"]["psmodule_count"] = len(psmodule_entries)
        else:
            report["summary"]["psmodule_count"] = len(self._split_entries(env_map.get("PSModulePath", "")))
        if options.include_custom:
            custom = [
                {"name": name, "value": value}
                for name, value in env_items
                if name not in self.well_known
            ]
            report["custom_variables"] = custom
            report["summary"]["custom_variable_count"] = len(custom)
        else:
            report["summary"]["custom_variable_count"] = sum(
                1 for name, _ in env_items if name not in self.well_known
            )
        if options.include_diagnostics:
            missing_essential = sorted(var for var in self.essential if var not in env_map)
            if missing_essential:
                diagnostics.append(
                    {
                        "level": "error",
                        "message": "Missing essential variables: " + ", ".join(missing_essential),
                    }
                )
            short_path_vars = sorted(name for name, value in env_items if "~" in value)
            if short_path_vars:
                diagnostics.append(
                    {
                        "level": "info",
                        "message": "Variables using short paths: " + ", ".join(short_path_vars),
                    }
                )
        severity_order = {"error": 0, "warning": 1, "info": 2}
        diagnostics.sort(key=lambda item: (severity_order.get(item.get("level", "info"), 3), item.get("message", "")))
        report["diagnostics"] = diagnostics if options.include_diagnostics else []
        summary_counts = {"error": 0, "warning": 0, "info": 0}
        for item in diagnostics:
            level = item.get("level", "info").lower()
            if level in summary_counts:
                summary_counts[level] += 1
        report["summary"]["diagnostic_counts"] = summary_counts
        return report

    @staticmethod
    def _split_entries(raw: str) -> List[str]:
        return [segment.strip() for segment in raw.split(";") if segment.strip()]

    def _build_path_section(self, raw: str) -> Dict[str, Any]:
        entries = self._split_entries(raw)
        normalized_keys: List[str] = []
        for entry in entries:
            expanded = safe_expandvars(entry)
            normalized_keys.append(os.path.normcase(os.path.normpath(expanded)))
        duplicates_map: Dict[str, List[int]] = {}
        for idx, key in enumerate(normalized_keys):
            duplicates_map.setdefault(key, []).append(idx)
        result_entries = []
        missing_count = 0
        access_denied_count = 0
        diagnostics: List[Dict[str, str]] = []
        seen_messages: set[str] = set()
        for idx, entry in enumerate(entries):
            expanded = safe_expandvars(entry)
            status = self._determine_status(expanded)
            exists = os.path.exists(expanded)
            if status == "missing":
                missing_count += 1
            elif status == "access_denied":
                access_denied_count += 1
            duplicate = len(duplicates_map.get(normalized_keys[idx], [])) > 1
            uses_short = "~" in entry
            for level, message in (
                ("warning", f"PATH entry does not exist: {entry}"),
                ("warning", f"PATH entry access denied: {entry}"),
                ("info", f"Duplicate PATH entry: {entry}"),
                ("info", f"PATH entry uses short path notation: {entry}"),
            ):
                condition = (
                    (level == "warning" and "does not exist" in message and status == "missing")
                    or (level == "warning" and "access denied" in message and status == "access_denied")
                    or (level == "info" and "Duplicate" in message and duplicate)
                    or (level == "info" and "short path" in message and uses_short)
                )
                if condition and message not in seen_messages:
                    diagnostics.append({"level": level, "message": message})
                    seen_messages.add(message)
            result_entries.append(
                {
                    "index": idx + 1,
                    "raw": entry,
                    "expanded": expanded,
                    "exists": exists,
                    "duplicate": duplicate,
                    "uses_short_path": uses_short,
                    "status": status,
                }
            )
        duplicates = [
            {"entry": entries[indices[0]], "count": len(indices)}
            for indices in duplicates_map.values()
            if len(indices) > 1
        ]
        duplicates.sort(key=lambda item: item["entry"].lower())
        return {
            "entries": result_entries,
            "duplicates": duplicates,
            "missing": missing_count,
            "access_denied": access_denied_count,
            "diagnostics": diagnostics,
        }

    @staticmethod
    def _determine_status(expanded: str) -> str:
        if not expanded:
            return "missing"
        try:
            if os.path.isdir(expanded):
                return "dir"
            if os.path.isfile(expanded):
                return "file"
            if os.path.exists(expanded) and not os.access(expanded, os.R_OK):
                return "access_denied"
            if not os.path.exists(expanded):
                return "missing"
        except OSError:
            return "access_denied"
        return "unknown"


def ascii_table(headers: List[str], rows: List[List[Any]], wrap: int = REPORT_WRAP_WIDTH) -> str:
    wrapped_rows: List[List[List[str]]] = []
    for row in rows:
        row_lines: List[List[str]] = []
        for cell in row:
            text = "" if cell is None else str(cell)
            text = text.replace("\n", " ⏎ ")
            wrapped = textwrap.wrap(text, width=wrap) or [""]
            row_lines.append(wrapped)
        wrapped_rows.append(row_lines)
    col_widths: List[int] = []
    for col_index, header in enumerate(headers):
        max_len = len(header)
        for row in wrapped_rows:
            lines = row[col_index]
            max_line = max((len(line) for line in lines), default=0)
            if max_line > max_len:
                max_len = max_line
        col_widths.append(max_len)
    border = "+" + "+".join("-" * (width + 2) for width in col_widths) + "+"

    def format_line(cells: List[str]) -> str:
        padded = [f" {cells[i].ljust(col_widths[i])} " for i in range(len(cells))]
        return "|" + "|".join(padded) + "|"

    lines = [border, format_line(headers), border]
    for row in wrapped_rows:
        max_lines = max(len(cell_lines) for cell_lines in row)
        for line_idx in range(max_lines):
            display_cells = [
                cell_lines[line_idx] if line_idx < len(cell_lines) else ""
                for cell_lines in row
            ]
            lines.append(format_line(display_cells))
        lines.append(border)
    return "\n".join(lines)


def build_markdown(report: Dict[str, Any], options: AuditOptions) -> str:
    summary = report["summary"]
    diag_counts = summary.get("diagnostic_counts", {"error": 0, "warning": 0, "info": 0})
    lines = [
        "# Environment & Session Report",
        "",
        f"- Generated: {report['generated_at']}",
        f"- Environment variables: {summary.get('environment_variable_count', 0)}",
        f"- PATH entries: {summary.get('path_entry_count', 0)}",
        f"- PATH duplicates: {summary.get('path_duplicate_count', 0)}",
        f"- PATH entries with missing targets: {summary.get('path_missing_targets', 0)}",
        f"- PATH entries with access denied: {summary.get('path_access_denied', 0)}",
        f"- PSModulePath entries: {summary.get('psmodule_count', 0)}",
        f"- Custom environment variables: {summary.get('custom_variable_count', 0)}",
        (
            "- Diagnostics summary: "
            f"Errors:{diag_counts.get('error', 0)}  "
            f"Warnings:{diag_counts.get('warning', 0)}  "
            f"Info:{diag_counts.get('info', 0)}"
        ),
        "",
    ]
    if options.include_env and report.get("environment_variables"):
        env_rows = [[item["name"], item["value"]] for item in report["environment_variables"]]
        lines.append("## All Environment Variables")
        lines.append("```")
        lines.append(ascii_table(["Name", "Value"], env_rows))
        lines.append("```")
        lines.append("")
    if options.include_path and report.get("path_entries"):
        path_rows = [
            [
                entry["index"],
                entry["raw"],
                "Yes" if entry["duplicate"] else "-",
                entry["status"],
                "Yes" if entry["uses_short_path"] else "-",
            ]
            for entry in report["path_entries"]
        ]
        lines.append("## PATH Entries")
        lines.append("```")
        lines.append(ascii_table(["#", "Entry", "Duplicate", "Status", "Short Path"], path_rows))
        lines.append("```")
        lines.append("")
        if report.get("path_duplicates"):
            duplicate_rows = [
                [item["count"], item["entry"]]
                for item in report["path_duplicates"]
            ]
            lines.append("### PATH Duplicates")
            lines.append("```")
            lines.append(ascii_table(["Count", "Entry"], duplicate_rows))
            lines.append("```")
            lines.append("")
    if options.include_psmodule and report.get("psmodule_entries"):
        module_rows = [
            [
                entry["index"],
                entry["raw"],
                entry["status"],
            ]
            for entry in report["psmodule_entries"]
        ]
        lines.append("## PSModulePath Entries")
        lines.append("```")
        lines.append(ascii_table(["#", "Entry", "Status"], module_rows))
        lines.append("```")
        lines.append("")
    if options.include_custom and report.get("custom_variables"):
        custom_rows = [
            [item["name"], item["value"]]
            for item in report["custom_variables"]
        ]
        lines.append("## Custom Environment Variables")
        lines.append("```")
        lines.append(ascii_table(["Name", "Value"], custom_rows))
        lines.append("```")
        lines.append("")
    if options.include_diagnostics and report.get("diagnostics"):
        lines.append("## Diagnostics")
        for item in report["diagnostics"]:
            lines.append(f"- **{item['level'].upper()}** — {item['message']}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def build_powershell_script() -> str:
    """Return a deterministic PowerShell module matching the CLI feature set."""
    script = textwrap.dedent("""
Set-StrictMode -Version Latest
function Get-EnvAuditorReport {
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [switch]$IncludeEnv = $true,
        [switch]$IncludePath = $true,
        [switch]$IncludePSModule = $true,
        [switch]$IncludeCustom = $true,
        [switch]$IncludeDiagnostics = $true
    )
    $envItems = Get-ChildItem Env: | Sort-Object Name
    $report = [ordered]@{}
    $report.generated_at = (Get-Date -AsUTC).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $summary = [ordered]@{
        environment_variable_count = $envItems.Count
        path_entry_count = 0
        path_duplicate_count = 0
        path_missing_targets = 0
        path_access_denied = 0
        psmodule_count = 0
        custom_variable_count = 0
        diagnostic_counts = [ordered]@{ error = 0; warning = 0; info = 0 }
    }
    $report.summary = $summary
    if ($IncludeEnv) {
        $report.environment_variables = $envItems | ForEach-Object {
            [ordered]@{ name = $_.Name; value = $_.Value }
        }
    }
    if ($IncludePath) {
        $entries = @()
        $duplicates = @{}
        $index = 0
        foreach ($item in ($env:Path -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })) {
            $index++
            $expanded = [System.Environment]::ExpandEnvironmentVariables($item)
            $norm = [System.IO.Path]::GetFullPath($expanded).ToLowerInvariant()
            if (-not $duplicates.ContainsKey($norm)) { $duplicates[$norm] = @() }
            $duplicates[$norm] += $index
            $status = 'unknown'
            if (-not $expanded) { $status = 'missing' }
            elseif (Test-Path $expanded -PathType Container) { $status = 'dir' }
            elseif (Test-Path $expanded -PathType Leaf) { $status = 'file' }
            elseif ((Test-Path $expanded) -and -not (Test-Path $expanded -PathType Any)) { $status = 'access_denied' }
            else { $status = 'missing' }
            if ($status -eq 'missing') { $summary.path_missing_targets++ }
            if ($status -eq 'access_denied') { $summary.path_access_denied++ }
            $entries += [ordered]@{ index = $index; raw = $item; status = $status }
        }
        $report.path_entries = $entries
        $summary.path_entry_count = $entries.Count
        $report.path_duplicates = @()
        foreach ($key in $duplicates.Keys) {
            if ($duplicates[$key].Count -gt 1) {
                $report.path_duplicates += [ordered]@{ entry = ($entries[($duplicates[$key][0] - 1)]).raw; count = $duplicates[$key].Count }
            }
        }
        $summary.path_duplicate_count = $report.path_duplicates.Count
    }
    if ($IncludePSModule) {
        $moduleEntries = ($env:PSModulePath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })
        $summary.psmodule_count = $moduleEntries.Count
        $report.psmodule_entries = for ($i = 0; $i -lt $moduleEntries.Count; $i++) {
            [ordered]@{ index = $i + 1; raw = $moduleEntries[$i] }
        }
    } else {
        $summary.psmodule_count = ($env:PSModulePath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' }).Count
    }
    $wellKnown = @()
    if ($IncludeCustom) {
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            try { $wellKnown = (Get-Content $ConfigPath -Raw | ConvertFrom-Json).well_known } catch { $wellKnown = @() }
        }
        if (-not $wellKnown) {
            $wellKnown = @(
                'ALLUSERSPROFILE','APPDATA','CLIENTNAME','CommonProgramFiles','CommonProgramFiles(x86)','CommonProgramW6432',
                'COMPUTERNAME','ComSpec','DriverData','HOMEDRIVE','HOMEPATH','LOCALAPPDATA','LOGONSERVER','NUMBER_OF_PROCESSORS',
                'OneDrive','OneDriveConsumer','OS','Path','PATHEXT','PROCESSOR_ARCHITECTURE','PROCESSOR_IDENTIFIER','PROCESSOR_LEVEL',
                'PROCESSOR_REVISION','ProgramData','ProgramFiles','ProgramFiles(x86)','ProgramW6432','PROMPT','PUBLIC','SystemDrive','SystemRoot',
                'TEMP','TMP','USERDOMAIN','USERDOMAIN_ROAMINGPROFILE','USERNAME','USERPROFILE','windir','PSModulePath','ChocolateyInstall',
                'ChocolateyLastPathUpdate','POSH_THEMES_PATH'
            )
        }
        $report.custom_variables = $envItems | Where-Object { $wellKnown -notcontains $_.Name } | ForEach-Object {
            [ordered]@{ name = $_.Name; value = $_.Value }
        }
        $summary.custom_variable_count = $report.custom_variables.Count
    } else {
        $summary.custom_variable_count = ($envItems | Where-Object { $_.Name -notin $wellKnown }).Count
    }
    if ($IncludeDiagnostics) {
        $diagnostics = @()
        $essential = @('SystemRoot','ComSpec','Path','TEMP','TMP','USERPROFILE','PSModulePath')
        $missing = @($essential | Where-Object { -not $env:$_ })
        if ($missing.Count -gt 0) {
            $diagnostics += [ordered]@{ level = 'error'; message = 'Missing essential variables: ' + ($missing -join ', ') }
            $summary.diagnostic_counts.error += 1
        }
        $report.diagnostics = $diagnostics
    }
    return [pscustomobject]$report
}
Export-ModuleMember -Function Get-EnvAuditorReport
""")
    return script.rstrip() + "\n"
