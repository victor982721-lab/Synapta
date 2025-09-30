# ==== DEDUP YSD/DCY DESDE FILEMAP (pegar y ejecutar) =========================
# Configuración rápida (ajusta si lo necesitas):
$WHATIF          = $false   # $true = simulación (no cambia nada); $false = ejecuta
$KeepInternalEdb = $false   # $true para incluir admin1.edb; por defecto se ignora
$FileMap         = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA\FileList_01_Software_20250920_135703.csv'
$RootPath        = $null    # si null, se autodetecta

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Utilidades ---
function Remove-Diacritics([string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
  $n = $Text.Normalize([Text.NormalizationForm]::FormD)
  $sb = [System.Text.StringBuilder]::new()
  foreach ($c in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  ($sb.ToString() -replace '[^A-Za-z0-9._-]', '_')
}
function Get-DesirabilityScore([System.IO.FileInfo]$File) {
  $ext  = $File.Extension.ToLowerInvariant()
  $name = $File.BaseName
  $score = 0
  switch ($ext) { '.ysd' { $score += 0 } '.dcy' { $score += 5 } default { $score += 10 } }
  if ($name -match '^(?i)temp') { $score += 5 }
  if ($name -match '[^\x00-\x7F]') { $score += 2 }
  return $score
}
function Infer-DateFromName([string]$BaseName) {
  if ($BaseName -match '\b(20\d{6})\b') {
    $y=[int]$Matches[1].Substring(0,4);$m=[int]$Matches[1].Substring(4,2);$d=[int]$Matches[1].Substring(6,2)
    if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) { return [datetime]::new($y,$m,$d) }
  }
  if ($BaseName -match '\b(\d{6})\b') {
    $yy=[int]$Matches[1].Substring(0,2);$m=[int]$Matches[1].Substring(2,2);$d=[int]$Matches[1].Substring(4,2)
    if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) { return [datetime]::new(2000+$yy,$m,$d) }
  }
  return $null
}
function Resolve-RootFromFilemap([object[]]$Rows,[string[]]$Candidates) {
  foreach ($root in $Candidates) {
    try {
      if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
      foreach ($r in $Rows) {
        $p = Join-Path $root ($r.relpath -replace '^[\\/]+','')
        if (Test-Path -LiteralPath $p -PathType Leaf) { return $root }
      }
    } catch { }
  }
  return $null
}
function Log-Line { param($Path,$Line) Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8 }

# --- Localizar filemap si no está en la ruta por defecto ---
if (-not (Test-Path -LiteralPath $FileMap -PathType Leaf)) {
  $cands = @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA'),
    ([Environment]::GetFolderPath('Desktop')),
    (Join-Path $HOME 'Downloads'),
    (Get-Location).Path
  )
  $fm = Get-ChildItem -Path $cands -Filter 'FileList_01_*.csv' -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($fm) { $FileMap = $fm.FullName } else { throw "No encuentro el filemap. Ajusta `\$FileMap`." }
}

# --- Cargar filemap ---
$rows = Import-Csv -LiteralPath $FileMap
if (-not ($rows | Get-Member -Name relpath)) { throw "El CSV debe tener columna 'relpath'." }
if (-not ($rows | Get-Member -Name ext))     { throw "El CSV debe tener columna 'ext'." }
if (-not ($rows | Get-Member -Name name))    { throw "El CSV debe tener columna 'name'." }

# --- Autodetectar RootPath si no se especificó ---
if (-not $RootPath) {
  $RootPath = Resolve-RootFromFilemap -Rows $rows -Candidates @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA\user1_zip_extracted'),
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA'),
    ([Environment]::GetFolderPath('Desktop')),
    (Get-Location).Path
  )
  if (-not $RootPath) { throw "No pude autodetectar la raíz. Fija `\$RootPath` manualmente." }
}

# --- Selección de objetivos desde el CSV ---
$targets = foreach ($r in $rows) {
  $ext = ($r.ext ?? '').ToString(); if ($ext -and ($ext[0] -ne '.')) { $ext = ".$ext" }
  $isData = $ext -match '^\.(ysd|dcy)$'
  $isEdb  = ($r.name -eq 'admin1.edb') -or ($ext -eq '.edb')
  if ($isData -or ($isEdb -and $KeepInternalEdb)) {
    $rel = ($r.relpath ?? '').ToString() -replace '^[\\/]+',''
    [pscustomobject]@{ relpath=$rel; abspath=(Join-Path $RootPath $rel); ext=$ext.ToLowerInvariant() }
  }
}
if (-not $targets) { throw "No hay .ysd/.dcy (o admin1.edb con -KeepInternalEdb) en el filemap." }

# --- Verificar existencia ---
$existing = @(); $missing = @()
foreach ($t in $targets) { if (Test-Path -LiteralPath $t.abspath -PathType Leaf) { $existing += $t } else { $missing += $t } }
if ($missing.Count -gt 0) { Write-Warning ("{0} entradas del CSV no existen bajo {1}" -f $missing.Count, $RootPath) }

