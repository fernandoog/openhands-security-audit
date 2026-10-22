---
name: secrets-scan
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
  - secret
  - secrets
  - secreto
  - api key
  - token
  - credential
  - .env
  - gitleaks
---

# Escaneo de secretos

Busca claves API, tokens, contraseñas, certificados privados y credenciales en el árbol
de trabajo (código, historial reciente si se pide, configs).

- Usa `gitleaks` / `trufflehog` si existen; si no, `rg` con patrones prudentes.
- No exfiltres secretos reales al chat: redáctalos (`AKIA…****`).
- Indica archivo, tipo probable y acción (rotar, mover a secret manager, añadir a `.gitignore`).
