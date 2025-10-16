#!/usr/bin/env pwsh
# DeDupe.Pipeline — Pipeline: Enumeración → Hashing → Dedupe → Cuarentena → Resumen
using namespace System.IO
using namespace System.Collections.Generic
Set-StrictMode -Version Latest

function Resolve-LogPathSafe {
  [CmdletBinding()] param([Parameter(Mandatory)][string]$Requested)
  try {
    $dir = Split-Path -Parent $Requested
    if ([string]::IsNullOrWhiteSpace($dir)) { $dir = '.' }
    if (-not (Test-Path -LiteralPath $dir)) { [void][Directory]::CreateDirectory($dir) }
    return $Requested
  } catch {
    $fallback = Join-Path $env:LOCALAPPDATA 'DeDupe/logs/actions.jsonl'
    $fbDir = Split-Path -Parent $fallback
    if (-not (Test-Path -LiteralPath $fbDir)) { [void][Directory]::CreateDirectory($fbDir) }
    return $fallback
  }
}

function Get-DeDupeFiles {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$Recurse = $true,
    [switch]$IncludeHidden,
    [switch]$AllowZeroByte
  )
  if (-not (Test-Path -LiteralPath $Path)) { throw "Ruta no encontrada: $Path" }
  $opt = [System.IO.EnumerationOptions]::new(); $opt.RecurseSubdirectories=[bool]$Recurse; $opt.AttributesToSkip=[System.IO.FileAttributes]::System
  $all = [System.Collections.Generic.List[System.IO.FileInfo]]::new(); $sizeCounts = [System.Collections.Generic.Dictionary[int64,int]]::new(); $totalBytes=0L
  foreach ($p in [System.IO.Directory]::EnumerateFiles($Path, '*', $opt)) {
    try { $fi=[System.IO.FileInfo]::new($p); if (-not $IncludeHidden -and ($fi.Attributes.HasFlag([System.IO.FileAttributes]::Hidden))) { continue }; if (-not $AllowZeroByte -and $fi.Length -eq 0) { continue }; $all.Add($fi); $totalBytes+=[int64]$fi.Length; $len=[int64]$fi.Length; if ($sizeCounts.ContainsKey($len)) { $sizeCounts[$len] = $sizeCounts[$len]+1 } else { $sizeCounts[$len]=1 } } catch {}
  }
  $collision=[System.Collections.Generic.HashSet[int64]]::new(); $groupsBySize=0
  foreach ($kv in $sizeCounts.GetEnumerator()) { if ($kv.Value -gt 1) { if ($collision.Add($kv.Key)) { $groupsBySize++ } } }
  $candidates=[System.Collections.Generic.List[System.IO.FileInfo]]::new(); $candBytes=0L; foreach($f in $all){ if($collision.Contains([int64]$f.Length)){ $candidates.Add($f); $candBytes+=[int64]$f.Length } }
  [pscustomobject]@{ Files=$all; TotalCount=$all.Count; TotalBytes=$totalBytes; CandidateFiles=$candidates; CandidateCount=$candidates.Count; CandidateBytes=$candBytes; GroupsBySize=$groupsBySize }
}

function Format-ProgressLine { [CmdletBinding()] param([Parameter(Mandatory)][pscustomobject]$S,[int]$TotalCount)
  $eta = if ($S.ETA -ne $null) { "{0}s" -f $S.ETA } else { '—' }
  "{0} MB/s | {1}/{2} archivos | {3}/{4} MB | ETA {5}" -f $S.MBps,$S.ItemsDone,$TotalCount,[int]([double]$S.BytesDone/1MB),[int]([double]$S.TotalBytes/1MB),$eta
}

