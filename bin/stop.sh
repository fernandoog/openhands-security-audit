#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
load_env
cd "$ROOT"
if docker_ok; then
  docker compose --env-file "$ROOT/config/hardware.env" down || true
  echo "OpenHands detenido."
else
  echo "Docker no accesible; no se pudo parar el contenedor." >&2
fi
