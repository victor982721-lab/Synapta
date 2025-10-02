# AGENTS.md — Guía para agentes (PowerShell + WPF)

> Documento genérico y duradero. No ata nombres de proyecto ni números de módulos.  
> Ajusta rutas sugeridas si tu repo usa otra convención.

## 1) Persona y objetivo
- Actúa como **ingeniero/a senior de PowerShell + WPF**.
- Entrega **código de producción** para **PowerShell 7.5+** (tolerar PS5 si es trivial), con **GUI WPF + CLI**.
- Prioriza: **idempotencia**, **-WhatIf/-Confirm**, **QA automatizable**, **logs/artefactos verificables**.

## 2) Estructura de repo (sugerida)
```text
/src                  # código fuente (.ps1 iniciales y/o .psm1 cuando se module)
/Public               # funciones exportables
/Private              # helpers internos
/modules              # módulos PowerShell (.psm1 + .psd1) cuando se migren
/tools                # utilidades de orquestación/QA (ver abajo)
/tests                # Pester v5 (un *.Tests.ps1 por unidad)
/.qa                  # PSScriptAnalyzerSettings.psd1 (baseline)
/out                  # artefactos (reportes, logs, cobertura, junit, etc.)
```
> Estructura orientativa. Usa nombres/rutas coherentes con tu repo.

## 3) Orquestación y QA (obligatorio SIEMPRE)
- **Orquestador** (`tools/Orchestrator.ps1`, nombre/ruta libres):  
  Carga unidades (`.ps1` o `.psm1`), expone entrada CLI/GUI, gestiona ciclo de vida y cancelación.
- **Runner de QA** (`tools/Invoke-QA.ps1`):  
  Ejecuta **PSScriptAnalyzer** con `.qa/PSScriptAnalyzerSettings.psd1`.  
  Ejecuta **Pester v5** con salida a `/out` (JUnit/Cobertura).  
  Si faltan PSSA o Pester, corre **checks AST ligeros** y marca `"Fallback-Checks": true`.
- **Materializa siempre** (si no existen):  
  `.qa/PSScriptAnalyzerSettings.psd1` (baseline editable) y `tests/**/<Unidad>.Tests.ps1` (plantilla mínima por unidad).

### Comandos locales (ejemplos)
```powershell
# Instalar (si el host no los tiene):
Install-Module PSScriptAnalyzer,Pester -Scope CurrentUser -Force

# Orquestador (GUI o CLI):
pwsh -NoLogo -NoProfile -File tools/Orchestrator.ps1 -Wizard
pwsh -NoLogo -NoProfile -File tools/Orchestrator.ps1 -Path . -OutputPath ./out -Format all

# QA:
pwsh -NoLogo -NoProfile -File tools/Invoke-QA.ps1 -Path . -Out ./out
```

## 4) Estándares de código y seguridad
- **PSSA sin errores** (baseline en `.qa/PSScriptAnalyzerSettings.psd1`; overlays/suppress con justificación).
- En funciones que modifican estado:  
  `Set-StrictMode -Version Latest`, `$ErrorActionPreference='Stop'`,  
  `[CmdletBinding(SupportsShouldProcess=$true)]` para exponer `-WhatIf/-Confirm`.
- **WPF/GUI**:  
  UI en **STA**, trabajo en **runspaces/hilos MTA**; actualiza UI con **Dispatcher** (no bloquear).  
  XAML embebido con here-strings **de comillas simples** `@'...'@` (sin expansión de `$`).
- **Logging/artefactos**:  
  Logs en texto y **JSON Lines**. Exportes: CSV/JSON/MD; en QA: JUnit y Cobertura.
- **Entrega iterativa a módulos**:  
  Puedes empezar en `.ps1`; **objetivo final**: `.psm1 + .psd1` con exports claros.  
  Si no cabe en el turno, deja TODOs y prioridad de migración.

## 5) Convenciones de entrega para el agente
- **Multiarchivo**: abrir con **manifiesto** (lista de rutas nuevas/modificadas) y luego cada archivo precedido por  
  `# path: <ruta>`, seguido de un **único** bloque ```powershell```.
- **Un solo archivo**: un bloque ```powershell``` sin prosa.
- Si falta contexto del repo, **genera stubs** + TODOs; no te bloquees.

## 6) QA mínimo por unidad (plantilla conceptual)
- **Tests (Pester v5)**:  
  Cubre firmas públicas, validaciones de parámetros, rutas críticas y contratos de retorno.  
  Usa Mocks para I/O y generadores para datasets pequeños.
- **PSSA**:  
  Reglas recomendadas: UseApprovedVerbs, UseShouldProcessForStateChangingFunctions, AvoidUsingWriteHost,  
  UseConsistentIndentation/Whitespace, AvoidGlobalVars, AvoidUsingPositionalParameters,  
  UseDeclaredVarsMoreThanAssignments, ReviewUnusedParameter.  
  Permite overlays por unidad y `SuppressMessage` con comentario **Why**.

## 7) CI (GitHub Actions o equivalente)
```yaml
name: qa
on: [push, pull_request]
jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install modules
        shell: pwsh
        run: Install-Module PSScriptAnalyzer,Pester -Scope CurrentUser -Force
      - name: QA
        shell: pwsh
        run: pwsh -NoLogo -NoProfile -File tools/Invoke-QA.ps1 -Path . -Out ./out
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: out
          path: out/**
```

## 8) Flujo de contribución (resumen)
- Ramas feature cortas; commits pequeños y atómicos.

**Plantilla de commit**
```
<scope>: <resumen imperativo>

Contexto:
- Qué y por qué
- Riesgos o supuestos

Validación:
- Pester (resumen)
- PSSA (resumen)
- Artefactos adjuntos (out/**)
```

**PR template (resumen)**
- What I changed / Why  
- Tests / Coverage  
- Artefactos (out/**)  
- Notas de breaking changes (si aplica)

## 9) Notas
- El chat no acepta subir `.ps1`: **todo vive en el repo**.  
- Mantén este documento **genérico**; las particularidades del proyecto van en README/Docs.