& {
  # ==== DEDUP YSD/DCY DESDE FILEMAP v3 (scope aislado, sin RootPath global) ====
  # Simulación ON/OFF
  $WHATIF          = $true    # true = plan (no cambia nada) | false = ejecuta
  $KeepInternalEdb = $false   # true para incluir admin1.edb
  $FileMap         = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA\FileList_01_Software_20250920_135703.csv'

  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'

  # --- Utilidades seguras ---
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
  function Resolve-BaseRoot([object[]]$Rows,[string[]]$Candidates) {
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
  function Test-IsUnder([string]$Path,[string]$Root) {
    try {
      $full = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
      $root = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath
    } catch { return $false }
    return $full.ToLowerInvariant().StartsWith($root.ToLowerInvariant())
  }
  function Log-Line { param($Path,$Line) Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8 }

  # --- Localizar filemap (fallback si no existe el indicado) ---
  if (-not (Test-Path -LiteralPath $FileMap -PathType Leaf)) {
    $cands = @(
      (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA'),
      ([Environment]::GetFolderPath('Desktop')),
      (Join-Path $HOME 'Downloads'),
      (Get-Location).Path
    )
    $fm = Get-ChildItem -Path $cands -Filter 'FileList_01_*.csv' -Recurse -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($fm) { $FileMap = $fm.FullName } else { throw "No encuentro el filemap. Ajusta `$FileMap`." }
  }

  # --- Cargar filemap con validación mínima ---
  try { $rows = Import-Csv -LiteralPath $FileMap -ErrorAction Stop }
  catch { throw "Error al leer CSV: $($_.Exception.Message)" }

  foreach ($req in 'relpath','ext','name') {
    if (-not ($rows | Get-Member -Name $req)) { throw "El CSV debe tener columna '$req'." }
  }

  # --- Autodetección de base root (sin usar variables globales) ---
  $BaseRoot = Resolve-BaseRoot -Rows $rows -Candidates @(
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA\user1_zip_extracted'),
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA'),
    ([Environment]::GetFolderPath('Desktop')),
    (Get-Location).Path
  )
  if (-not $BaseRoot) { throw "No pude autodetectar la raíz. Indica la ruta correcta en el CSV o mueve los archivos." }

  # --- Selección de objetivos (.ysd/.dcy y opcional admin1.edb) ---
  $targets = foreach ($r in $rows) {
    $ext = ($r.ext ?? '').ToString()
    if ($ext -and ($ext[0] -ne '.')) { $ext = ".$ext" }
    $isData = $ext -match '^\.(ysd|dcy)$'
    $isEdb  = ($r.name -eq 'admin1.edb') -or ($ext -eq '.edb')
    if ($isData -or ($isEdb -and $KeepInternalEdb)) {
      $rel = ($r.relpath ?? '').ToString() -replace '^[\\/]+',''
      [pscustomobject]@{ relpath=$rel; abspath=(Join-Path $BaseRoot $rel); ext=$ext.ToLowerInvariant() }
    }
  }
  if (-not $targets) { throw "No hay .ysd/.dcy (o admin1.edb con -KeepInternalEdb) en el filemap." }

  # --- Verificar existencia ---
  $existing = @(); $missing = @()
  foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t.abspath -PathType Leaf) { $existing += $t } else { $missing += $t }
  }
  if ($missing.Count -gt 0) { Write-Warning ("{0} entradas del CSV no existen bajo {1}" -f $missing.Count, $BaseRoot) }
  if ($existing.Count -eq 0) { throw "No hay archivos presentes para procesar." }

  # --- Agrupar por SHA256 ---
  $byHash = @{}
  foreach ($t in $existing) {
    try {
      $fi = Get-Item -LiteralPath $t.abspath -ErrorAction Stop
      $h  = Get-FileHash -LiteralPath $fi.FullName -Algorithm SHA256 -ErrorAction Stop
    } catch { throw "Hashing falló en '$($t.abspath)': $($_.Exception.Message)" }
    $rec = [pscustomobject]@{ File=$fi; Hash=$h.Hash }
    $byHash[$h.Hash] = @() + ($byHash[$h.Hash]) + ,$rec
  }

  # --- Logging y contadores ---
  $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
  $logPath   = Join-Path $BaseRoot ("actions_dedup_{0}.csv" -f $timestamp)
  "Action,Path,Target,Hash,Notes" | Out-File -LiteralPath $logPath -Encoding UTF8
  $stats = [ordered]@{ PLAN_RENAME=0; PLAN_DELETE=0; RENAME=0; DELETE=0; SKIP_OUTSIDE_ROOT=0; ERRORS=0 }

  function Log-Plan { param($A,$P,$T,$H,$N) Log-Line $logPath ('"'+$A+'","'+$P+'","'+$T+'","'+$H+'","'+$N+'"') ; if ($stats.Contains($A)) {$stats[$A]++} }
  function Log-Real { param($A,$P,$T,$H,$N) Log-Line $logPath ('"'+$A+'","'+$P+'","'+$T+'","'+$H+'","'+$N+'"') ; if ($stats.Contains($A)) {$stats[$A]++} }

  # --- Procesamiento por grupo ---
  foreach ($entry in $byHash.GetEnumerator()) {
    $hash  = $entry.Key
    $files = $entry.Value | ForEach-Object { $_.File }

    # Keeper
    $keeper = $files | Sort-Object `
        @{Expression={ Get-DesirabilityScore $_ }}, `
        @{Expression={$_.FullName.Length}}, `
        @{Expression={$_.Name}} | Select-Object -First 1

    $ext  = $keeper.Extension.ToLowerInvariant()
    $base = $keeper.BaseName

    # Nombre objetivo
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

    # Colisiones
    $suffix = 1
    while (Test-Path -LiteralPath $targetPath) {
      $existingHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256 -ErrorAction Stop).Hash
      if ($existingHash -eq $hash) {
        if ($keeper.FullName -ne $targetPath) {
          if (-not (Test-IsUnder -Path $keeper.FullName -Root $BaseRoot)) { $stats.SKIP_OUTSIDE_ROOT++; break }
          if ($WHATIF) {
            Log-Plan 'PLAN_DELETE' $keeper.FullName $targetPath $hash 'Duplicate of existing target'
          } else {
            try {
              Remove-Item -LiteralPath $keeper.FullName -Force -ErrorAction Stop -WhatIf:$WHATIF
              Log-Real 'DELETE' $keeper.FullName $targetPath $hash 'Duplicate of existing target'
            } catch { $stats.ERRORS++; Log-Real 'ERROR' $keeper.FullName $targetPath $hash $_.Exception.Message }
          }
          $keeper = Get-Item -LiteralPath $targetPath -ErrorAction Stop
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
      if (-not (Test-IsUnder -Path $keeper.FullName -Root $BaseRoot)) { $stats.SKIP_OUTSIDE_ROOT++; continue }
      if ($WHATIF) {
        Log-Plan 'PLAN_RENAME' $keeper.FullName $targetPath $hash 'Keeper normalized to ASCII-safe name'
      } else {
        try {
          Rename-Item -LiteralPath $keeper.FullName -NewName $targetName -Force -ErrorAction Stop -WhatIf:$WHATIF
          Log-Real 'RENAME' $keeper.FullName $targetPath $hash 'Keeper normalized to ASCII-safe name'
          $keeper = Get-Item -LiteralPath $targetPath -ErrorAction Stop
        } catch { $stats.ERRORS++; Log-Real 'ERROR' $keeper.FullName $targetPath $hash $_.Exception.Message }
      }
    }

    # Eliminar duplicados restantes
    foreach ($f in $files) {
      if ($f.FullName -ne $keeper.FullName) {
        if (-not (Test-IsUnder -Path $f.FullName -Root $BaseRoot)) { $stats.SKIP_OUTSIDE_ROOT++; continue }
        if ($WHATIF) {
          Log-Plan 'PLAN_DELETE' $f.FullName $keeper.FullName $hash 'Duplicate removed'
        } else {
          try {
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop -WhatIf:$WHATIF
            Log-Real 'DELETE' $f.FullName $keeper.FullName $hash 'Duplicate removed'
          } catch { $stats.ERRORS++; Log-Real 'ERROR' $f.FullName $keeper.FullName $hash $_.Exception.Message }
        }
      }
    }
  }

  # Resumen
  Write-Host ("Listo. Log: {0}" -f $logPath)
  "{0} PLAN_RENAME | {1} PLAN_DELETE | {2} RENAME | {3} DELETE | {4} SKIP_OUTSIDE_ROOT | {5} ERRORS" -f `
    $stats.PLAN_RENAME,$stats.PLAN_DELETE,$stats.RENAME,$stats.DELETE,$stats.SKIP_OUTSIDE_ROOT,$stats.ERRORS
}