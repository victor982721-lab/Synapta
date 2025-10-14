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
  [string]$OutputDir,
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
  [ValidateSet('Sencillo','Automatico','Completo')][string]$Mode = 'Automatico',
  [switch]$StrictJson,
  [string[]]$Include,
  [string[]]$Exclude,
  [ValidateRange(1,100000000)][int]$MaxEntries = 100000000,
  [switch]$NoProgress,
  [switch]$Parallel,
  [ValidateRange(1,256)][int]$DegreeOfParallelism = [Environment]::ProcessorCount
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ruta de salida por defecto: C:\.CODEX\out\filemaps
if(-not $PSBoundParameters.ContainsKey('OutputDir') -or [string]::IsNullOrWhiteSpace($OutputDir)){
  try {
    # Subir 3 niveles desde ...\Herramientas\=FileMap= hasta C:\.CODEX
    $wsRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    # Si no es .CODEX, intentar localizar el ancestro ".CODEX"
    if ((Split-Path -Leaf $wsRoot) -ne '.CODEX') {
      $probe = Get-Item -LiteralPath $PSScriptRoot
      while ($probe -and $probe.PSParentPath) {
        if ($probe.Name -eq '.CODEX') { $wsRoot = $probe.FullName; break }
        $probe = $probe.Parent
      }
    }
    if([string]::IsNullOrWhiteSpace($wsRoot) -or -not (Test-Path $wsRoot)){
      $wsRoot = (Get-Location).Path
    }
  } catch { $wsRoot = (Get-Location).Path }
  $OutputDir = Join-Path (Join-Path $wsRoot 'out') 'filemaps'
}

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
  }
  catch {
    Write-Verbose "Win32 Add-Type falló: $($_.Exception.Message)"
  }
}

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

function Convert-FileTimeUtc {
  param([Native.Win32+FILETIME]$FileTime)
  $ticks = ([int64]$FileTime.dwHighDateTime -shl 32) -bor ([uint32]$FileTime.dwLowDateTime)
  [datetime]::FromFileTimeUtc($ticks)
}

