#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="setup-synapta-env"
SCRIPT_VERSION="1.0.0"
DEFAULT_DOTNET_CHANNEL="8.0"
DEFAULT_PWSH_VERSION="7.5.4"
DEFAULT_HOME_DIR="${HOME:-/workspace}"
SUMMARY_FILE=""
SKIP_PSSA=false
DOTNET_CHANNEL="$DEFAULT_DOTNET_CHANNEL"
PWSH_VERSION="$DEFAULT_PWSH_VERSION"
HOME_DIR="$DEFAULT_HOME_DIR"
COLOR=true

# -------------------------
# ANSI helpers
# -------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  COLORS=("$(tput setaf 6)" "$(tput setaf 2)" "$(tput setaf 3)" "$(tput setaf 1)" "$(tput bold)" "$(tput sgr0)")
else
  COLOR=false
fi

if [[ "$COLOR" == true ]]; then
  CYAN="${COLORS[0]}"
  GREEN="${COLORS[1]}"
  YELLOW="${COLORS[2]}"
  RED="${COLORS[3]}"
  BOLD="${COLORS[4]}"
  RESET="${COLORS[5]}"
else
  CYAN=""; GREEN=""; YELLOW=""; RED=""; BOLD=""; RESET=""
fi

print_banner() {
  cat <<'ART'
   ____                        _        _          
  / ___| _   _ _ __   ___ _ __| |_ __ _| |_ ___ _ __ 
  \___ \| | | | '_ \ / _ \ '__| __/ _` | __/ _ \ '__|
   ___) | |_| | |_) |  __/ |  | || (_| | ||  __/ |   
  |____/ \__,_| .__/ \___|_|   \__\__,_|\__\___|_|   
               |_|                                     
ART
}

log_section() { printf "\n${BOLD}${CYAN}==> %s${RESET}\n" "$1"; }
log_info()    { printf "${CYAN}• %s${RESET}\n" "$1"; }
log_success() { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
log_warn()    { printf "${YELLOW}! %s${RESET}\n" "$1"; }
log_error()   { printf "${RED}✖ %s${RESET}\n" "$1"; }

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
        COLOR=false; CYAN=""; GREEN=""; YELLOW=""; RED=""; BOLD=""; RESET=""; shift;;
      -h|--help)
        usage; exit 0;;
      *)
        log_error "Opción desconocida: $1"; usage; exit 1;;
    esac
  done
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Comando requerido no encontrado: $1"; exit 1
  fi
}

install_dotnet() {
  local install_dir="$HOME_DIR/.dotnet"
  local installer="/tmp/dotnet-install.sh"
  mkdir -p "$install_dir"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer"
  chmod +x "$installer"
  "$installer" --channel "$DOTNET_CHANNEL" --install-dir "$install_dir" --no-path
  rm -f "$installer"
  export DOTNET_ROOT="$install_dir"
  export PATH="$DOTNET_ROOT:$PATH"
}

check_dotnet() {
  local install_dir="$HOME_DIR/.dotnet"
  export DOTNET_ROOT="$install_dir"
  export PATH="$DOTNET_ROOT:$PATH"
  if command -v dotnet >/dev/null 2>&1 && dotnet --list-sdks 2>/dev/null | grep -q "^${DOTNET_CHANNEL%%.*}\\."; then
    DOTNET_STATUS="already-installed"
    DOTNET_VERSION="$(dotnet --version)"
    log_success ".NET SDK ${DOTNET_VERSION} disponible."
  else
    log_info "Instalando .NET SDK canal ${DOTNET_CHANNEL} en ${install_dir}..."
    install_dotnet
    DOTNET_STATUS="installed"
    DOTNET_VERSION="$("$install_dir/dotnet" --version)"
    log_success "Instalado .NET SDK ${DOTNET_VERSION}."
  fi
}

install_pwsh() {
  local pwsh_dir="$HOME_DIR/.powershell/${PWSH_VERSION}"
  local tarball="/tmp/powershell-${PWSH_VERSION}.tar.gz"
  mkdir -p "$pwsh_dir"
  curl -L -o "$tarball" "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-x64.tar.gz"
  tar -xzf "$tarball" -C "$pwsh_dir"
  chmod +x "$pwsh_dir/pwsh"
  rm -f "$tarball"
  export PATH="$pwsh_dir:$PATH"
}

check_pwsh() {
  local pwsh_dir="$HOME_DIR/.powershell/${PWSH_VERSION}"
  export PATH="$pwsh_dir:$PATH"
  if [[ -x "$pwsh_dir/pwsh" ]]; then
    PWSH_STATUS="already-installed"
    log_success "PowerShell ${PWSH_VERSION} ya presente en ${pwsh_dir}."
  else
    log_info "Instalando PowerShell ${PWSH_VERSION} en ${pwsh_dir}..."
    install_pwsh
    PWSH_STATUS="installed"
    log_success "PowerShell ${PWSH_VERSION} instalado."
  fi
  PWSH_VERSION_INSTALLED="$("$pwsh_dir/pwsh" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')"
}

install_pssa() {
  local script="/tmp/install_pssa.ps1"
  cat > "$script" <<'PSSCRIPT'
$ErrorActionPreference = 'Stop'
if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
  Register-PSRepository -Default
}
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
PSSCRIPT
  if pwsh -NoLogo -NoProfile -File "$script"; then
    PSSA_STATUS="installed"
    log_success "PSScriptAnalyzer instalado."
  else
    PSSA_STATUS="failed"
    log_warn "No se pudo instalar PSScriptAnalyzer."
  fi
  rm -f "$script"
}

check_pssa() {
  if [[ "$SKIP_PSSA" == true ]]; then
    PSSA_STATUS="skipped"
    log_warn "Instalación de PSScriptAnalyzer omitida por bandera."
    return
  fi
  if pwsh -NoLogo -NoProfile -Command 'Get-Module PSScriptAnalyzer -ListAvailable | Select-Object -First 1 Name' >/dev/null 2>&1; then
    PSSA_STATUS="already-installed"
    log_success "PSScriptAnalyzer ya está disponible."
  else
    log_info "Instalando PSScriptAnalyzer (best-effort)..."
    install_pssa
  fi
}

write_summary() {
  local summary
  summary=$(cat <<JSON
{
  "script": {
    "name": "${SCRIPT_NAME}",
    "version": "${SCRIPT_VERSION}"
  },
  "dotnet": {
    "status": "${DOTNET_STATUS:-unknown}",
    "version": "${DOTNET_VERSION:-n/a}",
    "channel": "${DOTNET_CHANNEL}",
    "path": "${HOME_DIR}/.dotnet"
  },
  "powershell": {
    "status": "${PWSH_STATUS:-unknown}",
    "version": "${PWSH_VERSION_INSTALLED:-n/a}",
    "path": "${HOME_DIR}/.powershell/${PWSH_VERSION}"
  },
  "psscriptanalyzer": {
    "status": "${PSSA_STATUS:-unknown}"
  }
}
JSON
  )
  if [[ -n "$SUMMARY_FILE" ]]; then
    mkdir -p "$(dirname "$SUMMARY_FILE")"
    printf '%s\n' "$summary" > "$SUMMARY_FILE"
    log_info "Resumen JSON guardado en $SUMMARY_FILE"
  fi
  printf '\n%s\n' "$summary"
}

main() {
  parse_args "$@"
  print_banner
  log_info "Directorio base: ${HOME_DIR}"
  log_section "Validaciones previas"
  require_cmd curl
  require_cmd tar

  log_section "Configurando .NET SDK"
  check_dotnet

  log_section "Configurando PowerShell"
  check_pwsh

  log_section "Configurando PSScriptAnalyzer"
  check_pssa

  log_section "Resumen"
  write_summary
}

main "$@"
