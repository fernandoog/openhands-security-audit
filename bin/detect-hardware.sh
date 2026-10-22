#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

cores=$(nproc)
ram_gib=$(awk '/MemTotal:/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
avail=$(ram_available_mib)
gpu="none"
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)
fi
cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | xargs)

echo "CPU:        $cpu"
echo "Cores:      $cores"
echo "RAM total:  ${ram_gib} GiB"
echo "RAM libre:  ${avail} MiB"
echo "GPU:        $gpu"
echo

recommend="qwen2.5-coder:1.5b"
ctx=16384
profile="n100-8g"

if [[ "$ram_gib" -ge 24 ]] && [[ "$gpu" != "none" ]]; then
  recommend="qwen2.5-coder:14b"
  ctx=32768
  profile="gpu-24g+"
elif [[ "$ram_gib" -ge 16 ]]; then
  recommend="qwen2.5-coder:7b"
  ctx=24576
  profile="cpu-16g"
elif [[ "$ram_gib" -ge 12 ]]; then
  recommend="qwen2.5-coder:3b"
  ctx=20480
  profile="cpu-12g"
else
  recommend="qwen2.5-coder:1.5b"
  ctx=16384
  profile="cpu-8g"
fi

echo "Perfil:     $profile"
echo "Modelo:     $recommend"
echo "Contexto:   $ctx"
echo
echo "Actualiza config/hardware.env si quieres forzar otro modelo."
