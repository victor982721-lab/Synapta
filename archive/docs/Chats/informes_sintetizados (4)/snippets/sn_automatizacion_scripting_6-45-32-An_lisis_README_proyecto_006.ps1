Add-Type -AssemblyName System.Security
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($RequireAdmin -and -not $IsAdmin) { throw "Se requiere ejecución como Administrador." }