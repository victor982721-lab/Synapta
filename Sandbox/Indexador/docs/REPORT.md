# Reporte rápido

Este archivo resume los comandos y artefactos clave del entorno `Indexador` para que puedas consultarlo o compartirlo con otros miembros.

## Comandos clave

- **Watcher**  
  `Get-ScheduledTask -TaskName IndexadorWatcher`  
  `Start-ScheduledTask IndexadorWatcher` / `Stop-ScheduledTask IndexadorWatcher`

- **Checklist post-reboot**  
  `pwsh -NoProfile scripts/Run-PostRebootChecks.ps1`  
  `scripts/Register-PostRebootChecksTask.ps1 -ReplaceExisting`

- **Health + Monitor + Backup**  
  `Scripts/Register-IndexadorMonitoringTasks.ps1 -ReplaceExisting`  
  `scripts/IndexadorHealthCheck.ps1`  
  `scripts/Monitor-IndexadorLog.ps1 -LogPath C:\Users\VictorFabianVeraVill\IndexadorWatcher.log`  
  `scripts/Backup-IndexadorDb.ps1 -Database C:\Users\VictorFabianVeraVill\indexador.db -BackupFolder Backups\Indexador`

- **Control Center**  
  `pwsh scripts/IndexadorControlCenter.ps1` o doble clic en el acceso directo generado por `scripts/Create-ControlCenterShortcut.ps1`.

- **API/Indexador.Tool/Filelist**  
  `dotnet run --framework net8.0 --project Indexador.Api`  
  `dotnet run --framework net8.0 --project Indexador.Tool -- --root C:\Users\VictorFabianVeraVill --watch`  
  `dotnet run --framework net8.0 --project Filelist -- --list`

## Documentación relacionada

- `README.md` (página principal).  
- `docs/INDEXADOR.md`: descripción técnica del core.  
- `docs/WATCHER.md`: flujo del watcher.  
- `docs/SERVICE.md`: despliegue de tareas y recomendaciones.  
- `docs/FILELIST.md`: uso del CLI `Filelist`.  
- `docs/API.md`: endpoints REST disponibles.  
- `docs/CHECKLIST.md`: pasos post-reinicio.  
- `docs/STATUS.md`: comandos para distinguir procesos legítimos y rastrear bloqueos.  
- `docs/REPORT.md`: este archivo de referencia rápida.

## Notas adicionales

- Los logs principales están en `C:\Users\VictorFabianVeraVill\IndexadorWatcher.log`.  
- Los backups se guardan en `Backups\Indexador\indexador_YYYYMMDD_HHMMSS.db`.  
- MsMpEng es el antivirus de Microsoft, ignóralo salvo que aparezca fuera de `C:\Program Files\Windows Defender`.  
- Si el watcher bloquea `indexador.db`, cierra procesos `dotnet` conflictivos y deja que sólo la tarea programada opere el archivo.
