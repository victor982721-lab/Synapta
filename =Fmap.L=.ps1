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

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
  [string]$RootPath,
  [ValidateSet('md','txt')][string]$OutputKind = 'md',
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
  [switch]$NoProgress,
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

$script:IsWindowsPlatform = $false
try {
  if ($PSVersionTable.Platform -eq 'Win32NT') {
    $script:IsWindowsPlatform = $true
  }
  elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    $script:IsWindowsPlatform = $true
  }
}
catch {
  Write-Verbose "Determinación de plataforma falló: $($_.Exception.Message)"
}

if ($StdOut) {
  $EmitJsonl = $true
  $StrictJson = $true
  $NoProgress = $true
}

try {
  if (-not $StdOut -and -not $NoProgress) {
    if ([System.Console]::IsOutputRedirected -or [System.Console]::IsErrorRedirected) {
      $NoProgress = $true
    }
  }
}
catch {
  Write-Verbose "Detección de TTY falló: $($_.Exception.Message)"
}

if ($StdOut -and $CompressOutput) {
  Write-Warning '-CompressOutput no aplica con -StdOut; emitiendo datos sin comprimir hacia el pipeline.'
  $CompressOutput = $false
}

if (-not $PSBoundParameters.ContainsKey('DopProbes')) {
  $DopProbes = [math]::Max([int][math]::Ceiling($DegreeOfParallelism / 2.0), 1)
}

if (-not $PSBoundParameters.ContainsKey('DopHash')) {
  $DopHash = [math]::Max([int][math]::Ceiling($DegreeOfParallelism / 2.0), 1)
}

if ($FindDuplicates -and -not $ComputeHashes) {
  $ComputeHashes = $true
}

try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue | Out-Null
  Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null
}
catch {
  Write-Verbose "Inicialización de ensamblados opcionales: $($_.Exception.Message)"
  # Dependencias opcionales; continuamos sin bloquear la ejecución en entornos sin soporte (ej. Linux/macOS).
}

