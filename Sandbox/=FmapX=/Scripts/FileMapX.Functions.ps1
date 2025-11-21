function Format-Size {
  param([long]$Bytes)
  switch ($Bytes) {
    { $_ -lt 1KB } { return "{0} B" -f $Bytes }
    { $_ -lt 1MB } { return "{0:N2} KB" -f ($Bytes / 1KB) }
    { $_ -lt 1GB } { return "{0:N2} MB" -f ($Bytes / 1MB) }
    default        { return "{0:N2} GB" -f ($Bytes / 1GB) }
  }
}

# ==========================================================================================================================================

function Has-NonAscii {
  param([string]$s)
  if ([string]::IsNullOrEmpty($s)) { return $false }
  -not ([regex]::IsMatch($s, '^[\u0020-\u007E]+$'))
}

# ==========================================================================================================================================

function Is-ReparsePoint {
  param([System.IO.FileSystemInfo]$Info)
  $Info.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)
}

# ==========================================================================================================================================

function Is-Visible {
  param(
    [System.IO.FileSystemInfo]$Info,
    [bool]$IncludeHidden
  )
  if ($IncludeHidden) { return $true }
  -not (
    $Info.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) -or
    $Info.Attributes.HasFlag([System.IO.FileAttributes]::System)
  )
}

# ==========================================================================================================================================

function Match-Patterns {
  param([string]$Name)
  if ($script:ExcludePatterns) {
    foreach ($pattern in $script:ExcludePatterns) {
      if ($pattern.IsMatch($Name)) { return $false }
    }
  }
  if ($script:IncludePatterns) {
    foreach ($pattern in $script:IncludePatterns) {
      if ($pattern.IsMatch($Name)) { return $true }
    }
    return $false
  }
  return $true
}

function Is-DirectoryExcluded {
  param([object]$Directory)
  if (-not $Directory) { return $false }
  $dirPath = if ($Directory -is [System.IO.DirectoryInfo]) { $Directory.FullName }
  elseif ($Directory.PSObject.Properties['FullName']) { [string]$Directory.FullName }
  else { [string]$Directory }
  if ([string]::IsNullOrWhiteSpace($dirPath)) { return $false }
  $fullPath = [System.IO.Path]::GetFullPath($dirPath)
  if ($script:OutputDirExclusionActive) {
    if ($fullPath.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and -not $fullPath.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      return $true
    }
  }
  if ($script:ExcludedPaths -and $script:ExcludedPaths.Contains($fullPath)) { return $true }
  return $false
}

# ==========================================================================================================================================

