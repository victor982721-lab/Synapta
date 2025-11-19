#!/usr/bin/env bash
# shellcheck disable=SC2034

synapta::log::init() {
  local mode=${1:-auto}
  local supports_color=false

  if [[ $mode == always ]]; then
    supports_color=true
  elif [[ $mode == auto && -t 1 ]]; then
    if command -v tput >/dev/null 2>&1; then
      supports_color=true
    fi
  fi

  if [[ $supports_color == true ]]; then
    SYNAPTA_CLR_CYAN=$(tput setaf 6)
    SYNAPTA_CLR_GREEN=$(tput setaf 2)
    SYNAPTA_CLR_YELLOW=$(tput setaf 3)
    SYNAPTA_CLR_RED=$(tput setaf 1)
    SYNAPTA_CLR_BOLD=$(tput bold)
    SYNAPTA_CLR_RESET=$(tput sgr0)
  else
    SYNAPTA_CLR_CYAN=""
    SYNAPTA_CLR_GREEN=""
    SYNAPTA_CLR_YELLOW=""
    SYNAPTA_CLR_RED=""
    SYNAPTA_CLR_BOLD=""
    SYNAPTA_CLR_RESET=""
  fi
}

synapta::log::banner() {
  cat <<'ART'
   ____                        _        _
  / ___| _   _ _ __   ___ _ __| |_ __ _| |_ ___ _ __
  \___ \| | | | '_ \ / _ \ '__| __/ _` | __/ _ \ '__|
   ___) | |_| | |_) |  __/ |  | || (_| | ||  __/ |
  |____/ \__,_| .__/ \___|_|   \__\__,_|\__\___|_|
               |_|
ART
}

synapta::log::section() { printf "\n%s%s==> %s%s\n" "$SYNAPTA_CLR_BOLD" "$SYNAPTA_CLR_CYAN" "$1" "$SYNAPTA_CLR_RESET"; }
synapta::log::info()    { printf "%s• %s%s\n" "$SYNAPTA_CLR_CYAN" "$1" "$SYNAPTA_CLR_RESET"; }
synapta::log::success() { printf "%s✔ %s%s\n" "$SYNAPTA_CLR_GREEN" "$1" "$SYNAPTA_CLR_RESET"; }
synapta::log::warn()    { printf "%s! %s%s\n" "$SYNAPTA_CLR_YELLOW" "$1" "$SYNAPTA_CLR_RESET"; }
synapta::log::error()   { printf "%s✖ %s%s\n" "$SYNAPTA_CLR_RED" "$1" "$SYNAPTA_CLR_RESET"; }
