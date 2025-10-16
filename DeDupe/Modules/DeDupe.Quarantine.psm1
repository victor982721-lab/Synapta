# DeDupe.Quarantine
# - Entrada: SurvivorsBySize (size -> group{Files[List[FileInfo]], Length}) tras dedupe por hash
# - Mantiene 1 por tamaño; el resto se mueve a cuarentena (Flat o BySize)
# - Devuelve métricas y raíz efectiva

using namespace System.IO
using namespace System.Collections.Generic
Set-StrictMode -Version Latest

function New-Directory {
  param([string]$Dir)
  if (-not [string]::IsNullOrWhiteSpace($Dir) -and -not (Test-Path -LiteralPath $Dir)) {
    [void][System.IO.Directory]::CreateDirectory($Dir)
  }
}

function Select-KeepFile {
  param([System.IO.FileInfo[]]$List,[ValidateSet('Oldest','Newest','ShortestPath')][string]$Strategy='Oldest')
  switch ($Strategy) {
    'Oldest'       { return ($List | Sort-Object -Property LastWriteTimeUtc, FullName | Select-Object -First 1) }
    'Newest'       { return ($List | Sort-Object -Property @{Expression='LastWriteTimeUtc';Descending=$true}, @{Expression='FullName'} | Select-Object -First 1) }
    'ShortestPath' { return ($List | Sort-Object -Property @{Expression={ $_.FullName.Length }}, @{Expression='FullName'} | Select-Object -First 1) }
    default        { return ($List | Sort-Object -Property LastWriteTimeUtc, FullName | Select-Object -First 1) }
  }
}

function Move-ToQuarantine {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
  param(
    [Parameter(Mandatory)][hashtable]$SurvivorsBySize,
    [ValidateSet('Oldest','Newest','ShortestPath')][string]$Keep='Oldest',
    [Parameter(Mandatory)][string]$QuarantinePath,
    [ValidateSet('Flat','BySize')][string]$Layout='Flat',
    [switch]$Run,
    [string]$Policy='pdp:test',
    $Logger
  )
  $quar = 0
  $qBytes = 0L
  $errors = 0

  New-Directory $QuarantinePath
  $rootEff = (Resolve-Path -LiteralPath $QuarantinePath -ErrorAction SilentlyContinue)?.Path
  if (-not $rootEff) { $rootEff = $QuarantinePath }

  foreach ($sizeKey in $SurvivorsBySize.Keys) {
    $g = $SurvivorsBySize[$sizeKey]
    $arr = $g.Files.ToArray()
    if ($arr.Length -le 1) { continue }
    $keeper = Select-KeepFile -List $arr -Strategy $Keep
    foreach ($f in $arr) {
      if ($f.FullName -eq $keeper.FullName) { continue }
      $destDir = if ($Layout -eq 'BySize') { Join-Path $rootEff ([string][int64]$sizeKey) } else { $rootEff }
      New-Directory $destDir
      $name = [System.IO.Path]::GetFileName($f.FullName)
      $dest = Join-Path $destDir $name
      $i = 1
      while (Test-Path -LiteralPath $dest) {
        $dest = Join-Path $destDir ("{0}.{1}{2}" -f ([System.IO.Path]::GetFileNameWithoutExtension($name)), $i, [System.IO.Path]::GetExtension($name))
        $i++
      }

      if ($Logger) {
        DeDupe.Logging\Write-Jsonl -Logger $Logger -Data @{
          ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$Policy; action='quarantine_same_size_diff_hash';
          size_bytes=[int64]$sizeKey; keep=$keeper.FullName; target=$f.FullName; dest=$dest;
          mode= ($(if($Run){'move'}else{'simulate'})); layout=$Layout
        }
      }

      if ($Run) {
        if ($PSCmdlet.ShouldProcess($f.FullName,'Move to quarantine')) {
          try { Move-Item -LiteralPath $f.FullName -Destination $dest -Force; $quar++; $qBytes+=[int64]$sizeKey }
          catch { $errors++; if($Logger){ DeDuPe.Logging\Write-Jsonl -Logger $Logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$Policy; action='move_error'; target=$f.FullName; error=$_.Exception.Message } } }
        }
      } else {
        $quar++; $qBytes+=[int64]$sizeKey
      }
    }
  }

  [pscustomobject]@{
    Quarantined       = $quar
    BytesQuarantined  = $qBytes
    Errors            = $errors
    Layout            = $Layout
    QuarantineRoot    = $rootEff
  }
}

Export-ModuleMember -Function Move-ToQuarantine
