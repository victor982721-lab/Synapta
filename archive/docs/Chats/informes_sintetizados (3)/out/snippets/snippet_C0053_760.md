```powershell
$desktop = [Environment]::GetFolderPath('Desktop')
$script  = Join-Path $desktop 'Entorno.ps1'
Set-Location $desktop
if (-not (Test-Path -LiteralPath $script)) { Write-Warning "No se encontró: $script"; return }

# Asegurar -Stay por defecto
$paramList = @($args)
if (-not ($paramList -contains '-Stay')) { $paramList += '-Stay' }

$ran = $false
try {
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($pwsh) {
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null
    if ($LASTEXITCODE -eq 0) { $ran = $true }
  }
} catch { }

if (-not $ran) {
  try {
    $ps5 = Get-Command powershell -ErrorAction SilentlyContinue
    if ($ps5) {
      & $ps5.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null
      $ran = $true
    }
  } catch { }
}

if (-not $ran) { Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)." }
```