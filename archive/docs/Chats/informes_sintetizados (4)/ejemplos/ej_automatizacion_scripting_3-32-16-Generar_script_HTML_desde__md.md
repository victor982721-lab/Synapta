### Entrada (user)

{"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

### Salida (assistant)

Script Canónico — genera una página HTML desde un .md mediante GUI y selector de archivos. Puede ejecutarse con confianza.

`````
#requires -Version 7.0
<#
.SYNOPSIS
GUI para convertir un archivo Markdown (.md) a HTML con selector de archivos.

.DESCRIPTION
Carga una ventana con botones para seleccionar el .md, definir salida .html y convertir usando ConvertFrom-Markdown.
Incluye validaciones, manejo de errores, barra de progreso y opción de abrir el resultado.

.PARAMETER StartDirectory
Directorio inicial para los diálogos de abrir/guardar. Debe existir.

.PARAMETER DefaultCssPath
Ruta a un archivo .css opcional para incrustar en el <style>. Si no se indica, se usa un CSS mínimo integrado.

.PARAMETER OpenAfter
Abre el HTML generado al finalizar.

.EXAMPLE
.\MdToHtml-GUI.ps1 -OpenAfter

.EXAMPLE
.\MdToHtml-GUI.ps1 -StartDirectory "C:\Users\Public\Documents" -DefaultCssPath "C:\estilos\site.css"
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter()]
    [ValidateScript({
        if (-not $_) { return $true }
        if (-not (Test-Path -LiteralPath $_ -PathType Container)) { throw "StartDirectory no existe: '$_'" }
        $true
    })]
    [string]$StartDirectory = [Environment]::GetFolderPath('Desktop'),

    [Parameter()]
    [ValidateScript({
        if (-not $_) { return $true }
        if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) { throw "DefaultCssPath no existe: '$_'" }
        if ($_ -notmatch '\.css$') { throw "DefaultCssPath debe terminar en .css" }
        $true
    })]
    [string]$DefaultCssPath,

    [Parameter()]
    [switch]$OpenAfter
)

begin {
    $ErrorActionPreference = 'Stop'

    function Show-Error([string]$Message, [Exception]$Exception) {
        try {
            [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
            [System.Windows.Forms.MessageBox]::Show(($Message + "`n`n" + $Exception.Message), 'Error', 'OK', 'Error') | Out-Null
        } catch { }
    }

    function Get-EmbeddedCss {
@'
/* CSS mínimo por defecto */
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body { margin: 2rem auto; max-width: 900px; padding: 0 1rem; font-family: -apple-system, Segoe UI, Roboto, Arial, Helvetica, sans-serif; line-height: 1.6; }
pre, code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace; }
pre { overflow: auto; padding: 1rem; border: 1px solid #ccc3; border-radius: 12px; }
code { background: #00000010; padding: .15rem .35rem; border-radius: 6px; }
h1, h2, h3 { line-height: 1.25; margin-top: 2rem; }
a { text-decoration: none; }
a:hover { text-decoration: underline; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ccc3; padding: .5rem .6rem; text-align: left; }
blockquote { margin: 1rem 0; padding: .5rem 1rem; border-left: 4px solid #8885; color: inherit; background: #00000008; }
hr { border: none; border-top: 1px solid #ccc5; margin: 2rem 0; }
'@
    }

    function Convert-MarkdownToHtmlString {
        param(
            [Parameter(Mandatory)][string]$MarkdownPath,
            [string]$CssText
        )
        if (-not (Get-Command ConvertFrom-Markdown -ErrorAction SilentlyContinue)) {
            throw "ConvertFrom-Markdown no está disponible. Requiere PowerShell 7+. Versión actual: $($PSVersionTable.PSVersion)"
        }
        $md = Get-Content -LiteralPath $MarkdownPath -Raw -Encoding UTF8
        $result = ConvertFrom-Markdown -Markdown $md
        $htmlBody = $result.Html

        # Título a partir del primer encabezado # si existe
        $title = 'Documento'
        $m = [Regex]::Match($md, '^\s*#\s+(.+?)\s*$', [Text.RegularExpressions.RegexOptions]::Multiline)
        if ($m.Success) { $title = $m.Groups[1].Value.Trim() }

        if (-not $CssText) {
            if ($DefaultCssPath) { $CssText = Get-Content -LiteralPath $DefaultCssPath -Raw -Encoding UTF8 }
            else { $CssText = Get-EmbeddedCss }
        }

        $doc = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>$([System.Web.HttpUtility]::HtmlEncode($title))</title>
<style>
$CssText
</style>
</head>
<body>
<main id="content">
$htmlBody
</main>
</body>
</html>
"@
        return $doc
    }

    # Preparar entorno de GUI
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    Add-Type -AssemblyName System.Drawing | Out-Null

    # Cambiar al directorio indicado al inicio
    try {
        if ($StartDirectory -and (Test-Path -LiteralPath $StartDirectory -PathType Container)) {
            Set-Location -LiteralPath $StartDirectory
        }
    } catch {
        Write-Warning "No se pudo establecer StartDirectory: $StartDirectory. Se usará el directorio actual."
    }
}

process {
    try {
        # Ventana
        $form                 = New-Object System.Windows.Forms.Form
        $form.Text            = "MD → HTML"
        $form.Width           = 700
        $form.Height          = 280
        $form.StartPosition   = 'CenterScreen'
        $form.MaximizeBox     = $false
        $form.FormBorderStyle = 'FixedDialog'
        $form.TopMost         = $false

        # Etiquetas y cajas de texto
        $lblMd        = New-Object System.Windows.Forms.Label
        $lblMd.Text   = "Archivo Markdown (.md):"
        $lblMd.AutoSize = $true
        $lblMd.Location = '12,15'

        $txtMd          = New-Object System.Windows.Forms.TextBox
        $txtMd.Location = '12,35'
        $txtMd.Width    = 560
        $txtMd.ReadOnly = $true
        $txtMd.AllowDrop = $true

        $btnSelMd          = New-Object System.Windows.Forms.Button
        $btnSelMd.Text     = "Seleccionar..."
        $btnSelMd.Location = '580,33'
        $btnSelMd.Width    = 90

        $lblOut        = New-Object System.Windows.Forms.Label
        $lblOut.Text   = "Salida HTML:"
        $lblOut.AutoSize = $true
        $lblOut.Location = '12,75'

        $txtOut          = New-Object System.Windows.Forms.TextBox
        $txtOut.Location = '12,95'
        $txtOut.Width    = 560

        $btnSelOut          = New-Object System.Windows.Forms.Button
        $btnSelOut.Text     = "Guardar como..."
        $btnSelOut.Location = '580,93'
        $btnSelOut.Width    = 90

        $chkOpen            = New-Object System.Windows.Forms.CheckBox
        $chkOpen.Text       = "Abrir al finalizar"
        $chkOpen.AutoSize   = $true
        $chkOpen.Location   = '12,130'
        $chkOpen.Checked    = [bool]$OpenAfter

        $pb               = New-Object System.Windows.Forms.ProgressBar
        $pb.Location      = '12,160'
        $pb.Width         = 658
        $pb.Style         = 'Continuous'
        $pb.Minimum       = 0
        $pb.Maximum       = 100
        $pb.Value         = 0

        $lblStatus          = New-Object System.Windows.Forms.Label
        $lblStatus.Text     = "Listo."
        $lblStatus.AutoSize = $true
        $lblStatus.Location = '12,190'

        $btnConvert          = New-Object System.Windows.Forms.Button
        $btnConvert.Text     = "Generar HTML"
        $btnConvert.Location = '12,210'
        $btnConvert.Width    = 140

        $btnClose          = New-Object System.Windows.Forms.Button
        $btnClose.Text     = "Cerrar"
        $btnClose.Location = '530,210'
        $btnClose.Width    = 140

        # Eventos
        $btnSelMd.Add_Click({
            try {
                $ofd = New-Object System.Windows.Forms.OpenFileDialog
                $ofd.Title            = "Seleccionar archivo Markdown"
                $ofd.Filter           = "Markdown|*.md;*.markdown|Todos|*.*"
                if ($StartDirectory -and (Test-Path -LiteralPath $StartDirectory -PathType Container)) {
                    $ofd.InitialDirectory = (Resolve-Path -LiteralPath $StartDirectory).Path
                }
                if ($ofd.ShowDialog() -eq 'OK') {
                    $txtMd.Text = $ofd.FileName
                    $base = [IO.Path]::GetFileNameWithoutExtension($ofd.FileName)
                    $dir  = [IO.Path]::GetDirectoryName($ofd.FileName)
                    $txtOut.Text = [IO.Path]::Combine($dir, "$base.html")
                }
            } catch {
                Show-Error "No se pudo seleccionar el archivo." $_
            }
        })

        $txtMd.Add_DragEnter({
            if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
                $_.Effect = [Windows.Forms.DragDropEffects]::Copy
            }
        })
        $txtMd.Add_DragDrop({
            try {
                $paths = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
                if ($paths -and $paths[0]) {
                    $p = $paths[0]
                    if ($p -notmatch '\.md(|own)?$|\.markdown$') { throw "El archivo no parece .md: $p" }
                    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "El archivo no existe: $p" }
                    $txtMd.Text = $p
                    $base = [IO.Path]::GetFileNameWithoutExtension($p)
                    $dir  = [IO.Path]::GetDirectoryName($p)
                    $txtOut.Text = [IO.Path]::Combine($dir, "$base.html")
                }
            } catch {
                Show-Error "Error al arrastrar el archivo." $_
            }
        })

        $btnSelOut.Add_Click({
            try {
                $sfd = New-Object System.Windows.Forms.SaveFileDialog
                $sfd.Title  = "Guardar HTML como"
                $sfd.Filter = "HTML|*.html;*.htm"
                if ($txtOut.Text) {
                    $sfd.FileName = [IO.Path]::GetFileName($txtOut.Text)
                    $dirO = [IO.Path]::GetDirectoryName($txtOut.Text)
                    if ($dirO -and (Test-Path -LiteralPath $dirO -PathType Container)) { $sfd.InitialDirectory = (Resolve-Path $dirO).Path }
                } elseif ($StartDirectory) {
                    $sfd.InitialDirectory = (Resolve-Path $StartDirectory).Path
                }
                if ($sfd.ShowDialog() -eq 'OK') {
                    $txtOut.Text = $sfd.FileName
                }
            } catch {
                Show-Error "No se pudo definir la ruta de salida." $_
            }
        })

        $btnConvert.Add_Click({
            try {
                $pb.Value = 0
                $lblStatus.Text = "Validando entradas..."
                [System.Windows.Forms.Application]::DoEvents()

                $inPath  = $txtMd.Text.Trim()
                $outPath = $txtOut.Text.Trim()

                if (-not $inPath)  { throw "Debe seleccionar un archivo .md" }
                if (-not (Test-Path -LiteralPath $inPath -PathType Leaf)) { throw "El archivo no existe: $inPath" }
                if ($inPath -notmatch '\.md(|own)?$|\.markdown$') { throw "La entrada debe ser un .md o .markdown" }

                if (-not $outPath) {
                    throw "Debe especificar la ruta de salida .html"
                }
                $outDir = [IO.Path]::GetDirectoryName($outPath)
                if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
                }

                $pb.Value = 20
                Write-Progress -Activity "Convirtiendo" -Status "Leyendo Markdown" -PercentComplete 20

                $lblStatus.Text = "Convirtiendo a HTML..."
                [System.Windows.Forms.Application]::DoEvents()

                $pb.Value = 60
                Write-Progress -Activity "Convirtiendo" -Status "Procesando Markdown" -PercentComplete 60

                $cssText = $null
                if ($DefaultCssPath) { $cssText = Get-Content -LiteralPath $DefaultCssPath -Raw -Encoding UTF8 }

                $docHtml = Convert-MarkdownToHtmlString -MarkdownPath $inPath -CssText $cssText

                $pb.Value = 85
                Write-Progress -Activity "Convirtiendo" -Status "Generando documento" -PercentComplete 85

                if ($PSCmdlet.ShouldProcess($outPath, "Escribir HTML")) {
                    Set-Content -LiteralPath $outPath -Value $docHtml -Encoding UTF8 -NoNewline
                }

                $pb.Value = 100
                Write-Progress -Activity "Convirtiendo" -Status "Completado" -PercentComplete 100
                $lblStatus.Text = "HTML generado: $outPath"

                if ($chkOpen.Checked) {
                    Start-Process -FilePath $outPath
                }
            } catch {
                Show-Error "Fallo al convertir a HTML." $_
                $lblStatus.Text = "Error: $($_.Exception.Message)"
            } finally {
                Start-Sleep -Milliseconds 150
                Write-Progress -Activity "Convirtiendo" -Completed
            }
        })

        $btnClose.Add_Click({ $form.Close() })

        # Agregar controles
        $form.Controls.AddRange(@($lblMd, $txtMd, $btnSelMd, $lblOut, $txtOut, $btnSelOut, $chkOpen, $pb, $lblStatus, $btnConvert, $btnClose))

        # Mostrar
        [void][System.Windows.Forms.Application]::EnableVisualStyles()
        [void]$form.ShowDialog()
    }
    catch {
        Show-Error "Error inesperado en la aplicación." $_
        throw
    }
}

end {
    # Salida útil para scripting si se usó la GUI y el usuario generó un archivo:
    # Nota: No se rastrea la ruta final salvo que se almacene de forma explícita.
    # El objetivo primario es la interacción GUI solicitada.
}
`````

