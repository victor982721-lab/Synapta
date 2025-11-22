param(
    [string]$HealthTaskName = "IndexadorHealthCheck",
    [string]$MonitorTaskName = "IndexadorLogMonitor",
    [string]$HealthScript = "IndexadorHealthCheck.ps1",
    [string]$MonitorScript = "Monitor-IndexadorLog.ps1",
    [int]$HealthIntervalMinutes = 30,
    [int]$MonitorIntervalMinutes = 60,
    [switch]$ReplaceExisting
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$healthPath = Resolve-Path (Join-Path $scriptDir $HealthScript)
$monitorPath = Resolve-Path (Join-Path $scriptDir $MonitorScript)
$defaultLog = Join-Path (Split-Path -Parent $scriptDir) "IndexadorWatcher.log"

function Register-CheckTask($name, $actionCmd, $intervalMinutes) {
    if ($ReplaceExisting -and (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue)) {
        Unregister-ScheduledTask -TaskName $name -Confirm:$false
    }

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $intervalMinutes) -RepetitionDuration (New-TimeSpan -Days 1)
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -File `"$actionCmd`""
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable)
    Write-Host "Tarea de monitoreo '$name' programada cada $intervalMinutes minutos."
}

Register-CheckTask -name $HealthTaskName -actionCmd $healthPath -intervalMinutes $HealthIntervalMinutes
Register-CheckTask -name $MonitorTaskName -actionCmd "$monitorPath -LogPath `"$defaultLog`" -Tail 100" -intervalMinutes $MonitorIntervalMinutes
