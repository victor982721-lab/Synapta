param(
    [string]$Root = (Get-Location).Path,
    [string]$Database,
    [ValidateSet("CRC32","SHA256")] [string]$Hash = "CRC32",
    [int]$Debounce = 1500,
    [string]$LogPath,
    [switch]$Force,
    [switch]$NoClean,
    [int]$RetryDelaySeconds = 5
)

$rootPath = Resolve-Path $Root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionDir = Split-Path -Parent $scriptDir
$project = Join-Path $solutionDir "Indexador.Tool\Indexador.Tool.csproj"

Write-Host "Iniciando watcher para '$rootPath' (hash=$Hash, debounce=${Debounce}ms)"
$logPath = if ($LogPath) { Resolve-Path $LogPath } else { Join-Path $scriptDir "IndexadorWatcher.log" }
Add-Content -Path $logPath -Value "$(Get-Date -Format o) [Watcher] Servicio arrancado para '$rootPath'."

while ($true)
{
    $argsList = @(
        "--root", $rootPath,
        "--watch",
        "--debounce", $Debounce.ToString(),
        "--hash", $Hash
    )

    if ($Force.IsPresent)
    {
        $argsList += "--force"
    }

    if ($NoClean.IsPresent)
    {
        $argsList += "--no-clean"
    }

    if ($Database) { $argsList += @("--db", $Database) }

    $exitCode = 0

    Add-Content -Path $logPath -Value "$(Get-Date -Format o) [Watcher] Ejecutando dotnet run."
    try
    {
        & dotnet run --project $project -- $argsList
        $exitCode = $LASTEXITCODE
    }
    catch
    {
        Add-Content -Path $logPath -Value "$(Get-Date -Format o) [Watcher] Excepción: $($_.Exception.Message)"
        $exitCode = 1
    }

    if ($exitCode -eq 0)
    {
        Write-Host "Watcher finalizó correctamente; saliendo."
        Add-Content -Path $logPath -Value "$(Get-Date -Format o) [Watcher] Finalizó correctamente."
        break
    }

    Add-Content -Path $logPath -Value "$(Get-Date -Format o) [Watcher] Resultado $exitCode, reintentando en $RetryDelaySeconds s."
    Write-Warning "Watcher finalizó con código $exitCode. Reintentando en $RetryDelaySeconds segundos..."
    Start-Sleep -Seconds $RetryDelaySeconds
}
