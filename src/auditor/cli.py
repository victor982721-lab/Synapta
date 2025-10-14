"""Command-line interface for EnvAuditor."""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

from .auditor_core import (
    AuditOptions,
    EnvironmentAuditor,
    RuntimeContext,
    atomic_write_text,
    build_markdown,
    create_runtime_context,
    ensure_within_directory,
    generate_op_id,
)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Environment auditor CLI")
    parser.add_argument("--config", help="Ruta alternativa para env_auditor.config.json")
    parser.add_argument(
        "--output",
        type=Path,
        help="Archivo de salida (debe residir bajo ROOT/out). Si se omite, stdout",
    )
    parser.add_argument("--include-env", action="store_true", default=True, help="Incluir variables de entorno (default)")
    parser.add_argument("--no-include-env", dest="include_env", action="store_false", help="Omitir variables de entorno")
    parser.add_argument("--include-path", action="store_true", default=True, help="Incluir PATH")
    parser.add_argument("--no-include-path", dest="include_path", action="store_false", help="Omitir PATH")
    parser.add_argument("--include-psmodule", action="store_true", default=True, help="Incluir PSModulePath")
    parser.add_argument("--no-include-psmodule", dest="include_psmodule", action="store_false", help="Omitir PSModulePath")
    parser.add_argument("--include-custom", action="store_true", default=True, help="Incluir variables personalizadas")
    parser.add_argument("--no-include-custom", dest="include_custom", action="store_false", help="Omitir variables personalizadas")
    parser.add_argument("--include-diagnostics", action="store_true", default=True, help="Incluir diagnósticos")
    parser.add_argument(
        "--no-include-diagnostics",
        dest="include_diagnostics",
        action="store_false",
        help="Omitir diagnósticos",
    )
    format_group = parser.add_mutually_exclusive_group(required=True)
    format_group.add_argument("--json", action="store_true", dest="json_output", help="Exportar como JSON")
    format_group.add_argument("--markdown", "--md", action="store_true", dest="markdown_output", help="Exportar como Markdown")
    return parser


def _write_output(
    content: str,
    target: Optional[Path],
    context: RuntimeContext,
    format_label: str,
) -> Dict[str, Any]:
    op_id = generate_op_id()
    payload_bytes = content.encode("utf-8")
    if target is None:
        sys.stdout.write(content)
        if not content.endswith("\n"):
            sys.stdout.write("\n")
        context.logger.log_event(
            level="info",
            event="cli.stdout",
            op_id=op_id,
            message=f"Emitted {format_label} report to stdout",
            bytes_count=len(payload_bytes),
        )
        return {"destination": "stdout", "bytes": len(payload_bytes)}
    candidate = target
    if not candidate.is_absolute():
        candidate = context.paths.root / candidate
    candidate = ensure_within_directory(
        candidate,
        root=context.paths.root,
        directory=context.paths.out_dir,
        label=str(context.paths.out_dir),
    )
    start = time.perf_counter()
    info = atomic_write_text(
        content=content,
        target=candidate,
        root=context.paths.root,
        logger=context.logger,
        op_id=op_id,
    )
    duration = (time.perf_counter() - start) * 1000
    context.logger.log_event(
        level="info",
        event="cli.file_output",
        op_id=op_id,
        message=f"Persisted {format_label} report",
        context={"path": info["path"]},
        result={k: v for k, v in info.items() if k != "path"},
        duration_ms=duration,
        bytes_count=info.get("bytes"),
    )
    return info


def run_cli(argv: Optional[Iterable[str]] = None) -> int:
    context = create_runtime_context()
    parser = _build_parser()
    try:
        args = parser.parse_args(list(argv) if argv is not None else None)
    except SystemExit as exc:  # pragma: no cover - argparse handles message
        return exc.code or 1
    options = AuditOptions(
        include_env=args.include_env,
        include_path=args.include_path,
        include_psmodule=args.include_psmodule,
        include_custom=args.include_custom,
        include_diagnostics=args.include_diagnostics,
    )
    try:
        auditor = EnvironmentAuditor(context.paths.root, config_path=args.config)
    except ValueError as exc:
        context.logger.log_event(
            level="error",
            event="cli.config_invalid",
            op_id=generate_op_id(),
            message=str(exc),
        )
        return 2
    report = auditor.run(options)
    format_label = "json" if args.json_output else "markdown"
    if args.json_output:
        output = json.dumps(report, indent=2, ensure_ascii=False)
    else:
        output = build_markdown(report, options)
    try:
        output_info = _write_output(output, args.output, context, format_label)
    except ValueError as exc:
        context.logger.log_event(
            level="error",
            event="cli.validation_failed",
            op_id=generate_op_id(),
            message=str(exc),
        )
        return 2
    except OSError as exc:
        context.logger.log_event(
            level="error",
            event="cli.io_failed",
            op_id=generate_op_id(),
            message=str(exc),
        )
        return 3
    context.logger.log_event(
        level="info",
        event="cli.completed",
        op_id=generate_op_id(),
        message="CLI execution finished successfully",
        result={
            "format": format_label,
            "diagnostics": report["summary"].get("diagnostic_counts", {}),
            "output": output_info,
        },
    )
    return 0


def main() -> int:
    return run_cli()


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    sys.exit(main())
