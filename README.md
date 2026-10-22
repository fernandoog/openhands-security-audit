# openhands-security-audit

Agente **local** de auditoría de seguridad **defensiva** (Python + Ollama). Sin Docker.

Calibrado para PCs modestos (p. ej. Intel N100 · ~8 GiB · sin GPU).

## Uso

```bash
git clone https://github.com/fernandoog/openhands-security-audit.git
cd openhands-security-audit
./install.sh
./bin/audit-local.sh /ruta/al/proyecto
./bin/audit-fast.sh /ruta/al/proyecto    # sin LLM
```

Tras instalar: `oh-audit`, `oh-audit-fast`, `oh-audit-status`.

Informes en `reports/AUDIT-*.md`.

| Comando | Qué hace |
|---------|----------|
| `audit-local.sh` | Escaneo determinista + narración Ollama |
| `audit-fast.sh` | Solo heurísticas |
| `audit-local.sh --react` | Bucle ReAct (mejor con qwen coder) |

Modelo por defecto: `dolphin-phi`. Opcional: `qwen2.5-coder:1.5b` en `config/hardware.env`.

## Requisitos

- Linux, `python3`, `curl`, [Ollama](https://ollama.com)

## Ética

Solo en repos/sistemas que administras. Defensa (secretos, misconfigs, remediación): no exploits.

## Licencia

MIT — [LICENSE](LICENSE).
