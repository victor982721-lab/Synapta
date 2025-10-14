"""Core utilities for the environment auditor GUI/CLI tools."""
from __future__ import annotations

import datetime as _dt
import json
import logging
import os
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

logger = logging.getLogger(__name__)
if not logging.getLogger().handlers:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)sZ %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )

REPORT_WRAP_WIDTH = 110
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


def safe_expandvars(value: str) -> str:
    """Expand environment variables without throwing."""
    try:
        return os.path.expandvars(value)
    except Exception:  # pragma: no cover - defensive path
        logger.debug("Failed to expand environment variables", exc_info=True)
        return value


def _load_config_candidates(explicit_path: Optional[Path] = None) -> Iterable[Path]:
    if explicit_path:
        yield explicit_path
    env_override = os.environ.get("ENV_AUDITOR_CONFIG")
    if env_override:
        yield Path(env_override)
    cwd_candidate = Path.cwd() / "env_auditor.config.json"
    yield cwd_candidate
    module_dir = Path(__file__).resolve().parent
    yield module_dir / "env_auditor.config.json"
    yield module_dir.parent / "env_auditor.config.json"
    yield module_dir.parent / "config" / "env_auditor.config.json"
    yield module_dir.parent.parent / "env_auditor.config.json"
    yield module_dir.parent.parent / "config" / "env_auditor.config.json"


