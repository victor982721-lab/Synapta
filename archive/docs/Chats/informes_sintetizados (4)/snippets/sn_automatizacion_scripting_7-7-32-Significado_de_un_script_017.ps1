# Parámetros finales del script genérico

# Rutas adicionales (validación ya definida arriba)
[string[]]$RutasExtra,

# Switch para limpieza de componentes genéricos
[switch]$LimpiezaComponentes,

# Ruta de transcripción o bitácora
[string]$RutaTranscripcion,

# Nivel de detalle del log
[ValidateSet('Error','Warn','Info','Debug')]
[string]$NivelLog = 'Info',

# Tiempo de espera por fase (puede ser objeto, int, etc.)
[object]$TiempoEsperaFase,

# Switches adicionales de control
[switch]$CrearRespaldo,
[switch]$IncluirComplementos,
[switch]$IncluirPaquetes = $true,
[switch]$OmitirPaso1,
[switch]$OmitirPaso2,
[switch]$OmitirPaso3,
[switch]$OmitirPaso4,
[switch]$OmitirPaso5,

# Autoevaluación y control de salida
[switch]$AutoPrueba,
[switch]$DefinirCodigoSalida
)