if ($script:IsWindowsPlatform -and -not ('Native.Win32' -as [type])) {
  try {
    Add-Type -Language CSharp -Namespace Native -Name Win32 -MemberDefinition @"
using System;
using System.Runtime.InteropServices;

namespace Native {
  public static class Win32 {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FILETIME {
      public uint dwLowDateTime;
      public uint dwHighDateTime;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WIN32_FIND_DATAW {
      public uint dwFileAttributes;
      public FILETIME ftCreationTime;
      public FILETIME ftLastAccessTime;
      public FILETIME ftLastWriteTime;
      public uint nFileSizeHigh;
      public uint nFileSizeLow;
      public uint dwReserved0;
      public uint dwReserved1;
      [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
      public string cFileName;
      [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
      public string cAlternateFileName;
    }

    public enum FINDEX_INFO_LEVELS : int {
      FindExInfoStandard = 0,
      FindExInfoBasic = 1
    }

    public enum FINDEX_SEARCH_OPS : int {
      FindExSearchNameMatch = 0
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr FindFirstFileExW(
      string lpFileName,
      FINDEX_INFO_LEVELS fInfoLevelId,
      out WIN32_FIND_DATAW lpFindFileData,
      FINDEX_SEARCH_OPS fSearchOp,
      IntPtr lpSearchFilter,
      int dwAdditionalFlags
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool FindNextFileW(IntPtr hFindFile, out WIN32_FIND_DATAW lpFindFileData);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool FindClose(IntPtr hFindFile);

    public const int FIND_FIRST_EX_LARGE_FETCH = 0x00000002;

    public const uint FILE_ATTRIBUTE_DIRECTORY = 0x10;
    public const uint FILE_ATTRIBUTE_REPARSE_POINT = 0x400;
    public const uint FILE_ATTRIBUTE_HIDDEN = 0x2;
    public const uint FILE_ATTRIBUTE_SYSTEM = 0x4;
  }
}

"@
    if (-not ('Native.FileId' -as [type])) {
      Add-Type -Language CSharp -Namespace Native -Name FileId -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace Native {
  public static class FileId {
    [StructLayout(LayoutKind.Sequential)]
    public struct BY_HANDLE_FILE_INFORMATION {
      public uint dwFileAttributes;
      public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
      public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
      public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
      public uint dwVolumeSerialNumber;
      public uint nFileSizeHigh;
      public uint nFileSizeLow;
      public uint nNumberOfLinks;
      public uint nFileIndexHigh;
      public uint nFileIndexLow;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr securityAttributes, uint creationDisposition, uint flags, IntPtr templateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetFileInformationByHandle(SafeFileHandle hFile, out BY_HANDLE_FILE_INFORMATION lpFileInformation);

    public const uint FILE_SHARE_READ = 1;
    public const uint FILE_SHARE_WRITE = 2;
    public const uint FILE_SHARE_DELETE = 4;
    public const uint FILE_READ_ATTRIBUTES = 0x80;
    public const uint OPEN_EXISTING = 3;
    public const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
  }
}
"@
    }
  }
  catch {
    Write-Verbose "Inicialización Win32 nativa falló: $($_.Exception.Message)"
  }
}

$script:Win32NativeAvailable = $script:IsWindowsPlatform -and ('Native.Win32' -as [type])

$script:RunId = [guid]::NewGuid().ToString()
$script:StartedUtc = (Get-Date).ToUniversalTime()
$script:IncludePatterns = if ($Include) {
  $Include | ForEach-Object { [Management.Automation.WildcardPattern]::new($_, 'IgnoreCase') }
} else {
  $null
}
$script:ExcludePatterns = if ($Exclude) {
  $Exclude | ForEach-Object { [Management.Automation.WildcardPattern]::new($_, 'IgnoreCase') }
} else {
  $null
}
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
# region Utilidades generales
function Format-Size {
  param([long]$Bytes)
  switch ($Bytes) {
    { $_ -lt 1KB } { return "{0} B" -f $Bytes }
    { $_ -lt 1MB } { return "{0:N2} KB" -f ($Bytes / 1KB) }
    { $_ -lt 1GB } { return "{0:N2} MB" -f ($Bytes / 1MB) }
    default        { return "{0:N2} GB" -f ($Bytes / 1GB) }
  }
}

function Has-NonAscii {
  param([string]$s)
  if ([string]::IsNullOrEmpty($s)) { return $false }
  -not ([regex]::IsMatch($s, '^[\u0020-\u007E]+$'))
}

function Is-ReparsePoint {
  param([System.IO.FileSystemInfo]$Info)
  $Info.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)
}

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

function Add-ToDupGroups {
  param([hashtable]$Rec)
  if (-not $Rec) { return }
  if (-not $Rec.ContainsKey('hash_sha256')) { return }
  $hashValue = $Rec.hash_sha256
  if ([string]::IsNullOrWhiteSpace($hashValue)) { return }
  if (-not $Rec.ContainsKey('size_bytes')) { return }
  $size = [int64]$Rec.size_bytes
  $key = "{0}-{1}" -f $size, $hashValue
  if (-not $script:DupGroups.ContainsKey($key)) {
    $script:DupGroups[$key] = [System.Collections.Generic.List[hashtable]]::new()
  }
  $script:DupGroups[$key].Add($Rec) | Out-Null
}

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

function Bump-Error {
  param([string]$Op)
  if ([string]::IsNullOrWhiteSpace($Op)) { return }
  if (-not $script:ErrorsByOp.ContainsKey($Op)) {
    $script:ErrorsByOp[$Op] = 0
  }
  $script:ErrorsByOp[$Op] = $script:ErrorsByOp[$Op] + 1
}

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


function New-FileRecord {
  param(
    [object]$FileEntry,
    [System.IO.FileInfo]$FileInfoFallback,
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
  elseif ($FileInfoFallback) { $FileInfoFallback }
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

  $shouldHash = ($ComputeHashes -or $FindDuplicates)
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
        $hashValue = Get-Sha256Safe -Path $fullPath -Size $length -MaxMB $MaxHashMB
      }
      finally {
        $script:HashStopwatch.Stop()
      }
    }
    finally {
      if ($HashSemaphore) { $HashSemaphore.Release() }
    }
    if ($hashValue) {
      if ($ComputeHashes -or $FindDuplicates) { $record.hash_sha256 = $hashValue }
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
# endregion

# region Tablas de clasificación
$TextExts = @('txt','text','md','markdown','json','csv','ts','js','jsx','tsx','css','scss','less','html','htm','xml','xhtml','yml','yaml','toml','ini','cfg','conf','log','ps1','psm1','psd1','bat','cmd','sh','java','py','cs','cpp','c','h','hpp','rs','go','kt','rb','php','sql','svg')
$BinaryExts = @('pdf','jpg','jpeg','png','gif','bmp','tif','tiff','webp','ico','zip','7z','rar','gz','bz2','xz','tar','doc','docx','xls','xlsx','ppt','pptx','rtf','exe','dll','msi','sys','com','db','sqlite','mdb','accdb','parquet','orc','avro')

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

function Is-ExecutableKind {
  param([string]$Ext)
  (($Ext ?? '').ToLowerInvariant()) -in @('exe','dll','sys','msi','bat','cmd','ps1','psm1','psd1','vbs','vbe','com')
}

function Get-Sha256Safe {
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
    $hash = $null
    try {
      $hash = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
      $blockSize = [Math]::Max(4096, $BlockKB * 1024)
      $buffer = [System.Buffers.ArrayPool[byte]]::Shared.Rent($blockSize)
      while ($true) {
        $read = $fs.Read($buffer, 0, $blockSize)
        if ($read -le 0) { break }
        $hash.AppendData($buffer, 0, $read)
      }
      $hashBytes = $hash.GetHashAndReset()
      $sb = [System.Text.StringBuilder]::new($hashBytes.Length * 2)
      foreach ($b in $hashBytes) {
        [void]$sb.AppendFormat('{0:x2}', $b)
      }
      $sb.ToString()
    }
    finally {
      if ($hash) { $hash.Dispose() }
      if ($buffer) { [System.Buffers.ArrayPool[byte]]::Shared.Return($buffer, $false) }
      if ($fs) { $fs.Dispose() }
    }
  }
  catch {
    Write-Verbose "Get-Sha256Safe(ArrayPool): $Path — $($_.Exception.Message)"
    Write-ErrorJson -Op 'Hash' -Path $Path -Exception $_.Exception -Context 'SHA256-Pooled'
    $null
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
# endregion

function JsonString {
  param($s)
  if ($null -eq $s) { return 'null' }
  $text = [string]$s
  $text = $text -replace '\\','\\\\'
  $text = $text -replace '"','\"'
  $text = $text -replace "`r",'\\r' -replace "`n",'\\n' -replace "`t",'\\t' -replace "`b",'\\b' -replace "`f",'\\f'
  '"' + $text + '"'
}

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

function Convert-FileTimeUtc {
  param([Native.Win32+FILETIME]$FileTime)
  $ticks = ([int64]$FileTime.dwHighDateTime -shl 32) -bor ([uint32]$FileTime.dwLowDateTime)
  [DateTime]::FromFileTimeUtc([int64]$ticks)
}

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

function Write-ProgressSafe {
  param(
    [string]$Activity,
    [string]$Status = '',
    [switch]$Completed
  )
  if ($NoProgress) { return }
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

# region Inicialización interactiva y configuración
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

# endregion

# region Salida
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
# endregion

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