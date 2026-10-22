#!/usr/bin/env bash
# Instala Auditoría IA Local como aplicación de usuario (Omarchy/Linux).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/oh-security-audit"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"

echo "Origen:  $SRC"
echo "Destino: $SHARE"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Falta: $1" >&2; exit 1; }; }
need rsync
need python3
need curl

mkdir -p "$SHARE" "$BIN_DIR" "$APPS" "$ICON_DIR" "$SHARE/reports"

rsync -a --delete \
  --exclude '.git/' \
  --exclude 'reports/AUDIT-*' \
  --exclude 'reports/*.log' \
  --exclude '.env' \
  "$SRC/" "$SHARE/"

mkdir -p "$SHARE/reports"
[[ -f "$SRC/reports/.gitkeep" ]] && cp -f "$SRC/reports/.gitkeep" "$SHARE/reports/"
[[ -f "$SRC/reports/TEMPLATE.md" ]] && cp -f "$SRC/reports/TEMPLATE.md" "$SHARE/reports/"

chmod +x "$SHARE"/bin/*.sh "$SHARE"/bin/oh-security-audit "$SHARE"/agent/*.py "$SHARE"/install.sh

# PATH
ln -sfn "$SHARE/bin/oh-security-audit" "$BIN_DIR/oh-security-audit"
ln -sfn "$SHARE/bin/audit-local.sh" "$BIN_DIR/oh-audit"
ln -sfn "$SHARE/bin/audit-fast.sh" "$BIN_DIR/oh-audit-fast"
ln -sfn "$SHARE/bin/status.sh" "$BIN_DIR/oh-audit-status"

# Icono
cp -f "$SHARE/share/icons/oh-security-audit.svg" "$ICON_DIR/oh-security-audit.svg"

# .desktop (Exec con ruta absoluta al launcher en PATH)
cp -f "$SHARE/share/applications/oh-security-audit.desktop" "$APPS/oh-security-audit.desktop"
sed -i "s|^Exec=xdg-terminal-exec --app-id=oh.security.audit -e oh-security-audit\$|Exec=xdg-terminal-exec --app-id=oh.security.audit -e ${BIN_DIR}/oh-security-audit|" \
  "$APPS/oh-security-audit.desktop"
sed -i "s|^Exec=xdg-terminal-exec --app-id=oh.security.audit -e oh-security-audit |Exec=xdg-terminal-exec --app-id=oh.security.audit -e ${BIN_DIR}/oh-security-audit |" \
  "$APPS/oh-security-audit.desktop"
sed -i "s|^Exec=oh-security-audit reports\$|Exec=${BIN_DIR}/oh-security-audit reports|" \
  "$APPS/oh-security-audit.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true
fi

# Modelo Ollama (no bloquea si falla)
# shellcheck source=/dev/null
source "$SHARE/config/hardware.env" 2>/dev/null || true
local_model="${LOCAL_OLLAMA_MODEL:-dolphin-phi:latest}"
if command -v ollama >/dev/null 2>&1; then
  if ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -q "${local_model%%:*}"; then
    echo "Modelo Ollama: $local_model (ok)"
  else
    echo "Descarga opcional: ollama pull $local_model"
  fi
else
  echo "Aviso: instala Ollama para el modo con LLM."
fi

mkdir -p "$HOME/.config"
cat > "$HOME/.config/openhands-security-audit.env" <<EOF
export LOCAL_OLLAMA_MODEL=${local_model}
export LOCAL_CONTEXT_LENGTH=${LOCAL_CONTEXT_LENGTH:-2048}
export OLLAMA_HOST_LOCAL=127.0.0.1:11434
EOF

# Refresco menú Omarchy
if command -v omarchy-refresh-applications >/dev/null 2>&1; then
  omarchy-refresh-applications 2>/dev/null || true
fi

echo
echo "Instalado como aplicación."
echo "  Menú:     Auditoría IA Local"
echo "  Comando:  oh-security-audit"
echo "  También:  oh-audit | oh-audit-fast | oh-audit-status"
echo "  Datos:    $SHARE"
echo "  Informes: $SHARE/reports"
echo
echo "Prueba: oh-security-audit"
