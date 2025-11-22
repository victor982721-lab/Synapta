# Checklist post-reinicio

1. **Verificar tarea programada**
   ```powershell
   Get-ScheduledTask -TaskName IndexadorWatcher
   ```
   Debe responder `Ready` o `Running`.

2. **Validar API**
   ```powershell
   pwsh -NoProfile -File scripts\IndexadorHealthCheck.ps1 -ApiUrl http://localhost:5000
   ```
   Ajusta la URL si publicas la API en otro puerto o reverse proxy.

3. **Monitor de log**
   ```powershell
   pwsh -NoProfile -File scripts\Monitor-IndexadorLog.ps1 -LogPath C:\Logs\IndexadorWatcher.log -Tail 200
   ```
   Busca “Error” o keywords personalizadas.

4. **Respaldo del índice**
   ```powershell
   pwsh -NoProfile -File scripts\Backup-IndexadorDb.ps1 -Database C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Indexador\indexador.db -BackupFolder C:\Backups\Indexador
   ```
   Mantén varios snapshots si trabajas en cambios importantes.

5. **Opcional: ejecutar Filelist/health del API**
   - `dotnet run --project Filelist -- --root C:\Users\VictorFabianVeraVill --list --summary`.  
   - Llama `/records` o `/duplicates` si la API se expone públicamente.
