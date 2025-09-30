# Parámetros adicionales del script genérico

# Ruta donde se guardará el reporte
[string]$RutaReporte,

# Formato de salida permitido
[ValidateSet('txt','json','csv','all')]
[string]$FormatoReporte = 'txt',

# Validación de una ruta de sesión (no puede estar vacía ni apuntar a un archivo existente)
[ValidateScript({
    if ($_ -eq $null) { return $true }
    if ([string]::IsNullOrWhiteSpace($_)) {
        throw 'La ruta de sesión no puede estar vacía.'
    }
    $full = [IO.Path]::GetFullPath($_)
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        throw "La ruta de sesión apunta a un archivo existente: $full"
    }
    $true
})]
[string]$RutaSesion