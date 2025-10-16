# DeDupe.Metrics.Ultra (PowerShell 7+)
# - ETA/MB/s/EPS con EMA estable
# - Canal paralelo con backpressure (System.Threading.Channels)
# - ThreadPool tuning + Background Mode (I/O+CPU baja prioridad)
# - JSONL writer de alto rendimiento (Utf8JsonWriter) con rotación
# - Copy con progreso real (CopyFile2/CopyFileEx)
# - DOP recomendado por p95 de cola de disco
# Exporta: Initialize-HiResMetrics, Update-HiResMetrics, Get-HiResSnapshot, Start-ProgressTicker, Stop-ProgressTicker,
#          Optimize-ThreadPool, Use-BackgroundMode, New-BoundedChannel, Invoke-ParallelChannel, Complete-Channel,
#          New-JsonlWriter, Write-Jsonl, Close-JsonlWriter, Get-AvgDiskQueueLength, Get-RecommendedDOP, Copy-ItemWithETA

using namespace System
using namespace System.IO
using namespace System.Text
using namespace System.Text.Json
using namespace System.Threading
using namespace System.Threading.Channels
Set-StrictMode -Version Latest

#region C# helpers (RateCounter, BackgroundMode, JsonlWriter, CopyFileEx/2)
Add-Type -Language CSharp -IgnoreWarnings -TypeDefinition @"
using System;
using System.IO;
using System.Text.Json;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.IO.Compression;

public static class FMPrio {
  const uint PROCESS_MODE_BACKGROUND_BEGIN = 0x00100000;
  const uint PROCESS_MODE_BACKGROUND_END   = 0x00200000;
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
  [DllImport("kernel32.dll", SetLastError=true)] static extern bool SetPriorityClass(IntPtr h, uint c);
  public static bool BeginBackground() => SetPriorityClass(GetCurrentProcess(), PROCESS_MODE_BACKGROUND_BEGIN);
  public static bool EndBackground()   => SetPriorityClass(GetCurrentProcess(), PROCESS_MODE_BACKGROUND_END);
}

public sealed class RateCounter {
  readonly Stopwatch sw = Stopwatch.StartNew();
  readonly object gate = new object();
  long totalBytes, totalItems, lastBytes, lastItems;
  double emaBps, emaEps, alpha;
  double lastTs = -1;
  public RateCounter(double windowSeconds = 2.0) {
    SetWindow(windowSeconds);
  }
  public void SetWindow(double windowSeconds) {
    alpha = Math.Min(1.0, Math.Max(0.05, 2.0/(windowSeconds+1.0)));
  }
  public void Add(long bytes, long items) {
    lock(gate) {
      var t = sw.Elapsed.TotalSeconds;
      var dB = totalBytes + bytes - lastBytes;
      var dI = totalItems + items - lastItems;
      var dt = Math.Max(1e-3, t - (lastTs>=0 ? lastTs : t-1e-3));
      var bps = dB/dt; var eps = dI/dt;
      emaBps = emaBps<=0 ? bps : emaBps + alpha*(bps-emaBps);
      emaEps = emaEps<=0 ? eps : emaEps + alpha*(eps-emaEps);
      totalBytes += bytes; totalItems += items;
      lastBytes = totalBytes; lastItems = totalItems; lastTs = t;
    }
  }
  public Snapshot GetSnapshot(long? goalBytes, long? goalItems) {
    lock(gate) {
      double mbps = emaBps/(1024.0*1024.0);
      double? pct = null; double? eta = null;
      if (goalBytes.HasValue && goalBytes.Value>0) {
        pct = 100.0 * totalBytes / (double)goalBytes.Value;
        var rem = Math.Max(0.0, goalBytes.Value - (double)totalBytes);
        eta = emaBps>0 ? rem/emaBps : (double?)null;
      } else if (goalItems.HasValue && goalItems.Value>0) {
        pct = 100.0 * totalItems / (double)goalItems.Value;
        var remI = Math.Max(0.0, goalItems.Value - (double)totalItems);
        eta = emaEps>0 ? remI/emaEps : (double?)null;
      }
      return new Snapshot {
        BytesDone = totalBytes, ItemsDone = totalItems,
        Elapsed = sw.Elapsed, MBps = mbps, EPS = emaEps,
        Percent = pct, Eta = eta.HasValue ? TimeSpan.FromSeconds(eta.Value) : (TimeSpan?)null
      };
    }
  }
  public struct Snapshot {
    public long BytesDone; public long ItemsDone;
    public TimeSpan Elapsed; public double MBps; public double EPS;
    public double? Percent; public TimeSpan? Eta;
  }
}