function Write-ErrorJson {
  param(
    [string]$Op,
    [string]$Path,
    [Exception]$Exception,
    [string]$Context = '',
    [bool]$IsParallel = $false,
    [string]$Message,
    [int]$HResult
  )
  if (-not $script:ErrorLogWriter) { return }
  try {
    Bump-Error $Op
    $msg = if ($Exception) { $Exception.Message } elseif ($Message) { $Message } else { '' }
    $hr = if ($Exception) { '0x{0:X8}' -f $Exception.HResult } elseif ($PSBoundParameters.ContainsKey('HResult')) { '0x{0:X8}' -f $HResult } else { '' }
    $payload = [ordered]@{
      ts          = (Get-Date).ToUniversalTime().ToString('o')
      op          = $Op
      path        = $Path
      message     = $msg
      hresult     = $hr
      context     = $Context
      is_parallel = [bool]$IsParallel
    }
    $pairs = @()
    foreach ($key in $payload.Keys) {
      $escapedKey = $key -replace '"','\"'
      $pairs += "`"$escapedKey`":$(JsonPrimitive $payload[$key])"
    }
    $line = '{' + ($pairs -join ',') + '}'
    $script:ErrorLogWriter.WriteLine($line)
  }
  catch {
    Write-Verbose "Write-ErrorJson: $($_.Exception.Message)"
  }
}

# ==========================================================================================================================================

function Test-OutputDirHealth {
  param(
    [string]$Dir,
    [int]$MinFreeMB = 200
  )
  try {
    $full = [System.IO.Path]::GetFullPath($Dir)
    if (-not (Test-Path -LiteralPath $full)) {
      [void][System.IO.Directory]::CreateDirectory($full)
    }
    $root = [System.IO.Path]::GetPathRoot($full)
    if ([string]::IsNullOrWhiteSpace($root)) {
      $root = $full
    }
    $drive = [System.IO.DriveInfo]::new($root)
    $freeMB = [math]::Floor($drive.AvailableFreeSpace / 1MB)
    if ($freeMB -lt $MinFreeMB) {
      Write-Warning ("Espacio libre bajo en '{0}': {1} MB" -f $root, $freeMB)
    }
    $tmpName = '.ar-filemap.tmp.{0}' -f ([guid]::NewGuid().ToString('N'))
    $tmpPath = [System.IO.Path]::Combine($full, $tmpName)
    $renamed = $tmpPath + '.ren'
    try {
      $fs = [System.IO.FileStream]::new($tmpPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
      $fs.Dispose()
      [System.IO.File]::Move($tmpPath, $renamed)
    }
    finally {
      if (Test-Path -LiteralPath $tmpPath) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
      if (Test-Path -LiteralPath $renamed) { Remove-Item -LiteralPath $renamed -Force -ErrorAction SilentlyContinue }
    }
  }
  catch {
    Bump-Error 'OutputDirHealth'
    throw "OutputDir no usable: $Dir — $($_.Exception.Message)"
  }
}

# ==========================================================================================================================================

function Update-CategoryTotals {
  param(
    [string]$Category,
    [long]$Bytes
  )
  $key = if ([string]::IsNullOrWhiteSpace($Category)) { 'uncategorized' } else { $Category }
  if (-not $script:CategoryTotals.ContainsKey($key)) {
    $script:CategoryTotals[$key] = @{ files = 0L; bytes = 0L }
  }
  $entry = $script:CategoryTotals[$key]
  $entry.files = [long]$entry.files + 1
  $entry.bytes = [long]$entry.bytes + [long]$Bytes
}

# ==========================================================================================================================================

function Add-ToDupGroups {
  param([hashtable]$Rec)
  if (-not $Rec) { return }
  $hashValue = if ($Rec.ContainsKey('finger_md5_16')) { $Rec.finger_md5_16 }
               elseif ($Rec.ContainsKey('hash_md5')) { $Rec.hash_md5 }
               else { $null }
  if (-not $hashValue) { return }
  if ([string]::IsNullOrWhiteSpace($hashValue)) { return }
  if (-not $Rec.ContainsKey('size_bytes')) { return }
  $size = [int64]$Rec.size_bytes
  $key = "{0}-{1}" -f $size, $hashValue
  if (-not $script:DupGroups.ContainsKey($key)) {
    $script:DupGroups[$key] = [System.Collections.Generic.List[hashtable]]::new()
  }
  $script:DupGroups[$key].Add($Rec) | Out-Null
}

# ==========================================================================================================================================

function Get-RecordFromResult {
  param([object]$Result)
  if (-not $Result) { return $null }
  if ($Result -is [hashtable]) {
    if ($Result.ContainsKey('Record')) { return $Result['Record'] }
    return $null
  }
  if ($Result -is [string]) { return $null }
  if ($Result -is [System.Collections.IEnumerable]) {
    foreach ($item in $Result) {
      $resolved = Get-RecordFromResult -Result $item
      if ($resolved) { return $resolved }
    }
    return $null
  }
  if ($Result.PSObject -and $Result.PSObject.Properties.Match('Record').Count -gt 0) {
    return $Result.Record
  }
  return $null
}

# ==========================================================================================================================================

function Compute-DupReclaimable {
  $total = 0L
  $groups = 0
  foreach ($entry in $script:DupGroups.GetEnumerator()) {
    $list = $entry.Value
    if ($list.Count -le 1) { continue }
    $groups++
    $size = [int64]$list[0].size_bytes
    $total += ($size * ([int64]$list.Count - 1))
  }
  $script:DupGroupsReclaimable = $total
  [pscustomobject]@{ dup_groups = $groups; reclaimable_bytes = $total }
}

# ==========================================================================================================================================

function Measure-HashWait {
  param([scriptblock]$Body)
  if (-not $Body) { return }
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try { & $Body }
  finally {
    $sw.Stop()
    $script:HashWaitTicks += $sw.Elapsed.Ticks
  }
}

# ==========================================================================================================================================

function Measure-ProbeWait {
  param([scriptblock]$Body)
  if (-not $Body) { return }
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try { & $Body }
  finally {
    $sw.Stop()
    $script:ProbeWaitTicks += $sw.Elapsed.Ticks
  }
}

# ==========================================================================================================================================

function Bump-Error {
  param([string]$Op)
  if ([string]::IsNullOrWhiteSpace($Op)) { return }
  if (-not $script:ErrorsByOp.ContainsKey($Op)) {
    $script:ErrorsByOp[$Op] = 0
  }
  $script:ErrorsByOp[$Op] = $script:ErrorsByOp[$Op] + 1
}

# ==========================================================================================================================================

function Get-DriveKind {
  param([string]$RootPath)
  try {
    $resolved = [System.IO.Path]::GetFullPath($RootPath)
    $root = [System.IO.Path]::GetPathRoot($resolved)
    $info = [System.IO.DriveInfo]::new($root)
    switch ($info.DriveType) {
      'Network'   { return 'network' }
      'Removable' { return 'removable' }
      'CDRom'     { return 'optical' }
      'Ram'       { return 'ram' }
      'NoRootDirectory' { return 'unknown' }
      default     { return 'fixed' }
    }
  }
  catch {
    Write-Verbose "Get-DriveKind: $($_.Exception.Message)"
    Bump-Error 'DriveKind'
    Write-ErrorJson -Op 'DriveKind' -Path $RootPath -Exception $_.Exception -Context 'Get-DriveKind'
    return 'unknown'
  }
}

# ==========================================================================================================================================

function Get-FileIdentity {
  param([string]$Path)
  if (-not $script:IsWindowsPlatform) { return $null }
  if (-not ('Native.FileId' -as [type])) { return $null }
  try {
    $isDirectory = $false
    try { $isDirectory = Test-Path -LiteralPath $Path -PathType Container }
    catch {}
    $flags = if ($isDirectory) { [Native.FileId]::FILE_FLAG_BACKUP_SEMANTICS } else { 0 }
    $handle = [Native.FileId]::CreateFile(
      $Path,
      [Native.FileId]::FILE_READ_ATTRIBUTES,
      [Native.FileId]::FILE_SHARE_READ -bor [Native.FileId]::FILE_SHARE_WRITE -bor [Native.FileId]::FILE_SHARE_DELETE,
      [IntPtr]::Zero,
      [Native.FileId]::OPEN_EXISTING,
      $flags,
      [IntPtr]::Zero
    )
    if ($handle.IsInvalid) { return $null }
    try {
      $info = New-Object Native.FileId+BY_HANDLE_FILE_INFORMATION
      if ([Native.FileId]::GetFileInformationByHandle($handle, [ref]$info)) {
        $size = ([int64]$info.nFileSizeHigh -shl 32) -bor [uint32]$info.nFileSizeLow
        $key = "{0:X8}-{1:X8}:{2:X8}-{3:X8}" -f $info.dwVolumeSerialNumber, $info.nNumberOfLinks, $info.nFileIndexHigh, $info.nFileIndexLow
        return [pscustomobject]@{ Key = $key; Size = $size; Links = [int]$info.nNumberOfLinks }
      }
    }
    finally {
      $handle.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-FileIdentity: $($_.Exception.Message)"
    Write-ErrorJson -Op 'FileIdentity' -Path $Path -Exception $_.Exception -Context 'Get-FileIdentity'
  }
  return $null
}

# ==========================================================================================================================================

function Test-FileFilters {
  param([object]$File)
  if (-not $File) { return $false }
  $length = 0L
  $lastWriteUtc = $null
  if ($File -is [System.IO.FileInfo]) {
    $length = [int64]$File.Length
    $lastWriteUtc = $File.LastWriteTimeUtc
  }
  else {
    if ($File.PSObject.Properties['Length']) { $length = [int64]$File.Length }
    elseif ($File.PSObject.Properties['Size']) { $length = [int64]$File.Size }
    if ($File.PSObject.Properties['LastWriteTimeUtc']) { $lastWriteUtc = [datetime]$File.LastWriteTimeUtc }
  }
  if (-not $lastWriteUtc) { $lastWriteUtc = [datetime]::UtcNow }
  $minValue = $script:MinMBValue
  if ($null -ne $minValue -and $minValue -gt 0) {
    $minBytes = [int64]$minValue * 1MB
    if ($length -lt $minBytes) { return $false }
  }
  $maxValue = $script:MaxMBValue
  if ($null -ne $maxValue -and $maxValue -gt 0) {
    $maxBytes = [int64]$maxValue * 1MB
    if ($length -gt $maxBytes) { return $false }
  }
  $ageDays = [int]([math]::Max(($script:StartedUtc - $lastWriteUtc).TotalDays, 0))
  $minAge = $script:MinAgeDaysValue
  if ($null -ne $minAge -and $minAge -ge 0 -and $ageDays -lt $minAge) { return $false }
  $maxAge = $script:MaxAgeDaysValue
  if ($null -ne $maxAge -and $maxAge -ge 0 -and $ageDays -gt $maxAge) { return $false }
  return $true
}

# ==========================================================================================================================================

function Open-JsonWriter {
  param([string]$PathBase)
  if ($script:StdOutEnabled) { return }
  if ($script:swJson) {
    try {
      $script:swJson.Flush()
      $script:swJson.Dispose()
    }
    catch {
      Write-Verbose "Open-JsonWriter: cierre previo falló — $($_.Exception.Message)"
    }
  }
  $suffix = if ($script:JsonPartIndex -gt 0 -and $OutputMaxMB -gt 0) { '.part{0:00}' -f $script:JsonPartIndex } else { '' }
  $baseWithoutExt = $PathBase -replace '\.jsonl$',''
  if ($CompressOutput) {
    $targetPath = "{0}{1}.jsonl.gz" -f $baseWithoutExt, $suffix
  }
  else {
    $targetPath = if ($suffix) { "{0}{1}.jsonl" -f $baseWithoutExt, $suffix } else { $PathBase }
  }
  if ($script:ExcludedPaths) {
    $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($targetPath)) | Out-Null
  }
  $script:JsonOutputPaths.Add($targetPath) | Out-Null
  $fsJson = [System.IO.FileStream]::new(
    $targetPath,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::Read,
    1048576,
    [System.IO.FileOptions]::SequentialScan
  )
  $encoding = $script:Utf8NoBom
  if ($CompressOutput) {
    $compressionLevel = if ($PreferCompressionSpeed) { [System.IO.Compression.CompressionLevel]::Fastest } else { [System.IO.Compression.CompressionLevel]::Optimal }
    $gzip = [System.IO.Compression.GZipStream]::new($fsJson, $compressionLevel, $false)
    $script:swJson = [System.IO.StreamWriter]::new($gzip, $encoding, 1048576, $false)
  }
  else {
    $script:swJson = [System.IO.StreamWriter]::new($fsJson, $encoding, 1048576, $false)
  }
  $script:JsonBytesWritten = 0
  $script:CurrentJsonPath = $targetPath
}

# ==========================================================================================================================================

function Ensure-JsonRotation {
  param([int]$PendingBytes = 0)
  if ($OutputMaxMB -le 0) { return }
  if ($script:StdOutEnabled) { return }
  if (-not $script:swJson) { return }
  $limit = [int64]$OutputMaxMB * 1MB
  if (($script:JsonBytesWritten + $PendingBytes) -ge $limit) {
    $script:JsonPartIndex++
    Open-JsonWriter -PathBase $script:JsonBasePath
  }
}

function Normalize-Name {
  param([string]$Name)
  if ($NormalizeNames) { return $Name.Normalize([System.Text.NormalizationForm]::FormC) }
  return $Name
}

# ==============================================================================================================================
# Salida JSONL y escritura de árbol

function Write-JsonLine {
  param([object]$Object)
  if (-not $EmitJsonl) { return }
  if (-not $Object) { return }
  $objectMap = if ($Object -is [System.Collections.IDictionary]) { $Object }
  else {
    $ht = [ordered]@{}
    foreach ($prop in $Object.PSObject.Properties) { $ht[$prop.Name] = $prop.Value }
    $ht
  }
  $line = $null
  if ($StrictJson) {
    $payload = ConvertTo-JsonCompatible $objectMap
    $payloadType = if ($payload) { $payload.GetType() } else { [object] }
    $line = [System.Text.Json.JsonSerializer]::Serialize($payload, $payloadType)
  }
  else {
    $pairs = @()
    foreach ($key in $objectMap.Keys) {
      $escapedKey = $key -replace '"','\"'
      $pairs += "`"$escapedKey`":$(JsonPrimitive $objectMap[$key])"
    }
    $line = '{' + ($pairs -join ',') + '}'
  }
  if ($null -eq $line) { return }
  $encodedBytes = [System.Text.Encoding]::UTF8.GetByteCount($line)
  $newlineBytes = if ($script:StdOutEnabled -or -not $script:swJson) { 0 } else { [System.Text.Encoding]::UTF8.GetByteCount($script:swJson.NewLine) }
  $script:JsonLogicalBytes += ($encodedBytes + $newlineBytes)
  if ($script:StdOutEnabled) {
    Write-Output -NoEnumerate $line
    return
  }
  if (-not $script:swJson) { return }
  Ensure-JsonRotation -PendingBytes ($encodedBytes + $newlineBytes)
  $script:swJson.WriteLine($line)
  $script:JsonBytesWritten += ($encodedBytes + $newlineBytes)
}

$script:DirCount = 0L
$script:FileCount = 0L
$script:EntryCounter = 0L
$script:TotalBytes = 0L

$glyphs = @{ Pipe = '|   '; Space = '    '; Tee = '+-- '; Elbow = '\-- '; Root = '// ' }

