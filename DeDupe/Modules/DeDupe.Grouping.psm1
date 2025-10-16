# DeDupe.Grouping
# Entradas esperadas: objetos con { Kind='Record'; Size=<int64>; Hash=<string>; File=<FileInfo> }
# Salida: Map size -> (dict hash -> group{Files[List[FileInfo]], Length}),
#         GroupsByHash, UniqueSizes, TotalRecords

using namespace System.Collections.Generic
using namespace System.IO
Set-StrictMode -Version Latest

function New-FileGroup {
  $g = [pscustomobject]@{
    Files  = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    Length = 0
  }
  $g
}

function Group-BySizeHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Collections.IEnumerable]$HashRecords
  )
  $map = [System.Collections.Generic.Dictionary[int64, System.Collections.Generic.Dictionary[string, object]]]::new()
  $groupsByHash = 0
  $total = 0
  foreach ($rec in $HashRecords) {
    if ($null -eq $rec -or $rec.Kind -ne 'Record') { continue }
    $size = [int64]$rec.Size
    $hash = [string]$rec.Hash
    $fi   = if ($rec.File -is [System.IO.FileInfo]) { $rec.File } else { [System.IO.FileInfo]::new([string]$rec.File) }
    if (-not $map.ContainsKey($size)) {
      $map[$size] = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    $hmap = $map[$size]
    if (-not $hmap.ContainsKey($hash)) {
      $hmap[$hash] = New-FileGroup
    }
    $g = $hmap[$hash]
    $g.Files.Add($fi)
    $g.Length = $g.Length + 1
    $total++
  }

  foreach ($sizeKey in $map.Keys) {
    foreach ($hashKey in $map[$sizeKey].Keys) {
      $g = $map[$sizeKey][$hashKey]
      if ($g.Length -gt 1) { $groupsByHash++ }
    }
  }

  [pscustomobject]@{
    Map          = $map
    GroupsByHash = $groupsByHash
    UniqueSizes  = $map.Count
    TotalRecords = $total
  }
}

Export-ModuleMember -Function Group-BySizeHash
