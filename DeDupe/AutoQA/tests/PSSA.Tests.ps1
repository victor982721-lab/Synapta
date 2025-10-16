param(
  [string]$Settings = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\PSScriptAnalyzerSettings.psd1')
)

Describe 'PSSA (linting con reglas personalizadas)' {
  It 'Carga settings y corre sin errores de severidad Error' {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $settingsPath = Resolve-Path $Settings

    $include = @(
      (Join-Path $repoRoot '*.ps1'),
      (Join-Path $repoRoot '*.psm1'),
      (Join-Path $repoRoot '*.psd1'),
      (Join-Path $repoRoot 'Modules\*.psm1'),
      (Join-Path $repoRoot 'DeDuPe*.ps1'),
      (Join-Path $repoRoot '*GUI*.ps1')
    )

    $files = foreach($pat in $include){ Get-ChildItem -Path $pat -File -ErrorAction SilentlyContinue }
    $files | Should -Not -BeNullOrEmpty

    $result = Invoke-ScriptAnalyzer -Path $files.FullName -Settings $settingsPath -Recurse -ReportSummary -ErrorAction Stop
    $errors = $result | Where-Object Severity -eq 'Error'
    if ($errors) { $errors | Format-Table RuleName,Message,ScriptName,Line -AutoSize | Out-String | Write-Host }
    ($errors.Count) | Should -Be 0
  }
}