function Write-DirectoryEntry {
  param(
    [System.IO.DirectoryInfo]$Directory,
    [int]$Depth,
    [bool[]]$AncestorHasMore,
    [hashtable]$Prefetched
  )

  if ($script:ReachedEntryLimit) { return }

  if ($script:Cancelled) { return }
  $childLists = if ($Prefetched) { $Prefetched } else { Get-ChildLists -Directory $Directory -IncludeHidden ([bool]$IncludeHidden) }
  $dirs = @($childLists.Dirs)
  $files = @($childLists.Files)

  $summaryBytes = 0L
  foreach ($f in $files) { $summaryBytes += $f.Length }

  $inclusionMap = @{}
  $eligibleList = New-Object System.Collections.Generic.List[object]
  if ($EmitJsonl) {
    foreach ($file in $files) {
      $include = Test-FileFilters -File $file
      if (-not $include) { $script:FilteredCount++ }
      $inclusionMap[$file.FullName] = $include
      if ($include) { $eligibleList.Add($file) }
    }
  }

  $parallelRecords = $null
  if ($EmitJsonl -and $Parallel -and $eligibleList.Count -gt 0) {
    $pathBatch = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in $eligibleList) {
      $candidatePath = $null
      if ($candidate -is [string]) { $candidatePath = [string]$candidate }
      elseif ($candidate.PSObject -and $candidate.PSObject.Properties.Match('FullName').Count -gt 0) {
        $candidatePath = [string]$candidate.FullName
      }
      if ([string]::IsNullOrWhiteSpace($candidatePath)) {
        Write-Verbose "Parallel: se omitió una entrada sin ruta durante la preparación"
        Write-ErrorJson -Op 'ParallelFilePath' -Path $Directory.FullName -Context 'PrepareParallelFiles' -Message 'Entrada sin FullName en lote paralelo' -IsParallel:$true
        continue
      }
      $pathBatch.Add($candidatePath) | Out-Null
    }
    if ($pathBatch.Count -gt 0) {
      $parallelRecords = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::OrdinalIgnoreCase)
      $pathArray = $pathBatch.ToArray()
      $hashSemaphoreLocal = $script:HashSemaphore
      $probeSemaphoreLocal = $script:ProbeSemaphore
      $timeoutLocal = $script:TimeoutSecPerProbeValue
      $duplicateMapLocal = $script:DuplicateGroupMap
      $results = $pathArray | ForEach-Object -Parallel {
        param($filePath)
        if ([string]::IsNullOrWhiteSpace($filePath)) { return $null }
        try {
          $fi = [System.IO.FileInfo]::new($filePath)
        }
        catch {
          Write-Verbose ("Parallel: error al abrir '{0}' — {1}" -f $filePath, $_.Exception.Message)
          return [pscustomobject]@{ Path = $filePath; Record = $null; ErrorMessage = $_.Exception.Message; ErrorHResult = $_.Exception.HResult }
        }
        if ($fi.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) { return $null }
        try {
          New-FileRecord -FileEntry $fi -FileInfoFallback $fi -Depth $using:Depth -StartedUtc $using:script:StartedUtc -RootPath $using:RootPath -PathSplitPattern $using:script:PathSplitPattern -Classify:$using:Classify -DetectExecutables:$using:DetectExecutables -ProbeText:$using:ProbeText -ProbeTextMaxMB $using:ProbeTextMaxMB -ComputeHashes:$using:ComputeHashes -MaxHashMB $using:MaxHashMB -ProbeDocs:$using:ProbeDocs -ProbeArchives:$using:ProbeArchives -ZipListEntries $using:ZipListEntries -LargeFileMB $using:LargeFileMB -TextExtensions $using:TextExts -BinaryExtensions $using:BinaryExts -HashSemaphore $using:hashSemaphoreLocal -ProbeSemaphore $using:probeSemaphoreLocal -EmitTimes:$using:EmitTimes -NormalizeNames:$using:NormalizeNames -FindDuplicates:$using:FindDuplicates -DuplicateGroupMap $using:duplicateMapLocal -TimeoutSecPerProbe $using:timeoutLocal
        }
        catch {
          Write-ErrorJson -Op 'ParallelFile' -Path $filePath -Exception $_.Exception -Context 'Parallel' -Message $_.Exception.Message -IsParallel:$true
          return [pscustomobject]@{ Path = $filePath; Record = $null; ErrorMessage = $_.Exception.Message; ErrorHResult = $_.Exception.HResult }
        }
      } -ThrottleLimit $DegreeOfParallelism
      foreach ($item in $results) {
        $rec = Get-RecordFromResult -Result $item
        if (-not $rec) { continue }
        $parallelRecords[$rec.full_path] = $rec
      }
    }
  }

  if ($EmitJsonl) {
    foreach ($file in $files) {
      if ($script:ReachedEntryLimit) { break }
      $script:EntryCounter++
      if (($MaxEntries -gt 0) -and ($script:EntryCounter -gt $MaxEntries)) {
        $script:ReachedEntryLimit = $true
        break
      }
      if ($script:EntryCounter -lt 0) { throw 'Overflow EntryCounter' }
      $include = if ($Parallel -and $parallelRecords -and $parallelRecords.ContainsKey($file.FullName)) { $true } else { [bool]$inclusionMap[$file.FullName] }
      if (-not $include) { continue }
      $record = $null
      if ($parallelRecords -and $parallelRecords.ContainsKey($file.FullName)) {
        $record = $parallelRecords[$file.FullName]
        if ($record -is [hashtable]) { $record['is_parallel'] = $true }
      }
      else {
        $record = New-FileRecord -FileEntry $file -FileInfoFallback $file -Depth $Depth -StartedUtc $script:StartedUtc -RootPath $RootPath -PathSplitPattern $script:PathSplitPattern -Classify:$Classify -DetectExecutables:$DetectExecutables -ProbeText:$ProbeText -ProbeTextMaxMB $ProbeTextMaxMB -ComputeHashes:$ComputeHashes -MaxHashMB $MaxHashMB -ProbeDocs:$ProbeDocs -ProbeArchives:$ProbeArchives -ZipListEntries $ZipListEntries -LargeFileMB $LargeFileMB -TextExtensions $TextExts -BinaryExtensions $BinaryExts -HashSemaphore $HashSemaphore -ProbeSemaphore $ProbeSemaphore -EmitTimes:$EmitTimes -NormalizeNames:$NormalizeNames -FindDuplicates:$FindDuplicates -DuplicateGroupMap $script:DuplicateGroupMap -TimeoutSecPerProbe $TimeoutSecPerProbeValue
      }
      if ($record) {
        Write-JsonLine -Object $record
        $script:FileCount++
        $script:TotalBytes += [int64]$file.Length
        if ($Classify -and $record.PSObject.Properties['category']) {
          Update-CategoryTotals -Category $record.category -Bytes $file.Length
        }
      }
    }
  }

  $childDirs = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
  foreach ($d in $dirs) {
    $dirInfo = if ($d -is [System.IO.DirectoryInfo]) { $d }
    elseif ($d.PSObject.Properties['FullName']) {
      try { [System.IO.DirectoryInfo]::new([string]$d.FullName) }
      catch { $null }
    }
    else { $null }
    if (-not $dirInfo) { continue }
    if (-not (Is-DirectoryExcluded -Directory $dirInfo)) { $childDirs.Add($dirInfo) | Out-Null }
  }
  $childDirsSorted = @($childDirs | Sort-Object -Property FullName)
  $childDirsCount = $childDirsSorted.Count
  $childFilesCount = $files.Count
  $hasMoreDir = $false
  $index = 0
  foreach ($dir in $childDirsSorted) {
    $index++
    $hasMoreDir = ($index -lt $childDirsCount)
    $spacer = foreach ($ancestorMore in $AncestorHasMore) { if ($ancestorMore) { $glyphs.Pipe } else { $glyphs.Space } }
    $glyph = if ($hasMoreDir -or $childFilesCount -gt 0) { $glyphs.Tee } else { $glyphs.Elbow }
    $line = '{0}{1}{2}' -f ($spacer -join ''), $glyph, (Normalize-Name $dir.Name)
    $script:swTree.WriteLine($line)
    $script:DirCount++
    $prefetch = Get-ChildLists -Directory $dir -IncludeHidden ([bool]$IncludeHidden)
    $nextAncestors = @($AncestorHasMore + @($hasMoreDir -or ($childFilesCount -gt 0)))
    Write-DirectoryEntry -Directory $dir -Depth ($Depth + 1) -AncestorHasMore $nextAncestors -Prefetched $prefetch
  }

  $fileIndex = 0
  foreach ($file in $files) {
    $fileIndex++
    $isLastFile = ($fileIndex -eq $childFilesCount)
    $spacer = foreach ($ancestorMore in $AncestorHasMore) { if ($ancestorMore) { $glyphs.Pipe } else { $glyphs.Space } }
    $glyph = if ($isLastFile) { $glyphs.Elbow } else { $glyphs.Tee }
    $line = '{0}{1}{2}' -f ($spacer -join ''), $glyph, (Normalize-Name $file.Name)
    $script:swTree.WriteLine($line)
  }
}

# ==========================================================================================================================================

