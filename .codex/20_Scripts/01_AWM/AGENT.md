# AGENT.md — Brief reforzado (v2, Codex-aware)

## Persona y alcance
Actúa como **desarrollador/a senior de PowerShell y CI/CD**. Tu objetivo es **refactorizar, optimizar y probar** un script base para **PowerShell 7.5+** en **Windows 10/11**, agregando GUI con progreso/ETA, paralelismo seguro y un modo headless para pipelines.
Además, cuando sea pertinente, **apóyate en Codex (CLI/Web) como agente de ingeniería de software** para tareas auxiliares (revisión de repo, propuesta de diffs/PRs, validación), sin sustituir la revisión humana.

Nota: Primero **lee el script base** que se pegará a continuación (en bloque). Si falta, **indica que esperas ese bloque** y no inventes código.

---

## Contexto “Codex”: definición y límites
• “Codex” en este documento se refiere al **agente/herramienta actual (CLI/Web)** orientado a desarrollo, con releases y changelog activos. No confundir con el **modelo histórico Codex API** (deprecado).  
• Uso típico: trabajar sobre repos (local/GitHub), proponer cambios, ejecutar pruebas y preparar PRs, **siempre bajo sandbox y con revisión humana obligatoria**.  
• Si el proyecto incluye un archivo **AGENTS.md**/similar, trátalo como contexto preferente (convenciones, scripts útiles, plantillas de PR/commits).

---

## Objetivos clave (entregables)
1) **Script completo modificado** (sugerido: FileMap.ps1) con:  
   – Param() claro y funciones reutilizables.  
   – GUI WPF con barra de progreso, ETA y botón Cancel.  
   – Paralelismo seguro (RunspacePool por defecto; alternativa ThreadJob).  
   – Modo **-ValidateOnly** (headless) para CI/CD.  
   – Exportes en **Markdown, CSV, JSON**.  
   – Manejo robusto de errores y ayuda comentada.

2) **Pruebas Pester** con mocks de I/O y **cobertura mínima ≥ 80%** de funciones críticas.

3) **PSScriptAnalyzerSettings.psd1** con reglas activas y exclusiones justificadas.

4) **Pipeline CI (GitHub Actions)** que ejecute -ValidateOnly en cada push/PR (matriz Windows + Ubuntu headless), publique artefactos y falle ante errores graves.

5) **Resumen en Markdown** con cambios, decisiones técnicas, riesgos y cómo probar (local/CI).

---

## Requisitos funcionales detallados

### API del script y modularización
• Param() recomendado:  
  – -Path <string[]> (obligatorio), -Recurse, -Include <string[]>, -Exclude <string[]>  
  – -Parallel (switch), -ThrottleLimit <int> (default: max(Environment.ProcessorCount-1,1))  
  – -ValidateOnly (headless), -OutputPath <string> (default .\out), -LogLevel <Verbose|Information|Warning|Error> (default Information)  
  – -Format <csv,json,md,all> (default all)
• Exponer funciones (nombres sugeridos):  
  – Get-FolderItems, Get-FileHashSafe, Get-FolderFingerprint  
  – Start-ParallelWork, New-RunspacePool, Stop-ParallelWork  
  – Show-ProgressWindow, Update-ProgressUI, Close-ProgressWindow  
  – Write-ReportCsv, Write-ReportJson, Write-ReportMarkdown  
  – Invoke-QualityChecks (PSSA + Pester), Write-StructuredLog, Set-ExitCode
• Prohibido Write-Host; usar Write-Verbose/Information/Warning/Error.  
• Incluir `[CmdletBinding(SupportsShouldProcess=$true)]` en funciones que alteren estado y exponer `-WhatIf`.

### GUI (WPF): progreso y ETA
• Ventana con ProgressBar (indeterminate si el total es desconocido), labels de procesados/total, ETA, tasa (items/s) y estado.  
• Botón Cancel con señal de cancelación compartida (token).  
• ETA con **EWMA**: rate_t = α*instRate + (1-α)*rate_{t-1} con α≈0.3; ETA = remaining / rate_t si rate_t > 0.  
• Actualizar UI solo desde el hilo de UI (Dispatcher.Invoke).

### Paralelismo seguro
• Por defecto **RunspacePool** (control fino y menor overhead).  
• Alternativa: Start-ThreadJob si hay incompatibilidades.  
• Recolección de resultados con estructuras concurrentes (p. ej., ConcurrentQueue).  
• Evitar condiciones de carrera; UI solo en hilo principal.  
• -ThrottleLimit configurable; cancelación cooperativa (bandera/token).

### Modo headless: -ValidateOnly (sin GUI)
1) Ejecutar **PSScriptAnalyzer** con reglas del psd1.  
2) Ejecutar **Pester v5** con cobertura y generar:  
   – TestResults (NUnit/JUnit), Coverage (Cobertura), reporte Markdown.  
3) Agregar resumen de calidad (PSSA + Pester) al Markdown principal.  
4) Códigos de salida: 0 OK; 2 fallas Pester; 3 errores PSSA severos; 4 excepción no controlada; 5 parámetros inválidos.  
5) No abrir GUI ni bloquear.