if ($existing.Count -eq 0) { throw "No hay archivos presentes para procesar." }

# --- Agrupar por contenido (SHA256) ---
$byHash = @{}
foreach ($t in $existing) {
  $fi = Get-Item -LiteralPath $t.abspath
  $h  = Get-FileHash -LiteralPath $fi.FullName -Algorithm SHA256
  $rec = [pscustomobject]@{ File=$fi; Hash=$h.Hash }
  $byHash[$h.Hash] = @() + ($byHash[$h.Hash]) + ,$rec
}

# --- Logging ---
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$logPath   = Join-Path $RootPath ("actions_dedup_{0}.csv" -f $timestamp)
"Action,Path,Target,Hash,Notes" | Out-File -LiteralPath $logPath -Encoding UTF8

# --- Procesar duplicados por grupo ---
foreach ($entry in $byHash.GetEnumerator()) {
  $hash  = $entry.Key
  $files = $entry.Value | ForEach-Object { $_.File }

  # Elegir "keeper"
  $keeper = $files | Sort-Object `
      @{Expression={ Get-DesirabilityScore $_ }}, `
      @{Expression={$_.FullName.Length}}, `
      @{Expression={$_.Name}} | Select-Object -First 1

  $ext  = $keeper.Extension.ToLowerInvariant()
  $base = $keeper.BaseName

  # Nombre final (ASCII seguro + posible fecha)
  $safeBase = Remove-Diacritics $base
  if (-not $safeBase) { $safeBase = '' }
  $safeBase = $safeBase -replace '[^A-Za-z0-9._-]', '_'
  if (-not ($safeBase -match '[A-Za-z0-9]')) {
    $dt = Infer-DateFromName $base
    $safeBase = if ($dt) { 'YSD_{0}' -f $dt.ToString('yyyy-MM-dd') } else { 'YSD_{0}' -f $hash.Substring(0,8) }
  } else {
    $dt2 = Infer-DateFromName $base
    if ($dt2 -ne $null -and -not ($safeBase -like 'YSD_*')) { $safeBase = 'YSD_{0}_{1}' -f $dt2.ToString('yyyy-MM-dd'), $safeBase }
  }

  $targetName = "$safeBase$ext"
  $targetPath = Join-Path $keeper.DirectoryName $targetName

  # Resolver colisiones de nombre
  $suffix = 1
  while (Test-Path -LiteralPath $targetPath) {
    $existingHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
    if ($existingHash -eq $hash) {
      if ($keeper.FullName -ne $targetPath) {
        if ($WHATIF) {
          Log-Line $logPath ('"PLAN_DELETE","{0}","{1}","{2}","Duplicate of existing target"' -f $keeper.FullName,$targetPath,$hash)
        } else {
          Remove-Item -LiteralPath $keeper.FullName -Force -WhatIf:$WHATIF
          Log-Line $logPath ('"DELETE","{0}","{1}","{2}","Duplicate of existing target"' -f $keeper.FullName,$targetPath,$hash)
        }
        $keeper = Get-Item -LiteralPath $targetPath
      }
      break
    } else {
      $targetName = "{0}__{1}{2}" -f $safeBase, $suffix, $ext
      $targetPath = Join-Path $keeper.DirectoryName $targetName
      $suffix++
    }
  }

  # Renombrar keeper si procede
  if ($keeper.FullName -ne $targetPath -and -not (Test-Path -LiteralPath $targetPath)) {
    if ($WHATIF) {
      Log-Line $logPath ('"PLAN_RENAME","{0}","{1}","{2}","Keeper normalized to ASCII-safe name"' -f $keeper.FullName,$targetPath,$hash)
    } else {
      Rename-Item -LiteralPath $keeper.FullName -NewName $targetName -Force -WhatIf:$WHATIF
      Log-Line $logPath ('"RENAME","{0}","{1}","{2}","Keeper normalized to ASCII-safe name"' -f $keeper.FullName,$targetPath,$hash)
      $keeper = Get-Item -LiteralPath $targetPath
    }
  }

  # Eliminar duplicados restantes
  foreach ($f in $files) {
    if ($f.FullName -ne $keeper.FullName) {
      if ($WHATIF) {
        Log-Line $logPath ('"PLAN_DELETE","{0}","{1}","{2}","Duplicate removed"' -f $f.FullName,$keeper.FullName,$hash)
      } else {
        Remove-Item -LiteralPath $f.FullName -Force -WhatIf:$WHATIF
        Log-Line $logPath ('"DELETE","{0}","{1}","{2}","Duplicate removed"' -f $f.FullName,$keeper.FullName,$hash)
      }
    }
  }
}

Write-Host ("Listo. Registro de acciones: {0}" -f $logPath)
# ============================================================================