function Invoke-DeDupePipeline {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [switch]$Recurse = $true,
    [switch]$IncludeHidden,
    [switch]$AllowZeroByte,
    [ValidateSet('Oldest','Newest','ShortestPath')][string]$Keep='Oldest',
    [string]$QuarantinePath = (Join-Path $PSScriptRoot 'quarantine'),
    [string]$LogPath        = (Join-Path $PSScriptRoot 'logs/actions.jsonl'),
    [ValidateSet('Flat','BySize')][string]$QuarantineLayout='Flat',
    [int]$DegreeOfParallelism = 0,
    [int]$BlockSizeKB = 1024,
    [int]$ReportIntervalMs = 750,
    [switch]$Verify,
    [switch]$Run,
    [scriptblock]$OnTick
  )
  $policyTag = if ($Run) { 'pdp:run' } else { 'pdp:test' }
  $logEffective = Resolve-LogPathSafe -Requested $LogPath
  $logger = DeDuPe.Logging\New-JsonlLogger -Path $logEffective -RotateAtMB 768
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='start'; root=$Path }
  $enum = Get-DeDupeFiles -Path $Path -Recurse:$Recurse -IncludeHidden:$IncludeHidden -AllowZeroByte:$AllowZeroByte
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='enumeration'; total_files=$enum.TotalCount; total_bytes=$enum.TotalBytes; groups_by_size=$enum.GroupsBySize; candidates=$enum.CandidateCount; candidate_bytes=$enum.CandidateBytes }
  if ($DegreeOfParallelism -le 0) { $DegreeOfParallelism = DeDuPe.Metrics.Ultra\Get-RecommendedDOP -Path $Path }
  DeDuPe.Metrics.Ultra\Optimize-ThreadPool -Workers $DegreeOfParallelism -IOCP ($DegreeOfParallelism*2) | Out-Null
  DeDuPe.Metrics.Ultra\Initialize-HiResMetrics -TotalBytes $enum.CandidateBytes -TotalItems $enum.CandidateCount -WindowSeconds 2
  $tick = if ($PSBoundParameters.ContainsKey('OnTick') -and $OnTick) { $OnTick } else { { param($s) $pct = if ($s -and $s.Percent) { [int][math]::Floor($s.Percent) } else { 0 }; $status = if ($s) { Format-ProgressLine -S $s -TotalCount $enum.CandidateCount } else { '—' }; Write-Progress -Id 1 -Activity 'Hashing' -PercentComplete $pct -Status $status } }
  DeDuPe.Metrics.Ultra\Start-ProgressTicker -IntervalMs $ReportIntervalMs -OnTick $tick
  $records = @(); if ($enum.CandidateCount -gt 0) { $records = Invoke-HashRecordsParallel -Files $enum.CandidateFiles -AllowZeroByte:$AllowZeroByte -DegreeOfParallelism $DegreeOfParallelism -BlockSizeKB $BlockSizeKB }
  DeDuPe.Metrics.Ultra\Stop-ProgressTicker; Write-Progress -Id 1 -Activity 'Hashing' -Completed
  $grouped = Group-BySizeHash -HashRecords $records
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='grouping'; groups_by_hash=$grouped.GroupsByHash; unique_sizes=$grouped.UniqueSizes; records=$grouped.TotalRecords }
  $dedupe = Remove-DuplicatesByHash -Map $grouped.Map -Keep $Keep -Verify:$Verify -Run:$Run -Policy $policyTag -Logger $logger
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='dedupe_result'; duplicates_deleted=$dedupe.DuplicatesDeleted; bytes_deleted=$dedupe.BytesDeleted; errors=$dedupe.Errors }
  $quar = Move-ToQuarantine -SurvivorsBySize $dedupe.SurvivorsBySize -Keep $Keep -QuarantinePath $QuarantinePath -Layout $QuarantineLayout -Run:$Run -Policy $policyTag -Logger $logger
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='quarantine_result'; quarantined=$quar.Quarantined; bytes_quarantined=$quar.BytesQuarantined; errors=$quar.Errors; layout=$quar.Layout; root=$quar.QuarantineRoot }
  $summary = [ordered]@{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; path=(Resolve-Path -LiteralPath $Path).Path; groups_by_size=$enum.GroupsBySize; groups_by_hash=$grouped.GroupsByHash; duplicates_deleted=$dedupe.DuplicatesDeleted; bytes_deleted=$dedupe.BytesDeleted; quarantined=$quar.Quarantined; bytes_quarantined=$quar.BytesQuarantined; keep_strategy=$Keep; recurse=[bool]$Recurse; include_hidden=[bool]$IncludeHidden; quarantine_path=(Resolve-Path -LiteralPath $QuarantinePath -ErrorAction SilentlyContinue)?.Path; log_path_effective=$logEffective; dop_hash=$DegreeOfParallelism; verify=[bool]$Verify; candidate_count=$enum.CandidateCount; candidate_bytes=$enum.CandidateBytes; total_files=$enum.TotalCount; total_bytes=$enum.TotalBytes }
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data $summary
  DeDuPe.Logging\Write-Jsonl -Logger $logger -Data @{ ts_utc=(Get-Date).ToUniversalTime().ToString('o'); policy=$policyTag; action='end' }
  Close-JsonlLogger -Logger $logger
  [pscustomobject]$summary
}

