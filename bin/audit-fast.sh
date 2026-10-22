#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
  TARGET="$1"
  shift
else
  TARGET="."
fi
exec python3 "$ROOT/agent/local_audit_agent.py" "$TARGET" --fast "$@"
