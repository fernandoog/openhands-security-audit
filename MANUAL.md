# Manual

## A) Agente local sin Docker (recomendado)

### 1. Ollama

```bash
ollama serve          # si no está ya
ollama list           # debe listar al menos dolphin-phi o qwen2.5-coder:1.5b
```

### 2. Auditar

```bash
cd ~/Dv/openhands-security-audit
./bin/audit-local.sh .
./bin/audit-local.sh ~/Dv/otro-proyecto --steps 8
./bin/audit-fast.sh ~/Dv/otro-proyecto
```

### 3. Qué hace el agente (modo híbrido, por defecto)

1. Escaneo determinista en el host: inventario, secretos, configs, permisos.
2. (Opcional) Una llamada a Ollama para narrar el informe.
3. Escribe `reports/AUDIT-YYYYMMDD-HHMM.md`.
4. `--fast` / `--no-llm`: sin Ollama. `--react`: bucle Thought/Action (modelos mejores).

Comandos ofensivos quedan bloqueados en la allowlist de `run_safe`.

### 4. Modelos en N100 / 8 GiB

| Modelo | Notas |
|--------|--------|
| `dolphin-phi` | Por defecto ahora; ctx 2k; lento pero cabe |
| `qwen2.5-coder:1.5b` | Mejor para código; `ollama pull qwen2.5-coder:1.5b` |
| `qwen2.5-coder:3b` | Solo si cierras apps y tienes margen de RAM |

Edita `LOCAL_OLLAMA_MODEL` y `LOCAL_CONTEXT_LENGTH` en `config/hardware.env`.

### 5. Flags útiles

```bash
./bin/audit-local.sh . --fast
./bin/audit-local.sh . --model dolphin-phi:latest --ctx 2048 --steps 6
./bin/audit-local.sh . --goal "Busca secretos y revisa Dockerfiles"
```

---

## B) OpenHands con Docker (opcional)

```bash
sudo usermod -aG docker "$USER" && newgrp docker
# Ollama en 0.0.0.0:11434
./bin/start.sh
# UI http://localhost:3000
```

Detalles LLM en el README antiguo / `config/hardware.env` (bloque OpenHands).

---

## Problemas

| Síntoma | Qué hacer |
|---------|-----------|
| Ollama connection refused | `ollama serve` |
| Muy lento | `--fast` o modelo 1.5b; cierra Chrome |
| Informe vacío de calidad | Modelo débil: usa `--fast` + revisión manual |
| Comando bloqueado | Es la allowlist defensiva; no uses herramientas ofensivas |
