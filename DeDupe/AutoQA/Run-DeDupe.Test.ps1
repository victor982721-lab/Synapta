<#  Run-DeDupe.Test.ps1
    - Instala PSScriptAnalyzer y Pester (si faltan)
    - Ejecuta PSSA (lint) y pruebas Pester
#>
param(
  [switch]$SkipInstall
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$autoqa = $here
$tools = Join-Path $autoqa 'tools'
$tests = Join-Path $autoqa 'tests'
$settings = Join-Path $tools 'PSScriptAnalyzerSettings.psd1'

if (-not $SkipInstall) {
  if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host 'Instalando PSScriptAnalyzer...' -ForegroundColor Cyan
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
  }
  if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host 'Instalando Pester...' -ForegroundColor Cyan
    Install-Module Pester -Scope CurrentUser -Force -AllowClobber
  }
}

Write-Host "`n=== LINT: PSScriptAnalyzer ===" -ForegroundColor Yellow
Invoke-ScriptAnalyzer -Path (Split-Path -Parent $autoqa) -Settings $settings -Recurse -ReportSummary

Write-Host "`n=== Pester: tests ===" -ForegroundColor Yellow
Invoke-Pester -Path $tests -Output Detailed

Write-Host "`nListo." -ForegroundColor Green