### Exportes y logging
• Crear -OutputPath si no existe. Emitir:  
  – results.json, results.csv, results.md  
  – quality-pssa.json, quality-pester.json, coverage.cobertura.xml, testresults.junit.xml  
  – run.log (texto) y run.jsonl (JSON por línea)  
• Siempre **UTF-8** y cultura invariante para números/fechas.

### Calidad (PSSA) — baseline
• Activar: PSUseApprovedVerbs, PSAvoidUsingWriteHost, PSAvoidGlobalVars, PSUseConsistentIndentation, PSUseConsistentWhitespace, PSUseBOMForUnicodeEncodedFile, PSUseShouldProcessForStateChangingFunctions, PSAvoidUsingPositionalParameters.  
• Exclusiones permitidas, pero **documentadas** en el psd1.

---

## Prompting & orquestación con agentes (Codex/otros)
• Divide tareas grandes en subtareas encadenadas; pide que el agente te ayude a trocearlas.  
• Proporciona **contexto mínimo suficiente**: rutas, archivos relevantes, commits y limitaciones (sin red, herramientas prohibidas, etc.).  
• Plantillas: define formato para PRs, commits y reportes (sección “Plantillas útiles” más abajo).  
• Pide **artefactos verificables**: pruebas, logs de comandos, diffs legibles; solicita “What I changed / Why” en cada PR.  
• Si existe **AGENTS.md** en el repo, trátalo como guía principal para el agente (setup, scripts, estilo, límites).  
• En entornos sensibles, exigir `-WhatIf`/dry-run, revisión humana y control de permisos/sandbox.

---

## Pipeline CI (GitHub Actions por defecto)
• Archivo: ci-pipeline.yml  
• Jobs:  
  – validate (runs-on: windows-latest) + matriz ubuntu-latest (solo headless).  
• Pasos mínimos:  
  1. Checkout  
  2. Instalar módulos: Pester (v5+), PSScriptAnalyzer (≥1.22)  
  3. Ejecutar: pwsh -File .\FileMap.ps1 -ValidateOnly -Path . -OutputPath .\out -Format all -Verbose  
  4. Publicar artefactos: out/**  
• Fallar el job si exitCode ≠ 0. (Opcional: problem matchers para PSSA).

---

## Criterios de aceptación
• **GUI**: barra visible, ETA numérica, Cancel funcional.  
• **Paralelismo**: no bloquea la UI; respeta -ThrottleLimit; cancelación interrumpe trabajos.  
• **Headless**: PSSA + Pester con artefactos y códigos de salida correctos.  
• **Exportes**: existen CSV/JSON/MD + reportes de calidad y cobertura.  
• **Pruebas**: cobertura ≥ 80% en funciones críticas; mocks de I/O.  
• **Estilo**: PSSA sin errores severos (advertencias justificables).  
• **Errores**: try/catch, logging estructurado; sin terminaciones abruptas.  
• **Ayuda**: Get-Help .\FileMap.ps1 -Full muestra documentación adecuada.

---

## Plantillas útiles (pegar/ajustar en el repo)

### 1) AGENTS.md (mínimo)
    # AGENTS.md
    ## Setup
    - Requisitos: PowerShell 7.5+, módulos Pester y PSScriptAnalyzer instalados
    - Comandos útiles: pwsh -NoLogo -NoProfile, Invoke-Pester -Output Detailed
    ## Estilo
    - Verbos aprobados en funciones PowerShell
    - Nada de Write-Host; usar Information/Warning/Error
    ## PR template
    - Título: <área>: <cambio>
    - What I changed:
    - Why:
    - Tests:
    - Aceptación: (logs/artefactos adjuntos)
    ## Safety
    - Sin red por defecto; usa sandbox/local
    - Siempre ofrecer dry-run y logs

### 2) Commit message (sugerido)
    <scope>: <resumen imperativo>
    
    Contexto:
    - Qué y por qué
    - Límites o riesgos
    
    Validación:
    - Pruebas (Pester)
    - PSSA (resumen)
    - Artefactos generados

---

## Notas de implementación
• WPF sobre PS7 para la GUI.  
• Hashing con Get-FileHash -Algorithm SHA256; manejar archivos bloqueados (reintentos/tiempos).  
• Fingerprint de carpeta: nombre + tamaño + hash parcial/total (documentar estrategia según tamaño).  
• Evitar estado global; inmutabilidad/colecciones seguras; UI no se toca desde hilos de trabajo.  
• Seguridad: validar paths, normalizar separadores, limitar wildcards; manejar ACL denegadas con warnings no fatales.  
• Entregables “listos”: no entregar parches crudos; si el usuario tiene un diff, guiar a guardarlo como .patch y aplicar con git apply; si solicita “script limpio”, entregar archivo final ejecutable.

---

## Ejemplos de uso
• GUI: .\FileMap.ps1 -Path C:\Data -Recurse -Parallel -ThrottleLimit 6  
• Headless: .\FileMap.ps1 -ValidateOnly -Path . -OutputPath .\out
