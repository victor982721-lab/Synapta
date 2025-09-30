# === Compilar Ghidra dentro de TBEA (sin tocar fuera) ===
$root = "$env:USERPROFILE\Desktop\TBEA"
$repo = Join-Path $root 'ghidra-master'

# 1) Encaminar la caché de Gradle a TBEA (regla: nada fuera de TBEA)
$env:GRADLE_USER_HOME = Join-Path $root '.gradle'

# 2) Verificar Java (sólo lectura)
java -version

# 3) Ir al repo y preparar el entorno de desarrollo
Set-Location -LiteralPath $repo
.\gradlew.bat --no-daemon -g "$env:GRADLE_USER_HOME" prepDev

# 4) Construir distribución
.\gradlew.bat --no-daemon -g "$env:GRADLE_USER_HOME" buildGhidra

# 5) Descomprimir la distro resultante a TBEA\tools
$distZip = Get-ChildItem -LiteralPath (Join-Path $repo 'build\dist') -Filter 'ghidra*.zip' |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
$toolsDir = Join-Path $root 'tools'
Expand-Archive -LiteralPath $distZip.FullName -DestinationPath $toolsDir -Force

# 6) Ubicar carpeta de Ghidra recién expandida y arrancar UI
$ghDir = Get-ChildItem -LiteralPath $toolsDir -Directory -Filter 'ghidra*' |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
Start-Process -FilePath (Join-Path $ghDir.FullName 'ghidraRun.bat') -WorkingDirectory $ghDir.FullName