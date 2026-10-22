#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
load_env
need_cmd ollama

# Ollama debe escuchar en 0.0.0.0 para que Docker llegue vía host.docker.internal
export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-16384}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-30m}"

if curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
  # Reinicio suave si está solo en localhost
  bind=$(ss -tlnp 2>/dev/null | grep 11434 || true)
  if echo "$bind" | grep -q '127.0.0.1:11434' && ! echo "$bind" | grep -qE '0\.0\.0\.0:11434|\*:11434'; then
    echo "Ollama está en 127.0.0.1; Docker no podrá alcanzarlo."
    echo "Para este equipo: para el servicio y relanza con este script, o configura OLLAMA_HOST=0.0.0.0:11434."
    echo "Intentando servir en 0.0.0.0 (si el puerto está ocupado, libera 11434 primero)."
  else
    echo "Ollama ya responde en :11434"
  fi
else
  echo "Arrancando ollama serve (contexto=$OLLAMA_CONTEXT_LENGTH)…"
  nohup ollama serve >"$ROOT/reports/ollama.log" 2>&1 &
  for _ in $(seq 1 30); do
    curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1 && break
    sleep 0.5
  done
fi

model="${OLLAMA_MODEL:-qwen2.5-coder:1.5b}"
if ! ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$model" && \
   ! ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -q "^${model}:"; then
  echo "Descargando modelo $model (puede tardar)…"
  ollama pull "$model"
else
  echo "Modelo presente: $model"
fi

# Precarga con el contexto deseado (Ollama usa num_ctx en la petición)
echo "Precargando $model (ctx=$OLLAMA_CONTEXT_LENGTH)…"
curl -sf http://127.0.0.1:11434/api/generate -d "{
  \"model\": \"$model\",
  \"prompt\": \"ping\",
  \"stream\": false,
  \"options\": {\"num_ctx\": $OLLAMA_CONTEXT_LENGTH, \"num_predict\": 1}
}" >/dev/null || echo "Aviso: precarga falló (seguirá en la primera petición)."

echo "OK · Ollama listo · modelo=$model"