function Optimize-ThreadPool {
  param(
    [int]$CpuDop,
    [int]$IoDop
  )
  try {
    $minWorkers = [Math]::Max([Environment]::ProcessorCount, [Math]::Max($CpuDop, 0) + [Math]::Max($IoDop, 0))
    $minIocp = [Math]::Max(4, [Environment]::ProcessorCount)
    [void][System.Threading.ThreadPool]::SetMinThreads($minWorkers, $minIocp)
  }
  catch {
    Write-Verbose "Optimize-ThreadPool: $($_.Exception.Message)"
  }
  try {
    [System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = 'BelowNormal'
  }
  catch {
    Write-Verbose "Optimize-ThreadPool priority: $($_.Exception.Message)"
  }
}

$cpuDopTarget = if ($ParallelHash) { $DopHash } else { 0 }
$ioDopTarget = if ($ParallelProbes) { $DopProbes } else { 0 }
Optimize-ThreadPool -CpuDop $cpuDopTarget -IoDop $ioDopTarget

# ==========================================================================================================================================

function New-FileRecord {
  param(
    [object]$FileEntry,
    [object]$FileInfoFallback,
    [int]$Depth,
    [datetime]$StartedUtc,
    [string]$RootPath,
    [string]$PathSplitPattern,
    [bool]$Classify,
    [bool]$DetectExecutables,
    [bool]$ProbeText,
    [int]$ProbeTextMaxMB,
    [bool]$ComputeHashes,
    [int]$MaxHashMB,
    [bool]$ProbeDocs,
    [bool]$ProbeArchives,
    [int]$ZipListEntries,
    [int]$LargeFileMB,
    [string[]]$TextExtensions,
    [string[]]$BinaryExtensions,
    [System.Threading.SemaphoreSlim]$HashSemaphore,
    [System.Threading.SemaphoreSlim]$ProbeSemaphore,
    [bool]$EmitTimes,
    [bool]$NormalizeNames,
    [bool]$FindDuplicates,
    [System.Collections.Concurrent.ConcurrentDictionary[string,int]]$DuplicateGroupMap,
    [int]$TimeoutSecPerProbe
  )

  if (-not $FileEntry) { return $null }

  $fullPath = if ($FileEntry -is [System.IO.FileInfo]) { $FileEntry.FullName }
  elseif ($FileEntry.PSObject.Properties['FullName']) { [string]$FileEntry.FullName }
  else { [string]$FileEntry }

  if ([string]::IsNullOrWhiteSpace($fullPath)) { return $null }

  $fileInfoLocal = if ($FileEntry -is [System.IO.FileInfo]) { $FileEntry }
  elseif ($FileInfoFallback -is [System.IO.FileInfo]) { $FileInfoFallback }
  elseif ($FileInfoFallback -and $FileInfoFallback.PSObject.Properties['FullName']) {
    try { [System.IO.FileInfo]::new([string]$FileInfoFallback.FullName) }
    catch { $null }
  }
  else { $null }

  $name = if ($FileEntry.PSObject.Properties['Name']) { [string]$FileEntry.Name }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    $fileInfoLocal.Name
  }

  $length = if ($FileEntry.PSObject.Properties['Length']) { [int64]$FileEntry.Length }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    [int64]$fileInfoLocal.Length
  }

  $lastWriteUtc = if ($FileEntry.PSObject.Properties['LastWriteTimeUtc']) {
    ([datetime]$FileEntry.LastWriteTimeUtc).ToUniversalTime()
  }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    $fileInfoLocal.LastWriteTimeUtc.ToUniversalTime()
  }

  $creationUtc = if ($FileEntry.PSObject.Properties['CreationTimeUtc']) {
    ([datetime]$FileEntry.CreationTimeUtc).ToUniversalTime()
  }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    $fileInfoLocal.CreationTimeUtc.ToUniversalTime()
  }

  $lastAccessUtc = if ($FileEntry.PSObject.Properties['LastAccessTimeUtc']) {
    ([datetime]$FileEntry.LastAccessTimeUtc).ToUniversalTime()
  }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    $fileInfoLocal.LastAccessTimeUtc.ToUniversalTime()
  }

  $attributesValue = if ($FileEntry.PSObject.Properties['Attributes']) {
    [System.IO.FileAttributes]$FileEntry.Attributes
  }
  else {
    if (-not $fileInfoLocal) { $fileInfoLocal = [System.IO.FileInfo]::new($fullPath) }
    $fileInfoLocal.Attributes
  }

  $extRaw = [System.IO.Path]::GetExtension($name)
  $ext = if ($extRaw) { $extRaw.TrimStart('.').ToLowerInvariant() } else { '' }

  $relPath = Get-RelativePath -Base $RootPath -Full $fullPath
  if ([string]::IsNullOrWhiteSpace($relPath)) { $relPath = '.' }

  $record = [ordered]@{
    relpath       = $relPath
    type          = 'file'
    name          = $name
    ext           = $ext
    size_bytes    = [int64]$length
    mtime_iso     = $lastWriteUtc.ToString('o')
    depth         = $Depth + 1
    attributes    = $attributesValue.ToString().Replace(', ', '|')
    top_segment   = if ($relPath -match $PathSplitPattern) { ($relPath -split $PathSplitPattern)[0] } else { $relPath }
    path_len      = $relPath.Length
    age_days      = [int](($StartedUtc - $lastWriteUtc).TotalDays)
    has_non_ascii = Has-NonAscii $name
    is_large      = ($length -ge ($LargeFileMB * 1MB))
  }

  if ($EmitTimes) {
    $record.ctime_iso = $creationUtc.ToString('o')
    $record.atime_iso = $lastAccessUtc.ToString('o')
  }

  if ($NormalizeNames) {
    $normalized = $name.Normalize([System.Text.NormalizationForm]::FormC)
    $record.name_norm_nfc = $normalized
    $record.has_unicode_norm_delta = ($normalized -ne $name)
  }

  if ($Classify) {
    $record.category = Get-Category $ext
    $record.mime_guess = Get-MimeGuess $ext
  }

  if ($DetectExecutables) {
    $record.is_executable = Is-ExecutableKind $ext
  }

  if ($ProbeText) {
    if ($TextExtensions -and ($TextExtensions -contains $ext)) {
      $record.is_text = $true
    }
    elseif ($BinaryExtensions -and ($BinaryExtensions -contains $ext)) {
      $record.is_text = $false
    }
    elseif ($length -le ($ProbeTextMaxMB * 1MB)) {
      $record.is_text = Is-TextFile -Path $fullPath
    }
  }

  # Fingerprint rápido (head/tail) si hay candidatos por tamaño
  if ($script:SizeCount.ContainsKey([int64]$length) -and ($script:SizeCount[[int64]$length] -gt 1)) {
    $fp = Get-FingerprintFast -Path $fullPath -Size $length -NBytes 65536
    if ($fp) { $record.finger_md5_16 = $fp }
  }

  # Solo hashear cuando hay candidatos (mismo tamaño) o si FindDuplicates está activo
  $shouldHash = ($FindDuplicates -or ($ComputeHashes -and $script:SizeCount.ContainsKey([int64]$length) -and ($script:SizeCount[[int64]$length] -gt 1)))
  $skipHashDueToHardlink = $false
  if ($shouldHash) {
    $fileIdentity = Get-FileIdentity -Path $fullPath
    if ($fileIdentity -and $fileIdentity.Size -eq $length) {
      if ($script:SeenFileIds.Contains($fileIdentity.Key)) {
        $skipHashDueToHardlink = $true
        $record.dup_hardlink = $true
      }
      else {
        $null = $script:SeenFileIds.Add($fileIdentity.Key)
      }
    }
  }

  $hashValue = $null
  if ($shouldHash -and -not $skipHashDueToHardlink) {
    if ($HashSemaphore) { Measure-HashWait { $HashSemaphore.Wait() } }
    try {
      $script:HashStopwatch.Start()
      try {
        $hashValue = Get-Md5Safe -Path $fullPath -Size $length -MaxMB $MaxHashMB
      }
      finally {
        $script:HashStopwatch.Stop()
      }
    }
    finally {
      if ($HashSemaphore) { $HashSemaphore.Release() }
    }
    if ($hashValue) {
      if ($ComputeHashes -or $FindDuplicates) { $record.hash_md5 = $hashValue }
      $script:HashBytesTotal += $length
      Add-ToDupGroups -Rec $record
    }
  }

  $probeTimedOut = $false
  if ($ProbeDocs -or ($ProbeArchives -and $ext -eq 'zip')) {
    if ($ProbeSemaphore) { Measure-ProbeWait { $ProbeSemaphore.Wait() } }
    try {
      $script:ProbeStopwatch.Start()
      try {
        if ($ProbeDocs) {
          if ($ext -eq 'pdf') {
            $pdfTimedOut = $false
            $pages = Get-PdfPageGuess -Path $fullPath -TimeoutSec $TimeoutSecPerProbe -TimedOut ([ref]$pdfTimedOut)
            if ($pdfTimedOut) { $probeTimedOut = $true }
            if ($null -ne $pages) { $record.pdf_pages = $pages }
          }
          if ($ext -in @('jpg','jpeg','png','gif','bmp','tif','tiff')) {
            $imgTimedOut = $false
            $img = Get-ImageSize -Path $fullPath -Size $length -TimeoutSec $TimeoutSecPerProbe -TimedOut ([ref]$imgTimedOut)
            if ($imgTimedOut) { $probeTimedOut = $true }
            if ($img) {
              $record.image_width = $img.width
              $record.image_height = $img.height
            }
          }
        }
        if ($ProbeArchives -and $ext -eq 'zip') {
          $zipTimedOut = $false
          $zipInfo = Get-ZipInfo -Path $fullPath -MaxEntries $ZipListEntries -TimeoutSec $TimeoutSecPerProbe -TimedOut ([ref]$zipTimedOut)
          if ($zipTimedOut) { $probeTimedOut = $true }
          if ($zipInfo) {
            $record.zip_entries = $zipInfo.entries
            if ($zipInfo.sample.Count -gt 0) { $record.zip_sample = $zipInfo.sample }
          }
        }
      }
      finally {
        $script:ProbeStopwatch.Stop()
      }
    }
    finally {
      if ($ProbeSemaphore) { $ProbeSemaphore.Release() }
    }
  }

  if ($probeTimedOut) {
    $record.probe_timeout = $true
    $script:TimeoutsCount++
  }

  if ($FindDuplicates) {
    if ($hashValue) {
      $dupKey = "{0}-{1}" -f $record.size_bytes, $hashValue
      if ($DuplicateGroupMap) {
        $count = $DuplicateGroupMap.AddOrUpdate($dupKey, 1, { param($k,$current) $current + 1 })
        $record.dup_group_id = $dupKey
        $record.dup_group_count = $count
      }
      else {
        $record.dup_group_id = $dupKey
      }
    }
    else {
      $record.dup_group_skipped = $true
    }
  }

  if ($skipHashDueToHardlink -and -not $hashValue) {
    $record.dup_group_skipped = $true
  }

  [pscustomobject]@{
    Path   = $fullPath
    Record = $record
  }
}