public sealed class JsonlWriter : IDisposable {
  readonly Stream baseStream;
  readonly Utf8JsonWriter writer;
  readonly bool lineMode;
  long bytesEmitted;
  readonly byte[] nl = new byte[]{ (byte)'\n' };
  public JsonlWriter(string path, int bufferBytes = 1_048_576, bool compress=false, bool overwrite=true, bool lineMode=true) {
    var dir = Path.GetDirectoryName(path);
    if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
    var fs = new FileStream(path, overwrite ? FileMode.Create : FileMode.CreateNew, FileAccess.Write,
                            FileShare.ReadWrite | FileShare.Delete, bufferBytes,
                            FileOptions.SequentialScan | FileOptions.Asynchronous | FileOptions.WriteThrough);
    Stream s = fs;
    if (compress) s = new GZipStream(fs, CompressionLevel.Fastest, false);
    baseStream = s;
    writer = new Utf8JsonWriter(baseStream, new JsonWriterOptions{ SkipValidation=false, Indented=false, Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping });
    this.lineMode = lineMode;
    bytesEmitted = 0;
  }
  public long BytesEmitted => baseStream is GZipStream ? bytesEmitted : (baseStream.Position);
  public void WriteObject(object obj) {
    JsonSerializer.Serialize(writer, obj); writer.Flush();
    if (lineMode) { baseStream.Write(nl,0,1); baseStream.Flush(); bytesEmitted += 1; }
  }
  public void Dispose() { try { writer.Dispose(); } catch {} baseStream.Dispose(); }
}

