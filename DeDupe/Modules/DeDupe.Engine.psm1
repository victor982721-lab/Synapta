# DeDupe.Engine
# Hot-path en C#:
#   - Hash SHA-256 de archivos con buffer grande y callbacks de progreso (IProgress<long>)
#   - Comparación byte-a-byte rápida con progreso (StreamsEqual)
#   - MiniHash de 64 KiB (head+middle+tail) para pre-filtrado
#   - FileId/Hardlinks (NTFS): identificación física y utilidades de hardlink
# Wrappers PowerShell:
#   - Invoke-EngineHash, Test-EngineStreamsEqual, Get-EngineMiniHash
#   - Get-EngineFileId, Test-EngineSameFile, New-EngineHardLink
#
# Integra progreso en tu métrica:
#   $act = [System.Action[long]]{ param([long]$d) Update-HiResMetrics -Bytes $d }
#   $prog = [System.Progress[long]]::new($act)
#   [DeDupeEngine]::HashFileSha256($path,1MB,256KB,$prog,[System.Threading.CancellationToken]::None)

using namespace System
using namespace System.IO
using namespace System.Buffers
using namespace System.Text
using namespace System.Security.Cryptography
using namespace System.Threading
using namespace Microsoft.Win32.SafeHandles

Set-StrictMode -Version Latest

# ---------- C# backend ----------
Add-Type -Language CSharp -IgnoreWarnings -TypeDefinition @"
using System;
using System.IO;
using System.Buffers;
using System.Text;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.Win32.SafeHandles;

