#!/usr/bin/env bash
# Solo heurísticas (sin LLM). Útil si Ollama está ocupado o el modelo aún no está.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-.}"
exec python3 "$ROOT/agent/local_audit_agent.py" "$TARGET" --fast
