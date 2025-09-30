# map_videos.ps1
# Escanea el teléfono Android por ADB y lista todos los archivos de video detectados.
# Resultado: CSV en el Desktop con rutas, tamaños y fechas.

$ErrorActionPreference = "Stop"

# Ruta Desktop
$desktopDir = [Environment]::GetFolderPath("Desktop")
$outFile = Join-Path $desktopDir "videos_phone.csv"

# Asegurar que ADB está en PATH
$toolsDir = "$env:USERPROFILE\android-tools"
$adbDir   = "$toolsDir\platform-tools"
if (!(Test-Path $adbDir)) {
    Write-Host "⚠️ ADB no encontrado, instálalo primero con tu script anterior (mirror_phone.ps1/record_phone.ps1)."
    exit 1
}
$env:PATH = "$adbDir;$env:PATH"

# Verificar dispositivo
$adbDevices = & adb devices
if (-not ($adbDevices -match "device`$")) {
    Write-Error "No se detectó dispositivo. Conecta por USB y habilita la depuración."
    exit 1
}

# Directorios a revisar
$dirs = @(
    "/sdcard",
    "/sdcard/DCIM",
    "/sdcard/Movies",
    "/sdcard/Download",
    "/sdcard/Android/data"
)

# Extensiones de video a buscar
$exts = @("mp4","3gp","mkv","webm")

# Colección de resultados
$results = @()

foreach ($d in $dirs) {
    Write-Host "🔍 Escaneando $d ..."
    try {
        $lines = & adb shell find $d -type f 2>$null
        foreach ($line in $lines) {
            foreach ($e in $exts) {
                if ($line -match "\.$e$") {
                    # Obtener info de archivo
                    $info = & adb shell ls -l --time-style=+"%Y-%m-%d %H:%M:%S" $line 2>$null
                    if ($info) {
                        $parts = $info -split "\s+"
                        $size = [int64]$parts[4]
                        $date = "$($parts[5]) $($parts[6])"
                        $results += [PSCustomObject]@{
                            Path  = $line
                            Size  = $size
                            Date  = $date
                        }
                    }
                }
            }
        }
    } catch {
        Write-Warning "No se pudo leer $d"
    }
}

if ($results.Count -eq 0) {
    Write-Host "⚠️ No se encontraron videos."
} else {
    $results | Sort-Object -Property Date -Descending | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
    Write-Host "✅ Listado generado: $outFile"
}