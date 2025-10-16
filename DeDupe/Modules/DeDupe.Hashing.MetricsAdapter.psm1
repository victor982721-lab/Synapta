<#
  DeDupe.Hashing.MetricsAdapter — hashing con progreso y paralelismo estable (PS 7+)
  - Secuencial por bloque (Get-FileHashStreamingWithMetrics)
  - Paralelo con ThreadJobs y ventana de DOP (Get-HashRecordsParallelWithMetrics)
    · Progreso: suma por archivo al completar (robusto; evita dependencias de módulo en runspaces)
#>

Set-StrictMode -Version Latest

function Get-FileHashStreamingWithMetrics {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory,ValueFromPipeline)][ValidateNotNull()]$InputObject,
    [switch]$AllowZeroByte,
    [int]$BlockSizeKB = 1024
  )
  process {
    $fi = if ($InputObject -is [System.IO.FileInfo]) { $InputObject } else { [System.IO.FileInfo]::new([string]$InputObject) }
    if (-not $fi -or -not $fi.Exists) { return }
    if (-not $AllowZeroByte -and $fi.Length -eq 0) { return }
    $fs = $null; $buf = $null
    try {
      $fs = [System.IO.FileStream]::new($fi.FullName,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,1048576,[System.IO.FileOptions]::SequentialScan)
      $hasher = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
      $block  = [Math]::Max(4096,$BlockSizeKB*1024)
      $buf    = [System.Buffers.ArrayPool[byte]]::Shared.Rent($block)
      while ($true) {
        $read = $fs.Read($buf,0,$block)
        if ($read -le 0) { break }
        $hasher.AppendData($buf,0,$read)
        if (Get-Command -Name Update-HiResMetrics -ErrorAction SilentlyContinue) { Update-HiResMetrics -Bytes $read -Items 0 }
      }
      $hashBytes = $hasher.GetHashAndReset()
      $sb=[System.Text.StringBuilder]::new($hashBytes.Length*2); foreach($b in $hashBytes){[void]$sb.AppendFormat('{0:x2}',$b)}
      [pscustomobject]@{ Kind='Record'; Size=[int64]$fi.Length; Hash=$sb.ToString(); File=$fi }
    } finally { if($buf){[System.Buffers.ArrayPool[byte]]::Shared.Return($buf,$false)}; if($fs){$fs.Dispose()} }
  }
}

function Get-HashRecordsParallelWithMetrics {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Collections.IEnumerable]$Files,
    [switch]$AllowZeroByte,
    [int]$DegreeOfParallelism = 0,
    [int]$BlockSizeKB = 1024
  )
  # Normaliza entrada
  $inputs = New-Object System.Collections.Generic.List[object]
  foreach ($it in $Files) { if ($it -is [System.IO.FileInfo]) { $inputs.Add($it) } else { $p=[string]$it; if([string]::IsNullOrWhiteSpace($p)){continue}; $inputs.Add([System.IO.FileInfo]::new($p)) } }
  if ($inputs.Count -eq 0) { return @() }
  # DOP
  if ($DegreeOfParallelism -le 0) { try { $DegreeOfParallelism = DeDuPe.Metrics.Ultra\Get-RecommendedDOP -Path $inputs[0].DirectoryName } catch { $DegreeOfParallelism = [Environment]::ProcessorCount } }
  $DegreeOfParallelism = [Math]::Max(1,[Math]::Min(32,[int]$DegreeOfParallelism))

  $results = New-Object System.Collections.Generic.List[object]
  $jobs = @()
  foreach ($fi in $inputs) {
    if ($null -eq $fi -or -not $fi.Exists) { continue }
    if (-not $AllowZeroByte -and $fi.Length -eq 0) { continue }
    $jobs += Start-ThreadJob -ScriptBlock {
      param($path,$size,$blockKB)
      try {
        $fs = [System.IO.FileStream]::new($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,1048576,[System.IO.FileOptions]::SequentialScan)
        try {
          $hasher = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
          $block  = [Math]::Max(4096,$blockKB*1024)
          $buf    = [System.Buffers.ArrayPool[byte]]::Shared.Rent($block)
          try { while ($true) { $read = $fs.Read($buf,0,$block); if ($read -le 0) { break }; $hasher.AppendData($buf,0,$read) } $hashBytes=$hasher.GetHashAndReset(); $sb=[System.Text.StringBuilder]::new($hashBytes.Length*2); foreach($b in $hashBytes){[void]$sb.AppendFormat('{0:x2}',$b)}; return [pscustomobject]@{ Kind='Record'; Size=[int64]$size; Hash=$sb.ToString(); Path=$path } } finally { [System.Buffers.ArrayPool[byte]]::Shared.Return($buf,$false) }
        } finally { if($fs){$fs.Dispose()} }
      } catch { return [pscustomobject]@{ Kind='Error'; Path=$path; Message=$_.Exception.Message } }
    } -ArgumentList $fi.FullName,[int64]$fi.Length,$BlockSizeKB
    if ($jobs.Count -ge $DegreeOfParallelism) {
      $j = Wait-Job -Job $jobs -Any; $obj = Receive-Job $j; Remove-Job $j | Out-Null; $jobs = $jobs | Where-Object { $_.Id -ne $j.Id }
      if ($obj) { if ($obj.Kind -eq 'Record') { try { Update-HiResMetrics -Bytes ([int64]$obj.Size) -Items 1 } catch {} }; $results.Add($obj) | Out-Null }
    }
  }
  if ($jobs.Count -gt 0) {
    Wait-Job -Job $jobs | Out-Null
    foreach ($j in $jobs) { $obj = Receive-Job $j; Remove-Job $j | Out-Null; if ($obj) { if ($obj.Kind -eq 'Record') { try { Update-HiResMetrics -Bytes ([int64]$obj.Size) -Items 1 } catch {} }; $results.Add($obj) | Out-Null } }
  }
  # Normaliza a FileInfo
  for ($i=0; $i -lt $results.Count; $i++) { $r = $results[$i]; if ($r.Kind -eq 'Record' -and -not $r.PSObject.Properties['File']) { $results[$i] = [pscustomobject]@{ Kind='Record'; Size=$r.Size; Hash=$r.Hash; File=([System.IO.FileInfo]::new($r.Path)) } }
  return $results
}

Export-ModuleMember -Function Get-FileHashStreamingWithMetrics, Get-HashRecordsParallelWithMetrics
