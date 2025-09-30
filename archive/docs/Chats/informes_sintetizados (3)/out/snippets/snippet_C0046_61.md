```powershell
$doc = @"
# Informe $($meta.Name)
Generado: $([DateTime]::Now.ToString('u'))
"@
$doc | Out-File $dest -Encoding utf8
```