# Validación de rutas adicionales (ej. carpetas de limpieza extra)
[ValidateScript({
    if ($_ -eq $null) { return $true }
    foreach ($ruta in $_) {
        # Debe ser string válido
        if (-not ($ruta -is [string]) -or [string]::IsNullOrWhiteSpace($ruta)) {
            throw "Ruta inválida en RutasExtra."
        }

        # No puede ser raíz vacía
        $nombre = [IO.Path]::GetFileName($ruta)
        if ([string]::IsNullOrWhiteSpace($nombre)) {
            throw "No se permiten rutas raíz: $ruta"
        }

        # Obtener ruta completa y validar bloqueadas
        $completa = [IO.Path]::GetFullPath($ruta)
        foreach ($bloqueada in @(
            'C:\Sistema',
            'C:\Aplicaciones',
            'C:\DatosCompartidos',
            'C:\Usuarios'
        )) {
            if ($completa.TrimEnd('\') -like ($bloqueada + '*')) {
                throw "Ruta bloqueada por seguridad: $completa"
            }
        }
    }
    $true
})]
[string[]]$RutasExtra