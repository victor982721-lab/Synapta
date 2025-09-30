$toHash = @(
  (Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe'),
  (Join-Path $Root '01_Software\300AN\YSD300AN-P2406.exe'),
  (Join-Path $Work 'YSD300AN.orig.exe'),
  (Join-Path $Work 'YSD300AN-P2406.orig.exe'),
  (Join-Path $Work 'YSD300AN.es.exe'),
  (Join-Path $Work 'YSD300AN-P2406.es.exe')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }