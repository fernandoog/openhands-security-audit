#!/usr/bin/env bash
set -euo pipefail

cores=$(nproc)
ram_gib=$(awk '/MemTotal:/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
avail=$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo)
cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | xargs)
gpu="none"
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)
fi

echo "CPU:        $cpu"
echo "Cores:      $cores"
echo "RAM total:  ${ram_gib} GiB"
echo "RAM libre:  ${avail} MiB"
echo "GPU:        $gpu"

if [[ "$ram_gib" -ge 12 ]]; then
  echo "Modelo:     qwen2.5-coder:3b (recomendado)"
elif [[ "$ram_gib" -ge 8 ]]; then
  echo "Modelo:     qwen2.5-coder:1.5b o dolphin-phi"
else
  echo "Modelo:     dolphin-phi / llama3.2:1b"
fi
