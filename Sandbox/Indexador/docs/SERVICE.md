# Servicio del watcher

## Objetivo
Automatizar la ejecución de `Indexador.Tool --watch` usando el script `scripts/Start-IndexadorWatcher.ps1` y un `Scheduled Task` de Windows para que el catálogo `indexador.db` se mantenga en tiempo real incluso después de reinicios.

## Pasos recomendados

1. **Configurar el script** `scripts/Start-IndexadorWatcher.ps1` con los parámetros deseados (`-Root`, `-Database`, `-Hash`, `-Debounce`).  
2. **Crear la tarea programada** con PowerShell (puedes usar `scripts/Register-IndexadorWatcherTask.ps1` para automatizar la creación):

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
