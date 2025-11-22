param(
    [string]$WatcherTask = "IndexadorWatcher",
    [string]$HealthCheckUrl = "http://localhost:5000",
    [string]$HealthCheckScript = ".\scripts\IndexadorHealthCheck.ps1",
    [string]$LogMonitorScript = ".\scripts\Monitor-IndexadorLog.ps1",
    [string]$LogPath = ".\IndexadorWatcher.log",
    [string]$BackupScript = ".\scripts\Backup-IndexadorDb.ps1",
    [string]$DatabasePath = ".\indexador.db",
    [string]$BackupFolder = ".\Backups\Indexador"
)

Write-Host "Verificando estado de la tarea '$WatcherTask'"
Get-ScheduledTask -TaskName $WatcherTask | Format-Table TaskName,State -AutoSize

Write-Host "Validando API con $HealthCheckUrl/summary"
pwsh -NoProfile -File $HealthCheckScript -ApiUrl $HealthCheckUrl

Write-Host "Revisando log de watcher"
pwsh -NoProfile -File $LogMonitorScript -LogPath $LogPath -Tail 200

Write-Host "Realizando backup de $DatabasePath"
pwsh -NoProfile -File $BackupScript -Database $DatabasePath -BackupFolder $BackupFolder

Write-Host "Checklist completado."
