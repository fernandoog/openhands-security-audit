---
name: security-audit
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - audit
  - auditoría
  - security
  - seguridad
  - vulnerabilidad
  - vulnerability
  - OWASP
  - CVE
  - hardening
  - secreto
  - secret
  - SAST
---

# Auditoría defensiva de seguridad

Cuando el usuario pida una auditoría:

1. Confirma alcance (ruta/repo) y que hay autorización.
2. Inventario rápido del proyecto.
3. Busca: secretos, deps vulnerables, injección/XSS/SSRF/path traversal en código,
   authz débil, crypto insegura, permisos excesivos, misconfig Docker/K8s/CI.
4. Clasifica hallazgos (Crit/Alta/Media/Baja/Info) con evidencia.
5. Propón remediación concreta (diff o pasos de config).
6. Genera informe en `reports/` con la plantilla del repo.

Nunca entregues exploits, payloads o procedimientos de ataque. Si el hallazgo es
una CVE conocida, enlaza advisory y describe mitigación, no reproducción ofensiva.
