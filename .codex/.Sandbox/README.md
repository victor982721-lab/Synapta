# path: README.md
# Synapta

Este repo concentra la guía operativa de agentes, las instrucciones persistentes para Codex y un índice rápido de contenidos.

## Archivos principales

- **AGENTS.md**  
  Manual operativo para agentes/humanos: roles, entregables, estándares (PowerShell/WPF/QA), pipelines y plantillas de PR/commits.

- **Codex_Instructions.md**  
  Instrucciones persistentes para Codex: comportamiento estable, límites de seguridad, calidad obligatoria y degradación a checks AST si faltan dependencias.  
  > Mantenerlo corto y genérico. Los *prompts* por tarea agregan el contexto específico.

- **Synaptafiles.txt**  
  Índice/árbol de contenidos del repositorio (referencia rápida de `src`, `tests`, `tools`, `pssa`, etc.).  
  > Si usabas un nombre Unicode, aquí se emplea la versión ASCII para compatibilidad con Windows.

## Convenciones rápidas
- PowerShell 7.5+ preferido; PS5 tolerado si no complica.
- Idempotencia, `-WhatIf/-Confirm`, `Set-StrictMode -Version Latest`, `$ErrorActionPreference='Stop'`.
- Evitar `Write-Host` fuera de diagnóstico; usar *logging* estructurado.
- QA: PSScriptAnalyzer + Pester. Si faltan, degradar a checks AST y generar artefactos equivalentes.

## Flujo recomendado
1. Lee **AGENTS.md** (criterios de aceptación y estructura sugerida).  
2. Revisa **Codex_Instructions.md** para el “contrato” del agente.  
3. Navega el repo con **Synaptafiles.txt**.  
4. Trabaja en una rama `codex/<feature>` y envía PR con artefactos de QA (PSSA/Pester).