public sealed class DeDupeEngine
{
    // ====== Hashing ======
    public static byte[] HashFileSha256(string path, int blockSizeBytes, long reportEveryBytes, IProgress<long> progress, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));
        if (blockSizeBytes <= 0) blockSizeBytes = 1024 * 1024; // 1 MiB
        using var fs = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 1024 * 1024, FileOptions.SequentialScan);
        using var hasher = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        byte[] buf = ArrayPool<byte>.Shared.Rent(blockSizeBytes);
        long acc = 0;
        try
        {
            while (true)
            {
                ct.ThrowIfCancellationRequested();
                int r = fs.Read(buf, 0, blockSizeBytes);
                if (r <= 0) break;
                hasher.AppendData(buf, 0, r);
                if (reportEveryBytes > 0)
                {
                    acc += r;
                    if (acc >= reportEveryBytes)
                    {
                        progress?.Report(acc);
                        acc = 0;
                    }
                }
            }
            if (acc > 0) progress?.Report(acc);
            return hasher.GetHashAndReset();
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buf, false);
        }
    }

    // ====== Mini-hash: 3 ventanas (head+middle+tail) total ~64 KiB por defecto ======
    public static byte[] MiniHash64K(string path, int windowBytes)
    {
        if (windowBytes <= 0) windowBytes = 65536 / 3; // ~21.8 KiB cada segmento
        using var fs = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 1024 * 256, FileOptions.SequentialScan);
        long len = fs.Length;
        if (len <= (windowBytes * 3))
        {
            // archivo pequeño → hash completo
            using var ih = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
            byte[] tmp = new byte[8192];
            int r;
            while ((r = fs.Read(tmp, 0, tmp.Length)) > 0) ih.AppendData(tmp, 0, r);
            return ih.GetHashAndReset();
        }

        long midStart = Math.Max(0, (len / 2) - (windowBytes / 2));
        long tailStart = Math.Max(0, len - windowBytes);

        using var ih2 = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        ReadWindow(fs, 0, windowBytes, ih2);
        ReadWindow(fs, midStart, windowBytes, ih2);
        ReadWindow(fs, tailStart, windowBytes, ih2);
        return ih2.GetHashAndReset();

        static void ReadWindow(FileStream fs, long start, int win, IncrementalHash ih)
        {
            fs.Position = start;
            byte[] buf = new byte[Math.Min(win, 64 * 1024)];
            int remaining = win;
            while (remaining > 0)
            {
                int toRead = Math.Min(remaining, buf.Length);
                int r = fs.Read(buf, 0, toRead);
                if (r <= 0) break;
                ih.AppendData(buf, 0, r);
                remaining -= r;
            }
        }
    }

    // ====== Comparación de streams (byte-a-byte) con progreso opcional ======
    public static bool StreamsEqual(string a, string b, int blockSizeBytes, long reportEveryBytes, IProgress<long> progress, CancellationToken ct)
    {
        if (blockSizeBytes <= 0) blockSizeBytes = 1024 * 1024;
        using var fa = new FileStream(a, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 1024 * 1024, FileOptions.SequentialScan);
        using var fb = new FileStream(b, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 1024 * 1024, FileOptions.SequentialScan);
        if (fa.Length != fb.Length) return false;

        byte[] ba = ArrayPool<byte>.Shared.Rent(blockSizeBytes);
        byte[] bb = ArrayPool<byte>.Shared.Rent(blockSizeBytes);
        long acc = 0;
        try
        {
            while (true)
            {
                ct.ThrowIfCancellationRequested();
                int ra = fa.Read(ba, 0, blockSizeBytes);
                int rb = fb.Read(bb, 0, blockSizeBytes);
                if (ra != rb) return false;
                if (ra <= 0) break;
                for (int i = 0; i < ra; i++)
                    if (ba[i] != bb[i]) return false;

                if (reportEveryBytes > 0)
                {
                    acc += ra;
                    if (acc >= reportEveryBytes)
                    {
                        progress?.Report(acc);
                        acc = 0;
                    }
                }
            }
            if (acc > 0) progress?.Report(acc);
            return true;
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(ba, false);
            ArrayPool<byte>.Shared.Return(bb, false);
        }
    }

    // ====== FileId / Hardlinks (NTFS) ======
    [StructLayout(LayoutKind.Sequential)]
    struct BY_HANDLE_FILE_INFORMATION
    {
        public uint FileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWriteTime;
        public uint VolumeSerialNumber;
        public uint FileSizeHigh;
        public uint FileSizeLow;
        public uint NumberOfLinks;
        public uint FileIndexHigh;
        public uint FileIndexLow;
    }

    const uint FILE_READ_ATTRIBUTES = 0x80;
    const uint FILE_SHARE_READ = 0x1;
    const uint FILE_SHARE_WRITE = 0x2;
    const uint FILE_SHARE_DELETE = 0x4;
    const uint OPEN_EXISTING = 3;
    const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFile(string lpFileName, uint dwDesiredAccess, uint dwShareMode,
        IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetFileInformationByHandle(SafeFileHandle hFile, out BY_HANDLE_FILE_INFORMATION lpFileInformation);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateHardLink(string lpFileName, string lpExistingFileName, IntPtr lpSecurityAttributes);

    public sealed class FileIdentity
    {
        public ulong VolumeSerial { get; init; }
        public ulong FileIndex { get; init; }
        public uint LinkCount { get; init; }
        public string VolumeSerialHex => VolumeSerial.ToString("X");
        public string FileIndexHex => FileIndex.ToString("X");
    }

    public static FileIdentity GetFileIdentity(string path)
    {
        using var h = CreateFile(path, FILE_READ_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
        if (h.IsInvalid) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        if (!GetFileInformationByHandle(h, out var info))
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        ulong idx = ((ulong)info.FileIndexHigh << 32) | info.FileIndexLow;
        return new FileIdentity { VolumeSerial = info.VolumeSerialNumber, FileIndex = idx, LinkCount = info.NumberOfLinks };
    }

    public static bool AreSamePhysicalFile(string a, string b)
    {
        var ia = GetFileIdentity(a);
        var ib = GetFileIdentity(b);
        return ia.VolumeSerial == ib.VolumeSerial && ia.FileIndex == ib.FileIndex;
    }

    public static void CreateHardLinkChecked(string newLinkPath, string existingPath, bool overwrite)
    {
        if (overwrite && File.Exists(newLinkPath)) File.Delete(newLinkPath);
        if (!CreateHardLink(newLinkPath, existingPath, IntPtr.Zero))
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    }
}
"@

# ---------- Helpers ----------
function Convert-BytesToHex {
  param([byte[]]$Bytes)
  $sb = [System.Text.StringBuilder]::new($Bytes.Length*2)
  foreach($b in $Bytes){ [void]$sb.AppendFormat('{0:x2}',$b) }
  $sb.ToString()
}

# ---------- Wrappers PowerShell ----------
function Invoke-EngineHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [int]$BlockSizeKB = 1024,
    [int]$ReportEveryKB = 256,
    [scriptblock]$OnProgress,
    [System.Threading.CancellationToken]$CancellationToken = [System.Threading.CancellationToken]::None
  )
  if (-not (Test-Path -LiteralPath $Path)) { throw "Ruta no encontrada: $Path" }
  $prog = $null
  if ($OnProgress) {
    $act = [System.Action[long]] { param([long]$delta) & $OnProgress $delta }
    $prog = [System.Progress[long]]::new($act)
  }
  $bytes = [DeDupeEngine]::HashFileSha256($Path, $BlockSizeKB*1024, [int64]($ReportEveryKB*1024), $prog, $CancellationToken)
  $fi = [System.IO.FileInfo]::new($Path)
  [pscustomobject]@{
    Path   = $fi.FullName
    Size   = [int64]$fi.Length
    Hash   = (Convert-BytesToHex $bytes)
    Algo   = 'SHA-256'
    Source = 'DeDupe.Engine'
  }
}

