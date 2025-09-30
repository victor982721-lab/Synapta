# Análisis de datos

## Resumen ejecutivo

Este informe sintetiza 1 conversaciones clasificadas dentro de la categoría **análisis de datos**. La cobertura promedio de secciones detectadas fue del 85.7%

## Alcance y supuestos

Se analizaron las conversaciones para extraer procedimientos, prompts, ejemplos, snippets, listas de verificación, errores y métricas. Se asume que los textos contienen suficiente contexto.

## Procedimiento paso a paso

- - Español siempre. Respuestas concisas, directas y accionables en el mismo turno.
- - Declarar límites y **suposiciones** explícitas cuando aplique.
- - Respetar el formato pedido: lista ≠ tabla. “Salida limpia”.
- - PowerShell 7.5.3 (Core), Windows 10 Pro 10.0.19045 64-bit.
- - Usuario objetivo: `VictorFabianVeraVill`, equipo `DESKTOP-K6RBEHS`.
- - Codificación: UTF-8 end-to-end.
- - **StrictMode**: habilitar al cargar módulos o al inicio del script.
- - **Rutas**: nunca cambiar CWD en módulos `.psm1`. Construir rutas con `$PSScriptRoot` + `Join-Path`.
- - **Operaciones peligrosas**: exponer `-WhatIf/-Confirm` con `SupportsShouldProcess` y **llamar** a `ShouldProcess` en acciones que mutan estado.
- - **Errores**: `try/catch` y `-ErrorAction Stop` en operaciones críticas; registrar errores.

## Mejores prompts / plantillas

⚠️ FALTA: No se encontraron prompts claros.

## Ejemplos completos

  - [example_70288.txt] — sha256: c9ef9a5ea5b0712343cdcbb1d1d9732ab4d9bbbfea781eced30bdd698c71cf80 — ``` ## 1) Identidad y salida - Español siempre. Respuestas concisas, directas y accionables en el mismo turno. - Decla

## Snippets de código / comandos

- Ver archivo snippet_38015.txt — sha256: c9ef9a5ea5b0712343cdcbb1d1d9732ab4d9bbbfea781eced30bdd698c71cf80

## Checklists (previo, durante, posterior)

- - Respetar el formato pedido: lista ≠ tabla. “Salida limpia”.
- - Integrar checklist de **prácticas seguras**: validación de entrada, codificación de salida, autenticación, control de acceso, manejo de errores y *logging*.
- - Antes de asumir no acceso, intentar listar/leer desde disco.
- - Evaluar aplicabilidad, registrar en checklist, integrar solo lo pertinente y ensamblar en bloque canónico.
- compara con el snapshot previo y aplica políticas de retención.
- .PARAMETER CompareToPrevious
- Si se especifica, genera diff.json comparando contra el snapshot previo.
- .\Invoke-SeedsRepo.ps1 -ZipPath 'C:\tmp\seeds.zip' -RepoRoot 'D:\repo' -CompareToPrevious -EmitDiffJson -Verbose
- [switch]$CompareToPrevious,
- function Get-SeedsPreviousManifest {

## Errores comunes y mitigaciones

- - **Errores**: `try/catch` y `-ErrorAction Stop` en operaciones críticas; registrar errores.
- - **PSScriptAnalyzer**: ejecutar reglas recomendadas; fallar en *Error/Warning* según política.
- - Chequeos por defecto: StrictMode, higiene de rutas, manejo de errores, ShouldProcess, exportaciones, `Write-Host/Invoke-Expression`, complejidad, ayuda, portabilidad, firma.
- - Integrar checklist de **prácticas seguras**: validación de entrada, codificación de salida, autenticación, control de acceso, manejo de errores y *logging*.
- - En scripts que puedan activar AV: mitigar de forma segura y documentar la razón técnica.
- - Un único bloque con: propósito, parámetros, ejemplos, validación, `try/catch` con `-ErrorAction Stop`, y progreso.
- $ErrorActionPreference = 'Stop'
- $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
- Write-Error $_.Exception.Message

## Métricas / criterios de calidad

- - **Métricas**: complejidad ciclomática por función, cobertura de ayuda, cobertura de `ShouldProcess`.
- - **Revisiones de código**: objetivo es mejorar salud del código en el tiempo; CL/PR pequeños, con tests y diseño claro.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)


## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| id_fuente | archivo | cobertura_secciones_pct | duplicado | neardup |
|---|---|---|---|---|
| System_Core/2025-9-20/8-42-19-Guardar_contenido_documento | System_Core/2025-9-20/8-42-19-Guardar_contenido_documento.json | 86 | NO | NO |
