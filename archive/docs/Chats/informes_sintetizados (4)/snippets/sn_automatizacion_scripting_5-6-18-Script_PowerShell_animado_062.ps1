# Detectar la ruta del Escritorio del usuario actual
$desktop = [Environment]::GetFolderPath('Desktop')
$script  = Join-Path $desktop 'Entorno.ps1'

# Ejecutar en PS7 si existe, de lo contrario PS5, y sin mostrar error si uno falla
try {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
    }
    elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
    }
    else {
        Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)."
    }
}
catch {
    Write-Warning "No se pudo ejecutar el script: $($_.Exception.Message)"
}