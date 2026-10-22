# Manual · openhands-security-audit

## 1. Preparar Docker

```bash
sudo usermod -aG docker "$USER"
# Cierra sesión gráfica o:
newgrp docker
docker ps   # debe funcionar sin sudo
```

## 2. Instalar

```bash
cd ~/Dv/openhands-security-audit   # o tu clone
./install.sh
```

Descarga `qwen2.5-coder:1.5b` y crea symlinks en `~/.local/bin`.

## 3. Ollama en 0.0.0.0

Si `ss -tlnp | grep 11434` muestra solo `127.0.0.1`, Docker no alcanzará el LLM.

1. Para el proceso/servicio actual de Ollama.
2. Arranca:

```bash
source ~/.config/openhands-security-audit.env
ollama serve
```

O deja que `./bin/start-ollama.sh` lo intente (si el puerto está libre).

## 4. Arrancar el agente

```bash
./bin/start.sh
# o: oh-security-start
```

Espera a que la UI responda en http://localhost:3000.

## 5. Configurar LLM en la UI

*Settings → see advanced settings → Advanced ON*:

- Custom Model: `openai/qwen2.5-coder:1.5b`
- Base URL: `http://host.docker.internal:11434/v1`
- API Key: `local-llm`

Guarda. Abre conversación nueva.

## 6. Auditar un proyecto

1. El compose monta **este** repo en `/workspace/project`.
2. Para auditar otro código: cópialo/clónalo dentro de `workspace/` o cambia el volumen en `docker-compose.yml`.
3. Usa el prompt de `prompts/audit-starter.txt`.
4. Revisa `reports/AUDIT-*.md`.

## 7. Parar

```bash
./bin/stop.sh
```

Ollama puede seguir en marcha (útil para no recargar el modelo).

## 8. Problemas frecuentes

| Síntoma | Qué mirar |
|---------|-----------|
| `permission denied` docker.sock | Grupo `docker` + nueva sesión |
| LLM timeout / connection refused | Ollama en `0.0.0.0`, `curl` desde el contenedor |
| Agente “tonto” / no usa tools | Contexto demasiado bajo o modelo inadecuado; no uses `dolphin-phi` |
| Swap thrashing / muy lento | Cierra navegadores; baja a 1.5b; reduce `OPENHANDS_MEMORY` |
| OOM killer | Baja `OLLAMA_CONTEXT_LENGTH` a 12288 en `config/hardware.env` |

## 9. Subir de perfil

Si amplías RAM/GPU, ejecuta `./bin/detect-hardware.sh` y actualiza `OLLAMA_MODEL` / `OLLAMA_CONTEXT_LENGTH` en `config/hardware.env`.
