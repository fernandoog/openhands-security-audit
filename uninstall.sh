#!/usr/bin/env bash
set -euo pipefail

SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/oh-security-audit"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps/oh-security-audit.svg"

rm -f "$BIN_DIR/oh-security-audit" "$BIN_DIR/oh-audit" "$BIN_DIR/oh-audit-fast" "$BIN_DIR/oh-audit-status"
rm -f "$APPS/oh-security-audit.desktop"
rm -f "$ICON"
rm -rf "$SHARE"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS" 2>/dev/null || true
fi

echo "Desinstalado oh-security-audit (aplicación y datos en $SHARE)."