public static class FMCopy {
  public delegate int CopyProgressRoutine(long TotalFileSize,long TotalBytesTransferred,long StreamSize,long StreamBytesTransferred,uint dwStreamNumber,uint dwCallbackReason,IntPtr hSourceFile,IntPtr hDestinationFile,IntPtr lpData);
[DllImport("Kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  static extern bool CopyFileEx(string src, string dst, CopyProgressRoutine cb, IntPtr data, ref int cancel, uint flags);
[DllImport("Kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode, EntryPoint="CopyFile2")]
  static extern int CopyFile2Native(string a, string b, IntPtr p);
  public static void CopyWithProgress(string src, string dst, Action<long,long> onProgress, bool overwrite) {
    try { int hr = CopyFile2Native(src, dst, IntPtr.Zero); if (hr==0) return; } catch {
      int cancel = 0;
      const uint COPY_FILE_RESTARTABLE=0x00000002, COPY_FILE_FAIL_IF_EXISTS=0x00000001;
      uint flags = COPY_FILE_RESTARTABLE | (overwrite?0u:COPY_FILE_FAIL_IF_EXISTS);
      CopyProgressRoutine cb = (tot,done,s1,s2,sn,reason,hS,hD,data) => { onProgress?.Invoke(done, tot); return 0; };
      if (!CopyFileEx(src, dst, cb, IntPtr.Zero, ref cancel, flags))
        throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    }
  }
}
"@
#endregion

#region Estado y API de métricas (ETA/MB/s/EPS)
$script:FM_Metrics = [ordered]@{ Counter=$null; TotalBytes=$null; TotalItems=$null; LastSnapshot=$null; TickerCTS=$null }

function Initialize-HiResMetrics {
  [CmdletBinding()] param([long]$TotalBytes,[long]$TotalItems,[double]$WindowSeconds=2.0)
  $script:FM_Metrics.Counter = [RateCounter]::new($WindowSeconds)
  $script:FM_Metrics.TotalBytes = $PSBoundParameters.ContainsKey('TotalBytes') ? [Nullable[long]]$TotalBytes : $null
  $script:FM_Metrics.TotalItems = $PSBoundParameters.ContainsKey('TotalItems') ? [Nullable[long]]$TotalItems : $null
  $script:FM_Metrics.LastSnapshot = $null; $script:FM_Metrics.TickerCTS = $null
}
function Update-HiResMetrics { [CmdletBinding()] param([Parameter(Mandatory)][long]$Bytes,[long]$Items=0) if(-not $script:FM_Metrics.Counter){ return }; $script:FM_Metrics.Counter.Add($Bytes,$Items) }
function Get-HiResSnapshot {
  [CmdletBinding()] param()
if(-not $script:FM_Metrics.Counter){ return $null }
  $s = $script:FM_Metrics.Counter.GetSnapshot($script:FM_Metrics.TotalBytes,$script:FM_Metrics.TotalItems)
  $obj = [pscustomobject]@{ BytesDone=[int64]$s.BytesDone; ItemsDone=[int64]$s.ItemsDone; ElapsedMs=[int][math]::Round($s.Elapsed.TotalMilliseconds); MBps=[math]::Round($s.MBps,3); EPS=[math]::Round($s.EPS,2); Percent=($(if($s.Percent){[math]::Round($s.Percent.Value,3)}else{$null})); ETA=$(if($s.Eta){ [int][math]::Round($s.Eta.Value.TotalSeconds) } else { $null }) }
  $script:FM_Metrics.LastSnapshot = $obj; return $obj
}
function Start-ProgressTicker {
  [CmdletBinding()] param([int]$IntervalMs=750,[Parameter(Mandatory)][scriptblock]$OnTick)
  if ($script:FM_Metrics.Contains('Timer') -and $script:FM_Metrics['Timer']) { throw "Ticker ya activo." }
  $t = New-Object System.Timers.Timer([double][Math]::Max(100,$IntervalMs))
  $t.AutoReset = $true
  $t.add_Elapsed({ try { & $OnTick (Get-HiResSnapshot) } catch {} })
  $t.Start()
  $script:FM_Metrics['Timer'] = $t
}
function Stop-ProgressTicker { [CmdletBinding()] param() if($script:FM_Metrics.Contains('Timer') -and $script:FM_Metrics['Timer']){ $script:FM_Metrics['Timer'].Stop(); $script:FM_Metrics['Timer'].Dispose(); $script:FM_Metrics['Timer']=$null } }
#endregion

#region ThreadPool + Background Mode
function Optimize-ThreadPool {
  [CmdletBinding(SupportsShouldProcess)] param([int]$Workers,[int]$IOCP)
  if(-not $Workers -or $Workers -lt [Environment]::ProcessorCount){ $Workers=[Environment]::ProcessorCount }
  if(-not $IOCP   -or $IOCP   -lt 16){ $IOCP=[math]::Max(16,$Workers*2) }
  if($PSCmdlet.ShouldProcess("ThreadPool","SetMinThreads W=$Workers IOCP=$IOCP")){ [void][System.Threading.ThreadPool]::SetMinThreads($Workers,$IOCP) }
  [pscustomobject]@{ Workers=$Workers; IOCP=$IOCP }
}
function Use-BackgroundMode {
  [CmdletBinding(SupportsShouldProcess)] param([switch]$Enable,[switch]$Disable)
  if($Enable -and $Disable){ throw "No mezcles -Enable y -Disable." }
  if(-not $Enable -and -not $Disable){ $Enable=$true }
  if($Enable){
    if($PSCmdlet.ShouldProcess("Proceso actual","BackgroundMode=BEGIN")){ if(-not [FMPrio]::BeginBackground()){ throw "No se pudo activar Background Mode." }; "Background Mode: BEGIN" }
  } else {
    if($PSCmdlet.ShouldProcess("Proceso actual","BackgroundMode=END")){ if(-not [FMPrio]::EndBackground()){ throw "No se pudo desactivar Background Mode." }; "Background Mode: END" }
  }
}
#endregion

#region Canal paralelo con backpressure
function New-BoundedChannel { [CmdletBinding()] param([int]$Capacity=1024) $opt=[BoundedChannelOptions]::new($Capacity); $opt.SingleReader=$false; $opt.SingleWriter=$false; [Channel]::CreateBounded([object],$opt) }
function Invoke-ParallelChannel {
  [CmdletBinding()] param([Parameter(Mandatory)]$Channel,[Parameter(Mandatory)][scriptblock]$Process,[int]$DegreeOfParallelism=8,[int]$RetryCount=0,[int]$RetryDelayMs=100)
  $reader=$Channel.Reader; $tasks=New-Object 'System.Collections.Generic.List[System.Threading.Tasks.Task]'
  for($i=0;$i -lt $DegreeOfParallelism;$i++){
    $tasks.Add([System.Threading.Tasks.Task]::Run({ param($r,$proc,$rc,$rd)
      while($r.WaitToReadAsync().AsTask().GetAwaiter().GetResult()){
        object $item;
        while($r.TryRead([ref]$item)){
          int $attempt=0; for(;;){ try{ & $proc $item; break } catch{ if($attempt -ge $rc){ throw }; Start-Sleep -Milliseconds $rd; $attempt++ } }
        }
      }
    }, @($reader,$Process,$RetryCount,$RetryDelayMs))) | Out-Null
  }
  $tasks
}
function Complete-Channel { [CmdletBinding()] param([Parameter(Mandatory)]$Channel,[System.Threading.Tasks.Task[]]$Workers) $Channel.Writer.Complete(); if($Workers){ [System.Threading.Tasks.Task]::WaitAll($Workers) } }
#endregion

#region JSONL Writer con rotación
$script:FM_JSON = [ordered]@{ Writer=$null; Path=$null; MaxMB=0; Compress=$false }
function New-JsonlWriter {
  [CmdletBinding(SupportsShouldProcess)] param([Parameter(Mandatory)][string]$Path,[int]$BufferMB=1,[switch]$Compress,[int]$RotateAtMB=768)
  if($PSCmdlet.ShouldProcess($Path,"Create JSONL writer")){
    $script:FM_JSON.Writer = [JsonlWriter]::new($Path,$BufferMB*1MB,[bool]$Compress,$true,$true)
    $script:FM_JSON.Path   = $Path; $script:FM_JSON.MaxMB=$RotateAtMB; $script:FM_JSON.Compress=[bool]$Compress
  }
}
function Write-Jsonl { [CmdletBinding()] param([Parameter(Mandatory)]$Object)
  $w=$script:FM_JSON.Writer; if(-not $w){ throw "Llama New-JsonlWriter primero." }
  $w.WriteObject($Object); Update-HiResMetrics -Bytes 0 -Items 1 | Out-Null
  $emittedMB = [double]$w.BytesEmitted / 1MB
  if($script:FM_JSON.MaxMB -gt 0 -and $emittedMB -ge $script:FM_JSON.MaxMB){
    $old=$script:FM_JSON.Path; $w.Dispose()
    $ts=(Get-Date).ToString('yyyyMMdd_HHmmss'); $ext=[IO.Path]::GetExtension($old); $base=[IO.Path]::ChangeExtension($old,$null)
    $rot = "{0}.{1}{2}" -f $base,$ts,$ext
    Move-Item -LiteralPath $old -Destination $rot -Force
    $script:FM_JSON.Writer = [JsonlWriter]::new($old,1MB,$script:FM_JSON.Compress,$true,$true)
  }
}
function Close-JsonlWriter { [CmdletBinding()] param() if($script:FM_JSON.Writer){ $script:FM_JSON.Writer.Dispose(); $script:FM_JSON.Writer=$null } }
#endregion

#region Métricas de presión y DOP recomendado
function Get-AvgDiskQueueLength {
  [CmdletBinding()] param([Parameter(Mandatory)][string]$DriveRoot)
  $pd = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk -ErrorAction SilentlyContinue | Where-Object Name -ne '_Total'
  if(-not $pd){ return $null }
  $vals = $pd.AvgDiskQueueLength | ForEach-Object { [double]$_ } | Where-Object { $_ -ge 0 }
  if(-not $vals){ return $null }
  $sorted = $vals | Sort-Object
  $p95 = $sorted[[Math]::Min([int][Math]::Floor($sorted.Count*0.95), $sorted.Count-1)]
  [double]$p95
}
function Get-RecommendedDOP {
  [CmdletBinding()] param([Parameter(Mandatory)][string]$Path,[int]$Min=1,[int]$Max=32)
  $cpu=[Environment]::ProcessorCount; $base=[Math]::Clamp([int][Math]::Round($cpu*1.5),$Min,$Max)
  try{
    $root=(Get-Item -LiteralPath $Path).PSDrive.Root
    $q=Get-AvgDiskQueueLength -DriveRoot $root
    if($q -ne $null){ if($q -gt 2.5){ $base=[Math]::Max($Min,$base-2) } elseif($q -lt 1.0){ $base=[Math]::Min($Max,$base+1) } }
  } catch {}
  return $base
}
#endregion

#region Copy con ETA real
function Copy-ItemWithETA {
  [CmdletBinding(SupportsShouldProcess)] param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[switch]$Overwrite)
  if($PSCmdlet.ShouldProcess("$Source → $Destination","Copy with progress")){
    $fi=[IO.FileInfo]::new($Source)
    Initialize-HiResMetrics -TotalBytes $fi.Length
    [FMCopy]::CopyWithProgress($Source,$Destination,{ param($done,$total)
      Update-HiResMetrics -Bytes 0 | Out-Null
      $snap=Get-HiResSnapshot; $snap.BytesDone=[int64]$done; if($total -gt 0){ $snap.Percent=[math]::Round(($done*100.0)/$total,3) }; $snap
    }, [bool]$Overwrite) | Out-Null
  }
}
#endregion

Export-ModuleMember -Function Initialize-HiResMetrics, Update-HiResMetrics, Get-HiResSnapshot, Start-ProgressTicker, Stop-ProgressTicker, `
  Optimize-ThreadPool, Use-BackgroundMode, New-BoundedChannel, Invoke-ParallelChannel, Complete-Channel, `
  New-JsonlWriter, Write-Jsonl, Close-JsonlWriter, Get-AvgDiskQueueLength, Get-RecommendedDOP, Copy-ItemWithETA
