#requires -version 5.1

# Ruta al binario .NET en la misma carpeta que este script
$ExePath = Join-Path -Path $PSScriptRoot -ChildPath "Convertir_Parseo.exe"

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
    Write-Host "   Analizador estático de PowerShell" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) Seleccionar y analizar/corregir un script .ps1"
    Write-Host "0) Salir"
    Write-Host ""
}

function Invoke-Analyzer {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Selecciona el script de PowerShell a analizar"
    $dlg.Filter = "Scripts PowerShell (*.ps1)|*.ps1|Todos los archivos (*.*)|*.*"
    $dlg.Multiselect = $false

    $result = $dlg.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }

    $scriptPath = $dlg.FileName

    Write-Host ""
    Write-Host "Archivo seleccionado:" -ForegroundColor Yellow
    Write-Host "  $scriptPath"
    Write-Host ""

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.Arguments = '"' + $scriptPath + '"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    Write-Host "Ejecutando analizador..." -ForegroundColor Cyan
    [void]$proc.Start()

    $out = $proc.StandardOutput.ReadToEnd()
    $err = $proc.StandardError.ReadToEnd()

    $proc.WaitForExit()

    if ($out) {
        Write-Host ""
        Write-Host "==== Salida estándar ====" -ForegroundColor DarkCyan
        Write-Host $out
    }

    if ($err) {
        Write-Host ""
        Write-Host "==== Error estándar ====" -ForegroundColor Red
        Write-Host $err
    }

    if ($proc.ExitCode -eq 0) {
        Write-Host "Proceso completado correctamente." -ForegroundColor Green
    }
    else {
        Write-Host "El ejecutable devolvió código de salida $($proc.ExitCode)." -ForegroundColor Red
    }

    Write-Host ""
    [void](Read-Host "Pulsa Enter para volver al menú")
}

# Wizard interactivo
while ($true) {
    Show-Menu
    $op = Read-Host "Selecciona una opción"

    switch ($op) {
        "1" { Invoke-Analyzer }
        "0" { break }
        default {
            Write-Host "Opción no válida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
