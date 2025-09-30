# record_phone.ps1
# Graba la pantalla del móvil Android y guarda el video en el Desktop, reparado para que se abra en cualquier reproductor.
# Requiere: Windows 10/11 + PowerShell 7
# Uso:
#   .\record_phone.ps1 -Duration 30
# (Duration en segundos, por defecto 30)

param(
    [int]$Duration = 30
)

$ErrorActionPreference = "Stop"

# Rutas
$toolsDir   = "$env:USERPROFILE\android-tools"
$adbDir     = "$toolsDir\platform-tools"
$ffmpegDir  = "$toolsDir\ffmpeg"
$desktopDir = [Environment]::GetFolderPath("Desktop")

# Crear carpetas base
if (!(Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

# Función para descargar
function Download-File($url, $dest) {
    Write-Host "Descargando: $url"
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}

# Instalar ADB (platform-tools)
if (!(Test-Path $adbDir)) {
    $adbZip = "$toolsDir\platform-tools.zip"
    Download-File "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" $adbZip
    Expand-Archive $adbZip -DestinationPath $toolsDir -Force
    Remove-Item $adbZip
    Write-Host "✅ ADB instalado"
}

# Instalar FFmpeg (binario estático)
if (!(Test-Path $ffmpegDir)) {
    $ffmpegZip = "$toolsDir\ffmpeg.zip"
    Download-File "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" $ffmpegZip
    Expand-Archive $ffmpegZip -DestinationPath $toolsDir -Force
    $extracted = Get-ChildItem $toolsDir -Directory | Where-Object { $_.Name -like "ffmpeg-*" } | Select-Object -First 1
    if ($extracted) { Rename-Item -Path $extracted.FullName -NewName "ffmpeg" }
    Remove-Item $ffmpegZip
    Write-Host "✅ FFmpeg instalado"
}

# Agregar al PATH
$env:PATH = "$adbDir;$ffmpegDir\bin;$env:PATH"

# Verificar dispositivo
Write-Host "🔌 Verificando conexión con el móvil..."
$adbDevices = & adb devices
if (-not ($adbDevices -match "device`$")) {
    Write-Error "No se detectó dispositivo. Conecta por USB y habilita la depuración."
    exit 1
}

# Nombre temporal
$remoteFile = "/sdcard/demo.mp4"
$localFile  = Join-Path $desktopDir "demo_raw.mp4"
$fixedFile  = Join-Path $desktopDir "demo_fixed.mp4"

# Grabar pantalla
Write-Host "🎥 Grabando $Duration segundos de pantalla..."
& adb shell screenrecord --time-limit $Duration $remoteFile

# Copiar a PC
Write-Host "📂 Copiando a Desktop..."
& adb pull $remoteFile $localFile | Out-Null
& adb shell rm $remoteFile

# Reparar con FFmpeg
Write-Host "🛠 Reparando contenedor con FFmpeg..."
& ffmpeg -i $localFile -c copy $fixedFile -y

Write-Host "✅ Grabación lista en: $fixedFile"