function New-FileRecord {
  param(
    [object]$FileInfo,
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
    [string[]]$BinaryExtensions
  )

  if (-not $FileInfo) { return $null }

  $path = $null
  $name = $null
  $length = 0L
  $mtimeUtc = [datetime]::UtcNow
  $attributes = [System.IO.FileAttributes]::Normal

  if ($FileInfo -is [System.IO.FileInfo]) {
    $path = $FileInfo.FullName
    $name = $FileInfo.Name
    $length = [int64]$FileInfo.Length
    $mtimeUtc = $FileInfo.LastWriteTimeUtc
    $attributes = $FileInfo.Attributes
  }
  else {
    $path = [string]$FileInfo.FullName
    $name = [string]$FileInfo.Name
    $length = [int64]$FileInfo.Length
    if ($FileInfo.PSObject.Properties['LastWriteTimeUtc']) {
      $mtimeUtc = [datetime]$FileInfo.LastWriteTimeUtc
    } else {
      $mtimeUtc = (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue).LastWriteTimeUtc
    }
    if ($FileInfo.PSObject.Properties['Attributes']) {
      $attributes = [System.IO.FileAttributes]$FileInfo.Attributes
    } else {
      $attributes = ([System.IO.FileInfo]::new($path)).Attributes
    }
  }

  $relPath = Get-RelativePath -Base $RootPath -Full $path
  if ([string]::IsNullOrWhiteSpace($relPath)) { $relPath = '.' }
  $ext = [System.IO.Path]::GetExtension($name).TrimStart('.').ToLowerInvariant()
  $record = [ordered]@{
    relpath       = $relPath
    type          = 'file'
    name          = $name
    ext           = $ext
    size_bytes    = $length
    mtime_iso     = $mtimeUtc.ToString('o')
    depth         = $Depth + 1
    attributes    = $attributes.ToString().Replace(', ', '|')
    top_segment   = if ($relPath -match $PathSplitPattern) { ($relPath -split $PathSplitPattern)[0] } else { $relPath }
    path_len      = $relPath.Length
    age_days      = [int](($StartedUtc - $mtimeUtc).TotalDays)
    has_non_ascii = Has-NonAscii $name
    is_large      = ($length -ge ($LargeFileMB * 1MB))
  }

  if ($Classify) {
    $record.category = Get-Category $ext
    $record.mime_guess = Get-MimeGuess $ext
  }

  if ($DetectExecutables) {
    $record.is_executable = Is-ExecutableKind $ext
  }

  if ($ProbeText) {
    if ($TextExtensions -contains $ext) { $record.is_text = $true }
    elseif ($BinaryExtensions -contains $ext) { $record.is_text = $false }
    elseif ($length -le ($ProbeTextMaxMB * 1MB)) { $record.is_text = Is-TextFile -Path $path }
  }

  if ($ComputeHashes) {
    $record.hash_sha256 = Get-Sha256Safe -Path $path -Size $length -MaxMB $MaxHashMB
  }

  if ($ProbeDocs) {
    if ($ext -eq 'pdf') { $record.pdf_pages = Get-PdfPageGuess -Path $path }
    if ($ext -in @('jpg','jpeg','png','gif','bmp','tif','tiff')) {
      $img = Get-ImageSize -Path $path -Size $length
      if ($img) {
        $record.image_width = $img.width
        $record.image_height = $img.height
      }
    }
  }

  if ($ProbeArchives -and $ext -eq 'zip') {
    $zipInfo = Get-ZipInfo -Path $path -MaxEntries $ZipListEntries
    if ($zipInfo) {
      $record.zip_entries = $zipInfo.entries
      if ($zipInfo.sample.Count -gt 0) { $record.zip_sample = $zipInfo.sample }
    }
  }

  [pscustomobject]@{
    Path   = $path
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
      continue
    }
  }
  $count
}

function Optimize-ThreadPool {
  param([int]$WorkerCount)
  try {
    $minWorkers = [Math]::Max($WorkerCount, [Environment]::ProcessorCount)
    $minIo = [Math]::Max(4, [Environment]::ProcessorCount)
    [void][System.Threading.ThreadPool]::SetMinThreads($minWorkers, $minIo)
  }
  catch {
    Write-Verbose "Optimize-ThreadPool: no se pudo ajustar el ThreadPool — $($_.Exception.Message)"
  }
}

function Compute-AutoPlan {
  param([string]$Root)
  $stats = Get-SystemStats
  $estimate = Estimate-FileCount -Root $Root -Limit 120000
  $cpu = $stats.CPU
  $mem = $stats.MemGB
  $level = if ($estimate -le 12000) { 'small' } elseif ($estimate -le 60000) { 'medium' } elseif ($estimate -le 120000) { 'large' } else { 'huge' }

  $plan = [ordered]@{
    ShowSizes        = $true
    ShowDates        = $true
    Classify         = $true
    DetectExecutables= $true
    ComputeHashes    = $false
    ProbeDocs        = $false
    ProbeArchives    = $false
    ProbeText        = $false
    EmitSummaries    = $false
    ProgressInterval = 3000
    Parallel         = $false
    StrictJson       = $false
  }

  switch ($level) {
    'small' {
      $plan.ProbeText = $true
      $plan.ProgressInterval = 1000
      if ($mem -ge 8 -and $cpu -ge 4) {
        $plan.ProbeDocs = $true
        $plan.ProbeArchives = $true
      }
      $plan.EmitSummaries = $true
    }
    'medium' {
      $plan.ProgressInterval = 2000
      $plan.ProbeArchives = $true
      $plan.Parallel = $true
    }
    default {
      $plan.ProgressInterval = 4000
      $plan.Parallel = $true
      $plan.ShowDates = $false
      $plan.StrictJson = $true
      $plan.ProbeText = $false
      $plan.Classify = $false
      $plan.DetectExecutables = $false
    }
  }

  [pscustomobject]@{
    Level = $level
    Estimate = $estimate
    CPU = $cpu
    MemGB = $mem
    Plan = $plan
  }
}

