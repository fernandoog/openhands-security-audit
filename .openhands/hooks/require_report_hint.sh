#!/usr/bin/env bash
# No bloquea el stop; inyecta recordatorio si no hay informe reciente.
set -euo pipefail
root="${OPENHANDS_PROJECT_DIR:-.}"
shopt -s nullglob
reports=("$root"/reports/AUDIT-*.md)
if ((${#reports[@]} == 0)); then
  echo '{"additionalContext":"Si la tarea era una auditoría, genera reports/AUDIT-YYYYMMDD-HHMM.md con la plantilla reports/TEMPLATE.md antes de dar por cerrado el trabajo."}'
fi
exit 0
