# Tools

## MasterMaintenance.ps1
- Script de mantenimiento integral orientado a Windows 10/11 y PowerShell 7.x (requiere 7.0+). Ejecuta diagnósticos y snapshots de rendimiento, reparación de contadores, Defender, SFC/DISM, limpieza de red/temporales, limpieza de componente store, reparación de Windows Update y del indexador de búsqueda, cuarentena de duplicados por MD5 (solo tras colisión por tamaño) y detección de software obsoleto.
- Incluye restauración automática del CLI `codex` (desinstala e instala la última versión global vía npm) y registro en tiempo real (JSONL + Transcript) en `$env:USERPROFILE\MasterMaintenanceLogs`, con progreso interactivo reforzado (`Write-Progress`) y compatibilidad con `-WhatIf` / `-Confirm` gracias a `SupportsShouldProcess`.
- Añade telemetría viva: latidos periódicos con duración total/paso, velocidades de escaneo/hash y estados por paso para ver que el sistema sigue trabajando en tiempo real.
- Ejemplo: `pwsh -NoLogo -File ./Tools/MasterMaintenance.ps1 -Verbose` o para pasos específicos `pwsh -File ./Tools/MasterMaintenance.ps1 -Step Diagnostics,PerformanceSnapshot,RepairSearchIndex,RestoreCodexCli -SkipDefender -WhatIf`.