function Apply-AutomaticConfiguration {
  param([string]$Root)
  $auto = Compute-AutoPlan -Root $Root
  $plan = $auto.Plan

  foreach ($key in $plan.Keys) {
    if (-not $PSBoundParameters.ContainsKey($key)) {
      Set-Variable -Name $key -Value $plan[$key] -Scope Script
    }
  }

  $script:EstimatedEntries = [int64]$auto.Estimate

  $autoSummary = "Auto: archivos ~{0:N0}, CPU={1}, Mem={2}GB, nivel={3}" -f $auto.Estimate, $auto.CPU, $auto.MemGB, $auto.Level
  $autoFlags = "Auto: ProbeText={0}, ProbeDocs={1}, ProbeArchives={2}, Summaries={3}, Parallel={4}, StrictJson={5}, ProgressInterval={6}" -f @(
    [bool]$ProbeText,
    [bool]$ProbeDocs,
    [bool]$ProbeArchives,
    [bool]$EmitSummaries,
    [bool]$Parallel,
    [bool]$StrictJson,
    $ProgressInterval
  )
  Write-Host $autoSummary -ForegroundColor Cyan
  Write-Host $autoFlags -ForegroundColor DarkCyan
}

function Apply-SimpleConfiguration {
  $plan = [ordered]@{
    ShowSizes        = $true
    ShowDates        = $false
    Classify         = $false
    DetectExecutables= $false
    ComputeHashes    = $false
    ProbeDocs        = $false
    ProbeArchives    = $false
    ProbeText        = $false
    EmitSummaries    = $false
    ProgressInterval = 1200
    Parallel         = $false
    StrictJson       = $false
  }
  foreach ($key in $plan.Keys) {
    if (-not $PSBoundParameters.ContainsKey($key)) {
      Set-Variable -Name $key -Value $plan[$key] -Scope Script
    }
  }
  $script:EstimatedEntries = 0
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
    Write-Host '  3) Sencillo'
    $modeChoice = Read-Host 'Elige 1, 2 o 3'
    switch ($modeChoice) {
      '1' { $script:Mode = 'Automatico'; break }
      '2' { $script:Mode = 'Completo'; break }
      '3' { $script:Mode = 'Sencillo'; break }
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
  $hash = $null
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
    $hash = [System.Security.Cryptography.IncrementalHash]::CreateHash([System.Security.Cryptography.HashAlgorithmName]::SHA256)
    $bufferSize = [Math]::Max(4096, $BlockKB * 1024)
    $buffer = [System.Buffers.ArrayPool[byte]]::Shared.Rent($bufferSize)
    while ($true) {
      $read = $fs.Read($buffer, 0, $bufferSize)
      if ($read -le 0) { break }
      $hash.AppendData($buffer, 0, $read)
    }
    $hashBytes = $hash.GetHashAndReset()
    $sb = New-Object System.Text.StringBuilder ($hashBytes.Length * 2)
    foreach ($b in $hashBytes) { [void]$sb.AppendFormat('{0:x2}', $b) }
    $sb.ToString()
  }
  catch {
    Write-Verbose "Get-Sha256Safe(ArrayPool): $Path — $($_.Exception.Message)"
    $null
  }
  finally {
    if ($hash) { $hash.Dispose() }
    if ($fs) { $fs.Dispose() }
    if ($buffer) { [System.Buffers.ArrayPool[byte]]::Shared.Return($buffer, $false) }
  }
}