# ==========================================================================================================================================

function Is-TextFile {
  param(
    [string]$Path,
    [int]$ProbeBytes = 4096
  )
  try {
    $fs = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      65536,
      [System.IO.FileOptions]::SequentialScan
    )
    try {
      $len = [Math]::Min($ProbeBytes, $fs.Length)
      $buffer = New-Object byte[] $len
      [void]$fs.Read($buffer, 0, $len)
      if ($len -ge 3 -and $buffer[0] -eq 0xEF -and $buffer[1] -eq 0xBB -and $buffer[2] -eq 0xBF) { return $true }
      if ($len -ge 2 -and ( ($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF) )) { return $true }
      for ($i = 0; $i -lt $len; $i++) {
        if ($buffer[$i] -eq 0) { return $false }
      }
      return $true
    }
    finally {
      $fs.Dispose()
    }
  }
  catch {
    Write-Verbose "Is-TextFile: fallo al leer '$Path' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'Is-TextFile' -Path $Path -Exception $_.Exception -Context 'ProbeText'
    return $false
  }
}

# ==========================================================================================================================================

function Get-SystemStats {
  $cpu = [Environment]::ProcessorCount
  $memGB = 0
  try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($null -ne $os) { $memGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 0) }
  }
  catch {
    Write-Verbose "Get-SystemStats: no se pudo consultar Win32_OperatingSystem — $($_.Exception.Message)"
    Bump-Error 'SystemStats'
    $memGB = 0
  }
  [pscustomobject]@{ CPU = $cpu; MemGB = $memGB }
}

# ==========================================================================================================================================

function Estimate-FileCount {
  param(
    [Parameter(Mandatory)][string]$Root,
    [int]$Limit = 100000
  )
  $options = [System.IO.EnumerationOptions]::new()
  $options.RecurseSubdirectories = $false
  $options.AttributesToSkip = [System.IO.FileAttributes]::System
  $stack = New-Object System.Collections.Generic.Stack[string]
  $stack.Push([System.IO.Path]::GetFullPath($Root))
  $count = 0
  while ($stack.Count -gt 0) {
    $current = $stack.Pop()
    try {
      $enumerable = [System.IO.Directory]::EnumerateFileSystemEntries($current, '*', $options)
      foreach ($entry in $enumerable) {
        if ($count -ge $Limit) { return $count }
        try {
          $attr = [System.IO.File]::GetAttributes($entry)
        }
        catch {
          Write-Verbose "Estimate-FileCount: GetAttributes falló para '$entry' — $($_.Exception.Message)"
          Write-ErrorJson -Op 'Estimate-FileCount' -Path $entry -Exception $_.Exception -Context 'GetAttributes'
          continue
        }
        if ($attr.HasFlag([System.IO.FileAttributes]::Directory)) {
          if (-not $attr.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
            $stack.Push($entry)
          }
        }
        else {
          $count++
        }
      }
    }
    catch {
      Write-Verbose "Estimate-FileCount: EnumerateFileSystemEntries falló en '$current' — $($_.Exception.Message)"
      Write-ErrorJson -Op 'Estimate-FileCount' -Path $current -Exception $_.Exception -Context 'Enumerate'
      continue
    }
  }
  $count
}

# ==========================================================================================================================================

function Compute-AutoPlanV2 {
  param([string]$Root)
  $stats = Get-SystemStats
  $estimate = Estimate-FileCount -Root $Root -Limit 250000
  $driveKind = Get-DriveKind -RootPath $Root
  $cpu = $stats.CPU
  $mem = $stats.MemGB
  $level = if ($estimate -le 20000) { 'small' } elseif ($estimate -le 100000) { 'medium' } elseif ($estimate -le 200000) { 'large' } else { 'huge' }
  $dopBase = switch ($driveKind) {
    'network' { [Math]::Max(2, [int]([Environment]::ProcessorCount / 2)) }
    'fixed'   { [Environment]::ProcessorCount }
    default   { [Math]::Max(2, [Environment]::ProcessorCount - 1) }
  }

  $plan = [ordered]@{
    Parallel              = $true
    ParallelHash          = $true
    ParallelProbes        = $true
    DegreeOfParallelism   = $dopBase
    DopHash               = [Math]::Max(2, [int]$dopBase)
    DopProbes             = [Math]::Max(2, [int][Math]::Ceiling($dopBase / 2.0))
    ShowSizes             = $true
    ShowDates             = $true
    Classify              = $true
    DetectExecutables     = $true
    ComputeHashes         = $false
    ProbeDocs             = $false
    ProbeArchives         = $false
    ProbeText             = $false
    EmitSummaries         = $false
    ProgressInterval      = 2500
    StrictJson            = $true
    CompressOutput        = $true
    PreferCompressionSpeed= $true
    OutputMaxMB           = 512
    TimeoutSecPerProbe    = if ($driveKind -eq 'network') { 2 } else { 1 }
  }

  switch ($level) {
    'small' {
      $plan.ProbeText = $true
      $plan.ProbeDocs = ($mem -ge 8)
      $plan.ProbeArchives = $true
      $plan.EmitSummaries = $true
      $plan.ComputeHashes = $true
      $plan.OutputMaxMB = 0
      $plan.StrictJson = $false
      $plan.PreferCompressionSpeed = $false
      $plan.ProgressInterval = 1000
    }
    'medium' {
      $plan.ProbeArchives = $true
      $plan.ComputeHashes = ($mem -ge 8)
      $plan.ProgressInterval = 2000
    }
    'large' {
      $plan.ProbeArchives = $true
      $plan.ComputeHashes = $false
      $plan.DopHash = [Math]::Max(2, [int]([Environment]::ProcessorCount / 2))
      $plan.OutputMaxMB = 512
      $plan.ProgressInterval = 3000
    }
    default {
      $plan.ComputeHashes = $false
      $plan.ProbeArchives = $false
      $plan.ProbeDocs = $false
      $plan.ProbeText = $false
      $plan.OutputMaxMB = 256
      $plan.DegreeOfParallelism = [Math]::Max(2, [int]([Environment]::ProcessorCount / 2))
      $plan.DopHash = [Math]::Max(2, [int]([Environment]::ProcessorCount / 3))
      $plan.DopProbes = [Math]::Max(2, [int]([Environment]::ProcessorCount / 3))
      $plan.ProgressInterval = 4000
    }
  }

  if ($driveKind -eq 'network') {
    $plan.ComputeHashes = $false
    $plan.ProbeDocs = $false
    $plan.ProbeText = $false
    $plan.ProgressInterval = 4000
  }

  [pscustomobject]@{
    Level   = $level
    Estimate= $estimate
    CPU     = $cpu
    MemGB   = $mem
    Drive   = $driveKind
    Plan    = $plan
  }
}

# ==========================================================================================================================================

function Apply-AutomaticConfigurationV2 {
  param([string]$Root)
  $auto = Compute-AutoPlanV2 -Root $Root
  foreach ($key in $auto.Plan.Keys) {
    if ($StdOut -and $key -eq 'CompressOutput') { continue }
    if (-not $PSBoundParameters.ContainsKey($key)) {
      Set-Variable -Name $key -Value $auto.Plan[$key] -Scope Script
    }
  }
  Optimize-ThreadPool -CpuDop $auto.Plan.DopHash -IoDop $auto.Plan.DopProbes
  $script:EstimatedEntries = [int64]$auto.Estimate
  $summary = "AutoV2: ~{0:N0} archivos | CPU={1} | Mem={2}GB | Drive={3} | Nivel={4}" -f $auto.Estimate, $auto.CPU, $auto.MemGB, $auto.Drive, $auto.Level
  Write-Host $summary -ForegroundColor Cyan
}

# ==========================================================================================================================================

function Apply-CompleteConfiguration {
  $Script:ShowSizes = $true
  $Script:ShowDates = $true
  $Script:Classify = $true
  $Script:DetectExecutables = $true
  $Script:ComputeHashes = $true
  $Script:ProbeDocs = $true
  $Script:ProbeArchives = $true
  $Script:ProbeText = $true
  $Script:EmitSummaries = $true
  $Script:ProgressInterval = 1500
  $script:EstimatedEntries = 0
}

# ==========================================================================================================================================

function Prompt-Configuration {
  Write-Host 'AR-Filemap — Configuración CLI' -ForegroundColor Cyan
  while (-not $script:RootPath) {
    $candidate = Read-Host 'Ruta a mapear'
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      Write-Host 'Debes ingresar una ruta válida.' -ForegroundColor Yellow
      continue
    }
    $script:RootPath = $candidate
  }

  $outCandidate = Read-Host "Carpeta de salida (enter = $OutputDir)"
  if (-not [string]::IsNullOrWhiteSpace($outCandidate)) {
    $script:OutputDir = $outCandidate
  }

  while ($true) {
    Write-Host 'Selecciona tipo de reporte:' -ForegroundColor Cyan
    Write-Host '  1) Filemap Markdown'
    Write-Host '  2) Filelist JSONL'
    Write-Host '  3) Ambos'
    $choice = Read-Host 'Elige 1, 2 o 3'
    switch ($choice) {
      '1' { $script:EmitTree = $true; $script:EmitJsonl = $false; $script:OutputKind = 'md'; break }
      '2' { $script:EmitTree = $false; $script:EmitJsonl = $true; break }
      '3' { $script:EmitTree = $true; $script:EmitJsonl = $true; $script:OutputKind = 'md'; break }
      default {
        Write-Host 'Opción inválida.' -ForegroundColor Yellow
        continue
      }
    }
    break
  }

  while ($true) {
    Write-Host 'Modo de métricas:' -ForegroundColor Cyan
    Write-Host '  1) Automático'
    Write-Host '  2) Completo'
    $modeChoice = Read-Host 'Elige 1 o 2'
    switch ($modeChoice) {
      '1' { $script:Mode = 'Automatico'; break }
      '2' { $script:Mode = 'Completo'; break }
      default {
        Write-Host 'Opción inválida.' -ForegroundColor Yellow
        continue
      }
    }
    break
  }
}

