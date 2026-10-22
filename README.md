# openhands-security-audit

Agente **local** [OpenHands](https://github.com/OpenHands/OpenHands) orientado a **auditorías de seguridad defensivas**, calibrado para hardware modesto:

| Recurso | Perfil de este repo |
|---------|---------------------|
| CPU | Intel N100 (4 núcleos) / genérico ≤8 GiB |
| RAM | ~8 GiB (sin GPU NVIDIA usable) |
| LLM | Ollama `qwen2.5-coder:1.5b`, contexto **16k** |
| UI | OpenHands Docker `:3000` |

No genera exploits ni PoCs ofensivos. Hooks y skills limitan el alcance a inventario, hallazgos, remediación e informes.

## Requisitos

- Linux (probado en Omarchy/Arch)
- [Ollama](https://ollama.com)
- Docker + Compose (usuario en grupo `docker`)
- ~3 GiB libres en disco para modelo + imagen

## Instalación rápida

```bash
git clone https://github.com/fernandoog/openhands-security-audit.git
cd openhands-security-audit
./install.sh
./bin/start.sh
```

Abre **http://localhost:3000**. En *Settings → LLM → Advanced*:

| Campo | Valor |
|-------|--------|
| Custom Model | `openai/qwen2.5-coder:1.5b` |
| Base URL | `http://host.docker.internal:11434/v1` |
| API Key | `local-llm` |

Pega el contenido de `prompts/audit-starter.txt` para iniciar una auditoría.

## Comandos

| Script | Función |
|--------|---------|
| `./bin/detect-hardware.sh` | Detecta CPU/RAM/GPU y recomienda modelo |
| `./bin/start-ollama.sh` | Ollama + pull/precarga del modelo |
| `./bin/start.sh` | Ollama + OpenHands (compose) |
| `./bin/stop.sh` | Para OpenHands |
| `./bin/status.sh` | Estado hardware / Ollama / contenedor |

Tras `./install.sh` también: `oh-security-start`, `oh-security-stop`, `oh-security-status`.

## Por qué este modelo

OpenHands pide contexto ≥22k con modelos grandes (p. ej. Qwen3.6-35B), pensados para **≥24 GB VRAM**. En N100/8 GiB eso no cabe.

| Modelo | Uso |
|--------|-----|
| `qwen2.5-coder:1.5b` | **Por defecto** — cabe en RAM con Docker |
| `qwen2.5-coder:3b` | Si tienes ≥12 GiB o cierras todo lo demás |
| `dolphin-phi` | **No** — contexto 2k, insuficiente para OpenHands |

Ajusta `config/hardware.env` y vuelve a `./bin/start.sh`.

## Ollama visible desde Docker

Ollama debe escuchar en `0.0.0.0:11434`, no solo `127.0.0.1`:

```bash
source ~/.config/openhands-security-audit.env   # tras install.sh
# o:
OLLAMA_HOST=0.0.0.0:11434 OLLAMA_CONTEXT_LENGTH=16384 ollama serve
```

Comprueba desde el contenedor:

```bash
docker exec openhands-security-audit curl -s http://host.docker.internal:11434/v1/models
```

## Personalización OpenHands

- `AGENTS.md` — mandato defensivo permanente
- `.openhands/microagents/` — skills de auditoría / secretos
- `.openhands/hooks/` — bloqueo de herramientas ofensivas + log
- `config/config.toml` — referencia LLM/agente/seguridad
- `reports/TEMPLATE.md` — plantilla de informe

## Ética

Solo en sistemas y repos que administras o con autorización explícita. Este proyecto es para **defensa** (revisión, hardening, secretos, deps), no para ataque.

## Licencia

MIT — ver [LICENSE](LICENSE).
