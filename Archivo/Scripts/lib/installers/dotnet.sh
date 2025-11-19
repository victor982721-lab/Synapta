#!/usr/bin/env bash

synapta::dotnet::install() {
  local install_dir=$1
  local channel=$2
  local installer="/tmp/dotnet-install.sh"

  synapta::utils::ensure_dir "$install_dir"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer"
  chmod +x "$installer"
  "$installer" --channel "$channel" --install-dir "$install_dir" --no-path
  rm -f "$installer"
}

synapta::dotnet::ensure() {
  local home_dir=$1
  local channel=$2
  local major=${channel%%.*}
  local install_dir="$home_dir/.dotnet"

  export DOTNET_ROOT="$install_dir"
  export PATH="$DOTNET_ROOT:$PATH"

  if command -v dotnet >/dev/null 2>&1 && dotnet --list-sdks 2>/dev/null | grep -q "^${major}\\."; then
    SYNAPTA_DOTNET_STATUS="already-installed"
    SYNAPTA_DOTNET_VERSION="$(dotnet --version)"
    synapta::log::success ".NET SDK ${SYNAPTA_DOTNET_VERSION} disponible."
  else
    synapta::log::info "Instalando .NET SDK canal ${channel} en ${install_dir}..."
    synapta::dotnet::install "$install_dir" "$channel"
    SYNAPTA_DOTNET_STATUS="installed"
    SYNAPTA_DOTNET_VERSION="$("$install_dir/dotnet" --version)"
    synapta::log::success ".NET SDK ${SYNAPTA_DOTNET_VERSION} instalado."
  fi
  SYNAPTA_DOTNET_PATH="$install_dir"
}
