#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/lib.sh
source "$ROOT/bin/lib.sh"

echo "== openhands-security-audit · instalación =="
"$ROOT/bin/detect-hardware.sh"

chmod +x "$ROOT"/bin/*.sh "$ROOT"/.openhands/hooks/*.sh "$ROOT"/.openhands/setup.sh

need_cmd curl
need_cmd ollama || {
  echo "Instala Ollama: https://ollama.com/download" >&2
  exit 1
}

if ! docker_ok; then
  echo
  echo "Añade tu usuario al grupo docker (requiere sudo + nueva sesión):"
  echo "  sudo usermod -aG docker \"$USER\""
  echo "  # cierra sesión o: newgrp docker"
  echo
fi

# Symlinks opcionales
mkdir -p "$HOME/.local/bin"
ln -sfn "$ROOT/bin/start.sh" "$HOME/.local/bin/oh-security-start"
ln -sfn "$ROOT/bin/stop.sh" "$HOME/.local/bin/oh-security-stop"
ln -sfn "$ROOT/bin/status.sh" "$HOME/.local/bin/oh-security-status"
echo "Comandos: oh-security-start | oh-security-stop | oh-security-status"

load_env
model="${OLLAMA_MODEL:-qwen2.5-coder:1.5b}"
echo "Descargando modelo $model…"
ollama pull "$model"

# Nota OLLAMA_HOST
mkdir -p "$HOME/.config"
cat > "$HOME/.config/openhands-security-audit.env" <<EOF
# Sourced by optional user units / shells
export OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0:11434}
export OLLAMA_CONTEXT_LENGTH=${OLLAMA_CONTEXT_LENGTH:-16384}
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-30m}
EOF
echo "Env Ollama → ~/.config/openhands-security-audit.env"

echo
echo "Siguiente:"
echo "  1) Asegura Docker (grupo docker)."
echo "  2) Ollama debe escuchar en 0.0.0.0:11434 (no solo 127.0.0.1)."
echo "     source ~/.config/openhands-security-audit.env && ollama serve"
echo "  3) cd $ROOT && ./bin/start.sh"
echo "  4) Abre http://localhost:3000 y configura el LLM (ver README)."
