# Generar un script en PowerShell que automatice la creación de un informe en formato CSV
# con el estado de los servicios de Windows, incluyendo:
# - Nombre del servicio
# - Estado (en ejecución, detenido, etc.)
# - Descripción
# - Nombre del equipo
#
# El script debe:
# - Obtener la lista de servicios utilizando Get-Service
# - Filtrar servicios cuyo estado sea 'Running'
# - Exportar los resultados a un archivo CSV
# - Incluir un encabezado con la fecha y hora de ejecución
# - Manejar errores si no se puede acceder a los servicios
# - No utilizar Write-Host; en su lugar, usar Write-Output o Write-Error según corresponda
# - Asegurar la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2
#
# Ejemplo de salida esperada:
# "Servicio,Estado,Descripción,Equipo"
# "wuauserv,Running,Windows Update,MI-PC"