def load_configuration(config_path: Optional[str] = None) -> Tuple[set[str], set[str]]:
    """Load WELL_KNOWN and ESSENTIAL sets from JSON configuration."""
    explicit = Path(config_path) if config_path else None
    for candidate in _load_config_candidates(explicit):
        if candidate and candidate.is_file():
            try:
                with candidate.open("r", encoding="utf-8") as handle:
                    payload = json.load(handle)
                logger.info(json.dumps({
                    "event": "config_loaded",
                    "path": str(candidate),
                }))
                well_known = set(payload.get("well_known", DEFAULT_WELL_KNOWN))
                essential = set(payload.get("essential", DEFAULT_ESSENTIAL))
                return well_known, essential
            except (OSError, json.JSONDecodeError) as exc:
                logger.warning(json.dumps({
                    "event": "config_load_failed",
                    "path": str(candidate),
                    "error": str(exc),
                }))
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
        generated_at = _dt.datetime.utcnow().isoformat(timespec="seconds") + "Z"
        report: Dict[str, Any] = {
            "generated_at": generated_at,
            "summary": {
                "environment_variable_count": len(env_items),
            },
        }

        diagnostics: List[Dict[str, str]] = []

        if options.include_env:
            report["environment_variables"] = [
                {
                    "name": name,
                    "value": value,
                }
                for name, value in env_items
            ]

        if options.include_path:
            path_section = self._build_path_section(env_map.get("Path", ""))
            report["path_entries"] = path_section["entries"]
            report["path_duplicates"] = path_section["duplicates"]
            report["summary"]["path_entry_count"] = len(path_section["entries"])
            report["summary"]["path_duplicate_count"] = len(path_section["duplicates"])
            report["summary"]["path_missing_targets"] = path_section["missing"]
            report["summary"]["path_access_denied"] = path_section["access_denied"]
            diagnostics.extend(path_section["diagnostics"])
        else:
            report["summary"]["path_entry_count"] = len(self._split_entries(env_map.get("Path", "")))
            report["summary"]["path_duplicate_count"] = 0
            report["summary"]["path_missing_targets"] = 0
            report["summary"]["path_access_denied"] = 0

        if options.include_psmodule:
            psmodule_entries = self._split_entries(env_map.get("PSModulePath", ""))
            detailed_entries = []
            for index, entry in enumerate(psmodule_entries):
                expanded = safe_expandvars(entry)
                status = self._determine_status(expanded)
                detailed_entries.append({
                    "index": index + 1,
                    "raw": entry,
                    "expanded": expanded,
                    "exists": os.path.exists(expanded),
                    "status": status,
                })
            report["psmodule_entries"] = detailed_entries
            report["summary"]["psmodule_count"] = len(psmodule_entries)
            missing = [item for item in report["psmodule_entries"] if item["status"] == "missing"]
            for item in missing:
                diagnostics.append({
                    "level": "warning",
                    "message": f"PSModulePath entry does not exist or is inaccessible: {item['raw']}",
                })
        else:
            report["summary"]["psmodule_count"] = len(self._split_entries(env_map.get("PSModulePath", "")))

        if options.include_custom:
            custom = [
                {
                    "name": name,
                    "value": value,
                }
                for name, value in env_items
                if name not in self.well_known
            ]
            report["custom_variables"] = custom
            report["summary"]["custom_variable_count"] = len(custom)
        else:
            report["summary"]["custom_variable_count"] = len([
                name for name, _ in env_items if name not in self.well_known
            ])

        if options.include_diagnostics:
            missing_essential = [var for var in self.essential if var not in env_map]
            if missing_essential:
                diagnostics.append({
                    "level": "error",
                    "message": f"Missing essential variables: {', '.join(sorted(missing_essential))}",
                })

            short_path_vars = [name for name, value in env_items if "~" in value]
            if short_path_vars:
                diagnostics.append({
                    "level": "info",
                    "message": f"Variables using short paths: {', '.join(sorted(short_path_vars))}",
                })

        severity_order = {"error": 0, "warning": 1, "info": 2}
        diagnostics.sort(key=lambda item: severity_order.get(item.get("level", "info"), 3))
        report["diagnostics"] = diagnostics if options.include_diagnostics else []

        summary_counts = {"error": 0, "warning": 0, "info": 0}
        for item in diagnostics:
            level = item.get("level", "info").lower()
            summary_counts[level] = summary_counts.get(level, 0) + 1
        report["summary"]["diagnostic_counts"] = summary_counts

        logger.info(json.dumps({
            "event": "audit_completed",
            "diagnostics": summary_counts,
            "options": options.__dict__,
        }))

        return report

    @staticmethod
    def _split_entries(raw: str) -> List[str]:
        return [segment.strip() for segment in raw.split(";") if segment.strip()]

    def _build_path_section(self, raw: str) -> Dict[str, Any]:
        entries = self._split_entries(raw)
        normalized_keys = []
        for entry in entries:
            expanded = safe_expandvars(entry)
            norm = os.path.normcase(os.path.normpath(expanded))
            normalized_keys.append(norm)

        duplicates_map: Dict[str, List[int]] = {}
        for idx, key in enumerate(normalized_keys):
            duplicates_map.setdefault(key, []).append(idx)

        result_entries = []
        missing_count = 0
        access_denied_count = 0
        diagnostics: List[Dict[str, str]] = []

        for idx, entry in enumerate(entries):
            expanded = safe_expandvars(entry)
            exists = os.path.exists(expanded)
            status = self._determine_status(expanded)
            if status == "missing":
                missing_count += 1
            readable = os.access(expanded, os.R_OK)
            duplicate = len(duplicates_map.get(normalized_keys[idx], [])) > 1
            uses_short = "~" in entry
            if status == "missing":
                diagnostics.append({
                    "level": "warning",
                    "message": f"PATH entry does not exist: {entry}",
                })
            elif status == "access_denied":
                access_denied_count += 1
                diagnostics.append({
                    "level": "warning",
                    "message": f"PATH entry access denied: {entry}",
                })
            duplicate_message = f"Duplicate PATH entry: {entry}"
            if duplicate and not any(d.get("message") == duplicate_message for d in diagnostics):
                diagnostics.append({
                    "level": "info",
                    "message": duplicate_message,
                })
            short_path_message = f"PATH entry uses short path notation: {entry}"
            if uses_short and not any(d.get("message") == short_path_message for d in diagnostics):
                diagnostics.append({
                    "level": "info",
                    "message": short_path_message,
                })
            result_entries.append({
                "index": idx + 1,
                "raw": entry,
                "expanded": expanded,
                "exists": exists,
                "duplicate": duplicate,
                "uses_short_path": uses_short,
                "readable": readable,
                "status": status,
            })

        duplicates = [
            {
                "entry": entries[indices[0]],
                "count": len(indices),
            }
            for indices in duplicates_map.values()
            if len(indices) > 1
        ]

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
            is_dir = os.path.isdir(expanded)
            is_file = os.path.isfile(expanded)
            if is_dir:
                return "dir"
            if is_file:
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
            lines.append("### PATH Duplicate Details")
            lines.append("```")
            lines.append(ascii_table(["Count", "Entry"], duplicate_rows))
            lines.append("```")
            lines.append("")

    if options.include_psmodule and report.get("psmodule_entries"):
        module_rows = [
            [item["index"], item["raw"], item["status"]]
            for item in report["psmodule_entries"]
        ]
        lines.append("## PSModulePath Entries")
        lines.append("```")
        lines.append(ascii_table(["#", "Entry", "Status"], module_rows))
        lines.append("```")
        lines.append("")

    if options.include_custom and report.get("custom_variables"):
        custom_rows = [[item["name"], item["value"]] for item in report["custom_variables"]]
        lines.append("## Custom Environment Variables")
        lines.append("```")
        lines.append(ascii_table(["Name", "Value"], custom_rows))
        lines.append("```")
        lines.append("")

    if options.include_diagnostics and report.get("diagnostics"):
        diag_rows = [
            [item["level"].upper(), item["message"]]
            for item in report["diagnostics"]
        ]
        lines.append("## Diagnostics")
        lines.append("```")
        lines.append(ascii_table(["Level", "Message"], diag_rows))
        lines.append("```")
        lines.append("")

    return "\n".join(lines)


