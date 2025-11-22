param(
    [string]$TaskName = "IndexadorWatcher",
    [string]$Root = (Get-Location).Path,
    [string]$Database,
    [ValidateSet("CRC32","SHA256")] [string]$Hash = "CRC32",
    [int]$Debounce = 1500,
    [switch]$Force,
    [switch]$NoClean,
    [string]$User,
    [switch]$RunAtStartup,
    [switch]$ReplaceExisting
)

$rootPath = Resolve-Path $Root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$watcherScript = Join-Path $scriptDir "Start-IndexadorWatcher.ps1"

if (-not (Test-Path $watcherScript))
{
    throw "No se encontró $watcherScript. Ejecuta este script desde la raíz del repositorio."
}

$arguments = @(
    "-NoProfile",
    "-File", "`"$watcherScript`"",
    "-Root", "`"$rootPath`"",
    "-Hash", $Hash,
    "-Debounce", $Debounce
)

if ($Database)
{
    $arguments += "-Database"; "`"$Database`""
}

if ($Force.IsPresent)
{
    $arguments += "-Force"
}

if ($NoClean.IsPresent)
{
    $arguments += "-NoClean"
}

$trigger = if ($RunAtStartup.IsPresent) {
    New-ScheduledTaskTrigger -AtStartup
} else {
    New-ScheduledTaskTrigger -Daily -At 03:00
}

$options = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument ($arguments -join " ")

if ($ReplaceExisting -and (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue))
{
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$registerParams = @{
    TaskName = $TaskName
    Action = $action
    Trigger = $trigger
    Settings = $options
}

if ($User)
{
    $registerParams.User = $User
    $registerParams.RunLevel = "Highest"
}

Register-ScheduledTask @registerParams

Write-Host "Tarea programada '$TaskName' registrada. El watcher iniciará el índice siempre que se cumpla el trigger."
