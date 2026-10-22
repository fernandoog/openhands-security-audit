# Manual

## Instalación como aplicación

```bash
cd ~/Dv/openhands-security-audit
./install.sh
```

Busca en el launcher: **Auditoría IA Local**. También: `oh-security-audit`.

```bash
ollama serve   # si no está en marcha
oh-security-audit
oh-security-audit local ~/Dv/mi-proyecto
oh-security-audit fast .
oh-audit . --model qwen2.5-coder:1.5b --ctx 4096
./uninstall.sh
```

## Cómo funciona

1. Inventario, secretos heurísticos, configs, permisos (en el host).
2. Opcional: Ollama redacta el informe.
3. Salida: `reports/AUDIT-YYYYMMDD-HHMM.md`.

## Modelos (N100 / 8 GiB)

| Modelo | Notas |
|--------|--------|
| `dolphin-phi` | Por defecto |
| `qwen2.5-coder:1.5b` | Mejor narración (`ollama pull …`) |

## Problemas

| Síntoma | Qué hacer |
|---------|-----------|
| connection refused | `ollama serve` |
| Muy lento | `oh-audit-fast` |
