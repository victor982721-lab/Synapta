#!/usr/bin/env bash

synapta::utils::require_cmd() {
  local cmd=$1
  if ! command -v "$cmd" >/dev/null 2>&1; then
    synapta::log::error "Comando requerido no encontrado: $cmd"
    exit 1
  fi
}

synapta::utils::ensure_dir() {
  local dir=$1
  mkdir -p "$dir"
}

synapta::utils::emit_summary() {
  local output_file=$1
  local payload=$2

  if [[ -n $output_file ]]; then
    synapta::utils::ensure_dir "$(dirname "$output_file")"
    printf '%s\n' "$payload" >"$output_file"
    synapta::log::info "Resumen JSON guardado en $output_file"
  fi
  printf '\n%s\n' "$payload"
}
