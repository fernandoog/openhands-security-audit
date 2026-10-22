# openhands-security-audit

Agente **local** de auditoría de seguridad **defensiva** (Python + Ollama). Sin Docker.

Calibrado para PCs modestos (p. ej. Intel N100 · ~8 GiB · sin GPU).

## Instalación (aplicación del sistema)

```bash
git clone https://github.com/fernandoog/openhands-security-audit.git
cd openhands-security-audit
./install.sh
```

Queda en el menú de aplicaciones como **Auditoría IA Local**, con icono y lanzador en terminal.

| Qué | Dónde |
|-----|--------|
| App / datos | `~/.local/share/oh-security-audit` |
| Menú | Auditoría IA Local |
| Comando | `oh-security-audit` |
| Atajos | `oh-audit`, `oh-audit-fast`, `oh-audit-status` |
| Informes | `~/.local/share/oh-security-audit/reports/` |

```bash
oh-security-audit              # menú TUI
oh-security-audit local ~/Dv/mi-proyecto
oh-security-audit fast .
./uninstall.sh                 # quitar del sistema
```

Modelo por defecto: `dolphin-phi`. Opcional: `qwen2.5-coder:1.5b` en `config/hardware.env`.

## Requisitos

- Linux, `python3`, `curl`, [Ollama](https://ollama.com)

## Ética

Solo en repos/sistemas que administras. Defensa (secretos, misconfigs, remediación): no exploits.

## Licencia

MIT — [LICENSE](LICENSE).
