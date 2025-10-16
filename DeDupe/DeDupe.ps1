<# 
DeDupe.ps1 — PowerShell 7+
Lanza un asistente interactivo (wizard) para ejecutar la deduplicación SIN pasar parámetros.

Cómo usar:
  - Click derecho en el archivo → “Open with PowerShell 7”
  - o desde consola:  .\DeDupe.ps1

El asistente te pedirá:
  • Modo: Dry-run (WhatIf) o Ejecutar (Run)
  • Recurse: Sí / No
  • Carpeta a limpiar (Path)
  • Carpeta de cuarentena (QuarantinePath) — default: %LOCALAPPDATA%\DeDupe\Quarantine
  • Ruta del log JSONL (LogPath) — default: %LOCALAPPDATA%\DeDupe\logs\actions.jsonl
  • Exportar resumen JSON: Sí/No y ruta (default en %LOCALAPPDATA%\DeDupe\reports\*)

El resto usa valores sensatos por defecto:
  • Keep: Oldest
  • QuarantineLayout: BySize
  • DegreeOfParallelism: Auto (0 → auto-tune)
  • BlockSizeKB: 1024
  • Verify: false
#>

#requires -Version 7.2
[CmdletBinding()]
param() # sin parámetros: todo es interactivo

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Choice {
  param(
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$Message,
    [Parameter(Mandatory)][string[]]$Options,
    [int]$Default = 0
  )
  $list = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
  foreach ($opt in $Options) {
    $list.Add([System.Management.Automation.Host.ChoiceDescription]::new($opt))
  }
  return $Host.UI.PromptForChoice($Title, $Message, $list, $Default)
}

function Prompt-Path {
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)][string]$Default,
    [switch]$MustExist,
    [switch]$EnsureDirectory
  )
  while ($true) {
    $val = Read-Host "$Prompt [`$ENTER = default]`n  Default: $Default"
    if ([string]::IsNullOrWhiteSpace($val)) { $val = $Default }
    try {
      $expanded = [Environment]::ExpandEnvironmentVariables($val)
      if ($MustExist) {
        if (Test-Path -LiteralPath $expanded) { return $expanded }
        Write-Warning "No existe: $expanded"
      } elseif ($EnsureDirectory) {
        $dir = $expanded
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        return $dir
      } else {
        return $expanded
      }
    } catch {
      Write-Warning $_.Exception.Message
    }
  }
}

try {
  # ---------- Defaults ----------
  $defaultData = 'C:\.CODEX\.DATA'
  if (-not (Test-Path -LiteralPath $defaultData)) { $defaultData = (Get-Location).Path }

  $defaultQuarantine = Join-Path $env:LOCALAPPDATA 'DeDupe\Quarantine'
  $defaultLog        = Join-Path $env:LOCALAPPDATA 'DeDupe\logs\actions.jsonl'
  $reportsDir        = Join-Path $env:LOCALAPPDATA 'DeDupe\reports'
  if (-not (Test-Path -LiteralPath $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }
  $defaultReport     = Join-Path $reportsDir ("DeDupe_Summary_{0}.json" -f (Get-Date).ToString('yyyyMMdd_HHmmss'))

  # ---------- Wizard ----------
  $modeIdx = New-Choice -Title "Modo de ejecución" -Message "Elige acción:" -Options @("&Dry-run (no borra)", "&Run (aplica cambios)") -Default 0
  $isRun = ($modeIdx -eq 1)

  $recIdx = New-Choice -Title "Recorrer subcarpetas" -Message "¿Procesar recursivamente?" -Options @("&Sí", "&No") -Default 0
  $doRecurse = ($recIdx -eq 0)

  $path = Prompt-Path -Prompt "Ruta a limpiar (Path)" -Default $defaultData -MustExist
  $qPath = Prompt-Path -Prompt "Carpeta de cuarentena (QuarantinePath)" -Default $defaultQuarantine -EnsureDirectory
  $logPath = Prompt-Path -Prompt "Ruta del log JSONL (LogPath)" -Default $defaultLog
  $expIdx = New-Choice -Title "Exportar resumen JSON" -Message "¿Guardar un JSON con el resumen?" -Options @("&Sí", "&No") -Default 1
  $doExport = ($expIdx -eq 0)
  $outJson = $null
  if ($doExport) {
    $outJson = Prompt-Path -Prompt "Ruta del reporte JSON" -Default $defaultReport
    $outDir = Split-Path -Parent $outJson
    if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
  }

  # Valores por defecto “pro”
  $keep = 'Oldest'
  $layout = 'BySize'
  $dop = 0                 # auto
  $blkKB = 1024
  $verify = $false
  $includeHidden = $false
  $allowZero = $false
  $reportIntervalMs = 750

  # ---------- Importar módulos ----------
  $modDir = Join-Path $PSScriptRoot 'Modules'
  $mods = @(
    'DeDupe.Metrics.Ultra',
    'DeDupe.Logging',
    'DeDupe.Hashing.MetricsAdapter',
    'DeDupe.Grouping',
    'DeDupe.DedupeByHash',
    'DeDupe.Quarantine',
    'DeDupe.Pipeline'
  )
  foreach ($m in $mods) {
    $psm1 = Join-Path $modDir ("{0}.psm1" -f $m)
    if (Test-Path -LiteralPath $psm1) {
      . $psm1
    } else {
      $psd1 = Join-Path $modDir ("{0}.psd1" -f $m)
      if (-not (Test-Path -LiteralPath $psd1)) { throw "Módulo no encontrado: $psm1/$psd1" }
      Import-Module $psd1 -Force -ErrorAction Stop
    }
  }

  # ---------- Ejecutar ----------
  $summary = Invoke-DeDupePipeline `
    -Path $path `
    -Recurse:$doRecurse `
    -IncludeHidden:$includeHidden `
    -AllowZeroByte:$allowZero `
    -Keep $keep `
    -QuarantinePath $qPath `
    -LogPath $logPath `
    -QuarantineLayout $layout `
    -DegreeOfParallelism $dop `
    -BlockSizeKB $blkKB `
    -ReportIntervalMs $reportIntervalMs `
    -Verify:$verify `
    -Run:([bool]$isRun) `
    -Confirm:$false

  # ---------- Reporte ----------
  "`n==== RESUMEN ===="
  $summary | Format-Table -AutoSize | Out-Host
  "`nLog: $($summary.log_path_effective)"
  "`nQuarantine: $($summary.quarantine_path)"

  if ($doExport) {
    $json = $summary | ConvertTo-Json -Depth 8 -Compress
    Set-Content -LiteralPath $outJson -Value $json -Encoding UTF8
    "`nReporte JSON: $outJson"
  }

  "`nListo.`n"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
