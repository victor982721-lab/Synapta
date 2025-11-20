#requires -version 5.1

# Ruta fija al binario .NET
$ExePath = "C:\Users\VictorFabianVeraVill\Documents\GitHub\.RepoManager\Convertir_Documentos\Convertir_Word_a_Markdown.exe"

if (-not (Test-Path -LiteralPath $ExePath)) {
    Write-Host "No se encontró el binario en:" -ForegroundColor Red
    Write-Host "  $ExePath" -ForegroundColor Yellow
    exit 1
}

# Cargar WinForms para usar OpenFileDialog
Add-Type -AssemblyName System.Windows.Forms

function Show-Menu {
    Clear-Host
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "   Convertir documentos Word a Markdown" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) Seleccionar y convertir un archivo .docx"
    Write-Host "0) Salir"
    Write-Host ""
}

function Convert-WordToMarkdown {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Selecciona el archivo Word a convertir"
    $dlg.Filter = "Documentos Word (*.docx)|*.docx|Todos los archivos (*.*)|*.*"
    $dlg.Multiselect = $false
    $dlg.RestoreDirectory = $true

    $result = $dlg.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "Operación cancelada por el usuario."
        Start-Sleep -Seconds 1
        return
    }

    $docPath = $dlg.FileName
    Write-Host ""
    Write-Host "Convirtiendo:" -NoNewline
    Write-Host " $docPath" -ForegroundColor Yellow

    # Preparar proceso para llamar al binario, sin depender del directorio actual
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.UseShellExecute = $false
    $null = $psi.ArgumentList.Add($docPath)

    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.WaitForExit()

    if ($proc.ExitCode -eq 0) {
        $mdPath = [System.IO.Path]::ChangeExtension($docPath, ".md")
        Write-Host "Conversión completada." -ForegroundColor Green
        Write-Host "Archivo Markdown generado en:" -NoNewline
        Write-Host " $mdPath" -ForegroundColor Green
    }
    else {
        Write-Host "El conversor devolvió código de salida $($proc.ExitCode)." -ForegroundColor Red
    }

    Write-Host ""
    [void](Read-Host "Pulsa Enter para volver al menú")
}

# Wizard interactivo
while ($true) {
    Show-Menu
    $op = Read-Host "Selecciona una opción"

    switch ($op) {
        "1" { Convert-WordToMarkdown }
        "0" { break }
        default {
            Write-Host "Opción no válida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}