function Get-ZipInfo {
  param(
    [string]$Path,
    [int]$MaxEntries
  )
  $result = @{ entries = $null; sample = @() }
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
      $zip = [System.IO.Compression.ZipArchive]::new($fs, [System.IO.Compression.ZipArchiveMode]::Read, $false)
      $result.entries = $zip.Entries.Count
      $take = [Math]::Min($MaxEntries, [int]$zip.Entries.Count)
      for ($i = 0; $i -lt $take; $i++) {
        $name = $zip.Entries[$i].FullName
        if ($name) { $result.sample += $name }
      }
    }
    finally {
      $fs.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-ZipInfo: fallo en '$Path' — $($_.Exception.Message)"
  }
  $result
}

function Get-PdfPageGuess {
  param([string]$Path,[int]$ProbeKB = 2048)
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
      $len = [Math]::Min($ProbeKB * 1024, $fs.Length)
      $buffer = New-Object byte[] $len
      [void]$fs.Read($buffer, 0, $len)
      $text = [System.Text.Encoding]::ASCII.GetString($buffer)
      ([regex]::Matches($text, '/Type\s*/Page').Count)
    }
    finally {
      $fs.Dispose()
    }
  }
  catch {
    Write-Verbose "Get-PdfPageGuess: fallo en '$Path' — $($_.Exception.Message)"
    $null
  }
}

