#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/lib.sh
source "$ROOT/bin/lib.sh"

echo "== openhands-security-audit · instalación =="
"$ROOT/bin/detect-hardware.sh"

chmod +x "$ROOT"/bin/*.sh "$ROOT"/agent/*.py "$ROOT"/.openhands/hooks/*.sh "$ROOT"/.openhands/setup.sh 2>/dev/null || true

need_cmd curl
need_cmd python3
need_cmd ollama || {
  echo "Instala Ollama: https://ollama.com/download" >&2
  exit 1
}

load_env

# Symlinks — modo local (principal) + OpenHands opcional
mkdir -p "$HOME/.local/bin"
ln -sfn "$ROOT/bin/audit-local.sh" "$HOME/.local/bin/oh-audit"
ln -sfn "$ROOT/bin/audit-fast.sh" "$HOME/.local/bin/oh-audit-fast"
ln -sfn "$ROOT/bin/start.sh" "$HOME/.local/bin/oh-security-start"
ln -sfn "$ROOT/bin/stop.sh" "$HOME/.local/bin/oh-security-stop"
ln -sfn "$ROOT/bin/status.sh" "$HOME/.local/bin/oh-security-status"
echo "Comandos: oh-audit | oh-audit-fast  (+ oh-security-* si usas Docker)"

local_model="${LOCAL_OLLAMA_MODEL:-dolphin-phi:latest}"
if ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -qE "^(${local_model}|${local_model%%:*}:)" \
  || ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -q "${local_model%%:*}"; then
  echo "Modelo local presente: $local_model"
else
  echo "Descargando modelo local $local_model…"
  ollama pull "$local_model" || echo "Aviso: pull falló; puedes usar ./bin/audit-fast.sh"
fi

mkdir -p "$HOME/.config"
cat > "$HOME/.config/openhands-security-audit.env" <<EOF
# Modo local (sin Docker)
export OLLAMA_HOST_LOCAL=${OLLAMA_HOST_LOCAL:-127.0.0.1:11434}
export LOCAL_OLLAMA_MODEL=${local_model}
export LOCAL_CONTEXT_LENGTH=${LOCAL_CONTEXT_LENGTH:-2048}
# OpenHands / Docker (opcional)
export OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0:11434}
export OLLAMA_CONTEXT_LENGTH=${OLLAMA_CONTEXT_LENGTH:-16384}
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-30m}
EOF
echo "Env → ~/.config/openhands-security-audit.env"

if ! docker_ok; then
  echo
  echo "(Opcional) Docker no accesible — el modo local no lo necesita."
  echo "  Para OpenHands UI: sudo usermod -aG docker \"\$USER\" && newgrp docker"
fi

echo
echo "Usar ahora (sin Docker):"
echo "  oh-audit ."
echo "  oh-audit-fast /ruta/proyecto"
