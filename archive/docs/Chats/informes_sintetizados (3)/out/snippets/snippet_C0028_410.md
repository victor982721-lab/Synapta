```powershell
# 1) Construir columna ABSOLUTA (abs_path) desde relpath
$SRC = '.\FileList_Users_20250921_020839.csv'
Import-Csv $SRC | ForEach-Object {
  $rel = $_.relpath
  if     ($rel -match '^[A-Za-z]:\\') { $abs = $rel }                        # ya absoluta
  elseif ($rel -match '^(\\|/).*')    { $abs = "C:$rel" }                    # empieza con "\..."
  elseif ($rel -match '^(Users|ProgramData|Windows)\\') { $abs = Join-Path 'C:\' $rel }
  else                                    { $abs = Join-Path 'C:\Users' $rel } # usuario directamente
  $_ | Add-Member -NotePropertyName abs_path -NotePropertyValue $abs -Force
  $_
} | Where-Object { Test-Path $_.abs_path } | Export-Csv .\FileList_abs.csv -NoTypeInformation -Encoding utf8
```