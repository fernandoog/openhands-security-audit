#!/usr/bin/env bash
# Utilidades compartidas.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT

load_env() {
  # shellcheck disable=SC1091
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

docker_ok() {
  docker info >/dev/null 2>&1
}

ensure_docker() {
  if docker_ok; then
    return 0
  fi
  echo "Docker no accesible (¿grupo docker?)." >&2
  echo "  sudo usermod -aG docker \"\$USER\" && newgrp docker" >&2
  return 1
}

ram_available_mib() {
  awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo
}
