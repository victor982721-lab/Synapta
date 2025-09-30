$toHash = @(
  (Join-Path $Root '01_Software\01_Drives_(Hl-340).exe'),
  ...
) ; $toHash = $toHash | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }