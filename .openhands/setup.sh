#!/usr/bin/env bash
# Se ejecuta al abrir el repo en OpenHands.
set -euo pipefail
echo "[setup] openhands-security-audit: perfil defensivo N100/8G"
mkdir -p reports workspace
# Herramientas ligeras si el sandbox es Debian/Ubuntu-like (ignorar fallos).
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq || true
  apt-get install -y -qq ripgrep jq ca-certificates || true
fi
echo "[setup] listo"
