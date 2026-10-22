#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
load_env

echo "=== Hardware ==="
"$ROOT/bin/detect-hardware.sh"
echo "=== Ollama ==="
if curl -sf http://127.0.0.1:11434/api/tags >/dev/null; then
  echo "API: OK"
  ollama list 2>/dev/null || true
  ollama ps 2>/dev/null || true
else
  echo "API: down (ollama serve)"
fi
echo "=== Modelo configurado ==="
echo "${LOCAL_OLLAMA_MODEL:-?}"
