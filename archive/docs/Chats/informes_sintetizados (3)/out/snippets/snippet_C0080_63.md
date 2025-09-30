```powershell
# Encabezado del script genérico
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    # Acción principal que define qué hacer
    [ValidateSet('Operacion1','Operacion2','Operacion3','Operacion4','Todo')]
    [string]$Action = 'Todo',

    # Parámetros tipo switch (verdadero/falso)
    [switch]$OpcionExtra1,
    [switch]$OpcionExtra2,
    [switch]$OpcionExtra3,
    [switch]$OpcionExtra4,

    # Validación de ruta de archivo de salida
    [ValidateScript({
        if ($_ -and ($_ -notmatch '(?i)\.txt$')) {
            throw 'La ruta de salida debe terminar en .txt'
        }
        $true
    })]
    [string]$RutaReporte
)
```