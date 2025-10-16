$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = (Get-ChildItem -Path $repoRoot -Filter '*GUI*.ps1' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName

Describe 'GUI (no bloquear hilo WPF)' {
  It 'Existe script de GUI' { Test-Path $guiPath | Should -BeTrue }

  It 'Usa Start-ThreadJob o invoca CLI externo (pwsh -File ...)' -Skip:(-not $guiPath) {
    $text = Get-Content -LiteralPath $guiPath -Raw -Encoding UTF8
    ($text -match 'Start-ThreadJob') -or ($text -match 'Start-Process\s+pwsh\s+-.*-File\s+.*DeDuPe\.ps1') | Should -BeTrue
  }

  It 'Hace tail con FileShare.ReadWrite' -Skip:(-not $guiPath) {
    $text = Get-Content -LiteralPath $guiPath -Raw -Encoding UTF8
    $text -match '\[IO\.File\]::Open\([^\)]*,\s*[^\)]*,\s*[^\)]*,\s*ReadWrite\)' | Should -BeTrue
  }
}
