---
name: security-audit-repo
type: repo
version: 1.0.0
agent: CodeActAgent
---

# Repositorio openhands-security-audit

Este repo configura OpenHands para auditorías **defensivas** en hardware N100/8 GiB.

## Arranque

- Perfil: `config/hardware.env`
- Scripts: `./bin/start.sh`, `./bin/stop.sh`, `./bin/status.sh`
- Informes: `reports/`

## Reglas del agente

Sigue `AGENTS.md`. No generes exploits ni PoCs. Prioriza remediación y hardening.
En este hardware usa el modelo Ollama `qwen2.5-coder:1.5b` con contexto ~16k.
