#!/usr/bin/env bash

synapta::pwsh::install() {
  local pwsh_dir=$1
  local version=$2
  local tarball="/tmp/powershell-${version}.tar.gz"
  synapta::utils::ensure_dir "$pwsh_dir"
  curl -L -o "$tarball" "https://github.com/PowerShell/PowerShell/releases/download/v${version}/powershell-${version}-linux-x64.tar.gz"
  tar -xzf "$tarball" -C "$pwsh_dir"
  chmod +x "$pwsh_dir/pwsh"
  rm -f "$tarball"
}

synapta::pwsh::ensure() {
  local home_dir=$1
  local version=$2
  local pwsh_dir="$home_dir/.powershell/${version}"
  local pwsh_bin="$pwsh_dir/pwsh"

  export PATH="$pwsh_dir:$PATH"

  if [[ -x $pwsh_bin ]]; then
    SYNAPTA_PWSH_STATUS="already-installed"
    synapta::log::success "PowerShell ${version} ya presente en ${pwsh_dir}."
  else
    synapta::log::info "Instalando PowerShell ${version} en ${pwsh_dir}..."
    synapta::pwsh::install "$pwsh_dir" "$version"
    SYNAPTA_PWSH_STATUS="installed"
    synapta::log::success "PowerShell ${version} instalado."
  fi

  SYNAPTA_PWSH_PATH="$pwsh_dir"
  SYNAPTA_PWSH_VERSION_INSTALLED="$("$pwsh_bin" -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')"
}
