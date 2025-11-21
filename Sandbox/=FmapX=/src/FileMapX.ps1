<#
.SYNOPSIS
  Genera un árbol jerárquico (Markdown/TXT) y un inventario JSONL con metadatos opcionales.

.DESCRIPTION
  - Recorre un directorio raíz y escribe:
      1) Árbol jerárquico (.md/.txt) en OutputDir.
      2) Inventario JSONL (una línea por elemento) con campos base y opcionales.
  - StreamWriter (rápido/baja memoria), manejo de errores, sin dependencias externas.
  - PowerShell 7.0+.

.PARAMETER RootPath
  Directorio raíz a mapear (obligatorio en modo no interactivo).

.PARAMETER OutputKind
  Formato del árbol. Valores: 'md' (predeterminado) o 'txt'.

.PARAMETER OutputDir
  Carpeta de salida. Por defecto, la carpeta del script.

.PARAMETER NoProgress
  Desactiva la visualización de progreso (útil para CI/pipelines o máximo rendimiento).

.EXAMPLE
  .\AR-Filemap.ps1 -RootPath 'C:\Data' -OutputKind md -EmitJsonl:$true -NoProgress
#>

# ==========================================================================================================================================

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
  [string]$RootPath,
  [string]$OutputKind = 'md',
  [string]$OutputDir = $PSScriptRoot,
  [ValidateRange(0,64)][int]$MaxDepth = 0,
  [switch]$IncludeHidden,
  [switch]$ShowSizes,
  [switch]$ShowDates,
  [ValidateRange(50,1000000)][int]$ProgressInterval = 2000,
  [bool]$EmitTree = $true,
  [bool]$EmitJsonl = $true,
  [switch]$ComputeHashes,
  [ValidateRange(1,4096)][int]$MaxHashMB = 50,
  [switch]$ProbeDocs,
  [switch]$ProbeArchives,
  [ValidateRange(1,1000)][int]$ZipListEntries = 10,
  [ValidateRange(1,4096)][int]$LargeFileMB = 100,
  [switch]$EmitSummaries,
  [switch]$Classify,
  [switch]$DetectExecutables,
  [switch]$ProbeText,
  [ValidateRange(1,1024)][int]$ProbeTextMaxMB = 5,
  [ValidateSet('Automatico','Completo')][string]$Mode = 'Automatico',
  [switch]$StrictJson,
  [string[]]$Include,
  [string[]]$Exclude,
  [ValidateRange(1,100000000)][int]$MaxEntries = 100000000,
  [switch]$Parallel,
  [ValidateRange(1,256)][int]$DegreeOfParallelism = [Environment]::ProcessorCount,
  [ValidateRange(0,102400)][int]$OutputMaxMB = 0,
  [string]$ErrorLog,
  [Nullable[int]]$MinMB,
  [Nullable[int]]$MaxMB,
  [Nullable[int]]$MinAgeDays,
  [Nullable[int]]$MaxAgeDays,
  [switch]$ParallelProbes,
  [switch]$ParallelHash,
  [ValidateRange(1,256)][int]$DopProbes,
  [ValidateRange(1,256)][int]$DopHash,
  [switch]$StdOut,
  [switch]$CompressOutput,
  [switch]$PreferCompressionSpeed,
  [switch]$EmitTimes,
  [switch]$NormalizeNames,
  [switch]$FindDuplicates,
  [ValidateRange(0,600)][int]$TimeoutSecPerProbe = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:IsWindowsPlatform = $true

# ==========================================================================================================================================

if (-not $StdOut -and ([System.Console]::IsOutputRedirected -or [System.Console]::IsErrorRedirected)) {
    Write-Verbose "La salida está redirigida."
}

# ==========================================================================================================================================

$ComputeHashes = $true

if (-not $PSBoundParameters.ContainsKey('DopProbes')) {
  $DopProbes = [math]::Max([int][math]::Ceiling($DegreeOfParallelism / 2.0), 1)
}

if (-not $PSBoundParameters.ContainsKey('DopHash')) {
  $DopHash = [math]::Max([int][math]::Ceiling($DegreeOfParallelism / 2.0), 1)
}

# ==========================================================================================================================================

try {
  $mods = if ($env:SYNAPTA_ROOT) {
    Join-Path $env:SYNAPTA_ROOT '.codex\02.- Datos del entorno\04.- Dependencias de herramientas\03.- Powershell\02.- Modules\03.- Aprobados'
  } else {
    # Fallback relativo al script (PSScriptRoot\..\..\..)
    $r = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    Join-Path $r '.codex\02.- Datos del entorno\04.- Dependencias de herramientas\03.- Powershell\02.- Modules\03.- Aprobados'
  }

  if (Test-Path -LiteralPath $mods) {
    $sep = [IO.Path]::PathSeparator
    if (-not (($env:PSModulePath -split [regex]::Escape($sep)) -contains $mods)) {
      $env:PSModulePath = "$mods$sep$env:PSModulePath"
    }
  }

  if (-not (Get-Command New-ZipFromFolder -ErrorAction SilentlyContinue)) {
    Import-Module System.IO.Compression.Tools -ErrorAction SilentlyContinue | Out-Null
  }
  if ($IsWindows -and -not (Get-Command Resize-Image -ErrorAction SilentlyContinue)) {
    Import-Module System.Drawing.Tools -ErrorAction SilentlyContinue | Out-Null
  }
}
catch {
  Write-Verbose "Inicialización de módulos opcionales: $($_.Exception.Message)"
}

