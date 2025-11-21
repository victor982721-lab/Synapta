# Bitácora

Registra decisiones, supuestos y hallazgos relevantes para este proyecto.

## 2025-11-19 – Preparación de solicitud Cortex
- Se revisó `docs/Informe.md` para sintetizar los ejes de refactor (separación lógica/UI, StrictMode, prompts maestro, calidad y descargas .NET).
- Se actualizaron `AGENTS.md`, `README.md`, `docs/solicitud_de_artefactos.md`, `csv/modules.csv`, `csv/artefacts.csv`, `docs/table_hierarchy.json` y `docs/filemap_ascii.txt` para describir la nueva arquitectura objetivo (Cortex Core/CLI/Automation/Exporter).
- Se documentaron compatibilidades requeridas (Windows 7+, PowerShell 5.1+/7+, .NET 6/7/8) y los criterios de aceptación para Codex Web.

## 2025-11-20 – Ajustes post auditoría
- Se aclararon compatibilidades (Win10/11 para desarrollo, soporte Win7/PS5.1) y preferencias de lenguajes en AGENTS generales y específicos.
- Se enriquecieron README, solicitud y Procedimiento con tabla de AutoOption, esquema de logging, plan Automation y directrices de pruebas.
- Se añadió 'Cortex_Plan_Schema.md', se actualizaron CSV, filemap y tabla de jerarquía, y se limpió el README raíz del repo.

## 2025-11-21 – Primer corte de Cortex.ps1 modular
- Se añadió `Cortex.ps1` en la raíz del proyecto con StrictMode, logging y capas Core/Services/CLI/Automation/Exporter en un solo archivo compatible con PS 5.1+/7+.
- Se implementaron funciones de scaffolding, GitOps (sync up/down), análisis (Parser, PSSA, dotnet), descargas de artefactos (`gh`/HTTP+ZipFile), menús interactivos y AutoOption 1–7.
- Se actualizaron CSV, mapa ASCII y jerarquía para reflejar el nuevo artefacto y se documentó el progreso en módulos/artefactos.
