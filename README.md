# Synapta — Configuración operativa de agentes

> Este repositorio define la **norma canónica** para trabajo con agentes (Codex / ChatGPT y afines).  
> La **SSOT** es `AGENTS.md`.

---

## 📌 Fuente única de verdad (SSOT)

- **[AGENTS.md](./AGENTS.md)** — Reglamento General Canónico v1.3  
  Guardrails, seguridad, reproducibilidad, DoD, patrones de prompts y perfil operativo (Codex CLI).

> Cualquier duda de comportamiento, formatos o políticas se resuelve **siempre** con `AGENTS.md`.

---

## 🚀 Requisitos rápidos

- **SO**: Windows 10  
- **Runtime**: PowerShell **7.5.x** (`pwsh.exe`)  
- **Modos**:  
  - Interactivo (por omisión): asistentes/menús  
  - Headless/CI: flags `--yes/--force` y `--dry-run` (cuando aplique)

---

## 🧭 Cómo empezar

1) Lee **AGENTS.md** (secciones *Alcance*, *Definiciones/contratos*, *DoD*).  
2) Crea tu rama de trabajo: `git checkout -b feature/<tema>`  
3) Implementa siguiendo DoD (idempotencia, escritura atómica, logs JSONL, etc.).  
4) Abre Pull Request con el resumen operativo (ver *Resumen final* en `AGENTS.md`).

---

## 🗂️ Estructura (orientativa)

```text
/                 # raíz del repo
AGENTS.md         # norma canónica (SSOT)
README.md         # este archivo
docs/             # perfiles/guías específicas (si aplica)
src/              # código fuente
tests/            # pruebas (Pester u otras)
tools/            # utilidades locales/CI
out/              # artefactos (logs, reports, cobertura, etc.)
```

> La estructura exacta puede variar; respeta **ROOT** y políticas de `AGENTS.md`.

---

## 🔐 Seguridad y cumplimiento (resumen)

- **No** subir secretos ni credenciales al repo.  
- Toda operación debe ser **reversible** y validada bajo **ROOT**.  
- **Logging** en JSONL con `run_id/op_id`, rotación y enmascarado de secretos.  
- Salidas **estructuradas** (JSON Schema) cuando se requiera formato estable.  
- **SBOM**/licencias y **code-signing** para artefactos distribuibles (cuando aplique).  
- Mitigaciones de **OWASP LLM Top-10** (prompt injection, filtrado de salidas, etc.).

> Detalle completo en `AGENTS.md` (secciones Seguridad, Supply-chain y Modelo de amenazas).

---

## ✅ Definition of Done (extracto)

- Validación de entradas y **ROOT** aplicada  
- Dry-Run/WhatIf disponible  
- Escrituras atómicas + verificación de hash  
- Logs JSONL con correlación (`run_id/op_id`)  
- Cancelación/timeouts soportados  
- Paridad CLI/GUI (headless cuando aplique)  
- Reproducibilidad y, si aplica, **SBOM** + firmas  
- Resumen final estructurado

> Lista completa y criterios en `AGENTS.md` → *DoD*.

---

## 🧾 Convención de commits

```
<scope>: <resumen imperativo>

Contexto:
- Qué y por qué
- Riesgos o supuestos

Validación:
- Resumen de pruebas / lint
- Artefactos (out/**)
```

Ejemplos:  
`delete(repo): remove legacy Codex_Instructions.md (superseded by AGENTS.md)`  
`build(orchestrator): atomic writes + sha256 verification`

---

## 🤝 Contribuir

- Usa ramas cortas `feature/<tema>`; PRs pequeños y atómicos.  
- Sigue estrictamente `AGENTS.md` para estilo, QA y seguridad.  
- Mantén la documentación actualizada en cada cambio relevante.

---
