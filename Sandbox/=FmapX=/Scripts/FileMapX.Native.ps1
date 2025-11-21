function Initialize-NativeInterop {
  param([bool]$IsWindowsPlatform)
  if (-not $IsWindowsPlatform) { return $false }
  try {
    if (-not ('Native.Win32' -as [type])) {
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

  $script:Win32NativeAvailable = ('Native.Win32' -as [type]) -and ('Native.FileId' -as [type])
  return $script:Win32NativeAvailable
}

# ==============================================================================================================================

function Get-FileSizesFastWin32 {
  param([Parameter(Mandatory)][string]$Root)
  if (-not (Test-Path -LiteralPath $Root)) { return }
  $ntRoot = if ($Root.StartsWith('\\\\?\\')) { $Root } else { "\\\\?\\$Root" }
  $stack = [System.Collections.Generic.Stack[string]]::new()
  $stack.Push($ntRoot)
  while ($stack.Count -gt 0) {
    $dir = $stack.Pop()
    try {
      $search = [System.IO.Path]::Combine($dir, '*')
      $findData = New-Object 'Native.Win32+WIN32_FIND_DATAW'
      $h = [Native.Win32]::FindFirstFileExW(
        $search,
        [Native.Win32+FINDEX_INFO_LEVELS]::FindExInfoBasic,
        [ref]$findData,
        [Native.Win32+FINDEX_SEARCH_OPS]::FindExSearchNameMatch,
        [IntPtr]::Zero,
        [Native.Win32]::FIND_FIRST_EX_LARGE_FETCH)
      if ($h -eq [IntPtr]::Zero -or $h.ToInt64() -eq -1) { continue }
      try {
        while ($true) {
          $name = $findData.cFileName
          if ($name -ne '.' -and $name -ne '..') {
            $attrs = $findData.dwFileAttributes
            $isDir = (($attrs -band [Native.Win32]::FILE_ATTRIBUTE_DIRECTORY) -ne 0)
            $isReparse = (($attrs -band [Native.Win32]::FILE_ATTRIBUTE_REPARSE_POINT) -ne 0)
            if ($isDir -and -not $isReparse) {
              $stack.Push([System.IO.Path]::Combine($dir,$name))
            } else {
              $len = ([int64]$findData.nFileSizeHigh -shl 32) -bor ([uint32]$findData.nFileSizeLow)
              Write-Output $len
            }
          }
          $ok = [Native.Win32]::FindNextFileW($h,[ref]$findData)
          if (-not $ok) { break }
        }
      } finally {
        [Native.Win32]::FindClose($h) | Out-Null
      }
    } catch { }
  }
}