function Get-ImageSize {
  param(
    [string]$Path,
    [long]$Size,
    [int]$MaxMB = 50
  )
  if ($Size -gt ($MaxMB * 1MB)) { return $null }
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
      $img = [System.Drawing.Image]::FromStream($imgStream, $false, $false)
      try {
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
    $null
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

function Get-ChildListsNet {
  param(
    [Parameter(Mandatory)][System.IO.DirectoryInfo]$Directory,
    [bool]$IncludeHidden
  )
  $dirs = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
  $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
  try {
    foreach ($dir in $Directory.EnumerateDirectories('*', [System.IO.SearchOption]::TopDirectoryOnly)) {
      if (Is-ReparsePoint -Info $dir) { continue }
      if (Is-Visible -Info $dir -IncludeHidden ([bool]$IncludeHidden)) {
        if ($script:OutputDirExclusionActive) {
          if ($dir.FullName.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
          if ($dir.FullName.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        }
        if (-not (Match-Patterns $dir.Name)) { continue }
        $dirs.Add($dir)
      }
    }
    foreach ($file in $Directory.EnumerateFiles('*', [System.IO.SearchOption]::TopDirectoryOnly)) {
      if (Is-Visible -Info $file -IncludeHidden ([bool]$IncludeHidden)) {
        if ($script:OutputDirExclusionActive -and $file.DirectoryName) {
          if ($file.DirectoryName.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
          if ($file.DirectoryName.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        }
        if ($script:ExcludedPaths -and $script:ExcludedPaths.Contains([System.IO.Path]::GetFullPath($file.FullName))) { continue }
        if (-not (Match-Patterns $file.Name)) { continue }
        $files.Add($file)
      }
    }
  }
  catch {
    Write-Verbose ("Sin acceso a: {0} ({1})" -f $Directory.FullName, $_.Exception.Message)
  }
  $sortedDirs = $dirs.ToArray()
  [Array]::Sort($sortedDirs, [System.Comparison[System.IO.DirectoryInfo]]{
    param($a, $b)
    [System.StringComparer]::OrdinalIgnoreCase.Compare($a.Name, $b.Name)
  })
  $sortedFiles = $files.ToArray()
  [Array]::Sort($sortedFiles, [System.Comparison[System.IO.FileInfo]]{
    param($a, $b)
    [System.StringComparer]::OrdinalIgnoreCase.Compare($a.Name, $b.Name)
  })
  @{ Dirs = $sortedDirs; Files = $sortedFiles }
}

function Get-ChildListsWinApi {
  param(
    [Parameter(Mandatory)][System.IO.DirectoryInfo]$Directory,
    [bool]$IncludeHidden
  )
  if (-not ('Native.Win32' -as [type])) {
    return Get-ChildListsNet -Directory $Directory -IncludeHidden:$IncludeHidden
  }
  $dirs = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
  $files = New-Object System.Collections.Generic.List[object]
  $pattern = Join-Path $Directory.FullName '*'
  $data = New-Object Native.Win32+WIN32_FIND_DATAW
  $handle = [Native.Win32]::FindFirstFileExW(
    $pattern,
    [Native.Win32+FINDEX_INFO_LEVELS]::FindExInfoBasic,
    [ref]$data,
    [Native.Win32+FINDEX_SEARCH_OPS]::FindExSearchNameMatch,
    [IntPtr]::Zero,
    [Native.Win32]::FIND_FIRST_EX_LARGE_FETCH
  )
  if ($handle -eq [IntPtr]::Zero -or $handle.ToInt64() -eq -1) {
    return @{ Dirs = @(); Files = @() }
  }
  try {
    do {
      $name = $data.cFileName
      if ([string]::IsNullOrEmpty($name) -or $name -eq '.' -or $name -eq '..') { continue }
      $attr = [uint32]$data.dwFileAttributes
      if (-not $IncludeHidden) {
        if (($attr -band [Native.Win32]::FILE_ATTRIBUTE_HIDDEN) -ne 0 -or ($attr -band [Native.Win32]::FILE_ATTRIBUTE_SYSTEM) -ne 0) {
          continue
        }
      }
      if (($attr -band [Native.Win32]::FILE_ATTRIBUTE_REPARSE_POINT) -ne 0) { continue }
      if (-not (Match-Patterns $name)) { continue }
      $full = Join-Path $Directory.FullName $name
      if ($script:OutputDirExclusionActive) {
        if ($full.StartsWith($script:OutputDirPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($full.Equals($script:OutputDirFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
      }
      if ($script:ExcludedPaths -and $script:ExcludedPaths.Contains([System.IO.Path]::GetFullPath($full))) { continue }

      $isDir = (($attr -band [Native.Win32]::FILE_ATTRIBUTE_DIRECTORY) -ne 0)
      if ($isDir) {
        try {
          $dirs.Add([System.IO.DirectoryInfo]::new($full)) | Out-Null
        }
        catch {
          Write-Verbose ("WinAPI dir fallo '{0}': {1}" -f $full, $_.Exception.Message)
        }
      }
      else {
        $length = ([int64]$data.nFileSizeHigh -shl 32) -bor [uint32]$data.nFileSizeLow
        $files.Add([pscustomobject]@{
          FullName = $full
          Name = $name
          Length = $length
          LastWriteTimeUtc = Convert-FileTimeUtc $data.ftLastWriteTime
          Attributes = [System.IO.FileAttributes]$attr
        }) | Out-Null
      }
    } while ([Native.Win32]::FindNextFileW($handle, [ref]$data))
  }
  finally {
    [void][Native.Win32]::FindClose($handle)
  }

  $dirArray = $dirs.ToArray()
  [Array]::Sort($dirArray, [System.Comparison[System.IO.DirectoryInfo]]{
    param($a, $b)
    [System.StringComparer]::OrdinalIgnoreCase.Compare($a.Name, $b.Name)
  })
  $fileArray = $files.ToArray()
  [Array]::Sort($fileArray, [System.Comparison[object]]{
    param($a, $b)
    [System.StringComparer]::OrdinalIgnoreCase.Compare($a.Name, $b.Name)
  })
  @{ Dirs = $dirArray; Files = $fileArray }
}

function Get-ChildLists {
  param(
    [Parameter(Mandatory)][System.IO.DirectoryInfo]$Directory,
    [bool]$IncludeHidden
  )
  if ($script:IsWindowsPlatform) {
    return Get-ChildListsWinApi -Directory $Directory -IncludeHidden:$IncludeHidden
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

switch ($Mode) {
  'Automatico' { Apply-AutomaticConfiguration -Root $RootPath }
  'Completo'   { Apply-CompleteConfiguration }
  'Sencillo'   { Apply-SimpleConfiguration }
  default      { Apply-AutomaticConfiguration -Root $RootPath }
}

if ($Parallel) {
  Optimize-ThreadPool -WorkerCount $DegreeOfParallelism
}

# endregion

# region Salida
try {
  if (-not (Test-Path -LiteralPath $OutputDir)) {
    [void](New-Item -ItemType Directory -Path $OutputDir -Force)
  }
}
catch {
  Write-Warning "No se pudo crear OutputDir '$OutputDir'. Usando carpeta del script."
  $OutputDir = $PSScriptRoot
}

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
if ([string]::IsNullOrWhiteSpace($rootName)) { $rootName = ($RootPath -replace '[:\\\/]','_') }
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')
$baseName = ("{0}_{1}" -f ($rootName -replace '[^\w\.-]','_'), $timestamp)
$treeFile = Join-Path $OutputDir ("FileMap_{0}.{1}" -f $baseName, $OutputKind)
$jsonFile = Join-Path $OutputDir ("FileList_{0}.jsonl" -f $baseName)

if ($EmitTree) {
  $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($treeFile)) | Out-Null
}
if ($EmitJsonl) {
  $script:ExcludedPaths.Add([System.IO.Path]::GetFullPath($jsonFile)) | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$swTree = $null
$swJson = $null
if ($EmitTree -and $PSCmdlet.ShouldProcess($treeFile, 'Crear archivo de árbol')) {
  $fsTree = [System.IO.FileStream]::new(
    $treeFile,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::Read,
    1048576,
    [System.IO.FileOptions]::SequentialScan
  )
  $swTree = [System.IO.StreamWriter]::new($fsTree, $utf8NoBom, 1048576, $false)
}
if ($EmitJsonl -and $PSCmdlet.ShouldProcess($jsonFile, 'Crear archivo JSONL')) {
  $fsJson = [System.IO.FileStream]::new(
    $jsonFile,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::Read,
    1048576,
    [System.IO.FileOptions]::SequentialScan
  )
  $swJson = [System.IO.StreamWriter]::new($fsJson, $utf8NoBom, 1048576, $false)
}
# endregion

function Write-JsonLine {
  param([hashtable]$Object)
  if (-not $swJson) { return }
  if ($StrictJson) {
    $payload = ConvertTo-JsonCompatible $Object
    $payloadType = if ($payload) { $payload.GetType() } else { [object] }
    $swJson.WriteLine([System.Text.Json.JsonSerializer]::Serialize($payload, $payloadType))
    return
  }
  $pairs = @()
  foreach ($key in $Object.Keys) {
    $escapedKey = $key -replace '"','\"'
    $pairs += "`"$escapedKey`":$(JsonPrimitive $Object[$key])"
  }
  $swJson.WriteLine('{' + ($pairs -join ',') + '}')
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

  $childLists = if ($Prefetched) { $Prefetched } else { Get-ChildLists -Directory $Directory -IncludeHidden ([bool]$IncludeHidden) }
  $dirs = $childLists.Dirs
  $files = $childLists.Files

  $summaryBytes = 0L
  foreach ($f in $files) {
    if ($f -is [System.IO.FileInfo]) { $summaryBytes += $f.Length }
    else { $summaryBytes += [int64]$f.Length }
  }

  $parallelRecords = $null
  if ($EmitJsonl -and $Parallel -and $files.Count -gt 0) {
    $parallelRecords = New-Object 'System.Collections.Generic.Dictionary[string,hashtable]' ([System.StringComparer]::OrdinalIgnoreCase)
    $filePaths = $files | ForEach-Object { $_.FullName }
    $results = $filePaths | ForEach-Object -Parallel {
      param($filePath)
      try {
        $fi = [System.IO.FileInfo]::new($filePath)
      }
      catch {
        Write-Verbose ("Parallel: error al abrir '{0}' — {1}" -f $filePath, $_.Exception.Message)
        return $null
      }
      if ($fi.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) { return $null }
      New-FileRecord -FileInfo $fi -Depth $using:Depth -StartedUtc $using:script:StartedUtc -RootPath $using:RootPath -PathSplitPattern $using:script:PathSplitPattern -Classify:$using:Classify -DetectExecutables:$using:DetectExecutables -ProbeText:$using:ProbeText -ProbeTextMaxMB $using:ProbeTextMaxMB -ComputeHashes:$using:ComputeHashes -MaxHashMB $using:MaxHashMB -ProbeDocs:$using:ProbeDocs -ProbeArchives:$using:ProbeArchives -ZipListEntries $using:ZipListEntries -LargeFileMB $using:LargeFileMB -TextExtensions $using:TextExts -BinaryExtensions $using:BinaryExts
    } -ThrottleLimit $DegreeOfParallelism
    foreach ($entry in $results) {
      if ($null -eq $entry) { continue }
      $parallelRecords[$entry.Path] = $entry.Record
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
    if ($script:ReachedEntryLimit) { break }
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
      $dirInfo = [System.IO.DirectoryInfo]$child.Info
      $meta = if ($ShowDates) { " (mod: {0:yyyy-MM-dd HH:mm} UTC)" -f $dirInfo.LastWriteTimeUtc } else { '' }
      if ($swTree) {
        $swTree.WriteLine(($indent + $branch + '[DIR] ' + $dirInfo.Name + $meta))
      }
      if (($script:EntryCounter % $ProgressInterval) -eq 0) {
        Write-ProgressSafe -Activity 'Generando FileMap'
      }
      if ($script:EntryCounter -ge $MaxEntries) {
        $script:ReachedEntryLimit = $true
      }
      $nextAncestors = $AncestorHasMore + @(-not $isLast)
      $prefetch = Get-ChildLists -Directory $dirInfo -IncludeHidden ([bool]$IncludeHidden)
      if (-not $script:ReachedEntryLimit) {
        Write-DirectoryEntry -Directory $dirInfo -Depth ($Depth + 1) -AncestorHasMore $nextAncestors -Prefetched $prefetch
      }
    }
    else {
      $fileEntry = $child.Info
      $isFileInfo = $fileEntry -is [System.IO.FileInfo]
      if ($isFileInfo -and (Is-ReparsePoint -Info $fileEntry)) { continue }
      $script:FileCount++
      $script:EntryCounter++
      $fullName = if ($isFileInfo) { $fileEntry.FullName } else { [string]$fileEntry.FullName }
      $name = if ($isFileInfo) { $fileEntry.Name } else { [string]$fileEntry.Name }
      $length = if ($isFileInfo) { [int64]$fileEntry.Length } else { [int64]$fileEntry.Length }
      $mtimeUtc = if ($isFileInfo) { $fileEntry.LastWriteTimeUtc } elseif ($fileEntry.PSObject.Properties['LastWriteTimeUtc']) { [datetime]$fileEntry.LastWriteTimeUtc } else { (Get-Item -LiteralPath $fullName -ErrorAction SilentlyContinue).LastWriteTimeUtc }
      $metaParts = @()
      if ($ShowSizes) {
        $script:TotalBytes += $length
        $metaParts += (Format-Size $length)
      }
      if ($ShowDates -and $mtimeUtc) { $metaParts += ("mod: {0:yyyy-MM-dd HH:mm} UTC" -f $mtimeUtc) }
      $meta = if ($metaParts.Count -gt 0) { ' - ' + ($metaParts -join ' | ') } else { '' }
      if ($swTree) {
        $swTree.WriteLine($indent + $branch + $name + $meta)
      }
      if ($EmitJsonl) {
        $jsonRecord = $null
        if ($parallelRecords -and $parallelRecords.ContainsKey($fullName)) {
          $jsonRecord = $parallelRecords[$fullName]
        }
        else {
          $result = New-FileRecord -FileInfo $fileEntry -Depth $Depth -StartedUtc $script:StartedUtc -RootPath $RootPath -PathSplitPattern $script:PathSplitPattern -Classify:$Classify -DetectExecutables:$DetectExecutables -ProbeText:$ProbeText -ProbeTextMaxMB $ProbeTextMaxMB -ComputeHashes:$ComputeHashes -MaxHashMB $MaxHashMB -ProbeDocs:$ProbeDocs -ProbeArchives:$ProbeArchives -ZipListEntries $ZipListEntries -LargeFileMB $LargeFileMB -TextExtensions $TextExts -BinaryExtensions $BinaryExts
          if ($result) { $jsonRecord = $result.Record }
        }
        if ($ProbeText -and $script:EntryCounter -gt 25000) {
          $Script:ProbeText = $false
          Write-Host 'AutoTune: desactivado ProbeText por volumen (> 25,000 entradas)' -ForegroundColor Yellow
        }
        if ($jsonRecord) {
          Write-JsonLine -Object $jsonRecord
        }
      }
      if (($script:EntryCounter % $ProgressInterval) -eq 0) {
        Write-ProgressSafe -Activity 'Generando FileMap'
      }
      if ($script:EntryCounter -ge $MaxEntries) {
        $script:ReachedEntryLimit = $true
      }
    }
  }
}

try {
  if ($swTree) {
    if ($OutputKind -eq 'md') {
      $swTree.WriteLine("# FileMap - $RootPath")
      $swTree.WriteLine()
      $headerTimestamp = (Get-Date).ToUniversalTime().ToString('o')
      $headerLine = "Generado: $headerTimestamp | Equipo: $env:COMPUTERNAME | PowerShell: $($PSVersionTable.PSVersion)"
      $swTree.WriteLine($headerLine)
      $swTree.WriteLine()
      $swTree.WriteLine('```')
    }
    else {
      $swTree.WriteLine("FileMap - $RootPath")
      $headerTimestamp = (Get-Date).ToUniversalTime().ToString('o')
      $headerLine = "Generado: $headerTimestamp | Equipo: $env:COMPUTERNAME | PowerShell: $($PSVersionTable.PSVersion)"
      $swTree.WriteLine($headerLine)
      $swTree.WriteLine()
    }
  }

  $rootMeta = if ($ShowDates) { "  (mod: {0:yyyy-MM-dd HH:mm} UTC)" -f $rootItem.LastWriteTimeUtc } else { '' }
  if ($swTree) {
    $swTree.WriteLine($glyphs.Root + '[DIR] ' + $RootPath + $rootMeta)
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

  if ($swTree) {
    if ($OutputKind -eq 'md') {
      $swTree.WriteLine('```')
      $swTree.WriteLine()
    }
    $summaryText = if ($ShowSizes) { ', total archivos: ' + (Format-Size $script:TotalBytes) } else { '' }
    $dirText = $script:DirCount.ToString('N0')
    $fileText = $script:FileCount.ToString('N0')
    $swTree.WriteLine("Resumen: $dirText directorios, $fileText archivos$summaryText.")
    Write-Host ("✔ FileMap generado en: {0}" -f $treeFile)
  }
  if ($swJson) {
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
    }
    $meta = [ordered]@{
      type             = 'run_meta'
      run_id           = $script:RunId
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
      max_depth        = $MaxDepth
      estimated_entries= $script:EstimatedEntries
      include_patterns = $Include
      exclude_patterns = $Exclude
      max_entries      = $MaxEntries
      plan             = $plan
    }
    Write-JsonLine -Object $meta
    Write-Host ("✔ JSONL generado en:   {0}" -f $jsonFile)
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
  foreach ($writer in @($swTree, $swJson)) {
    if ($writer) {
      try { $writer.Flush(); $writer.Dispose() }
      catch {
        Write-Verbose "Dispose writer: $($_.Exception.Message)"
      }
    }
  }
  Write-ProgressSafe -Activity 'Generando FileMap' -Completed
}

if ($swTree) { "OUTPUT => $treeFile" }
if ($swJson) { "OUTPUT => $jsonFile" }