# ==========================================================================================================================================


# ==============================================================================================================================
# Carga de módulos y utilidades
$projectRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $projectRoot 'Scripts'

. (Join-Path $scriptsRoot 'FileMapX.Native.ps1')
. (Join-Path $scriptsRoot 'FileMapX.Functions.ps1')

$script:Win32NativeAvailable = Initialize-NativeInterop -IsWindowsPlatform:$script:IsWindowsPlatform
# ==============================================================================================================================
# Preconteo por tamaño (evita hashear singletons)
$script:SizeCount = @{}
if (($ComputeHashes -or $FindDuplicates) -and (Test-Path -LiteralPath $RootPath)) {
  try {
    if ($script:Win32NativeAvailable) {
      foreach ($len in (Get-FileSizesFastWin32 -Root $RootPath)) {
        if ($script:SizeCount.ContainsKey($len)) { $script:SizeCount[$len] = [int64]$script:SizeCount[$len] + 1 }
        else { $script:SizeCount[$len] = 1 }
      }
    } else {
      Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $l = [int64]$_.Length
        if ($script:SizeCount.ContainsKey($l)) { $script:SizeCount[$l] = [int64]$script:SizeCount[$l] + 1 } else { $script:SizeCount[$l] = 1 }
      }
    }
  } catch { Write-Verbose "Preconteo por tamaño falló: $($_.Exception.Message)" }
}

$script:RunId = [guid]::NewGuid().ToString()
$script:StartedUtc = (Get-Date).ToUniversalTime()

# ==========================================================================================================================================

$script:IncludePatterns = if ($Include) {
  $Include | ForEach-Object { [Management.Automation.WildcardPattern]::new($_, 'IgnoreCase') }
} else {
  $null
}

# ==========================================================================================================================================

$script:ExcludePatterns = if ($Exclude) {
  $Exclude | ForEach-Object { [Management.Automation.WildcardPattern]::new($_, 'IgnoreCase') }
} else {
  $null
}

# ==========================================================================================================================================

$script:PathSplitPattern = '[\\/]'
$script:ReachedEntryLimit = $false
$script:EstimatedEntries = 0
$script:ProgressStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$script:LastProgressReportSeconds = 0.0
$script:JsonPartIndex = 0
$script:JsonBytesWritten = 0L
$script:JsonOutputPaths = [System.Collections.Generic.List[string]]::new()
$script:JsonBasePath = $null
$script:swJson = $null
$script:swTree = $null
$script:ErrorLogWriter = $null
$script:Cancelled = $false
$script:CancelSubscription = $null
$script:ExitCleanupSubscription = $null
$script:CategoryTotals = [System.Collections.Generic.Dictionary[string, hashtable]]::new([System.StringComparer]::OrdinalIgnoreCase)
$script:FilteredCount = 0L
$script:MinMBValue = if ($PSBoundParameters.ContainsKey('MinMB')) { [int]$MinMB } else { $null }
$script:MaxMBValue = if ($PSBoundParameters.ContainsKey('MaxMB')) { [int]$MaxMB } else { $null }
$script:MinAgeDaysValue = if ($PSBoundParameters.ContainsKey('MinAgeDays')) { [int]$MinAgeDays } else { $null }
$script:MaxAgeDaysValue = if ($PSBoundParameters.ContainsKey('MaxAgeDays')) { [int]$MaxAgeDays } else { $null }
$script:StdOutEnabled = [bool]$StdOut
$script:HashSemaphore = $null
$script:ProbeSemaphore = $null
$script:DuplicateGroupMap = if ($FindDuplicates) { [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new([System.StringComparer]::Ordinal) } else { $null }
$script:TimeoutSecPerProbeValue = $TimeoutSecPerProbe
$script:DupGroups = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[hashtable]]]::new([System.StringComparer]::Ordinal)
$script:DupGroupsReclaimable = 0L
$script:HashBytesTotal = 0L
$script:HashStopwatch = [System.Diagnostics.Stopwatch]::New()
$script:ProbeStopwatch = [System.Diagnostics.Stopwatch]::New()
$script:HashWaitTicks = 0L
$script:ProbeWaitTicks = 0L
$script:TimeoutsCount = 0
$script:ErrorsByOp = [System.Collections.Generic.Dictionary[string,int]]::new([System.StringComparer]::OrdinalIgnoreCase)
$script:JsonLogicalBytes = 0L
$script:SeenFileIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)


# ==========================================================================================================================================



if ($PSBoundParameters.Count -eq 0 -or -not $RootPath) {
  Prompt-Configuration
}