def build_powershell_script() -> str:
    return r"""
function Expand-EnvSafe {
    param([string]$Value)
    try {
        return [System.Environment]::ExpandEnvironmentVariables($Value)
    } catch {
        return $Value
    }
}

function Normalize-PathKey {
    param([string]$Value)
    try {
        $full = [System.IO.Path]::GetFullPath($Value)
        return $full.TrimEnd('\\').ToLowerInvariant()
    } catch {
        return $Value.ToLowerInvariant()
    }
}

function Get-PathStatus {
    param([string]$Value)
    try {
        $item = Get-Item -LiteralPath $Value -ErrorAction Stop
        if ($item.PSIsContainer) { return 'dir' }
        return 'file'
    } catch [System.UnauthorizedAccessException] {
        return 'access_denied'
    } catch {
        if (Test-Path -LiteralPath $Value) { return 'unknown' }
        return 'missing'
    }
}

function Invoke-EnvAudit {
    param(
        [switch]$IncludeEnv,
        [switch]$IncludePath,
        [switch]$IncludePSModule,
        [switch]$IncludeCustom,
        [switch]$IncludeDiagnostics
    )

    $envItems = Get-ChildItem Env: | Sort-Object Name
    $report = [ordered]@{}
    $report.GeneratedAt = (Get-Date -AsUTC).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $report.Summary = [ordered]@{
        EnvironmentVariableCount = $envItems.Count
        PathEntryCount = 0
        PathDuplicateCount = 0
        PathMissingTargets = 0
        PathAccessDenied = 0
        PSModuleCount = 0
        CustomVariableCount = 0
    }

    if ($IncludeEnv) {
        $report.EnvironmentVariables = $envItems | ForEach-Object {
            [ordered]@{ Name = $_.Name; Value = $_.Value }
        }
    }

    if ($IncludePath) {
        $pathEntries = ($env:Path -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })
        $normalized = @{}
        for ($i = 0; $i -lt $pathEntries.Count; $i++) {
            $expanded = Expand-EnvSafe $pathEntries[$i]
            $key = Normalize-PathKey $expanded
            if (-not $normalized.ContainsKey($key)) { $normalized[$key] = @() }
            $normalized[$key] += $i
        }

        $entries = @()
        $duplicates = @()
        for ($i = 0; $i -lt $pathEntries.Count; $i++) {
            $entry = $pathEntries[$i]
            $expanded = Expand-EnvSafe $entry
            $status = Get-PathStatus $expanded
            if ($status -eq 'missing') { $report.Summary.PathMissingTargets++ }
            if ($status -eq 'access_denied') { $report.Summary.PathAccessDenied++ }
            $key = Normalize-PathKey $expanded
            $duplicate = $false
            if ($normalized.ContainsKey($key) -and $normalized[$key].Count -gt 1) {
                $duplicate = $true
                $duplicates += [ordered]@{ Entry = $entry; Count = $normalized[$key].Count }
            }
            $entries += [ordered]@{
                Index = $i + 1
                Entry = $entry
                Duplicate = $duplicate
                Status = $status
            }
        }

        $report.PathEntries = $entries
        $report.PathDuplicates = $duplicates | Sort-Object Entry -Unique
        $report.Summary.PathEntryCount = $pathEntries.Count
        $report.Summary.PathDuplicateCount = $report.PathDuplicates.Count
    }

    if ($IncludePSModule) {
        $moduleEntries = ($env:PSModulePath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })
        $report.PSModulePathEntries = @()
        for ($i = 0; $i -lt $moduleEntries.Count; $i++) {
            $expanded = Expand-EnvSafe $moduleEntries[$i]
            $status = Get-PathStatus $expanded
            $report.PSModulePathEntries += [ordered]@{
                Index = $i + 1
                Entry = $moduleEntries[$i]
                Status = $status
            }
        }
        $report.Summary.PSModuleCount = $moduleEntries.Count
    }

    if ($IncludeCustom) {
        $configPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath 'env_auditor.config.json'
        $wellKnown = @()
        if (Test-Path $configPath) {
            try {
                $payload = Get-Content $configPath -Raw | ConvertFrom-Json
                $wellKnown = @($payload.well_known)
            } catch {
                $wellKnown = @()
            }
        }
        if (-not $wellKnown) {
            $wellKnown = @(
                'ALLUSERSPROFILE','APPDATA','CLIENTNAME','CommonProgramFiles','CommonProgramFiles(x86)',
                'CommonProgramW6432','COMPUTERNAME','ComSpec','DriverData','HOMEDRIVE','HOMEPATH','LOCALAPPDATA',
                'LOGONSERVER','NUMBER_OF_PROCESSORS','OneDrive','OneDriveConsumer','OS','Path','PATHEXT',
                'PROCESSOR_ARCHITECTURE','PROCESSOR_IDENTIFIER','PROCESSOR_LEVEL','PROCESSOR_REVISION','ProgramData',
                'ProgramFiles','ProgramFiles(x86)','ProgramW6432','PROMPT','PUBLIC','SystemDrive','SystemRoot','TEMP',
                'TMP','USERDOMAIN','USERDOMAIN_ROAMINGPROFILE','USERNAME','USERPROFILE','windir','PSModulePath',
                'ChocolateyInstall','ChocolateyLastPathUpdate','POSH_THEMES_PATH'
            )
        }
        $custom = $envItems | Where-Object { $wellKnown -notcontains $_.Name }
        $report.CustomVariables = $custom | ForEach-Object {
            [ordered]@{ Name = $_.Name; Value = $_.Value }
        }
        $report.Summary.CustomVariableCount = $custom.Count
    }

    if ($IncludeDiagnostics) {
        $diagnostics = @()
        $essential = @('SystemRoot','ComSpec','Path','TEMP','TMP','USERPROFILE','PSModulePath')
        $missing = $essential | Where-Object { -not $env:$_ }
        if ($missing) {
            $diagnostics += [ordered]@{ Level = 'Error'; Message = "Missing essential variables: $($missing -join ', ')" }
        }
        if ($IncludePath -and $report.PathEntries) {
            foreach ($entry in $report.PathEntries) {
                if ($entry.Status -eq 'missing' -or $entry.Status -eq 'access_denied') {
                    $diagnostics += [ordered]@{ Level = 'Warning'; Message = "PATH entry issue: $($entry.Entry) -> $($entry.Status)" }
                }
            }
        }
        $report.Diagnostics = $diagnostics
    }

    return [pscustomobject]$report
}

function Export-EnvAuditMarkdown {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [switch]$IncludeEnv,
        [switch]$IncludePath,
        [switch]$IncludePSModule,
        [switch]$IncludeCustom,
        [switch]$IncludeDiagnostics
    )

    $report = Invoke-EnvAudit @PSBoundParameters
    $sb = New-Object System.Text.StringBuilder
    $null = $sb.AppendLine('# Environment & Session Report')
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("- Generated: $($report.GeneratedAt)")
    $null = $sb.AppendLine("- Environment variables: $($report.Summary.EnvironmentVariableCount)")
    $null = $sb.AppendLine("- PATH entries: $($report.Summary.PathEntryCount)")
    $null = $sb.AppendLine("- PATH duplicates: $($report.Summary.PathDuplicateCount)")
    $null = $sb.AppendLine("- PATH entries with missing targets: $($report.Summary.PathMissingTargets)")
    $null = $sb.AppendLine("- PATH entries with access denied: $($report.Summary.PathAccessDenied)")
    $null = $sb.AppendLine("- PSModulePath entries: $($report.Summary.PSModuleCount)")
    $null = $sb.AppendLine("- Custom environment variables: $($report.Summary.CustomVariableCount)")
    Set-Content -Path $Path -Value $sb.ToString() -Encoding UTF8
}

Export-ModuleMember -Function Invoke-EnvAudit, Export-EnvAuditMarkdown
"""