function Test-EngineStreamsEqual {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$PathA,
    [Parameter(Mandatory)][string]$PathB,
    [int]$BlockSizeKB = 1024,
    [int]$ReportEveryKB = 512,
    [scriptblock]$OnProgress,
    [System.Threading.CancellationToken]$CancellationToken = [System.Threading.CancellationToken]::None
  )
  if (-not (Test-Path -LiteralPath $PathA)) { throw "Ruta no encontrada: $PathA" }
  if (-not (Test-Path -LiteralPath $PathB)) { throw "Ruta no encontrada: $PathB" }
  $prog = $null
  if ($OnProgress) {
    $act = [System.Action[long]] { param([long]$delta) & $OnProgress $delta }
    $prog = [System.Progress[long]]::new($act)
  }
  [DeDupeEngine]::StreamsEqual($PathA,$PathB,$BlockSizeKB*1024,[int64]($ReportEveryKB*1024),$prog,$CancellationToken)
}

function Get-EngineMiniHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$WindowBytes = 65536
  )
  if (-not (Test-Path -LiteralPath $Path)) { throw "Ruta no encontrada: $Path" }
  $raw = [DeDupeEngine]::MiniHash64K($Path,[int]$WindowBytes)
  [pscustomobject]@{
    Path = (Resolve-Path -LiteralPath $Path).Path
    MiniHash = (Convert-BytesToHex $raw)
    WindowBytes = [int]$WindowBytes
  }
}

function Get-EngineFileId {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "Ruta no encontrada: $Path" }
  $id = [DeDupeEngine]::GetFileIdentity($Path)
  [pscustomobject]@{
    Path           = (Resolve-Path -LiteralPath $Path).Path
    VolumeSerial   = $id.VolumeSerial
    VolumeSerialHex= $id.VolumeSerialHex
    FileIndex      = $id.FileIndex
    FileIndexHex   = $id.FileIndexHex
    LinkCount      = $id.LinkCount
  }
}

function Test-EngineSameFile {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PathA,[Parameter(Mandatory)][string]$PathB)
  if (-not (Test-Path -LiteralPath $PathA)) { throw "Ruta no encontrada: $PathA" }
  if (-not (Test-Path -LiteralPath $PathB)) { throw "Ruta no encontrada: $PathB" }
  [DeDupeEngine]::AreSamePhysicalFile($PathA,$PathB)
}

function New-EngineHardLink {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
  param(
    [Parameter(Mandatory)][string]$ExistingPath,
    [Parameter(Mandatory)][string]$NewLinkPath,
    [switch]$Overwrite
  )
  if ($PSCmdlet.ShouldProcess($NewLinkPath,"Create hardlink to $ExistingPath")) {
    [DeDupeEngine]::CreateHardLinkChecked($NewLinkPath,$ExistingPath,[bool]$Overwrite)
    Get-EngineFileId -Path $NewLinkPath
  }
}

Export-ModuleMember -Function Invoke-EngineHash, Test-EngineStreamsEqual, Get-EngineMiniHash, Get-EngineFileId, Test-EngineSameFile, New-EngineHardLink
