#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/lib.sh
source "$ROOT/bin/lib.sh"

echo "== openhands-security-audit · instalación local =="
"$ROOT/bin/detect-hardware.sh"

chmod +x "$ROOT"/bin/*.sh "$ROOT"/agent/*.py

need_cmd curl
need_cmd python3
need_cmd ollama || {
  echo "Instala Ollama: https://ollama.com/download" >&2
  exit 1
}

load_env
mkdir -p "$HOME/.local/bin" "$ROOT/reports"
ln -sfn "$ROOT/bin/audit-local.sh" "$HOME/.local/bin/oh-audit"
ln -sfn "$ROOT/bin/audit-fast.sh" "$HOME/.local/bin/oh-audit-fast"
ln -sfn "$ROOT/bin/status.sh" "$HOME/.local/bin/oh-audit-status"
echo "Comandos: oh-audit | oh-audit-fast | oh-audit-status"

local_model="${LOCAL_OLLAMA_MODEL:-dolphin-phi:latest}"
if ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -q "${local_model%%:*}"; then
  echo "Modelo presente: $local_model"
else
  echo "Descargando $local_model…"
  ollama pull "$local_model" || echo "Aviso: pull falló; usa oh-audit-fast"
fi

mkdir -p "$HOME/.config"
cat > "$HOME/.config/openhands-security-audit.env" <<EOF
export OLLAMA_HOST_LOCAL=${OLLAMA_HOST_LOCAL:-127.0.0.1:11434}
export LOCAL_OLLAMA_MODEL=${local_model}
export LOCAL_CONTEXT_LENGTH=${LOCAL_CONTEXT_LENGTH:-2048}
EOF

echo
echo "Usar: oh-audit /ruta/proyecto"
echo "      oh-audit-fast /ruta/proyecto"
