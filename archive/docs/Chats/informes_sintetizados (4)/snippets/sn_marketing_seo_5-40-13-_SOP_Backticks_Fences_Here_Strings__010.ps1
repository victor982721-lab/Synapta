function Write-BacktickSafeFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$BodyLiteral,    # contenido @' ... '@
        [Parameter()]           [string]$FooterExpandable = ''
    )
    Set-StrictMode -Version 3.0

    $sep = "`r`n`r`n"
    $final = if ($FooterExpandable) { $BodyLiteral + $sep + $FooterExpandable } else { $BodyLiteral }

    if ($PSCmdlet.ShouldProcess($Path, "Escribir contenido UTF-8 sin BOM (CRLF)")) {
        Write-Utf8NoBom -Path $Path -Content $final
    }
}