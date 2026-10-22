#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
load_env
ensure_docker
need_cmd curl

mkdir -p "$HOME/.openhands" "$ROOT/reports" "$ROOT/workspace"
chmod +x "$ROOT"/.openhands/hooks/*.sh "$ROOT"/.openhands/setup.sh 2>/dev/null || true

avail=$(ram_available_mib)
if (( avail < 1500 )); then
  echo "Poca RAM disponible (${avail} MiB). Cierra apps pesadas antes de continuar." >&2
fi

"$ROOT/bin/start-ollama.sh"

# Asegura bind 0.0.0.0 si hace falta aviso
if ! curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null; then
  echo "Ollama no responde" >&2
  exit 1
fi

cd "$ROOT"
echo "Arrancando OpenHands (${OPENHANDS_IMAGE}) en :${OPENHANDS_PORT}…"
docker compose --env-file "$ROOT/config/hardware.env" up -d

echo
echo "UI:  http://localhost:${OPENHANDS_PORT}"
echo "LLM: Settings → Advanced →"
echo "     Custom Model: ${LLM_MODEL}"
echo "     Base URL:     ${LLM_BASE_URL}"
echo "     API Key:      ${LLM_API_KEY}"
echo
echo "Prompt inicial: prompts/audit-starter.txt"
echo "Workspace montado: /workspace/project (este repo)"
