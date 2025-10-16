# DeDupe.DedupeByHash
# - Entrada: Map (size -> hash -> group) de DeDupe.Grouping
# - Mantiene 1 por hash (estrategia: Oldest|Newest|ShortestPath)
# - Borra el resto (dry-run si no se pasa -Run). Verify opcional (byte-a-byte con DeDupe.Engine si está cargado)
# - Devuelve SurvivorsBySize (para cuarentena posterior) y métricas

using namespace System.Collections.Generic
using namespace System.IO
Set-StrictMode -Version Latest

function Select-KeepFile {
  param([System.IO.FileInfo[]]$List,[ValidateSet('Oldest','Newest','ShortestPath')][string]$Strategy='Oldest')
  switch ($Strategy) {
    'Oldest'       { return ($List | Sort-Object -Property LastWriteTimeUtc, FullName | Select-Object -First 1) }
    'Newest'       { return ($List | Sort-Object -Property @{Expression='LastWriteTimeUtc';Descending=$true}, @{Expression='FullName'} | Select-Object -First 1) }
    'ShortestPath' { return ($List | Sort-Object -Property @{Expression={ $_.FullName.Length }}, @{Expression='FullName'} | Select-Object -First 1) }
    default        { return ($List | Sort-Object -Property LastWriteTimeUtc, FullName | Select-Object -First 1) }
  }
}

function Test-StreamsEqualSafe {
  param([string]$A,[string]$B)
  if (Get-Command -Name Test-EngineStreamsEqual -ErrorAction SilentlyContinue) {
    return (Test-EngineStreamsEqual -PathA $A -PathB $B)
  } else {
    # Fallback simple
    $fa=[File]::Open($A,'Open','Read','Read')
    $fb=[File]::Open($B,'Open','Read','Read')
    try {
      if ($fa.Length -ne $fb.Length) { return $false }
      $bufA = New-Object byte[] (1MB)
      $bufB = New-Object byte[] (1MB)
      while ($true) {
        $ra = $fa.Read($bufA,0,$bufA.Length); $rb = $fb.Read($bufB,0,$bufB.Length)
        if ($ra -ne $rb) { return $false }
        if ($ra -le 0) { break }
        for ($i=0; $i -lt $ra; $i++) { if ($bufA[$i] -ne $bufB[$i]) { return $false } }
      }
      return $true
    } finally { $fa.Dispose(); $fb.Dispose() }
  }
}

function Remove-DuplicatesByHash {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
  param(
    [Parameter(Mandatory)][hashtable]$Map,
    [ValidateSet('Oldest','Newest','ShortestPath')][string]$Keep='Oldest',
    [switch]$Verify,
    [switch]$Run,
    [string]$Policy = 'pdp:test',
    $Logger
  )
  $dupDeleted = 0
  $dupBytes   = 0L
  $errors     = 0
  $survivorsBySize = [System.Collections.Generic.Dictionary[int64, object]]::new()

  foreach ($sizeKey in $Map.Keys) {
    $hashGroups = $Map[$sizeKey]
    foreach ($hashKey in $hashGroups.Keys) {
      $group = $hashGroups[$hashKey]
      $keepArr = $group.Files.ToArray()
      $keeper = Select-KeepFile -List $keepArr -Strategy $Keep
      foreach ($f in $keepArr) {
        if ($f.FullName -eq $keeper.FullName) { continue }
        $ok = $true
        if ($Verify) { $ok = Test-StreamsEqualSafe -A $keeper.FullName -B $f.FullName }
        if ($Logger) {
          DeDupe.Logging\Write-Jsonl -Logger $Logger -Data @{
            ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$Policy; action='delete_duplicate_by_hash';
            hash=$hashKey; size_bytes=[int64]$sizeKey; keep=$keeper.FullName; target=$f.FullName;
            mode= ($(if($Run){'delete'}else{'simulate'})); verified=[bool]$Verify; verified_equal=[bool]$ok
          }
        }
        if ($ok) {
          if ($Run) {
            if ($PSCmdlet.ShouldProcess($f.FullName,'Remove-Item')) {
              try { Remove-Item -LiteralPath $f.FullName -Force; $dupDeleted++; $dupBytes+=[int64]$sizeKey }
              catch { $errors++; if($Logger){ DeDuPe.Logging\Write-Jsonl -Logger $Logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$Policy; action='delete_error'; target=$f.FullName; error=$_.Exception.Message } } }
            }
          } else {
            $dupDeleted++; $dupBytes+=[int64]$sizeKey
          }
        }
      }
      # agrega el keeper a los sobrevivientes
      if (-not $survivorsBySize.ContainsKey([int64]$sizeKey)) {
        $survivorsBySize[[int64]$sizeKey] = New-Object psobject -Property @{ Files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'; Length = 0 }
      }
      $s = $survivorsBySize[[int64]$sizeKey]
      $s.Files.Add($keeper); $s.Length = $s.Length + 1
    }
  }

  [pscustomobject]@{
    DuplicatesDeleted = $dupDeleted
    BytesDeleted      = $dupBytes
    SurvivorsBySize   = $survivorsBySize
    Errors            = $errors
  }
}

Export-ModuleMember -Function Remove-DuplicatesByHash
