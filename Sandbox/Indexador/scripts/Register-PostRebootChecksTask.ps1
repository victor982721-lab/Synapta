param(
    [string]$TaskName = "IndexadorPostRebootChecks",
    [string]$Script = ".\Run-PostRebootChecks.ps1",
    [string]$Trigger = "AtStartup",
    [switch]$ReplaceExisting
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedScript = Resolve-Path (Join-Path $scriptDir $Script)
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -File `"$resolvedScript`""

if ($ReplaceExisting -and (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue))
{
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$triggerDefinition = switch ($Trigger.ToLowerInvariant())
{
    "atstartup" { New-ScheduledTaskTrigger -AtStartup }
    "daily" { New-ScheduledTaskTrigger -Daily -At 03:10 }
    default { New-ScheduledTaskTrigger -AtStartup }
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggerDefinition -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable)
Write-Host "Tarea '$TaskName' registrada para ejecutar checks después del reinicio."
