```powershell
# Requiere módulo Microsoft.Graph y permisos Calendars.Read
Connect-MgGraph -Scopes "Calendars.Read"
$from = (Get-Date).AddYears(-1).ToString("o")
$to   = (Get-Date).ToString("o")

# Trae eventos del último año y filtra por el ID en asunto/cuerpo
$events = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me/calendarview?startDateTime=$from&endDateTime=$to&$top=1000"
$hits = $events.value | Where-Object {
  $_.subject -match '254 296 380 195' -or $_.bodyPreview -match '254 296 380 195'
}
$hits | Select-Object subject, @{n='start';e={$_.start.dateTime}}, @{n='end';e={$_.end.dateTime}}, organizer, webLink
```