#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${OPENHANDS_PROJECT_DIR:-.}/reports"
printf '[%s] tool=%s session=%s\n' \
  "$(date -Iseconds)" \
  "${OPENHANDS_TOOL_NAME:-unknown}" \
  "${OPENHANDS_SESSION_ID:-unknown}" \
  >> "${OPENHANDS_PROJECT_DIR:-.}/reports/tool-usage.log"
exit 0
