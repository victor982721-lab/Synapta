# Servicio del watcher

## Objetivo
Automatizar la ejecución de `Indexador.Tool --watch` usando el script `scripts/Start-IndexadorWatcher.ps1` y un `Scheduled Task` de Windows para que el catálogo `indexador.db` se mantenga en tiempo real incluso después de reinicios.

## Pasos recomendados

1. **Configurar el script** `scripts/Start-IndexadorWatcher.ps1` con los parámetros deseados (`-Root`, `-Database`, `-Hash`, `-Debounce`).  
2. **Crear la tarea programada** con PowerShell (puedes usar `scripts/Register-IndexadorWatcherTask.ps1` para automatizar la creación). Se recomienda agregar `-LogPath C:\Logs\IndexadorWatcher.log` o similar para revisar cuándo se reejecuta el watcher:

```powershell
$RegScript = Join-Path $PWD "scripts\Register-IndexadorWatcherTask.ps1"
pwsh -NoProfile -File $RegScript -Root C:\Datos -Database C:\Datos\indexador.db -Debounce 1200 -RunAtStartup -Force -ReplaceExisting
```

3. Ajusta la tarea para que se reinicie al fallar y para que use la cuenta que tenga permisos sobre el root.  
4. Si prefieres un Windows Service, el script puede empaquetarse dentro de un ejecutable (por ejemplo con `PowerShell` + `sc.exe create`) o usarse en conjunto con herramientas como `NSSM`.

## Observaciones

- El script hace `dotnet run --project Indexador.Tool` por lo que debe ejecutarse desde el árbol del repositorio; si lo distribuyes puedes compilar el proyecto con `dotnet publish` y reemplazar la llamada con el binario resultante.  
- `Debounce` controla cuántos milisegundos esperar antes de procesar un lote de eventos; reduce la cadencia si el filesystem es ruidoso.  
- `RetryDelaySeconds` reintenta automáticamente cuando el watcher termina con errores, evitando reinicios manuales.  
- Usa `scripts/IndexadorHealthCheck.ps1` para validar que la API responde `/summary` tras un reinicio o despliegue del servicio.  
- Después de comprobar que el watcher está vivo, ejecuta `scripts/Run-PostRebootChecks.ps1` (puedes dejarlo en un scheduled task) para obtener estado, API, log y backup en un solo paso.  
- Para automatizar ese check, registra `scripts/Register-PostRebootChecksTask.ps1` (usando `-Trigger AtStartup` o `-Trigger Daily`) y así el sistema ejecuta el checklist tras cada reboot.
- Puedes ejecutar `scripts/Monitor-IndexadorLog.ps1 -LogPath C:\Logs\IndexadorWatcher.log` en tareas periódicas para detectar errores recientes y `scripts/Backup-IndexadorDb.ps1 -Database C:\Datos\indexador.db -BackupFolder C:\Backups\Indexador` antes de reinicios largos.
