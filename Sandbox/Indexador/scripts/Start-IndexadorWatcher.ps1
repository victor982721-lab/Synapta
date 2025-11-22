param(
    [string]$Root = (Get-Location).Path,
    [string]$Database,
    [ValidateSet("CRC32","SHA256")] [string]$Hash = "CRC32",
    [int]$Debounce = 1500,
    [switch]$Force,
    [switch]$NoClean,
    [int]$RetryDelaySeconds = 5
)

$rootPath = Resolve-Path $Root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$solutionDir = Split-Path -Parent $scriptDir
$project = Join-Path $solutionDir "Indexador.Tool\Indexador.Tool.csproj"

Write-Host "Iniciando watcher para '$rootPath' (hash=$Hash, debounce=${Debounce}ms)"

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

    try
    {
        & dotnet run --project $project -- $argsList
        $exitCode = $LASTEXITCODE
    }
    catch
    {
        Write-Warning "El watcher terminó con excepción: $($_.Exception.Message)"
        $exitCode = 1
    }

    if ($exitCode -eq 0)
    {
        Write-Host "Watcher finalizó correctamente; saliendo."
        break
    }

    Write-Warning "Watcher finalizó con código $exitCode. Reintentando en $RetryDelaySeconds segundos..."
    Start-Sleep -Seconds $RetryDelaySeconds
}
