# Estado del sistema y procesos

Este documento resume cómo verificar que los procesos principales del entorno (`IndexadorWatcher`, `Indexador.Tool`, `MsMpEng`, nuestra API, etc.) están donde deben y no están interferidos.

## Comandos utiles

- `Get-ScheduledTask -TaskName IndexadorWatcher,IndexadorPostRebootChecks,IndexadorHealthCheck,IndexadorLogMonitor` → confirma que las tareas siguen en estado `Ready` y cuándo se ejecutaron.
- `Get-Process -Name Indexador.Tool` (o `Indexador.Api`, `Filelist`) → muestra la ruta y confirma que corren desde el repo. Si necesitas saber qué otro proceso bloquea el `.db`, simplemente:
  ```powershell
  Get-Process | Where-Object { $_.Path -like '*indexador.db*' } | Format-Table Id, ProcessName, Path
  ```

- `Get-Process -Name MsMpEng` → te muestra el `Path` y la memoria del motor de Defender; si está en `C:\Program Files\Windows Defender\MsMpEng.exe`, es legítimo. Si no confías en el path, puedes detenerlo temporalmente con cuidado, pero no lo asesines sin motivo, porque protege el PC.

- `tasklist /FI "IMAGENAME eq MsMpEng.exe" /FO LIST` — similar, para validar la ruta sin PowerShell.

## Qué buscar

1. Si el watcher no puede abrir `indexador.db`, es porque otro proceso lo tiene bloqueado (por ejemplo `Indexador.Tool` ejecutado desde el centro de control). Usa `Run-PostRebootChecks.ps1` o `IndexadorControlCenter.ps1` en lugar de arranques simultáneos.
2. Si ves errores en rojo al iniciar la tarea programada, abre el log `C:\Users\VictorFabianVeraVill\IndexadorWatcher.log` con `Monitor-IndexadorLog.ps1` para leerlos sin que la ventana se cierre.
3. Defender (`MsMpEng.exe`) aparece en la lista pero no es nuestro indexador; su ruta te lo confirma y puedes ignorarlo.

## Registro de eventos

- Los logs principales están en `C:\Users\VictorFabianVeraVill\IndexadorWatcher.log`.
- Los backups se crean en `Backups\Indexador\indexador_YYYYMMDD_HHMMSS.db`.
- Puedes agregar tu propio `eventcreate` (o escribir en un archivo) desde dentro de `IndexadorControlCenter` para registrar incidencias específicas si lo deseas.