if (-not (Test-Path -LiteralPath $RootPath)) {
  throw "La ruta especificada no existe: $RootPath"
}
$rootItem = Get-Item -LiteralPath $RootPath -ErrorAction Stop
if (-not $rootItem.PSIsContainer) {
  throw "La ruta debe ser un directorio: $RootPath"
}
$rootFull = [System.IO.Path]::GetFullPath($RootPath)
$script:RootFull = $rootFull
$rootFullPrefix = if ($rootFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
  $rootFull
} else {
  $rootFull + [System.IO.Path]::DirectorySeparatorChar
}

if ($Mode -eq 'Automatico') {
  Apply-AutomaticConfigurationV2 -Root $RootPath
}
else {
  Apply-CompleteConfiguration
}

if ($script:HashSemaphore) {
  try { $script:HashSemaphore.Dispose() } catch {}
}
if ($script:ProbeSemaphore) {
  try { $script:ProbeSemaphore.Dispose() } catch {}
}
$script:HashSemaphore = if ($ParallelHash) { [System.Threading.SemaphoreSlim]::new($DopHash, $DopHash) } else { $null }
$script:ProbeSemaphore = if ($ParallelProbes) { [System.Threading.SemaphoreSlim]::new($DopProbes, $DopProbes) } else { $null }

# ==========================================================================================================================================

Test-OutputDirHealth -Dir $OutputDir -MinFreeMB 200
$OutputDirFull = [System.IO.Path]::GetFullPath($OutputDir)
$script:OutputDirFull = $OutputDirFull
$script:OutputDirPrefix = if ($OutputDirFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
  $OutputDirFull
} else {
  $OutputDirFull + [System.IO.Path]::DirectorySeparatorChar
}
$script:OutputDirExclusionActive = (
  $OutputDirFull.StartsWith($rootFullPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
  -not $OutputDirFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)
)
$script:ExcludedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$rootName = Split-Path -Path $RootPath -Leaf
if ([string]::IsNullOrWhiteSpace($rootName)) { $rootName = ($RootPath -replace '[:\\\/]', '_') }
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')
$baseName = ("{0}_{1}" -f ($rootName -replace '[^\w\.-]', '_'), $timestamp)
$treeFile = Join-Path $OutputDir ("FileMap_{0}.{1}" -f $baseName, $OutputKind)
$jsonFile = Join-Path $OutputDir ("FileList_{0}.jsonl" -f $baseName)

if ($EmitTree) {
  $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($treeFile)) | Out-Null
}
if ($EmitJsonl -and -not $StdOut) {
  $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($jsonFile)) | Out-Null
}
if ($ErrorLog) {
  $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($ErrorLog)) | Out-Null
}

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:swTree = $null
if ($EmitTree -and $PSCmdlet.ShouldProcess($treeFile, 'Crear archivo de árbol')) {
  $fsTree = [System.IO.FileStream]::new(
    $treeFile,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::Read,
    1048576,
    [System.IO.FileOptions]::SequentialScan
  )
  $script:swTree = [System.IO.StreamWriter]::new($fsTree, $script:Utf8NoBom, 1048576, $false)
}
if ($EmitJsonl) {
  if ($StdOut) {
    $script:JsonBasePath = $jsonFile
    $script:JsonOutputPaths.Add('stdout') | Out-Null
  }
  elseif ($PSCmdlet.ShouldProcess($jsonFile, 'Crear archivo JSONL')) {
    $script:JsonBasePath = $jsonFile
    Open-JsonWriter -PathBase $jsonFile
  }
}
if ($ErrorLog) {
  $errorDir = Split-Path -Parent $ErrorLog
  if ($errorDir -and -not (Test-Path -LiteralPath $errorDir)) {
    [void][System.IO.Directory]::CreateDirectory($errorDir)
  }
  $fsErr = [System.IO.FileStream]::new(
    $ErrorLog,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::Read,
    65536,
    [System.IO.FileOptions]::SequentialScan
  )
  $script:ErrorLogWriter = [System.IO.StreamWriter]::new($fsErr, $script:Utf8NoBom, 65536, $false)
}

try {
  $script:CancelSubscription = Register-EngineEvent -SourceIdentifier ConsoleCancel -Action {
    param($sender, $eventArgs)
    $eventArgs.Cancel = $true
    $ExecutionContext.SessionState.PSVariable.Set('Cancelled', $true)
  }
}
catch {
  Write-Verbose "Register ConsoleCancel: $($_.Exception.Message)"
}

try {
  $script:ExitCleanupSubscription = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    param($sender, $eventArgs)
    try {
      $session = $ExecutionContext.SessionState
      foreach ($name in @('swJson','swTree','ErrorLogWriter')) {
        $writer = $session.PSVariable.GetValue($name)
        if ($writer) {
          try { $writer.Flush(); $writer.Dispose() }
          catch {}
        }
      }
    }
    catch {}
  }
}
catch {
  Write-Verbose "Register PowerShell.Exiting: $($_.Exception.Message)"
}

# ==========================================================================================================================================

