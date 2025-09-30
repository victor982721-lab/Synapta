# Convierte cada línea JSON a objeto, construye abs_path y filtra los que sí existen
Get-Content .\FileList_Users_20250921_020839.jsonl |
  ForEach-Object { $_ | ConvertFrom-Json } |
  Select-Object *, @{
    n='abs_path'; e={
      $rel = ($_.relpath -replace '/','\')
      if     ($rel -match '^[A-Za-z]:\\')                       { $rel }                       # ya absoluta
      elseif ($rel -match '^(\\|/).*')                          { "C:$rel" }                   # \algo -> C:\algo
      elseif ($rel -match '^(Users|ProgramData|Windows|Temp)\\'){ Join-Path 'C:\' $rel }       # Users\... -> C:\Users\...
      else                                                      { Join-Path 'C:\Users' $rel }  # usuario directo
    }
  } |
  Where-Object { Test-Path $_.abs_path } |
  Export-Csv .\FileList_abs.csv -NoTypeInformation -Encoding utf8