# ==========================================================================================================================================

$TextExts = @('txt','text','md','markdown','json','csv','ts','js','jsx','tsx','css','scss','less','html','htm','xml','xhtml','yml','yaml','toml','ini','cfg','conf','log','ps1','psm1','psd1','bat','cmd','sh','java','py','cs','cpp','c','h','hpp','rs','go','kt','rb','php','sql','svg')
$BinaryExts = @('pdf','jpg','jpeg','png','gif','bmp','tif','tiff','webp','ico','zip','7z','rar','gz','bz2','xz','tar','doc','docx','xls','xlsx','ppt','pptx','rtf','exe','dll','msi','sys','com','db','sqlite','mdb','accdb','parquet','orc','avro')

# ==========================================================================================================================================

function Get-MimeGuess {
  param([string]$Ext)
  switch (($Ext ?? '').ToLowerInvariant()) {
    'txt'  { 'text/plain'; break }
    'md'   { 'text/markdown'; break }
    'json' { 'application/json'; break }
    'csv'  { 'text/csv'; break }
    'html' { 'text/html'; break }
    'xml'  { 'application/xml'; break }
    'yml'  { 'text/yaml'; break }
    'yaml' { 'text/yaml'; break }
    'jpg'  { 'image/jpeg'; break }
    'jpeg' { 'image/jpeg'; break }
    'png'  { 'image/png'; break }
    'gif'  { 'image/gif'; break }
    'bmp'  { 'image/bmp'; break }
    'tif'  { 'image/tiff'; break }
    'tiff' { 'image/tiff'; break }
    'pdf'  { 'application/pdf'; break }
    'doc'  { 'application/msword'; break }
    'docx' { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break }
    'xls'  { 'application/vnd.ms-excel'; break }
    'xlsx' { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'; break }
    'ppt'  { 'application/vnd.ms-powerpoint'; break }
    'pptx' { 'application/vnd.openxmlformats-officedocument.presentationml.presentation'; break }
    'zip'  { 'application/zip'; break }
    '7z'   { 'application/x-7z-compressed'; break }
    'rar'  { 'application/vnd.rar'; break }
    'js'   { 'application/javascript'; break }
    'css'  { 'text/css'; break }
    'exe'  { 'application/vnd.microsoft.portable-executable'; break }
    'dll'  { 'application/vnd.microsoft.portable-executable'; break }
    'msi'  { 'application/x-msi'; break }
    default { '' }
  }
}

# ==========================================================================================================================================

function Get-Category {
  param([string]$Ext)
  $e = ($Ext ?? '').ToLowerInvariant()
  switch ($e) {
    { $_ -in @('txt','md','pdf','doc','docx','xls','xlsx','ppt','pptx','rtf') } { 'doc'; break }
    { $_ -in @('jpg','jpeg','png','gif','bmp','tif','tiff','webp') } { 'image'; break }
    { $_ -in @('js','ts','jsx','tsx','cs','ps1','psm1','psd1','py','java','rs','go','cpp','c','h','sh','bat','cmd','json','yml','yaml','toml') } { 'code'; break }
    { $_ -in @('zip','7z','rar','gz','bz2','xz','tar') } { 'archive'; break }
    { $_ -in @('sqlite','db','db3','accdb','mdb','parquet','orc','avro') } { 'data'; break }
    default { if ($e) { 'binary' } else { '' } }
  }
}

# ==========================================================================================================================================

function Is-ExecutableKind {
  param([string]$Ext)
  (($Ext ?? '').ToLowerInvariant()) -in @('exe','dll','sys','msi','bat','cmd','ps1','psm1','psd1','vbs','vbe','com')
}

# ==========================================================================================================================================

function Get-Md5Safe {
  param(
    [string]$Path,
    [long]$Size,
    [int]$MaxMB,
    [int]$BlockKB = 1024
  )
  if ($Size -gt ($MaxMB * 1MB)) { return $null }
  $fs = $null
  $buffer = $null
  try {
    $fs = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      1048576,
      [System.IO.FileOptions]::SequentialScan
    )
    $hash = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::MD5)
    $blockSize = [Math]::Max(4096, $BlockKB * 1024)
    $buffer = [System.Buffers.ArrayPool[byte]]::Shared.Rent($blockSize)
    while ($true) {
      $read = $fs.Read($buffer, 0, $blockSize)
      if ($read -le 0) { break }
      $hash.AppendData($buffer, 0, $read)
    }
    $hashBytes = $hash.GetHashAndReset()
    $sb = [System.Text.StringBuilder]::new($hashBytes.Length * 2)
    foreach ($b in $hashBytes) { [void]$sb.AppendFormat('{0:x2}', $b) }
    $sb.ToString()
  }
  catch {
    Write-Verbose "Get-Md5Safe: $Path — $($_.Exception.Message)"
    Write-ErrorJson -Op 'Hash' -Path $Path -Exception $_.Exception -Context 'MD5'
    $null
  }
  finally {
    if ($buffer) { [System.Buffers.ArrayPool[byte]]::Shared.Return($buffer, $false) }
    if ($fs) { $fs.Dispose() }
  }
}

# ==========================================================================================================================================

function Get-FingerprintFast {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][long]$Size,
    [int]$NBytes = 65536
  )
  if ($Size -le 0) { return $null }
  $fs = $null
  $buffer = $null
  try {
    $fs = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      1048576,
      [System.IO.FileOptions]::SequentialScan
    )
    $md5 = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::MD5)
    $block = [Math]::Min([int]$NBytes, [int][Math]::Min($Size, 4MB))
    $buffer = [System.Buffers.ArrayPool[byte]]::Shared.Rent($block)
    $read = $fs.Read($buffer,0,$block)
    if ($read -gt 0) { $md5.AppendData($buffer,0,$read) }
    $tailStart = [long]::Max(0, $Size - $block)
    if ($tailStart -gt $read) {
      $fs.Seek($tailStart, [System.IO.SeekOrigin]::Begin) | Out-Null
      $read2 = $fs.Read($buffer,0,$block)
      if ($read2 -gt 0) { $md5.AppendData($buffer,0,$read2) }
    }
    $hashBytes = $md5.GetHashAndReset()
    $sb=[System.Text.StringBuilder]::new($hashBytes.Length*2)
    foreach($b in $hashBytes){ [void]$sb.AppendFormat('{0:x2}',$b) }
    $hashString = $sb.ToString()
    return $hashString.Substring(0,[Math]::Min(16,$hashString.Length))
  }
  catch {
    Write-Verbose "Get-FingerprintFast: $Path — $($_.Exception.Message)"
    $null
  }
  finally {
    if ($buffer) { [System.Buffers.ArrayPool[byte]]::Shared.Return($buffer,$false) }
    if ($fs) { $fs.Dispose() }
  }
}

function Get-ZipInfo {
  param(
    [string]$Path,
    [int]$MaxEntries,
    [int]$TimeoutSec = 0,
    [ref]$TimedOut
  )
  $result = @{ entries = $null; sample = @() }
  $timedOutLocal = $false
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue | Out-Null
    $fs = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      65536,
      [System.IO.FileOptions]::SequentialScan
    )
    try {
      $stopwatch = if ($TimeoutSec -gt 0) { [System.Diagnostics.Stopwatch]::StartNew() } else { $null }
      $zip = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Read, $false)
      $result.entries = $zip.Entries.Count
      $take = [Math]::Min($MaxEntries, [int]$zip.Entries.Count)
      for ($i = 0; $i -lt $take; $i++) {
        if ($TimeoutSec -gt 0 -and $stopwatch -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSec) {
          $timedOutLocal = $true
          break
        }
        $name = $zip.Entries[$i].FullName
        if ($name) { $result.sample += $name }
      }
      if ($stopwatch) { $stopwatch.Stop() }
    }
    finally {
      $fs.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-ZipInfo: fallo en '$Path' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'ProbeZip' -Path $Path -Exception $_.Exception -Context 'Get-ZipInfo'
  }
  if ($PSBoundParameters.ContainsKey('TimedOut')) { $TimedOut.Value = $timedOutLocal }
  if ($timedOutLocal) {
    Write-Verbose "Get-ZipInfo: tiempo excedido en '$Path'"
    Write-ErrorJson -Op 'ProbeZipTimeout' -Path $Path -Message 'Timeout superado' -Context 'Get-ZipInfo'
  }
  $result
}

# ==========================================================================================================================================

