# === Normalizar nombres a ASCII (copias) ===
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$Root='C:\Users\VictorFabianVeraVill\Desktop\TBEA'; $SubPaths=@('01_Software')

function Convert-ToAsciiName([string]$Name){
  -join ($Name.ToCharArray() | ForEach-Object { if ([int][char]$_ -le 127) { $_ } else { '_' } })
}

$destRoot = Join-Path $Root 'normalized'
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

foreach($sub in $SubPaths){
  $src = Join-Path $Root $sub
  if(-not (Test-Path $src)){ continue }
  Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
    $relDir = Split-Path $rel -Parent
    $asciiName = Convert-ToAsciiName $_.Name
    $outDir = Join-Path $destRoot $relDir
    $outPath = Join-Path $outDir $asciiName
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $outPath -Force
  }
}
"Copias ASCII creadas bajo: $destRoot"