```text
# === Localiza Ghidra dentro de TBEA, verifica versión y Java (solo lectura) ===
$root = "$env:USERPROFILE\Desktop\TBEA"

$ghidraRun = Get-ChildItem -LiteralPath $root -Recurse -Filter 'ghidraRun.bat' -ErrorAction SilentlyContinue | Select-Object -First 1
if(-not $ghidraRun){ throw "No se encontró ghidraRun.bat dentro de TBEA. Coloca tu Ghidra portable debajo de TBEA (p.ej. TBEA\tools\ghidra\...)." }
$ghidraDir = Split-Path $ghidraRun.FullName -Parent

# Intento leer version desde application.properties si existe
$verFile = Join-Path (Split-Path $ghidraDir -Parent) 'Ghidra\application.properties'
$verLine = if(Test-Path $verFile){ (Select-String -Path $verFile -Pattern '^application\.version=.*' -ErrorAction SilentlyContinue).Line } else { $null }

"`nGhidra: $($ghidraRun.FullName)"
if($verLine){ "Versión: $verLine" } else { "Versión: (no detectada en application.properties)" }

# Java (solo lectura)
$java = Get-Command java -ErrorAction SilentlyContinue
if($java){ & $java.Source -version } else { "Java no encontrado en PATH (si Ghidra trae JRE, igual abre)" }

# Crea proyecto local en TBEA (carpeta vacía y ASCII)
$projRoot = Join-Path $root 'i18n_work\ghidra_project'
$null = New-Item -ItemType Directory -Force -Path $projRoot
"Proyecto Ghidra (carpeta): $projRoot"

# Abre la UI (no importa si ya existe el proyecto; lo eliges al abrir)
Start-Process -FilePath $ghidraRun.FullName -WorkingDirectory $ghidraDir
```