param(
    [string]$LogPath = "IndexadorWatcher.log",
    [int]$Tail = 100,
    [string]$Keyword = "Error",
    [switch]$AlertOnly
)

$resolved = Resolve-Path -LiteralPath $LogPath
if (-not (Test-Path $resolved))
{
    Write-Warning "No existe el log '$resolved'. Ejecuta primero el watcher."
    exit 1
}

$lines = Get-Content -Path $resolved -Tail $Tail
$errors = $lines | Where-Object { $_ -match $Keyword }

if ($errors.Count -gt 0)
{
    Write-Host "Se detectaron $($errors.Count) entradas con '$Keyword' en las últimas $Tail líneas."
    if (-not $AlertOnly)
    {
        $errors | ForEach-Object { Write-Host $_ }
    }
}
else
{
    Write-Host "No se detectaron entradas con '$Keyword' en las últimas $Tail líneas."
}