function Invoke-HashRecordsParallel {
  [CmdletBinding()] param([Parameter(Mandatory)][System.Collections.IEnumerable]$Files,[switch]$AllowZeroByte,[int]$DegreeOfParallelism=0,[int]$BlockSizeKB=1024)
  $inputs = New-Object System.Collections.Generic.List[object]; foreach($it in $Files){ if($it -is [System.IO.FileInfo]){ $inputs.Add($it) } else { $p=[string]$it; if([string]::IsNullOrWhiteSpace($p)){continue}; $inputs.Add([System.IO.FileInfo]::new($p)) } }
  if ($inputs.Count -eq 0) { return @() }
  if ($DegreeOfParallelism -le 0) { try { $DegreeOfParallelism = DeDuPe.Metrics.Ultra\Get-RecommendedDOP -Path $inputs[0].DirectoryName } catch { $DegreeOfParallelism = [Environment]::ProcessorCount } }
  $DegreeOfParallelism=[Math]::Max(1,[Math]::Min(32,[int]$DegreeOfParallelism))
  $results = New-Object System.Collections.Generic.List[object]; $jobs=@()
  foreach($fi in $inputs){ if($null -eq $fi -or -not $fi.Exists){continue}; if(-not $AllowZeroByte -and $fi.Length -eq 0){continue}; $jobs += Start-ThreadJob -ScriptBlock {
      param($path,$size,$blockKB)
      try{ $fs=[System.IO.FileStream]::new($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,1048576,[System.IO.FileOptions]::SequentialScan); try{ $hasher=[System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256); $block=[Math]::Max(4096,$blockKB*1024); $buf=[System.Buffers.ArrayPool[byte]]::Shared.Rent($block); try{ while($true){ $r=$fs.Read($buf,0,$block); if($r -le 0){break}; $hasher.AppendData($buf,0,$r) } $hash=$hasher.GetHashAndReset(); $sb=[System.Text.StringBuilder]::new($hash.Length*2); foreach($b in $hash){[void]$sb.AppendFormat('{0:x2}',$b)}; return [pscustomobject]@{ Kind='Record'; Size=[int64]$size; Hash=$sb.ToString(); Path=$path } } finally { [System.Buffers.ArrayPool[byte]]::Shared.Return($buf,$false) } } finally { if($fs){$fs.Dispose()} } } catch { return [pscustomobject]@{ Kind='Error'; Path=$path; Message=$_.Exception.Message } } } -ArgumentList $fi.FullName,[int64]$fi.Length,$BlockSizeKB; if($jobs.Count -ge $DegreeOfParallelism){ $j=Wait-Job -Job $jobs -Any; $obj=Receive-Job $j; Remove-Job $j | Out-Null; $jobs=$jobs | Where-Object { $_.Id -ne $j.Id }; if($obj){ if($obj.Kind -eq 'Record'){ try{ DeDuPe.Metrics.Ultra\Update-HiResMetrics -Bytes ([int64]$obj.Size) -Items 1 } catch{} }; $results.Add($obj) | Out-Null } }
  }
  if($jobs.Count -gt 0){ Wait-Job -Job $jobs | Out-Null; foreach($j in $jobs){ $obj=Receive-Job $j; Remove-Job $j | Out-Null; if($obj){ if($obj.Kind -eq 'Record'){ try{ DeDuPe.Metrics.Ultra\Update-HiResMetrics -Bytes ([int64]$obj.Size) -Items 1 } catch{} }; $results.Add($obj) | Out-Null } } }
  for($i=0;$i -lt $results.Count;$i++){ $r=$results[$i]; if($r.Kind -eq 'Record' -and -not $r.PSObject.Properties['File']){ $results[$i]=[pscustomobject]@{ Kind='Record'; Size=$r.Size; Hash=$r.Hash; File=([System.IO.FileInfo]::new($r.Path)) } } }
  return $results
}

Export-ModuleMember -Function Resolve-LogPathSafe, Get-DeDupeFiles, Format-ProgressLine, Invoke-DeDupePipeline

