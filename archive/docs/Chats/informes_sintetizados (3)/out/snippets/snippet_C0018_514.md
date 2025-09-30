```powershell
Set-Location $env:USERPROFILE
$ErrorActionPreference = 'Stop'
Try {
    # Código de deduplicación
} Catch {
    Write-Error "Error al procesar: $_"
}
```