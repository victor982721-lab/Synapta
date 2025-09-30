```powershell
# Detectar Escritorio del usuario actual y ubicar Entorno.ps1
$desktop = [Environment]::GetFolderPath('Desktop')
$script  = Join-Path $desktop 'Entorno.ps1'
Set-Location -Path $desktop

if (-not (Test-Path -LiteralPath $script)) {
    Write-Warning "No se encontró: $script"
    return
}

# Intentar primero pwsh (PS7), luego powershell (PS5), sin ruido si uno falla
$ran = $false

try {
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        & $pwshCmd.Source -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
        $ran = $true
    }
}
catch { }

if (-not $ran) {
    try {
        $ps5Cmd = Get-Command powershell -ErrorAction SilentlyContinue
        if ($ps5Cmd) {
            & $ps5Cmd.Source -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
            $ran = $true
        }
    }
    catch { }
}

if (-not $ran) {
    Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)."
}
```