```powershell
# Inventory-Coherence-Snapshot.ps1
# Requiere PowerShell 5.1+ (mejor 7+). No instala módulos.
param(
  [Parameter(Mandatory=$true)][string]$RootDir,
  [int]$MaxBytesToScan = 8192
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-VersionFromName([string]$name) {
  $patterns = @(
    'v(?<v>\d+(?:\.\d+){0,3})',           # v1 / v1.2 / v1.2.3.4
    '(?<v>\d+\.\d+\.\d+)',                 # 1.2.3
    'version[_\-\s:]*(?<v>\d+(?:\.\d+)*)'  # version: 1.2
  )
  foreach ($p in $patterns) {
    $m = [regex]::Match($name, $p, 'IgnoreCase')
    if ($m.Success) { return $m.Groups['v'].Value }
  }
  return $null
}

function Get-DateIsoFromName([string]$name) {
  $m = [regex]::Match($name, '(?<d>\d{4}-\d{2}-\d{2})')
  if ($m.Success) { return $m.Groups['d'].Value }
  return $null
}

function Get-TextPreview($path, $max) {
  try {
    $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($ext -in '.txt','.md','.json','.csv','.yml','.yaml','.ps1','.psm1','.psd1') {
      $fs = [IO.File]::OpenRead($path)
      try {
        $len = [Math]::Min($fs.Length, [int64]$max)
        $buf = New-Object byte[] $len
        [void]$fs.Read($buf,0,$len)
        return [Text.Encoding]::UTF8.GetString($buf)
      } finally { $fs.Dispose() }
    }
  } catch {}
  return $null
}

$items = Get-ChildItem -LiteralPath $RootDir -Recurse -File -ErrorAction Stop
$out = foreach ($f in $items) {
  $name = $f.Name
  $ver  = Get-VersionFromName $name
  $iso  = Get-DateIsoFromName $name
  $preview = Get-TextPreview $f.FullName $MaxBytesToScan
  if (-not $ver -and $preview) {
    $m = [regex]::Match($preview, 'version[_\-\s:]*(?<v>\d+(?:\.\d+)*)', 'IgnoreCase')
    if ($m.Success) { $ver = $m.Groups['v'].Value }
  }
  $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
  [pscustomobject]@{
    Path          = $f.FullName
    FileName      = $name
    Ext           = $f.Extension
    SizeBytes     = $f.Length
    LastWriteUtc  = $f.LastWriteTimeUtc.ToString('s') + 'Z'
    VersionGuess  = $ver
    DateISOinName = $iso
    SHA256        = $sha256
  }
}

$out | Sort-Object Path | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $RootDir 'inventory_snapshot.csv')
$out | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $RootDir 'inventory_snapshot.json')
Write-Host "Inventario generado: inventory_snapshot.csv / .json"
```