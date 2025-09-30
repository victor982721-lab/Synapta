```powershell
# Parámetros relacionados con sesión, red y mantenimiento

# Directorio base de sesión
[string]$RutaSesion,

# Umbral mínimo de "salud" (0 a 100)
[ValidateRange(0,100)]
[int]$PuntajeSaludMinimo = 0,

# Lista de hosts en red (no nulos ni vacíos)
[ValidateNotNullOrEmpty()]
[string[]]$HostsRed,

# Puerto de red válido (1 a 65535)
[ValidateRange(1,65535)]
[int]$PuertoRed,

# Espacio libre mínimo requerido (en GB, entre 1 y 100000)
[ValidateRange(1,100000)]
[int]$EspacioLibreMinGB = 2,

# Switches adicionales (banderas opcionales)
[switch]$CrearPuntoRestauracion,
[switch]$HabilitarServicioRemoto,
[switch]$LimpiarTemporales
```