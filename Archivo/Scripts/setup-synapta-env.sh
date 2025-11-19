#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="setup-synapta-env"
SCRIPT_VERSION="1.1.0"
DEFAULT_DOTNET_CHANNEL="8.0"
DEFAULT_PWSH_VERSION="7.5.4"
DEFAULT_HOME_DIR="${HOME:-/workspace}"

DOTNET_CHANNEL="$DEFAULT_DOTNET_CHANNEL"
PWSH_VERSION="$DEFAULT_PWSH_VERSION"
HOME_DIR="$DEFAULT_HOME_DIR"
SUMMARY_FILE=""
SKIP_PSSA=false
COLOR_MODE="auto"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/installers/dotnet.sh"
source "$LIB_DIR/installers/pwsh.sh"
source "$LIB_DIR/installers/pssa.sh"

synapta::log::init "$COLOR_MODE"

usage() {
  cat <<USAGE
${SCRIPT_NAME} v${SCRIPT_VERSION}

Instala/actualiza .NET SDK, PowerShell y PSScriptAnalyzer en carpetas locales.

Opciones:
  -c, --channel <ver>       Canal del instalador de .NET (default: ${DEFAULT_DOTNET_CHANNEL})
  -p, --pwsh-version <ver>  Versión de PowerShell a instalar (default: ${DEFAULT_PWSH_VERSION})
  -H, --home <path>         Carpeta base para las herramientas (default: ${DEFAULT_HOME_DIR})
  -o, --summary <path>      Archivo donde escribir el resumen JSON (stdout si no se indica)
      --skip-pssa           Omite la instalación de PSScriptAnalyzer
      --no-color            Desactiva los colores ANSI
  -h, --help                Muestra esta ayuda
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--channel)
        DOTNET_CHANNEL="$2"; shift 2;;
      -p|--pwsh-version)
        PWSH_VERSION="$2"; shift 2;;
      -H|--home)
        HOME_DIR="$2"; shift 2;;
      -o|--summary)
        SUMMARY_FILE="$2"; shift 2;;
      --skip-pssa)
        SKIP_PSSA=true; shift;;
      --no-color)
        COLOR_MODE="never"; synapta::log::init "$COLOR_MODE"; shift;;
      -h|--help)
        usage; exit 0;;
      *)
        synapta::log::error "Opción desconocida: $1"; usage; exit 1;;
    esac
  done
}

write_summary() {
  cat <<JSON
{
  "script": {
    "name": "${SCRIPT_NAME}",
    "version": "${SCRIPT_VERSION}"
  },
  "dotnet": {
    "status": "${SYNAPTA_DOTNET_STATUS:-unknown}",
    "version": "${SYNAPTA_DOTNET_VERSION:-n/a}",
    "channel": "${DOTNET_CHANNEL}",
    "path": "${SYNAPTA_DOTNET_PATH:-${HOME_DIR}/.dotnet}"
  },
  "powershell": {
    "status": "${SYNAPTA_PWSH_STATUS:-unknown}",
    "version": "${SYNAPTA_PWSH_VERSION_INSTALLED:-n/a}",
    "path": "${SYNAPTA_PWSH_PATH:-${HOME_DIR}/.powershell/${PWSH_VERSION}}"
  },
  "psscriptanalyzer": {
    "status": "${SYNAPTA_PSSA_STATUS:-unknown}"
  }
}
JSON
}

main() {
  parse_args "$@"
  synapta::log::banner
  synapta::log::info "Directorio base: ${HOME_DIR}"

  synapta::log::section "Validaciones previas"
  synapta::utils::require_cmd curl
  synapta::utils::require_cmd tar

  synapta::log::section "Configurando .NET SDK"
  synapta::dotnet::ensure "$HOME_DIR" "$DOTNET_CHANNEL"

  synapta::log::section "Configurando PowerShell"
  synapta::pwsh::ensure "$HOME_DIR" "$PWSH_VERSION"

  synapta::log::section "Configurando PSScriptAnalyzer"
  local pwsh_bin="${SYNAPTA_PWSH_PATH}/pwsh"
  synapta::pssa::ensure "$pwsh_bin" "$SKIP_PSSA"

  synapta::log::section "Resumen"
  local summary
  summary=$(write_summary)
  synapta::utils::emit_summary "$SUMMARY_FILE" "$summary"
}

main "$@"
