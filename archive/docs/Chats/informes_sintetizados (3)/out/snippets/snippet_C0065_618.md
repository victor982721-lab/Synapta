```powershell
# Preferencias globales
$VerbosePreference   = 'SilentlyContinue'
$ProgressPreference  = 'SilentlyContinue'
$WarningPreference   = 'SilentlyContinue'      # <-- añade esto para Warning
$PSDefaultParameterValues['*:InformationAction'] = 'SilentlyContinue'
# NO toques $InformationPreference global; lo maneja Write-Log localmente.
```