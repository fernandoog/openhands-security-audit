#!/usr/bin/env python3
"""Agente local de auditoría defensiva vía Ollama (sin Docker).

Por defecto: modo híbrido (herramientas deterministas + 1 llamada LLM opcional).
Stdlib only — pensado para N100 / ~8 GiB.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPORTS = ROOT / "reports"

BLOCKED_RE = re.compile(
    r"(?i)("
    r"rm\s+-rf\s+/($|\s)|mkfs\.|dd\s+if=.*of=/dev/"
    r"|msfconsole|metasploit|sqlmap|\bhydra\b|\bjohn\b|hashcat"
    r"|aircrack|bettercap|responder|impacket-|crackmapexec|netexec"
    r"|evil-winrm|reverse\s*shell|masscan|\bnikto\b|ysoserial|searchsploit"
    r"|nmap\s+.*-s[csv]"
    r")"
)

SECRET_PATTERNS = [
    (r"(?i)(api[_-]?key|secret|password|passwd|token)\s*[:=]\s*['\"][^'\"]{8,}", "posible secreto en claro"),
    (r"(?i)-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----", "clave privada"),
    (r"(?i)AKIA[0-9A-Z]{16}", "AWS access key"),
    (r"(?i)ghp_[A-Za-z0-9]{20,}", "GitHub PAT"),
    (r"(?i)xox[baprs]-[A-Za-z0-9-]{10,}", "Slack token"),
]

DUMMY_SECRET = re.compile(
    r"(?i)(local-llm|dummy|changeme|your[_-]?api[_-]?key|placeholder|example|xxx+|12345|password|todo)"
)

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", ".cache", "dist", "build", ".openhands"}

SYSTEM_REACT = """Eres auditor DEFENSIVO. Sin exploits/PoCs.
Responde solo:
Thought: ...
Action: inventory|grep_secrets|read_file|list_dir|run_safe|write_report|finish
Action Input: ...
Una Action por mensaje."""

SYSTEM_NARRATE = """Eres auditor de seguridad DEFENSIVO. Con datos ya recolectados, escribe un informe markdown breve:
resumen, tabla de hallazgos (ID, severidad, título, evidencia, remediación), secretos redactados, prioridades.
PROHIBIDO exploits o payloads. Español. Máximo ~80 líneas."""


def load_hardware_env() -> dict[str, str]:
    env: dict[str, str] = {}
    path = ROOT / "config" / "hardware.env"
    if not path.is_file():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def ollama_tags(base: str) -> list[str]:
    try:
        with urllib.request.urlopen(f"{base}/api/tags", timeout=5) as r:
            data = json.loads(r.read().decode())
        return [m.get("name", "") for m in data.get("models", [])]
    except Exception:
        return []


def pick_model(preferred: str, available: list[str]) -> str:
    if not available:
        return preferred
    for cand in (
        preferred,
        f"{preferred}:latest" if ":" not in preferred else preferred,
        "qwen2.5-coder:1.5b",
        "qwen2.5-coder:3b",
        "llama3.2:3b",
        "llama3.2:1b",
        "dolphin-phi:latest",
        "dolphin-phi",
    ):
        for n in available:
            if n == cand or n.startswith(cand.rstrip(":")):
                return n
            if cand.split(":")[0] == n.split(":")[0] and cand in (n, preferred):
                return n
        if cand in available:
            return cand
    # fuzzy: same family
    pref_base = preferred.split(":")[0]
    for n in available:
        if n.split(":")[0] == pref_base:
            return n
    return available[0]


def chat(base: str, model: str, messages: list[dict], num_ctx: int, num_predict: int) -> str:
    body = {
        "model": model,
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0.1, "num_ctx": num_ctx, "num_predict": num_predict},
    }
    req = urllib.request.Request(
        f"{base}/api/chat",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=600) as r:
        data = json.loads(r.read().decode())
    return (data.get("message") or {}).get("content") or ""


def resolve_under(target: Path, rel: str) -> Path:
    p = (target / rel).resolve() if rel not in (".", "") else target.resolve()
    t = target.resolve()
    if p != t and t not in p.parents:
        raise ValueError(f"ruta fuera del target: {rel}")
    return p


def tool_inventory(target: Path) -> str:
    counts: dict[str, int] = {}
    samples: list[str] = []
    for root, dirs, files in os.walk(target):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for f in files:
            ext = Path(f).suffix.lower() or "(sin_ext)"
            counts[ext] = counts.get(ext, 0) + 1
            interesting = ext in {
                ".py", ".js", ".ts", ".tsx", ".go", ".rs", ".java", ".rb",
                ".php", ".env", ".yml", ".yaml", ".toml", ".json", ".sh",
            } or f.lower() in {
                "dockerfile", "docker-compose.yml", "package.json",
                "requirements.txt", "go.mod", "cargo.toml",
            }
            if len(samples) < 40 and interesting:
                samples.append(str(Path(root, f).relative_to(target)))
    top = sorted(counts.items(), key=lambda x: -x[1])[:15]
    lines = [f"root={target}", f"extensiones: {top}", "archivos relevantes:"]
    lines.extend(f"  - {s}" for s in samples[:30])
    return "\n".join(lines)[:6000]


def tool_grep_secrets(target: Path) -> str:
    hits: list[str] = []
    text_ext = {
        ".py", ".js", ".ts", ".tsx", ".jsx", ".go", ".rs", ".java", ".rb", ".php",
        ".sh", ".env", ".yml", ".yaml", ".toml", ".json", ".ini", ".cfg", ".conf",
        ".md", ".txt", ".xml", ".properties",
    }
    for root, dirs, files in os.walk(target):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            path = Path(root, f)
            if path.suffix.lower() not in text_ext and f not in {".env", "Dockerfile"}:
                continue
            try:
                if path.stat().st_size > 512_000:
                    continue
                text = path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            for i, line in enumerate(text.splitlines(), 1):
                if DUMMY_SECRET.search(line) and "BEGIN" not in line and "AKIA" not in line and "ghp_" not in line:
                    continue
                for pat, label in SECRET_PATTERNS:
                    if re.search(pat, line):
                        redacted = re.sub(r"([A-Za-z0-9_\-]{6})[A-Za-z0-9_\-]{8,}", r"\1****", line.strip())
                        hits.append(f"{path.relative_to(target)}:{i} [{label}] {redacted[:120]}")
                        if len(hits) >= 40:
                            return "\n".join(hits)
    return "\n".join(hits) if hits else "Sin coincidencias de secretos con heurísticas locales."


def tool_read_file(target: Path, rel: str) -> str:
    p = resolve_under(target, rel.strip())
    if not p.is_file():
        return f"ERROR: no es archivo: {rel}"
    if p.stat().st_size > 200_000:
        return f"ERROR: demasiado grande"
    text = p.read_text(encoding="utf-8", errors="ignore")
    return text[:8000] + ("\n…[truncado]" if len(text) > 8000 else "")


def tool_list_dir(target: Path, rel: str) -> str:
    p = resolve_under(target, rel.strip() or ".")
    if not p.is_dir():
        return f"ERROR: no es directorio: {rel}"
    entries = sorted(p.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))
    return "\n".join(
        f"{'dir' if e.is_dir() else 'file'}\t{e.relative_to(target)}" for e in entries[:80]
    ) or "(vacío)"


def tool_run_safe(target: Path, cmd: str) -> str:
    cmd = cmd.strip()
    if not cmd:
        return "ERROR: vacío"
    if BLOCKED_RE.search(cmd):
        return "BLOQUEADO: ofensivo/destructivo."
    allow = (
        "ls", "find", "rg", "grep", "cat", "head", "tail", "wc", "file",
        "stat", "sha256sum", "md5sum", "git", "npm audit", "pip-audit",
        "pip list", "python", "python3", "jq", "ss", "id", "uname",
        "trivy", "gitleaks", "osv-scanner", "hadolint",
    )
    if not any(cmd == a or cmd.startswith(a + " ") for a in allow):
        return "BLOQUEADO: fuera de allowlist."
    try:
        proc = subprocess.run(
            cmd, shell=True, cwd=str(target), capture_output=True, text=True, timeout=60
        )
    except subprocess.TimeoutExpired:
        return "ERROR: timeout"
    out = (proc.stdout or "") + (proc.stderr or "")
    return f"exit={proc.returncode}\n{out[:6000]}"


def write_report(reports_dir: Path, markdown: str) -> Path:
    reports_dir.mkdir(parents=True, exist_ok=True)
    path = reports_dir / f"AUDIT-{datetime.now().strftime('%Y%m%d-%H%M')}.md"
    path.write_text(markdown.strip() + "\n", encoding="utf-8")
    return path


def collect_scan(target: Path) -> dict[str, str]:
    inv = tool_inventory(target)
    sec = tool_grep_secrets(target)
    flags: list[str] = []
    for name in ("Dockerfile", "docker-compose.yml", ".env", "package.json", "requirements.txt"):
        if (target / name).is_file():
            flags.append(name)
    # permisos world-writable suaves
    risky = []
    for root, dirs, files in os.walk(target):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            p = Path(root, f)
            try:
                mode = p.stat().st_mode & 0o777
            except OSError:
                continue
            if mode & 0o002:
                risky.append(f"{p.relative_to(target)} mode={oct(mode)}")
            if len(risky) >= 15:
                break
    return {
        "inventory": inv,
        "secrets": sec,
        "config_files": ", ".join(flags) or "(ninguno típico en raíz)",
        "world_writable": "\n".join(risky) if risky else "(ninguno detectado)",
    }


def build_heuristic_report(target: Path, scan: dict[str, str], note: str = "") -> str:
    findings: list[str] = []
    if "Sin coincidencias" not in scan["secrets"]:
        findings.append("| A-01 | Alta | Posibles secretos | sección Secretos | Rotar y sacar del repo |")
    for name in scan["config_files"].split(", "):
        if name and name != "(ninguno típico en raíz)":
            findings.append(f"| A-info | Info | Archivo `{name}` | raíz | Revisar secretos y permisos |")
    if "ninguno" not in scan["world_writable"]:
        findings.append("| A-02 | Media | Ficheros world-writable | sección Permisos | chmod o|g-w |")
    if not findings:
        findings.append("| A-00 | Info | Sin hallazgos heurísticos fuertes | inventory | Revisión humana de auth/deps |")
    return f"""# Informe de auditoría defensiva (local, sin Docker)

