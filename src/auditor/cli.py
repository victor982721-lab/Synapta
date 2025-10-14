"""Command line interface for the environment auditor."""
from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Iterable, Optional

from .auditor_core import AuditOptions, EnvironmentAuditor, build_markdown

logger = logging.getLogger(__name__)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Environment auditor CLI")
    parser.add_argument(
        "--config",
        help="Ruta alternativa para env_auditor.config.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Archivo de salida. Si se omite, imprime en stdout",
    )
    parser.add_argument(
        "--include-env",
        action="store_true",
        default=True,
        help="Incluir variables de entorno (default)",
    )
    parser.add_argument(
        "--no-include-env",
        dest="include_env",
        action="store_false",
        help="Omitir variables de entorno",
    )
    parser.add_argument(
        "--include-path",
        action="store_true",
        default=True,
        help="Incluir PATH",
    )
    parser.add_argument(
        "--no-include-path",
        dest="include_path",
        action="store_false",
        help="Omitir PATH",
    )
    parser.add_argument(
        "--include-psmodule",
        action="store_true",
        default=True,
        help="Incluir PSModulePath",
    )
    parser.add_argument(
        "--no-include-psmodule",
        dest="include_psmodule",
        action="store_false",
        help="Omitir PSModulePath",
    )
    parser.add_argument(
        "--include-custom",
        action="store_true",
        default=True,
        help="Incluir variables personalizadas",
    )
    parser.add_argument(
        "--no-include-custom",
        dest="include_custom",
        action="store_false",
        help="Omitir variables personalizadas",
    )
    parser.add_argument(
        "--include-diagnostics",
        action="store_true",
        default=True,
        help="Incluir diagnósticos",
    )
    parser.add_argument(
        "--no-include-diagnostics",
        dest="include_diagnostics",
        action="store_false",
        help="Omitir diagnósticos",
    )
    format_group = parser.add_mutually_exclusive_group(required=True)
    format_group.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Exportar como JSON",
    )
    format_group.add_argument(
        "--markdown",
        "--md",
        action="store_true",
        dest="markdown_output",
        help="Exportar como Markdown",
    )
    return parser


def _write_output(content: str, target: Optional[Path]) -> None:
    if target is None:
        sys.stdout.write(content)
        if not content.endswith("\n"):
            sys.stdout.write("\n")
        return
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("w", encoding="utf-8") as handle:
            handle.write(content)
        logger.info(json.dumps({
            "event": "cli_output_written",
            "path": str(target),
        }))
    except OSError as exc:
        logger.error(json.dumps({
            "event": "cli_output_failed",
            "path": str(target),
            "error": str(exc),
        }))
        raise


def run_cli(argv: Optional[Iterable[str]] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    options = AuditOptions(
        include_env=args.include_env,
        include_path=args.include_path,
        include_psmodule=args.include_psmodule,
        include_custom=args.include_custom,
        include_diagnostics=args.include_diagnostics,
    )
    auditor = EnvironmentAuditor(config_path=args.config)
    report = auditor.run(options)
    if args.json_output:
        output = json.dumps(report, indent=2, ensure_ascii=False)
    else:
        output = build_markdown(report, options)
    try:
        _write_output(output, args.output)
    except OSError:
        return 1
    return 0


def main() -> int:
    return run_cli()


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    sys.exit(main())
