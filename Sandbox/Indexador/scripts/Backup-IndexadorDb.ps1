param(
    [string]$DatabasePath = "indexador.db",
    [string]$BackupFolder = ".\Backups"
)

$dbResolved = Resolve-Path -LiteralPath $DatabasePath
if (-not (Test-Path $dbResolved))
{
    Write-Error "No existe el archivo de índice en '$dbResolved'."
    exit 1
}

New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$destination = Join-Path $BackupFolder "indexador_$timestamp.db"

Copy-Item -LiteralPath $dbResolved -Destination $destination -Force
Write-Host "Backup realizado en '$destination'."