| Campo | Valor |
|-------|-------|
| Fecha | {datetime.now().isoformat(timespec='minutes')} |
| Alcance | `{target}` |
| Motor | heurístico{' + LLM' if note else ''} |

## Resumen ejecutivo

Escaneo local defensivo: inventario, secretos heurísticos y señales de misconfig.
{note}

## Inventario

```
{scan['inventory'][:3500]}
```

## Hallazgos

| ID | Severidad | Título | Evidencia | Remediación |
|----|-----------|--------|-----------|-------------|
{chr(10).join(findings)}

## Secretos (redactados)

```
{scan['secrets'][:3000]}
```

## Config / superficie

- Archivos típicos: {scan['config_files']}

## Permisos

```
{scan['world_writable'][:1500]}
```

## Ética

Solo auditoría defensiva. Sin exploits ni PoCs.
"""


def narrate_with_llm(base: str, model: str, ctx: int, target: Path, scan: dict[str, str]) -> str | None:
    blob = (
        f"Target: {target}\n\n## inventory\n{scan['inventory'][:2500]}\n\n"
        f"## secrets\n{scan['secrets'][:1500]}\n\n"
        f"## configs\n{scan['config_files']}\n\n"
        f"## perms\n{scan['world_writable'][:800]}\n"
    )
    try:
        return chat(
            base,
            model,
            [
                {"role": "system", "content": SYSTEM_NARRATE},
                {"role": "user", "content": blob},
            ],
            num_ctx=ctx,
            num_predict=700,
        )
    except Exception as e:
        print(f"[llm] narración omitida: {e}", flush=True)
        return None


def parse_action(text: str) -> tuple[str, str]:
    action, action_input = "", ""
    for line in text.splitlines():
        s = line.strip()
        if s.lower().startswith("action input:"):
            action_input = s.split(":", 1)[1].strip()
        elif s.lower().startswith("action:"):
            action = s.split(":", 1)[1].strip()
    return action.lower().strip(), action_input


def execute(action: str, action_input: str, target: Path, reports_dir: Path) -> str:
    try:
        if action == "inventory":
            return tool_inventory(target)
        if action == "grep_secrets":
            return tool_grep_secrets(target)
        if action == "read_file":
            return tool_read_file(target, action_input)
        if action == "list_dir":
            return tool_list_dir(target, action_input or ".")
        if action == "run_safe":
            return tool_run_safe(target, action_input)
        if action == "write_report":
            md = action_input if len(action_input) > 80 else build_heuristic_report(target, collect_scan(target))
            path = write_report(reports_dir, md)
            return f"Escrito: {path}"
        if action == "finish":
            return action_input or "ok"
        return f"ERROR: acción desconocida '{action}'"
    except Exception as e:
        return f"ERROR: {e}"


def run_hybrid(target: Path, reports_dir: Path, base: str, model: str | None, ctx: int, use_llm: bool) -> int:
    print(f"[hybrid] escaneando {target} …", flush=True)
    scan = collect_scan(target)
    note = ""
    body = build_heuristic_report(target, scan)
    if use_llm and model:
        print(f"[hybrid] narración LLM ({model}, ctx={ctx}) …", flush=True)
        narr = narrate_with_llm(base, model, ctx, target, scan)
        if narr and len(narr.strip()) > 80 and "Action:" not in narr[:40]:
            body = (
                f"# Informe de auditoría defensiva (local + LLM)\n\n"
                f"**Alcance:** `{target}`  \n"
                f"**Fecha:** {datetime.now().isoformat(timespec='minutes')}  \n"
                f"**Modelo:** `{model}`\n\n"
                f"{narr.strip()}\n\n"
                f"---\n\n## Anexo: datos brutos\n\n### Inventario\n```\n{scan['inventory'][:2000]}\n```\n\n"
                f"### Secretos\n```\n{scan['secrets'][:1500]}\n```\n"
            )
            note = "Narración LLM añadida."
        else:
            note = "LLM débil o vacío; se conserva informe heurístico."
            print(f"[hybrid] {note}", flush=True)
            body = build_heuristic_report(target, scan, note=note)
    path = write_report(reports_dir, body)
    print(f"[hybrid] informe: {path}", flush=True)
    print(path.read_text(encoding="utf-8")[:1200])
    return 0


def run_react(target: Path, model: str, base: str, num_ctx: int, max_steps: int, reports_dir: Path, goal: str) -> int:
    messages = [
        {"role": "system", "content": SYSTEM_REACT},
        {"role": "user", "content": f"Target: {target}\nObjetivo: {goal}\nEmpieza con Action: inventory"},
    ]
    print(f"[react] modelo={model} ctx={num_ctx}", flush=True)
    for step in range(1, max_steps + 1):
        print(f"\n── paso {step}/{max_steps} ──", flush=True)
        try:
            reply = chat(base, model, messages, num_ctx=num_ctx, num_predict=400)
        except urllib.error.URLError as e:
            print(f"[error] {e}; cayendo a hybrid", file=sys.stderr)
            return run_hybrid(target, reports_dir, base, None, num_ctx, use_llm=False)
        print(reply[:800], flush=True)
        messages.append({"role": "assistant", "content": reply})
        action, action_input = parse_action(reply)
        if not action or " " in action:
            obs = "ERROR: Action inválida. Usa solo: inventory|grep_secrets|read_file|list_dir|run_safe|write_report|finish"
            messages.append({"role": "user", "content": f"Observation: {obs}"})
            continue
        obs = execute(action, action_input, target, reports_dir)
        print(f"Observation:\n{obs[:1200]}", flush=True)
        if action == "finish":
            if not list(reports_dir.glob("AUDIT-*.md")):
                run_hybrid(target, reports_dir, base, None, num_ctx, use_llm=False)
            return 0
        messages.append({"role": "user", "content": f"Observation:\n{obs}\nSiguiente Action."})
        if len(messages) > 10:
            messages = [messages[0], messages[1]] + messages[-6:]
    print("[react] max steps → hybrid", flush=True)
    return run_hybrid(target, reports_dir, base, None, num_ctx, use_llm=False)


def main() -> int:
    hw = load_hardware_env()
    p = argparse.ArgumentParser(description="Auditoría defensiva local (sin Docker)")
    p.add_argument("target", nargs="?", default=".")
    p.add_argument("--model", default=os.environ.get("OLLAMA_MODEL", hw.get("LOCAL_OLLAMA_MODEL", "dolphin-phi:latest")))
    p.add_argument("--host", default=os.environ.get("OLLAMA_API", "http://127.0.0.1:11434"))
    p.add_argument("--ctx", type=int, default=int(os.environ.get("LOCAL_CTX", hw.get("LOCAL_CONTEXT_LENGTH", "2048"))))
    p.add_argument("--steps", type=int, default=8)
    p.add_argument("--fast", action="store_true", help="Solo heurísticas")
    p.add_argument("--react", action="store_true", help="Bucle ReAct (modelos mejores)")
    p.add_argument("--no-llm", action="store_true", help="Hybrid sin narración LLM")
    p.add_argument("--goal", default="Auditoría defensiva e informe.")
    p.add_argument("--reports", default=str(DEFAULT_REPORTS))
    args = p.parse_args()

    target = Path(args.target).expanduser().resolve()
    if not target.is_dir():
        print(f"No es directorio: {target}", file=sys.stderr)
        return 1
    reports_dir = Path(args.reports).expanduser().resolve()

    if args.fast or args.no_llm:
        return run_hybrid(target, reports_dir, args.host, None, args.ctx, use_llm=False)

    available = ollama_tags(args.host)
    model = pick_model(args.model, available) if available else None
    if not model:
        print("Ollama sin modelos; modo --fast", file=sys.stderr)
        return run_hybrid(target, reports_dir, args.host, None, args.ctx, use_llm=False)

    ctx = args.ctx
    if "dolphin-phi" in model:
        ctx = min(ctx, 2048)

    if args.react:
        # Modelos tipo qwen coder; dolphin-phi suele fallar el protocolo
        if "dolphin-phi" in model:
            print("[warn] dolphin-phi es débil en ReAct; usando hybrid+LLM", flush=True)
            return run_hybrid(target, reports_dir, args.host, model, ctx, use_llm=True)
        return run_react(target, model, args.host, ctx, args.steps, reports_dir, args.goal)

    # Default: hybrid (+ narración LLM si hay modelo)
    return run_hybrid(target, reports_dir, args.host, model, ctx, use_llm=True)


if __name__ == "__main__":
    sys.exit(main())
