#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT

load_env() {
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/config/hardware.env"
  if [[ -f "$ROOT/.env" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT/.env"
  fi
  set +a
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta comando: $1" >&2
    return 1
  }
}
