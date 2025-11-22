# ================================
#  Módulo Utils - ProyectoBase
# ================================
# Este módulo carga automáticamente todas las funciones
# definidas en archivos .ps1 dentro de la carpeta Utils.
#
# Las funciones experimentales deben guardarse en:
#   /Utils_Experimental
# para evitar carga automática hasta que se aprueben.
# ================================

# Obtener la ruta del módulo
\ = Split-Path -Parent \System.Management.Automation.InvocationInfo.MyCommand.Path

# Cargar automáticamente todos los .ps1 dentro de Utils
Get-ChildItem -Path \ -Filter "*.ps1" -File | ForEach-Object {
    try {
        . \.FullName
    }
    catch {
        Write-Host "Error al cargar \: \"
    }
}

# Nota: Utils_Experimental NO se carga automáticamente
# para mantener la estabilidad del proyecto.
