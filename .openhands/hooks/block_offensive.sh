#!/usr/bin/env bash
# Bloquea comandos claramente ofensivos / destructivos en auditorías defensivas.
set -euo pipefail

input=$(cat || true)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
if [[ -z "$command" ]]; then
  exit 0
fi

lower=$(printf '%s' "$command" | tr '[:upper:]' '[:lower:]')

deny() {
  local reason=$1
  printf '{"decision":"deny","reason":%s}\n' "$(jq -Rn --arg r "$reason" '$r')"
  exit 2
}

# Destrucción masiva / disco
if [[ "$lower" =~ rm[[:space:]]+-rf[[:space:]]+/($|[[:space:]]) ]] ||
   [[ "$lower" =~ mkfs\. ]] ||
   [[ "$lower" =~ dd[[:space:]]+if=.*of=/dev/ ]]; then
  deny "Comando destructivo bloqueado. Usa rutas acotadas al workspace."
fi

# Ofensivo / explotación
patterns=(
  'msfconsole'
  'metasploit'
  'sqlmap'
  'hydra[[:space:]]'
  'john[[:space:]]'
  'hashcat'
  'aircrack'
  'bettercap'
  'responder'
  'impacket-'
  'crackmapexec'
  'netexec'
  'evil-winrm'
  'reverse[[:space:]]*shell'
  'nmap[[:space:]]+.*-s[csv]'
  'masscan'
  'nikto'
  'burpsuite'
  'ysoserial'
  'searchsploit'
)

for p in "${patterns[@]}"; do
  if [[ "$lower" =~ $p ]]; then
    deny "Herramienta/flujo ofensivo bloqueado ($p). Limítate a auditoría defensiva y remediación."
  fi
done

exit 0
