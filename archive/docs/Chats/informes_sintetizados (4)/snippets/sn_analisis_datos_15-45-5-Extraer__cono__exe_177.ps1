# Verifica si los archivos del .ini existen junto a cada EXE y en System32
$exes = @(
  'C:\TBEA\01_Software\YSD300AN\YSD300AN.exe',
  'C:\TBEA\01_Software\YSD300AN-P2406\YSD300AN-P2406.exe'
) | Where-Object { Test-Path $_ }

$rows = foreach ($e in $exes) {
  $root = Split-Path -Path $e -Parent
  foreach ($rel in 'dcc.ini','dccsys.ini','data','user') {
    $p = Join-Path $root $rel
    [pscustomobject]@{Exe=(Split-Path $e -Leaf); Item=$rel; Path=$p; Exists=(Test-Path $p)}
  }
}
$rows += [pscustomobject]@{
  Exe='System32'; Item='dcy.ufo'; Path=(Join-Path $env:WINDIR 'System32\dcy.ufo'); Exists=(Test-Path (Join-Path $env:WINDIR 'System32\dcy.ufo'))
}
$rows | Format-Table -Auto