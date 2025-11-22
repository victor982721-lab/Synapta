param()

[void]Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Show-Status {
    Write-Host ""
    Write-Host "Estado general:"
    Get-ScheduledTask -TaskName IndexadorWatcher, IndexadorPostRebootChecks, IndexadorHealthCheck, IndexadorLogMonitor -ErrorAction SilentlyContinue |
        Format-Table TaskName, State, LastRunTime -AutoSize
    Write-Host ""
    if (Test-Path ../indexador.db) {
        Write-Host "Índice: $(Get-Item ../indexador.db).LastWriteTime"
    } else {
        Write-Host "Índice: no generado todavía."
    }
}

function Start-Watcher {
    Write-Host "Iniciando watcher via scripts/Start-IndexadorWatcher.ps1..."
    Start-Process pwsh -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'scripts/Start-IndexadorWatcher.ps1', '-Root', "..", '-LogPath', "..\IndexadorWatcher.log", '-Database', "..\indexador.db", '-Hash', 'CRC32', '-Debounce', '800', '-Framework', 'net8.0' -NoNewWindow -Wait
}

function Run-Health {
    Write-Host "Ejecutando health check..."
    pwsh -NoProfile -File scripts/IndexadorHealthCheck.ps1 -ApiUrl http://localhost:5000
}

function Run-Monitor {
    Write-Host "Ejecutando monitor de log..."
    pwsh -NoProfile -File scripts/Monitor-IndexadorLog.ps1 -LogPath "..\IndexadorWatcher.log" -Tail 50
}

function Run-Backup {
    Write-Host "Respaldando índice..."
    pwsh -NoProfile -File scripts/Backup-IndexadorDb.ps1 -Database "..\indexador.db" -BackupFolder "..\Backups\Indexador"
}

function Show-Menu {
    Clear-Host
    Write-Host "=== Centro de Control Neurologic Indexador ==="
    Show-Status
    Write-Host "1) Start watcher (modo manual)."
    Write-Host "2) Health check API."
    Write-Host "3) Monitor log."
    Write-Host "4) Backup del índice."
    Write-Host "5) Ejecutar checklist post-reboot."
    Write-Host "6) Reenrollar tareas programadas (watcher/checks)."
    Write-Host "7) Salir."
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Selecciona una opción"
    switch ($choice) {
        '1' { Start-Watcher }
        '2' { Run-Health }
        '3' { Run-Monitor }
        '4' { Run-Backup }
        '5' { pwsh -NoProfile -File scripts/Run-PostRebootChecks.ps1 }
        '6' {
            & scripts/Register-IndexadorMonitoringTasks.ps1 -ReplaceExisting | Out-Null
            & scripts/Register-PostRebootChecksTask.ps1 -ReplaceExisting | Out-Null
            Write-Host "Tareas re-registradas."
        }
        '7' { break }
        default { Write-Warning "Opción inválida." }
    }
    Write-Host "Presiona Enter para volver al menú..."
    Read-Host
}
