# openhands-security-audit

Agente de **auditoría de seguridad defensiva** para PC locales modestos (p. ej. Intel N100 · ~8 GiB · sin GPU).

## Modo recomendado: local (sin Docker)

Python 3 + [Ollama](https://ollama.com). Sin contenedores, menos RAM, listo en este equipo.

```bash
cd ~/Dv/openhands-security-audit   # o tu clone
./install.sh                       # symlinks + comprueba Ollama
./bin/audit-local.sh /ruta/al/proyecto
# solo heurísticas (sin LLM):
./bin/audit-fast.sh /ruta/al/proyecto
```

Informes en `reports/AUDIT-*.md`.

| Comando | Qué hace |
|---------|----------|
| `./bin/audit-local.sh [dir]` | **Híbrido**: escaneo local + narración Ollama |
| `./bin/audit-fast.sh [dir]` | Solo heurísticas (sin LLM) |
| `./bin/audit-local.sh [dir] --react` | Bucle ReAct (mejor con qwen coder) |
| `oh-audit` / `oh-audit-fast` | Igual, tras `install.sh` |

Sin Docker: las herramientas corren en el host; el LLM solo redacta el informe. Modelo: **`dolphin-phi`**. Con `qwen2.5-coder:1.5b` mejora (`LOCAL_OLLAMA_MODEL` en `config/hardware.env`).

### Requisitos (modo local)

- Linux
- `python3`, `curl`
- Ollama en marcha (`ollama serve`)

No hace falta Docker ni grupo `docker`.

## Modo opcional: OpenHands (Docker)

Más capaz, pero pesado en 8 GiB. Ver `MANUAL.md` sección Docker.

```bash
./bin/start.sh   # requiere Docker + Ollama en 0.0.0.0:11434
```

## Ética

Solo en sistemas/repos que administras o con autorización. **Defensa** (revisión, secretos, misconfigs, remediación): no exploits ni PoCs.

## Licencia

MIT — [LICENSE](LICENSE).