function Get-PdfPageGuess {
  param(
    [string]$Path,
    [int]$ProbeKB = 2048,
    [int]$TimeoutSec = 0,
    [ref]$TimedOut
  )
  $timedOutLocal = $false
  try {
    $fs = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      65536,
      [System.IO.FileOptions]::SequentialScan
    )
    try {
      $stopwatch = if ($TimeoutSec -gt 0) { [System.Diagnostics.Stopwatch]::StartNew() } else { $null }
      $len = [Math]::Min($ProbeKB * 1024, $fs.Length)
      $buffer = New-Object byte[] $len
      [void]$fs.Read($buffer, 0, $len)
      if ($TimeoutSec -gt 0 -and $stopwatch -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSec) {
        $timedOutLocal = $true
        if ($PSBoundParameters.ContainsKey('TimedOut')) { $TimedOut.Value = $true }
        return $null
      }
      $text = [System.Text.Encoding]::ASCII.GetString($buffer)
      ([regex]::Matches($text, '/Type\s*/Page').Count)
    }
    finally {
      $fs.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-PdfPageGuess: fallo en '$Path' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'ProbePdf' -Path $Path -Exception $_.Exception -Context 'Get-PdfPageGuess'
    $null
  }
  finally {
    if ($PSBoundParameters.ContainsKey('TimedOut')) { $TimedOut.Value = $timedOutLocal }
    if ($timedOutLocal) {
      Write-Verbose "Get-PdfPageGuess: tiempo excedido en '$Path'"
      Write-ErrorJson -Op 'ProbePdfTimeout' -Path $Path -Message 'Timeout superado' -Context 'Get-PdfPageGuess'
    }
  }
}

# ==========================================================================================================================================