function Write-JsonLine {
  param([hashtable]$Object)
  if (-not $EmitJsonl) { return }
  $line = $null
  if ($StrictJson) {
    $payload = ConvertTo-JsonCompatible $Object
    $payloadType = if ($payload) { $payload.GetType() } else { [object] }
    $line = [System.Text.Json.JsonSerializer]::Serialize($payload, $payloadType)
  }
  else {
    $pairs = @()
    foreach ($key in $Object.Keys) {
      $escapedKey = $key -replace '"','\"'
      $pairs += "`"$escapedKey`":$(JsonPrimitive $Object[$key])"
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

# ==========================================================================================================================================

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
  $dirs = $childLists.Dirs
  $files = $childLists.Files

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
          return [pscustomobject]@{ Path = $filePath; Record = $null; ErrorMessage = $_.Exception.Message; ErrorHResult = $_.Exception.HResult }
        }
      } -ThrottleLimit $DegreeOfParallelism

      foreach ($entry in $results) {
        if ($null -eq $entry) { continue }

        $entryPath = $null
        if ($entry -is [hashtable]) {
          if ($entry.ContainsKey('Path')) { $entryPath = [string]$entry['Path'] }
        }
        elseif ($entry.PSObject -and $entry.PSObject.Properties.Match('Path').Count -gt 0) {
          $entryPath = [string]$entry.Path
        }
        if (-not $entryPath -and ($entry -is [System.Collections.IEnumerable]) -and -not ($entry -is [string])) {
          foreach ($item in $entry) {
            if ($item -is [hashtable] -and $item.ContainsKey('Path')) { $entryPath = [string]$item['Path']; break }
            if ($item.PSObject -and $item.PSObject.Properties.Match('Path').Count -gt 0) { $entryPath = [string]$item.Path; break }
          }
        }

        $resolvedRecord = Get-RecordFromResult -Result $entry
        if ($resolvedRecord) {
          if ($entryPath) { $parallelRecords[$entryPath] = $resolvedRecord }
          else { $parallelRecords[[guid]::NewGuid().ToString()] = $resolvedRecord }
          continue
        }

        if ($entry.PSObject -and $entry.PSObject.Properties.Match('ErrorMessage').Count -gt 0) {
          Write-ErrorJson -Op 'ParallelFile' -Path $entryPath -Context 'New-FileRecord' -IsParallel:$true -Message $entry.ErrorMessage -HResult $entry.ErrorHResult
          continue
        }

        $entryType = $entry.GetType().FullName
        Write-Verbose "Parallel: objeto devuelto sin propiedad Record para '$entryPath' (tipo $entryType)"
        Write-ErrorJson -Op 'ParallelFileShape' -Path $entryPath -Context 'New-FileRecord' -Message ("Objeto sin propiedad Record devuelto en ejecución paralela (tipo {0})" -f $entryType) -IsParallel:$true
      }
    }
  }

  if ($EmitJsonl) {
    $rel = Get-RelativePath -Base $RootPath -Full $Directory.FullName
    $name = $Directory.Name
    $obj = [ordered]@{
      relpath      = if ($rel) { $rel } else { '.' }
      type         = 'dir'
      name         = $name
      ext          = ''
      size_bytes   = 0
      mtime_iso    = $Directory.LastWriteTimeUtc.ToString('o')
      depth        = $Depth
      attributes   = $Directory.Attributes.ToString().Replace(', ', '|')
      top_segment  = if ($rel -match $script:PathSplitPattern) { ($rel -split $script:PathSplitPattern)[0] } else { $rel }
      path_len     = ($rel).Length
      has_non_ascii= Has-NonAscii $name
    }
    if ($EmitTimes) {
      $obj.ctime_iso = $Directory.CreationTimeUtc.ToString('o')
      $obj.atime_iso = $Directory.LastAccessTimeUtc.ToString('o')
    }
    if ($NormalizeNames) {
      $normalizedDir = $name.Normalize([System.Text.NormalizationForm]::FormC)
      $obj.name_norm_nfc = $normalizedDir
      $obj.has_unicode_norm_delta = ($normalizedDir -ne $name)
    }
    if ($EmitSummaries) {
      $obj.child_files = $files.Count
      $obj.child_dirs  = $dirs.Count
      $obj.child_bytes = $summaryBytes
    }
    Write-JsonLine -Object $obj
  }

  if ($MaxDepth -gt 0 -and $Depth -ge $MaxDepth) {
    return
  }

  $children = @()
  foreach ($dir in $dirs) { $children += [pscustomobject]@{ Kind = 'Dir'; Info = $dir } }
  foreach ($file in $files) { $children += [pscustomobject]@{ Kind = 'File'; Info = $file } }
  $count = $children.Count

  for ($index = 0; $index -lt $count; $index++) {
    if ($script:ReachedEntryLimit -or $script:Cancelled) { break }
    $child = $children[$index]
    $isLast = ($index -eq $count - 1)
    $indentBuilder = New-Object System.Text.StringBuilder
    foreach ($hasMore in $AncestorHasMore) {
      if ($hasMore) { [void]$indentBuilder.Append($glyphs.Pipe) }
      else { [void]$indentBuilder.Append($glyphs.Space) }
    }
    $indent = $indentBuilder.ToString()
    $branch = if ($isLast) { $glyphs.Elbow } else { $glyphs.Tee }

    if ($child.Kind -eq 'Dir') {
      $script:DirCount++
      $script:EntryCounter++
      $dirEntry = $child.Info
      $dirInfo = if ($dirEntry -is [System.IO.DirectoryInfo]) { $dirEntry } else { [System.IO.DirectoryInfo]::new($dirEntry.FullName) }
      $dirName = if ($dirEntry.PSObject.Properties['Name']) { [string]$dirEntry.Name } else { $dirInfo.Name }
      $dirMTimeUtc = if ($dirEntry.PSObject.Properties['LastWriteTimeUtc']) { [datetime]$dirEntry.LastWriteTimeUtc } else { $dirInfo.LastWriteTimeUtc.ToUniversalTime() }
      $meta = if ($ShowDates) { " (mod: {0:yyyy-MM-dd HH:mm} UTC)" -f $dirMTimeUtc } else { '' }
      if ($script:swTree) {
        $script:swTree.WriteLine(($indent + $branch + '[DIR] ' + $dirName + $meta))
      }
      if (($script:EntryCounter % $ProgressInterval) -eq 0) { Write-ProgressSafe -Activity 'Generando FileMap' }
      if ($script:EntryCounter -ge $MaxEntries) { $script:ReachedEntryLimit = $true }
      $nextAncestors = $AncestorHasMore + @(-not $isLast)
      $prefetch = Get-ChildLists -Directory $dirInfo -IncludeHidden ([bool]$IncludeHidden)
      if (-not $script:ReachedEntryLimit -and -not $script:Cancelled) {
        Write-DirectoryEntry -Directory $dirInfo -Depth ($Depth + 1) -AncestorHasMore $nextAncestors -Prefetched $prefetch
      }
    }
    else {
      $fileEntry = $child.Info
      $fullName = if ($fileEntry.PSObject.Properties['FullName']) { [string]$fileEntry.FullName } else { [string]$fileEntry.FullName }
      $fileInfoCache = $null
      $attributes = if ($fileEntry.PSObject.Properties['Attributes']) { [System.IO.FileAttributes]$fileEntry.Attributes } else {
        $fileInfoCache = [System.IO.FileInfo]::new($fullName)
        $fileInfoCache.Attributes
      }
      if ($attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) { continue }
      $includeForJson = if ($EmitJsonl) { $false } else { $true }
      if ($EmitJsonl -and $inclusionMap.ContainsKey($fullName)) { $includeForJson = $inclusionMap[$fullName] }
      $script:FileCount++
      $script:EntryCounter++
      $metaParts = @()
      $lengthValue = if ($fileEntry.PSObject.Properties['Length']) { [int64]$fileEntry.Length } else {
        if (-not $fileInfoCache) { $fileInfoCache = [System.IO.FileInfo]::new($fullName) }
        [int64]$fileInfoCache.Length
      }
      $mtimeUtc = if ($fileEntry.PSObject.Properties['LastWriteTimeUtc']) { [datetime]$fileEntry.LastWriteTimeUtc } else {
        if (-not $fileInfoCache) { $fileInfoCache = [System.IO.FileInfo]::new($fullName) }
        $fileInfoCache.LastWriteTimeUtc.ToUniversalTime()
      }
      $fileName = if ($fileEntry.PSObject.Properties['Name']) { [string]$fileEntry.Name } else { [System.IO.Path]::GetFileName($fullName) }
      if ($ShowSizes) {
        $script:TotalBytes += $lengthValue
        $metaParts += (Format-Size $lengthValue)
      }
      if ($ShowDates) { $metaParts += ("mod: {0:yyyy-MM-dd HH:mm} UTC" -f $mtimeUtc) }
      $meta = if ($metaParts.Count -gt 0) { ' - ' + ($metaParts -join ' | ') } else { '' }
      if ($script:swTree) {
        $script:swTree.WriteLine($indent + $branch + $fileName + $meta)
      }
      if ($EmitJsonl -and $includeForJson) {
        $jsonRecord = $null
        if ($parallelRecords -and $parallelRecords.ContainsKey($fullName)) {
          $jsonRecord = $parallelRecords[$fullName]
        }
        else {
          $result = New-FileRecord -FileEntry $fileEntry -FileInfoFallback $fileInfoCache -Depth $Depth -StartedUtc $script:StartedUtc -RootPath $RootPath -PathSplitPattern $script:PathSplitPattern -Classify:$Classify -DetectExecutables:$DetectExecutables -ProbeText:$ProbeText -ProbeTextMaxMB $ProbeTextMaxMB -ComputeHashes:$ComputeHashes -MaxHashMB $MaxHashMB -ProbeDocs:$ProbeDocs -ProbeArchives:$ProbeArchives -ZipListEntries $ZipListEntries -LargeFileMB $LargeFileMB -TextExtensions $TextExts -BinaryExtensions $BinaryExts -HashSemaphore $script:HashSemaphore -ProbeSemaphore $script:ProbeSemaphore -EmitTimes:$EmitTimes -NormalizeNames:$NormalizeNames -FindDuplicates:$FindDuplicates -DuplicateGroupMap $script:DuplicateGroupMap -TimeoutSecPerProbe $script:TimeoutSecPerProbeValue
          if ($result) {
            $jsonRecord = Get-RecordFromResult -Result $result
            if (-not $jsonRecord) {
              $resultType = $result.GetType().FullName
              Write-Verbose "Write-DirectoryEntry: objeto devuelto sin propiedad Record para '$fullName' (tipo $resultType)"
              Write-ErrorJson -Op 'FileRecordShape' -Path $fullName -Context 'Write-DirectoryEntry' -Message ("Objeto sin propiedad Record devuelto por New-FileRecord (tipo {0})" -f $resultType) -IsParallel:$false
            }
          }
        }
        if ($ProbeText -and $script:EntryCounter -gt 25000) {
          $Script:ProbeText = $false
          Write-Host 'AutoTune: desactivado ProbeText por volumen (> 25,000 entradas)' -ForegroundColor Yellow
        }
        if ($jsonRecord) {
          if (-not $parallelRecords) {
            $parallelRecords = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::OrdinalIgnoreCase)
          }
          $parallelRecords[$fullName] = $jsonRecord
          Write-JsonLine -Object $jsonRecord
        }
      }
      if ($EmitJsonl -and $includeForJson -and $jsonRecord) {
        Update-CategoryTotals -Category ($jsonRecord.category) -Bytes ($jsonRecord.size_bytes)
      }
      if (($script:EntryCounter % $ProgressInterval) -eq 0) { Write-ProgressSafe -Activity 'Generando FileMap' }
      if ($script:EntryCounter -ge $MaxEntries) { $script:ReachedEntryLimit = $true }
    }
    if ($script:Cancelled) { break }
  }
}

# ==========================================================================================================================================

try {
  if ($script:swTree) {
    if ($OutputKind -eq 'md') {
      $script:swTree.WriteLine("# FileMap - $RootPath")
      $script:swTree.WriteLine()
      $headerTimestamp = (Get-Date).ToUniversalTime().ToString('o')
      $headerLine = "Generado: $headerTimestamp | Equipo: $env:COMPUTERNAME | PowerShell: $($PSVersionTable.PSVersion)"
      $script:swTree.WriteLine($headerLine)
      $script:swTree.WriteLine()
      $script:swTree.WriteLine('```')
    }
    else {
      $script:swTree.WriteLine("FileMap - $RootPath")
      $headerTimestamp = (Get-Date).ToUniversalTime().ToString('o')
      $headerLine = "Generado: $headerTimestamp | Equipo: $env:COMPUTERNAME | PowerShell: $($PSVersionTable.PSVersion)"
      $script:swTree.WriteLine($headerLine)
      $script:swTree.WriteLine()
    }
  }

# ==========================================================================================================================================

  $rootMeta = if ($ShowDates) { "  (mod: {0:yyyy-MM-dd HH:mm} UTC)" -f $rootItem.LastWriteTimeUtc } else { '' }
  if ($script:swTree) {
    $script:swTree.WriteLine($glyphs.Root + '[DIR] ' + $RootPath + $rootMeta)
  }
  $script:DirCount++

  if ($EmitJsonl) {
    $rootRel = Get-RelativePath -Base $RootPath -Full $RootPath
    $rootSummary = Get-ChildLists -Directory ([System.IO.DirectoryInfo]$rootItem) -IncludeHidden ([bool]$IncludeHidden)
    $rootBytes = 0L
    foreach ($f in $rootSummary.Files) { $rootBytes += $f.Length }
    $rootObj = [ordered]@{
      relpath      = '.'
      type         = 'dir'
      name         = $rootItem.Name
      ext          = ''
      size_bytes   = 0
      mtime_iso    = $rootItem.LastWriteTimeUtc.ToString('o')
      depth        = 0
      attributes   = $rootItem.Attributes.ToString().Replace(', ', '|')
      top_segment  = '.'
      path_len     = 1
      has_non_ascii= Has-NonAscii $rootItem.Name
    }
    if ($EmitTimes) {
      $rootObj.ctime_iso = $rootItem.CreationTimeUtc.ToString('o')
      $rootObj.atime_iso = $rootItem.LastAccessTimeUtc.ToString('o')
    }
    if ($NormalizeNames) {
      $normalizedRoot = $rootItem.Name.Normalize([System.Text.NormalizationForm]::FormC)
      $rootObj.name_norm_nfc = $normalizedRoot
      $rootObj.has_unicode_norm_delta = ($normalizedRoot -ne $rootItem.Name)
    }
    if ($EmitSummaries) {
      $rootObj.child_files = $rootSummary.Files.Count
      $rootObj.child_dirs  = $rootSummary.Dirs.Count
      $rootObj.child_bytes = $rootBytes
    }
    Write-JsonLine -Object $rootObj
    Write-DirectoryEntry -Directory ([System.IO.DirectoryInfo]$rootItem) -Depth 0 -AncestorHasMore @() -Prefetched $rootSummary
  }
  else {
    Write-DirectoryEntry -Directory ([System.IO.DirectoryInfo]$rootItem) -Depth 0 -AncestorHasMore @()
  }

  if ($script:swTree) {
    if ($OutputKind -eq 'md') {
      $script:swTree.WriteLine('```')
      $script:swTree.WriteLine()
    }
    $summaryText = if ($ShowSizes) { ', total archivos: ' + (Format-Size $script:TotalBytes) } else { '' }
    $dirText = $script:DirCount.ToString('N0')
    $fileText = $script:FileCount.ToString('N0')
    $script:swTree.WriteLine("Resumen: $dirText directorios, $fileText archivos$summaryText.")
    if ($EmitSummaries -and $script:CategoryTotals.Count -gt 0) {
      $script:swTree.WriteLine()
      $script:swTree.WriteLine('| Categoria | Archivos | Bytes |')
      $script:swTree.WriteLine('|-----------|----------|-------|')
      foreach ($kv in ($script:CategoryTotals.GetEnumerator() | Sort-Object Key)) {
        $cat = $kv.Key
        $files = [long]$kv.Value.files
        $bytes = [long]$kv.Value.bytes
        $script:swTree.WriteLine("| $cat | $files | $(Format-Size $bytes) |")
      }
    }
    Write-Host ("✔ FileMap generado en: {0}" -f $treeFile)
  }
  if ($script:swJson) {
    $endedUtc = (Get-Date).ToUniversalTime()
    $plan = [ordered]@{
      ShowSizes        = [bool]$ShowSizes
      ShowDates        = [bool]$ShowDates
      Classify         = [bool]$Classify
      DetectExecutables= [bool]$DetectExecutables
      ComputeHashes    = [bool]$ComputeHashes
      ProbeDocs        = [bool]$ProbeDocs
      ProbeArchives    = [bool]$ProbeArchives
      ProbeText        = [bool]$ProbeText
      EmitSummaries    = [bool]$EmitSummaries
      ProgressInterval = $ProgressInterval
      EmitTree         = [bool]$EmitTree
      EmitJsonl        = [bool]$EmitJsonl
      IncludeHidden    = [bool]$IncludeHidden
      StrictJson       = [bool]$StrictJson
      ZipListEntries   = $ZipListEntries
      MaxHashMB        = $MaxHashMB
      LargeFileMB      = $LargeFileMB
      ProbeTextMaxMB   = $ProbeTextMaxMB
      OutputMaxMB      = $OutputMaxMB
      Parallel         = [bool]$Parallel
      ParallelHash     = [bool]$ParallelHash
      ParallelProbes   = [bool]$ParallelProbes
      DegreeOfParallelism = $DegreeOfParallelism
      DopHash          = $DopHash
      DopProbes        = $DopProbes
      StdOut           = [bool]$StdOut
      CompressOutput   = [bool]$CompressOutput
      EmitTimes        = [bool]$EmitTimes
      NormalizeNames   = [bool]$NormalizeNames
      FindDuplicates   = [bool]$FindDuplicates
      TimeoutSecPerProbe = $TimeoutSecPerProbe
      MinMB            = $script:MinMBValue
      MaxMB            = $script:MaxMBValue
      MinAgeDays       = $script:MinAgeDaysValue
      MaxAgeDays       = $script:MaxAgeDaysValue
    }
    $totals = [ordered]@{}
    foreach ($kv in ($script:CategoryTotals.GetEnumerator() | Sort-Object Key)) {
      $totals[$kv.Key] = [ordered]@{ files = [long]$kv.Value.files; bytes = [long]$kv.Value.bytes }
    }
    $elapsedSeconds = if ($script:ProgressStopwatch) { $script:ProgressStopwatch.Elapsed.TotalSeconds } else { 0 }
    $entriesPerSec = if ($elapsedSeconds -gt 0) { [double]$script:EntryCounter / $elapsedSeconds } else { 0.0 }
    $bytesPerSec = if ($elapsedSeconds -gt 0) { [double]$script:TotalBytes / $elapsedSeconds } else { 0.0 }
    $hashElapsedSeconds = if ($script:HashStopwatch) { $script:HashStopwatch.Elapsed.TotalSeconds } else { 0 }
    $hashThroughputMBs = if ($hashElapsedSeconds -gt 0) { ([double]$script:HashBytesTotal / 1MB) / $hashElapsedSeconds } else { 0.0 }
    $hashWaitMs = [TimeSpan]::FromTicks([long]$script:HashWaitTicks).TotalMilliseconds
    $probeElapsedSeconds = if ($script:ProbeStopwatch) { $script:ProbeStopwatch.Elapsed.TotalSeconds } else { 0 }
    $probeWaitMs = [TimeSpan]::FromTicks([long]$script:ProbeWaitTicks).TotalMilliseconds
    $dupStats = Compute-DupReclaimable
    $driveKind = Get-DriveKind -RootPath $RootPath
    $physicalBytes = 0L
    if ($CompressOutput -and -not $script:StdOutEnabled) {
      foreach ($jsonPath in $script:JsonOutputPaths) {
        if ($jsonPath -and $jsonPath -ne 'stdout' -and (Test-Path -LiteralPath $jsonPath)) {
          $physicalBytes += (Get-Item -LiteralPath $jsonPath).Length
        }
      }
    }
    $compressionRatio = $null
    if ($CompressOutput -and $script:JsonLogicalBytes -gt 0 -and $physicalBytes -gt 0) {
      $compressionRatio = [Math]::Round(($script:JsonLogicalBytes / [double]$physicalBytes), 3)
    }
    $ioMetrics = [ordered]@{
      bytes_per_sec   = [math]::Round($bytesPerSec, 6)
      entries_per_sec = [math]::Round($entriesPerSec, 6)
      elapsed_sec     = [math]::Round($elapsedSeconds, 3)
    }
    $ioMetrics.hash = [ordered]@{
      mb_per_sec = [math]::Round($hashThroughputMBs, 6)
      time_sec   = [math]::Round($hashElapsedSeconds, 3)
      wait_ms    = [math]::Round($hashWaitMs, 1)
    }
    $ioMetrics.probe = [ordered]@{
      time_sec = [math]::Round($probeElapsedSeconds, 3)
      wait_ms  = [math]::Round($probeWaitMs, 1)
      timeouts = $script:TimeoutsCount
    }
    $outputMetrics = [ordered]@{ logical_bytes = [int64]$script:JsonLogicalBytes }
    if ($physicalBytes -gt 0) { $outputMetrics.physical_bytes = [int64]$physicalBytes }
    if ($null -ne $compressionRatio) { $outputMetrics.compression_ratio = $compressionRatio }
    $errorsOrdered = [ordered]@{}
    foreach ($kv in ($script:ErrorsByOp.GetEnumerator() | Sort-Object Key)) {
      $errorsOrdered[$kv.Key] = [int]$kv.Value
    }
    $meta = [ordered]@{
      type             = 'run_meta'
      run_id           = $script:RunId
      schema_version   = '1.0'
      started_utc      = $script:StartedUtc.ToString('o')
      ended_utc        = $endedUtc.ToString('o')
      root             = $rootFull
      output_dir       = $OutputDirFull
      mode             = $Mode
      output_kind      = $OutputKind
      include_hidden   = [bool]$IncludeHidden
      dirs             = $script:DirCount
      files            = $script:FileCount
      entries_emitted  = $script:EntryCounter
      total_bytes      = $script:TotalBytes
      truncated        = $script:ReachedEntryLimit
      cancelled        = [bool]$script:Cancelled
      max_depth        = $MaxDepth
      estimated_entries= $script:EstimatedEntries
      include_patterns = $Include
      exclude_patterns = $Exclude
      max_entries      = $MaxEntries
      filtered_files   = $script:FilteredCount
      jsonl_paths      = $script:JsonOutputPaths.ToArray()
      error_log        = $ErrorLog
      plan             = $plan
      io               = $ioMetrics
      host             = [ordered]@{ drive_kind = $driveKind }
      output           = $outputMetrics
      dups             = [ordered]@{ groups = [int]$dupStats.dup_groups; reclaimable_bytes = [int64]$dupStats.reclaimable_bytes }
    }
    if ($totals.Count -gt 0) { $meta.totals = $totals }
    if ($errorsOrdered.Count -gt 0) { $meta.errors = $errorsOrdered }
    Write-JsonLine -Object $meta
    if ($script:JsonOutputPaths.Count -le 1) {
      Write-Host ("✔ JSONL generado en:   {0}" -f ($script:JsonOutputPaths[0]))
    }
    else {
      Write-Host '✔ JSONL generados:'
      foreach ($path in $script:JsonOutputPaths) { Write-Host ("   {0}" -f $path) }
    }
    if ($script:ReachedEntryLimit) {
      Write-Warning ("Se alcanzó el límite MaxEntries ({0}); la enumeración se detuvo temprano." -f $MaxEntries)
    }
  }
}
catch {
  Write-Error ("Error durante la generación: $($_.Exception.Message)")
  throw
}
finally {
  foreach ($writer in @($script:swTree, $script:swJson, $script:ErrorLogWriter)) {
    if ($writer) {
      try { $writer.Flush(); $writer.Dispose() }
      catch {
        Write-Verbose "Dispose writer: $($_.Exception.Message)"
      }
    }
  }
  if ($script:CancelSubscription) {
    try { Unregister-Event -SubscriptionId $script:CancelSubscription.Id }
    catch {}
    $script:CancelSubscription = $null
  }
  if ($script:ExitCleanupSubscription) {
    try { Unregister-Event -SubscriptionId $script:ExitCleanupSubscription.Id }
    catch {}
    $script:ExitCleanupSubscription = $null
  }
  Write-ProgressSafe -Activity 'Generando FileMap' -Completed
}

if ($script:swTree) { "OUTPUT => $treeFile" }
if ($EmitJsonl -and $script:JsonOutputPaths.Count -gt 0) {
  foreach ($path in $script:JsonOutputPaths) { "OUTPUT => $path" }
}

$finalExitCode = if ($script:Cancelled -or $script:ReachedEntryLimit) { 1 } else { 0 }
exit $finalExitCode

# ==========================================================================================================================================
