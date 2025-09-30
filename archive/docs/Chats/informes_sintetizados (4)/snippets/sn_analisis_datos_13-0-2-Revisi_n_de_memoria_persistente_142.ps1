# Crear staging
$staging = "C:\YSD300A"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

# Copiar ejecutables originales al staging
Copy-Item "C:\Users\VictorFabianVeraVill\Desktop\TBEA\01_Software\YSD_300AN\YSD300AN.exe" `
          -Destination "$staging\YSD300AN.exe" -Force

Copy-Item "C:\Users\VictorFabianVeraVill\Desktop\TBEA\01_Software\300AN\YSD300AN-P2406.exe" `
          -Destination "$staging\YSD300AN-P2406.exe" -Force

# Ruta de Resource Hacker ya instalada
$RH = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\tools\ResourceHacker.exe"
$dst = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\i18n_work"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# Extraer recursos de ambos EXE a .rc
& $RH -open "$staging\YSD300AN.exe"       -save "$dst\YSD300AN.rc"       -action extract
& $RH -open "$staging\YSD300AN-P2406.exe" -save "$dst\YSD300AN-P2406.rc" -action extract

Write-Host "[OK] Recursos extraídos a $dst"