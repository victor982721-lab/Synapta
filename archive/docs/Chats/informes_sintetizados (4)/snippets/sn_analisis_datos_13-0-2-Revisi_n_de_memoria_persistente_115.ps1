$dest = "$env:USERPROFILE\Desktop\TBEA\context\Memoria_Otra.txt"
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
Set-Content -Path $dest -Value (Get-Clipboard -Raw) -Encoding UTF8
Start-Process notepad $dest