function Get-ImageSize {
  param(
    [string]$Path,
    [long]$Size,
    [int]$MaxMB = 50,
    [int]$TimeoutSec = 0,
    [ref]$TimedOut
  )
  if ($Size -gt ($MaxMB * 1MB)) { return $null }
  $timedOutLocal = $false
  try {
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null
    $imgStream = [System.IO.FileStream]::new(
      $Path,
      [System.IO.FileMode]::Open,
      [System.IO.FileAccess]::Read,
      [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete,
      65536,
      [System.IO.FileOptions]::SequentialScan
    )
    try {
      $stopwatch = if ($TimeoutSec -gt 0) { [System.Diagnostics.Stopwatch]::StartNew() } else { $null }
      $img = [System.Drawing.Image]::FromStream($imgStream, $false, $false)
      try {
        if ($TimeoutSec -gt 0 -and $stopwatch -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSec) {
          $timedOutLocal = $true
          if ($PSBoundParameters.ContainsKey('TimedOut')) { $TimedOut.Value = $true }
          return $null
        }
        @{ width = $img.Width; height = $img.Height }
      }
      finally {
        $img.Dispose()
      }
    }
    finally {
      $imgStream.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-ImageSize: fallo en '$Path' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'ProbeImage' -Path $Path -Exception $_.Exception -Context 'Get-ImageSize'
    $null
  }
  finally {
    if ($PSBoundParameters.ContainsKey('TimedOut')) { $TimedOut.Value = $timedOutLocal }
    if ($timedOutLocal) {
      Write-Verbose "Get-ImageSize: tiempo excedido en '$Path'"
      Write-ErrorJson -Op 'ProbeImageTimeout' -Path $Path -Message 'Timeout superado' -Context 'Get-ImageSize'
    }
  }
}

# ==========================================================================================================================================

function JsonString {
  param($s)
  if ($null -eq $s) { return 'null' }
  $text = [string]$s
  $text = $text -replace '\\','\\\\'
  $text = $text -replace '"','\"'
  $text = $text -replace "`r",'\\r' -replace "`n",'\\n' -replace "`t",'\\t' -replace "`b",'\\b' -replace "`f",'\\f'
  '"' + $text + '"'
}

# ==========================================================================================================================================

function JsonPrimitive {
  param($v)
  switch ($v) {
    { $null -eq $_ } { 'null'; break }
    { $_ -is [bool] } { $_.ToString().ToLowerInvariant(); break }
    { $_ -is [int] -or $_ -is [long] -or $_ -is [double] } { $_.ToString([System.Globalization.CultureInfo]::InvariantCulture); break }
    { $_ -is [datetime] } { JsonString ($_.ToUniversalTime().ToString('o')); break }
    { $_ -is [System.Collections.IDictionary] } {
      $entries = @()
      foreach ($dictKey in $_.Keys) {
        $escapedKey = ([string]$dictKey) -replace '"','\"'
        $entries += "`"$escapedKey`":$(JsonPrimitive $_[$dictKey])"
      }
      '{' + ($entries -join ',') + '}'
      break
    }
    { $_ -is [System.Collections.IEnumerable] -and -not ($_ -is [string]) } {
      $items = @()
      foreach ($item in $_) {
        $items += (JsonPrimitive $item)
      }
      '[' + ($items -join ',') + ']'
      break
    }
    default { JsonString $_ }
  }
}

# ==========================================================================================================================================

function ConvertTo-JsonCompatible {
  param($Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [System.Collections.IDictionary]) {
    $dict = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($key in $Value.Keys) {
      $dict[$key] = ConvertTo-JsonCompatible $Value[$key]
    }
    return $dict
  }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $Value) {
      $list.Add((ConvertTo-JsonCompatible $item))
    }
    return $list
  }
  if ($Value -is [datetime]) { return $Value.ToUniversalTime() }
  return $Value
}

# ==========================================================================================================================================

function Convert-FileTimeUtc {
  param([Native.Win32+FILETIME]$FileTime)
  $ticks = ([int64]$FileTime.dwHighDateTime -shl 32) -bor ([uint32]$FileTime.dwLowDateTime)
  [DateTime]::FromFileTimeUtc([int64]$ticks)
}

# ==========================================================================================================================================

function Enumerate-WinEntriesLight {
  param(
    [string]$Dir,
    [bool]$IncludeHidden
  )
  $pattern = Join-Path $Dir '*'
  $data = New-Object Native.Win32+WIN32_FIND_DATAW
  $handle = [Native.Win32]::FindFirstFileExW(
    $pattern,
    [Native.Win32+FINDEX_INFO_LEVELS]::FindExInfoBasic,
    [ref]$data,
    [Native.Win32+FINDEX_SEARCH_OPS]::FindExSearchNameMatch,
    [IntPtr]::Zero,
    [Native.Win32]::FIND_FIRST_EX_LARGE_FETCH
  )
  if ($handle -eq [IntPtr]::Zero -or $handle.ToInt64() -eq -1) { return @() }
  $entries = New-Object System.Collections.Generic.List[object]
  try {
    do {
      $name = $data.cFileName
      if ([string]::IsNullOrEmpty($name) -or $name -eq '.' -or $name -eq '..') { continue }
      $attr = [uint32]$data.dwFileAttributes
      if (($attr -band [Native.Win32]::FILE_ATTRIBUTE_REPARSE_POINT) -ne 0) { continue }
      if (-not $IncludeHidden) {
        if (($attr -band [Native.Win32]::FILE_ATTRIBUTE_HIDDEN) -ne 0 -or ($attr -band [Native.Win32]::FILE_ATTRIBUTE_SYSTEM) -ne 0) { continue }
      }
      if (-not (Match-Patterns $name)) { continue }
      $full = Join-Path $Dir $name
      if ([string]::IsNullOrWhiteSpace($full)) {
        Write-Verbose "Enumerate-WinEntriesLight: se omitió una entrada con ruta vacía en '$Dir'"
        Write-ErrorJson -Op 'Enumerate' -Path $Dir -Context 'Enumerate-WinEntriesLight-EmptyPath' -Message "Entrada sin ruta para '$name'" -IsParallel:$false
        continue
      }
      if ($script:OutputDirExclusionActive) {
        if ($full.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($full.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
      }
      if ($script:ExcludedPaths -and $script:ExcludedPaths.Contains([System.IO.Path]::GetFullPath($full))) { continue }
      $isDir = (($attr -band [Native.Win32]::FILE_ATTRIBUTE_DIRECTORY) -ne 0)
      $size = if ($isDir) { 0L } else { ([int64]$data.nFileSizeHigh -shl 32) -bor ([uint32]$data.nFileSizeLow) }
      $entry = [pscustomobject]@{
        FullName          = $full
        Name              = $name
        IsDirectory       = $isDir
        Length            = [int64]$size
        LastWriteTimeUtc  = Convert-FileTimeUtc $data.ftLastWriteTime
        CreationTimeUtc   = Convert-FileTimeUtc $data.ftCreationTime
        LastAccessTimeUtc = Convert-FileTimeUtc $data.ftLastAccessTime
        Attributes        = [System.Enum]::ToObject([System.IO.FileAttributes], [int]$attr)
      }
      $entries.Add($entry) | Out-Null
    } while ([Native.Win32]::FindNextFileW($handle, [ref]$data))
  }
  catch {
    Write-Verbose "Enumerate-WinEntriesLight: $($_.Exception.Message)"
    Write-ErrorJson -Op 'Enumerate' -Path $Dir -Exception $_.Exception -Context 'Enumerate-WinEntriesLight'
  }
  finally {
    [void][Native.Win32]::FindClose($handle)
  }
  $entries
}

# ==========================================================================================================================================

function Get-ChildListsWinApi {
  param(
    [Parameter(Mandatory)][string]$DirectoryPath,
    [bool]$IncludeHidden
  )
  $entries = Enumerate-WinEntriesLight -Dir $DirectoryPath -IncludeHidden:$IncludeHidden
  $dirs = New-Object System.Collections.Generic.List[object]
  $files = New-Object System.Collections.Generic.List[object]
  foreach ($entry in $entries) {
    if ($entry.IsDirectory) { $dirs.Add($entry) | Out-Null }
    else { $files.Add($entry) | Out-Null }
  }
  $dirArray = $dirs.ToArray()
  [Array]::Sort($dirArray, [System.Comparison[object]]{
    param($a, $b)
    $nameA = if ($a.PSObject.Properties['Name']) { [string]$a.Name } else { '' }
    $nameB = if ($b.PSObject.Properties['Name']) { [string]$b.Name } else { '' }
    [System.StringComparer]::OrdinalIgnoreCase.Compare($nameA, $nameB)
  })
  $fileArray = $files.ToArray()
  [Array]::Sort($fileArray, [System.Comparison[object]]{
    param($a, $b)
    $nameA = if ($a.PSObject.Properties['Name']) { [string]$a.Name } else { '' }
    $nameB = if ($b.PSObject.Properties['Name']) { [string]$b.Name } else { '' }
    [System.StringComparer]::OrdinalIgnoreCase.Compare($nameA, $nameB)
  })
  @{ Dirs = $dirArray; Files = $fileArray }
}

# ==========================================================================================================================================

function Get-ChildListsNet {
  param(
    [Parameter(Mandatory)][System.IO.DirectoryInfo]$Directory,
    [bool]$IncludeHidden
  )
  $options = [System.IO.EnumerationOptions]::new()
  $options.RecurseSubdirectories = $false
  $options.IgnoreInaccessible = $true
  $options.AttributesToSkip = if ($IncludeHidden) {
    [System.IO.FileAttributes]::System
  }
  else {
    [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden
  }
  $dirs = New-Object System.Collections.Generic.List[object]
  $files = New-Object System.Collections.Generic.List[object]
  try {
    foreach ($entry in [System.IO.Directory]::EnumerateFileSystemEntries($Directory.FullName, '*', $options)) {
      $name = [System.IO.Path]::GetFileName($entry)
      if (-not (Match-Patterns $name)) { continue }
      try {
        $attr = [System.IO.File]::GetAttributes($entry)
      }
      catch {
        Write-Verbose "Get-ChildListsNet: no se pudo obtener atributos de '$entry' — $($_.Exception.Message)"
        Write-ErrorJson -Op 'EnumerateAttributes' -Path $entry -Exception $_.Exception -Context 'Get-ChildListsNet'
        continue
      }
      if ($attr.HasFlag([System.IO.FileAttributes]::ReparsePoint)) { continue }
      if ($attr.HasFlag([System.IO.FileAttributes]::Directory)) {
        if ($script:OutputDirExclusionActive) {
          if ($entry.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
          if ($entry.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        }
        try {
          $dirInfo = [System.IO.DirectoryInfo]::new($entry)
          $dirs.Add([pscustomobject]@{
              FullName          = $dirInfo.FullName
              Name              = $dirInfo.Name
              IsDirectory       = $true
              Length            = 0L
              LastWriteTimeUtc  = $dirInfo.LastWriteTimeUtc.ToUniversalTime()
              CreationTimeUtc   = $dirInfo.CreationTimeUtc.ToUniversalTime()
              LastAccessTimeUtc = $dirInfo.LastAccessTimeUtc.ToUniversalTime()
              Attributes        = $dirInfo.Attributes
            }) | Out-Null
        }
        catch {
          Write-Verbose "Get-ChildListsNet: error al materializar dir '$entry' — $($_.Exception.Message)"
          Write-ErrorJson -Op 'EnumerateMaterializeDir' -Path $entry -Exception $_.Exception -Context 'Get-ChildListsNet'
        }
        continue
      }
      $parent = [System.IO.Path]::GetDirectoryName($entry)
      if ($script:OutputDirExclusionActive -and $parent) {
        if ($parent.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($parent.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
      }
      if ($script:ExcludedPaths -and $script:ExcludedPaths.Contains([System.IO.Path]::GetFullPath($entry))) { continue }
      try {
        $fileInfo = [System.IO.FileInfo]::new($entry)
        $files.Add([pscustomobject]@{
            FullName          = $fileInfo.FullName
            Name              = $fileInfo.Name
            IsDirectory       = $false
            Length            = [int64]$fileInfo.Length
            LastWriteTimeUtc  = $fileInfo.LastWriteTimeUtc.ToUniversalTime()
            CreationTimeUtc   = $fileInfo.CreationTimeUtc.ToUniversalTime()
            LastAccessTimeUtc = $fileInfo.LastAccessTimeUtc.ToUniversalTime()
            Attributes        = $fileInfo.Attributes
          }) | Out-Null
      }
      catch {
        Write-Verbose "Get-ChildListsNet: error al materializar file '$entry' — $($_.Exception.Message)"
        Write-ErrorJson -Op 'EnumerateMaterializeFile' -Path $entry -Exception $_.Exception -Context 'Get-ChildListsNet'
      }
    }
  }
  catch {
    Write-Verbose "Get-ChildListsNet: enumeración falló en '$($Directory.FullName)' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'Enumerate' -Path $Directory.FullName -Exception $_.Exception -Context 'Get-ChildListsNet'
  }
  $sortedDirs = $dirs.ToArray()
  [Array]::Sort($sortedDirs, [System.Comparison[object]]{
    param($a, $b)
    $nameA = if ($a.PSObject.Properties['Name']) { [string]$a.Name } else { '' }
    $nameB = if ($b.PSObject.Properties['Name']) { [string]$b.Name } else { '' }
    [System.StringComparer]::OrdinalIgnoreCase.Compare($nameA, $nameB)
  })
  $sortedFiles = $files.ToArray()
  [Array]::Sort($sortedFiles, [System.Comparison[object]]{
    param($a, $b)
    $nameA = if ($a.PSObject.Properties['Name']) { [string]$a.Name } else { '' }
    $nameB = if ($b.PSObject.Properties['Name']) { [string]$b.Name } else { '' }
    [System.StringComparer]::OrdinalIgnoreCase.Compare($nameA, $nameB)
  })
  @{ Dirs = $sortedDirs; Files = $sortedFiles }
}

# ==========================================================================================================================================

function Get-ChildLists {
  param(
    [Parameter(Mandatory)][System.IO.DirectoryInfo]$Directory,
    [bool]$IncludeHidden
  )
  if ($script:Win32NativeAvailable) {
    return Get-ChildListsWinApi -DirectoryPath $Directory.FullName -IncludeHidden:$IncludeHidden
  }
  Get-ChildListsNet -Directory $Directory -IncludeHidden:$IncludeHidden
}
function Get-RelativePath {
  param([string]$Base,[string]$Full)
  try {
    $resolvedBase = [System.IO.Path]::GetFullPath($Base)
    $resolvedFull = [System.IO.Path]::GetFullPath($Full)
    if ($resolvedFull.StartsWith($resolvedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
      $rel = [System.IO.Path]::GetRelativePath($resolvedBase, $resolvedFull)
      if ([string]::IsNullOrWhiteSpace($rel)) { return '.' }
      return $rel
    }
    return $Full
  }
  catch {
    Write-Verbose "Get-RelativePath: error al resolver '$Full' desde '$Base' — $($_.Exception.Message)"
    Write-ErrorJson -Op 'Get-RelativePath' -Path $Full -Exception $_.Exception -Context 'PathResolution'
    return $Full
  }
}

# ==========================================================================================================================================

function Write-ProgressSafe {
  param(
    [string]$Activity,
    [string]$Status = '',
    [switch]$Completed
  )
  if ($Completed) {
    Write-Progress -Activity $Activity -Completed
    return
  }
  if ($Status) {
    Write-Progress -Activity $Activity -Status $Status
    return
  }
  if (-not $script:ProgressStopwatch) {
    $script:ProgressStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $script:LastProgressReportSeconds = 0.0
  }
  $elapsedSeconds = $script:ProgressStopwatch.Elapsed.TotalSeconds
  if ($elapsedSeconds -lt 0.5) { return }
  if ($script:LastProgressReportSeconds -gt 0 -and ($elapsedSeconds - $script:LastProgressReportSeconds) -lt 0.75) { return }
  $script:LastProgressReportSeconds = $elapsedSeconds
  $entries = [double][math]::Max($script:EntryCounter, 0)
  $bytes = [double][math]::Max($script:TotalBytes, 0)
  $eps = if ($elapsedSeconds -gt 0) { $entries / $elapsedSeconds } else { 0 }
  $mbps = if ($elapsedSeconds -gt 0) { ($bytes / $elapsedSeconds) / [double](1MB) } else { 0 }
  $elapsedSpan = [TimeSpan]::FromSeconds([math]::Min($elapsedSeconds, 359999))
  $elapsedText = $elapsedSpan.ToString('hh\:mm\:ss')
  $etaSuffix = ''
  if ($script:EstimatedEntries -gt 0 -and $eps -gt 0) {
    $remaining = [math]::Max($script:EstimatedEntries - $script:EntryCounter, 0)
    if ($remaining -gt 0) {
      $etaSeconds = $remaining / $eps
      $etaSpan = [TimeSpan]::FromSeconds([math]::Min($etaSeconds, 359999))
      $etaSuffix = " | ETA {0}" -f $etaSpan.ToString('hh\:mm\:ss')
    }
  }
  $statusLine = "{0:N0} entradas | {1:N2} elem/s | {2:N2} MB/s | Elapsed {3}{4}" -f (
    $script:EntryCounter,
    $eps,
    $mbps,
    $elapsedText,
    $etaSuffix
  )
  Write-Progress -Activity $Activity -Status $statusLine
}

# ==========================================================================================================================================
