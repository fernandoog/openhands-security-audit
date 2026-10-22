#!/usr/bin/env bash
# Auditoría defensiva local: Python + Ollama, SIN Docker.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/bin/lib.sh"
load_env

mkdir -p "$ROOT/reports"
chmod +x "$ROOT/agent/local_audit_agent.py"

need_cmd python3
need_cmd curl

if ! curl -sf "${OLLAMA_API:-http://127.0.0.1:11434}/api/tags" >/dev/null; then
  echo "Arrancando Ollama en 127.0.0.1 (modo local, sin Docker)…"
  export OLLAMA_HOST="${OLLAMA_HOST_LOCAL:-127.0.0.1:11434}"
  export OLLAMA_CONTEXT_LENGTH="${LOCAL_CONTEXT_LENGTH:-4096}"
  nohup ollama serve >"$ROOT/reports/ollama-local.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null && break
    sleep 0.25
  done
fi

# Preferir modelo local ligero; install puede haber dejado otro en hardware.env
export OLLAMA_MODEL="${LOCAL_OLLAMA_MODEL:-${OLLAMA_MODEL:-dolphin-phi:latest}}"
export LOCAL_CTX="${LOCAL_CONTEXT_LENGTH:-4096}"

TARGET="${1:-.}"
shift || true
exec python3 "$ROOT/agent/local_audit_agent.py" "$TARGET" "$@"
