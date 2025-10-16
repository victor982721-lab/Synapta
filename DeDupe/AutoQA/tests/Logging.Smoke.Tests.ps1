$repoRoot = Split-Path -Parent $PSScriptRoot
$loggingModule = Get-ChildItem -Path $repoRoot -Recurse -Filter 'DeDuPe.Logging.psd1' -ErrorAction SilentlyContinue | Select-Object -First 1

Describe 'Logging (JSONL + rotación)' {
  It 'Importa módulo' {
    if (-not $loggingModule) { Set-ItResult -Skipped -Because 'No se encontró DeDuPe.Logging.psd1'; return }
    Import-Module $loggingModule.FullName -Force
    Get-Command -Name New-JsonlLogger -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
  }

  It 'Escribe y rota a .bak' -Skip:(-not $loggingModule) {
    $log = Join-Path $env:TEMP "pssa_logs_$([guid]::NewGuid().Guid).jsonl"
    $lg  = New-JsonlLogger -Path $log -RotateAtMB 1
    1..8000 | ForEach-Object {
      Write-Jsonl -Logger $lg -Object @{ ts=(Get-Date).ToString('o'); i=$_; msg='smoke' }
    }
    Test-Path $log | Should -BeTrue
    (Get-ChildItem -Path (Split-Path -Parent $log) -Filter "$(Split-Path -Leaf $log)*.bak" -ErrorAction SilentlyContinue | Measure-Object).Count | Should -BeGreaterThan 0
  }
}
