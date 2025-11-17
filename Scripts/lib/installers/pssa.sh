#!/usr/bin/env bash

synapta::pssa::install() {
  local pwsh_bin=$1
  local script="/tmp/install_pssa.ps1"
  cat >"$script" <<'PSSCRIPT'
$ErrorActionPreference = 'Stop'
if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
  Register-PSRepository -Default
}
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
PSSCRIPT
  if "$pwsh_bin" -NoLogo -NoProfile -File "$script"; then
    SYNAPTA_PSSA_STATUS="installed"
    synapta::log::success "PSScriptAnalyzer instalado."
  else
    SYNAPTA_PSSA_STATUS="failed"
    synapta::log::warn "No se pudo instalar PSScriptAnalyzer."
  fi
  rm -f "$script"
}

synapta::pssa::ensure() {
  local pwsh_bin=$1
  local skip=$2

  if [[ $skip == true ]]; then
    SYNAPTA_PSSA_STATUS="skipped"
    synapta::log::warn "Instalación de PSScriptAnalyzer omitida por bandera."
    return
  fi

  if "$pwsh_bin" -NoLogo -NoProfile -Command 'Get-Module PSScriptAnalyzer -ListAvailable | Select-Object -First 1 Name' >/dev/null 2>&1; then
    SYNAPTA_PSSA_STATUS="already-installed"
    synapta::log::success "PSScriptAnalyzer ya está disponible."
  else
    synapta::log::info "Instalando PSScriptAnalyzer (best-effort)..."
    synapta::pssa::install "$pwsh_bin"
  fi
}
