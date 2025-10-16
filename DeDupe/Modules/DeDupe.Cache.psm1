# DeDupe.Cache
# Índice incremental para evitar re-hash:
#   - Backend A (preferido): SQLite (Microsoft.Data.Sqlite o System.Data.SQLite) en %LOCALAPPDATA%\DeDupe\index.sqlite
#   - Backend B (fallback):  JSONL + diccionario en memoria (%LOCALAPPDATA%\DeDupe\index.jsonl)
#
# Esquema lógico:
#   key: Path TEXT PRIMARY KEY
#   size_bytes INTEGER
#   mtime_utc  TEXT (o ticks)
#   mini_hash  TEXT (opcional)
#   sha256     TEXT (opcional)
#   seen_utc   TEXT
#
# Exporta:
#   New-FileIndex [-Path <dbPath>]               -> abre/crea el índice, autodetecta backend
#   Get-CacheInfo                                 -> info del backend activo
#   Get-CachedEntry   -Path <p> -Size <s> -MtimeUtc <iso>   -> entry si coincide size+mtime
#   Set-CachedEntry   -Path <p> -Size <s> -MtimeUtc <iso> -MiniHash <h> -SHA256 <h2>  -> upsert
#   Touch-CachedSeen  -Path <p>                              -> actualiza seen_utc
#   Compact-FileIndex                                       -> VACUUM / compacción JSONL
#
# Notas:
#   - No asume presencia de provider SQLite; si no se encuentra, cae a JSONL.
#   - Seguro ante rutas sin permisos: crea %LOCALAPPDATA%\DeDupe\ si es necesario.
#   - Integrable con DeDupe.Logging si está cargado (opcional).

using namespace System
using namespace System.IO
using namespace System.Collections.Generic
Set-StrictMode -Version Latest

$script:Cache = [ordered]@{
  Provider      = 'None'     # 'Sqlite-Microsoft' | 'Sqlite-System' | 'Jsonl'
  Path          = $null      # ruta a .sqlite o .jsonl
  Conn          = $null      # IDbConnection (si SQLite)
  Dict          = $null      # Dictionary[string, hashtable] (si JSONL)
  JsonlWriter   = $null      # usando DeDupe.Logging? opcional
  Initialized   = $false
}

function Resolve-CachePath {
  param([string]$Requested,[string]$Ext)
  try {
    $base = if ($Requested) { $Requested } else { Join-Path $env:LOCALAPPDATA 'DeDupe\index' }
    $p = if ($base -match '\.(sqlite|db|jsonl)$') { $base } else { "$base.$Ext" }
    $dir = Split-Path -Parent $p
    if (-not (Test-Path -LiteralPath $dir)) { [void][Directory]::CreateDirectory($dir) }
    return $p
  } catch {
    $fb = Join-Path $env:LOCALAPPDATA 'DeDupe\index'
    return "$fb.$Ext"
  }
}

function Try-LoadSqliteProvider {
  $loaded = $false
  try {
    Add-Type -AssemblyName 'Microsoft.Data.Sqlite' -ErrorAction Stop
    $script:Cache.Provider = 'Sqlite-Microsoft'
    $loaded = $true
  } catch {
    try {
      Add-Type -AssemblyName 'System.Data.SQLite' -ErrorAction Stop
      $script:Cache.Provider = 'Sqlite-System'
      $loaded = $true
    } catch { $loaded = $false }
  }
  return $loaded
}

function Open-SqliteConnection {
  param([string]$Path)
  if ($script:Cache.Provider -eq 'Sqlite-Microsoft') {
    $conn = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$Path;Pooling=True;Cache=Shared")
    $conn.Open()
    return $conn
  } elseif ($script:Cache.Provider -eq 'Sqlite-System') {
    $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$Path;Version=3;Pooling=True;Journal Mode=WAL;Synchronous=Normal;")
    $conn.Open()
    return $conn
  } else { throw "Proveedor SQLite no cargado." }
}

function Invoke-NonQuery {
  param($Conn,[string]$Sql)
  if ($Conn -is [Microsoft.Data.Sqlite.SqliteConnection]) {
    $cmd = $Conn.CreateCommand(); $cmd.CommandText = $Sql; [void]$cmd.ExecuteNonQuery()
  } else {
    $cmd = $Conn.CreateCommand(); $cmd.CommandText = $Sql; [void]$cmd.ExecuteNonQuery()
  }
}

function Ensure-SqliteSchema {
  param($Conn)
  $ddl = @"
CREATE TABLE IF NOT EXISTS files(
  path TEXT PRIMARY KEY,
  size_bytes INTEGER NOT NULL,
  mtime_utc  TEXT    NOT NULL,
  mini_hash  TEXT    NULL,
  sha256     TEXT    NULL,
  seen_utc   TEXT    NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_size_mtime ON files(size_bytes, mtime_utc);
"@
  Invoke-NonQuery -Conn $Conn -Sql $ddl
}

function New-FileIndex {
  [CmdletBinding()]
  param(
    [string]$Path
  )
  if (Try-LoadSqliteProvider) {
    $p = Resolve-CachePath -Requested $Path -Ext 'sqlite'
    $conn = Open-SqliteConnection -Path $p
    Ensure-SqliteSchema -Conn $conn
    $script:Cache.Path = $p
    $script:Cache.Conn = $conn
    $script:Cache.Dict = $null
    $script:Cache.Initialized = $true
    return [pscustomobject]@{ Provider=$script:Cache.Provider; Path=$p; Mode='SQLite' }
  } else {
    # Fallback JSONL
    $p = Resolve-CachePath -Requested $Path -Ext 'jsonl'
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force | Out-Null }
    $dict = [System.Collections.Generic.Dictionary[string,hashtable]]::new([System.StringComparer]::OrdinalIgnoreCase)
    # Carga incremental: parsea rápido las últimas N líneas (si > 50MB podrías querer truncar/compactar)
    $lenMB = [int](([new-object System.IO.FileInfo] $p).Length / 1MB)
    $lines = Get-Content -LiteralPath $p -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
      try {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $o = $line | ConvertFrom-Json -ErrorAction Stop
        if ($o.path) {
          $dict[$o.path] = @{
            path       = [string]$o.path
            size_bytes = [int64]$o.size_bytes
            mtime_utc  = [string]$o.mtime_utc
            mini_hash  = $o.mini_hash
            sha256     = $o.sha256
            seen_utc   = $o.seen_utc
          }
        }
      } catch {}
    }
    $script:Cache.Provider = 'Jsonl'
    $script:Cache.Path = $p
    $script:Cache.Dict = $dict
    $script:Cache.Conn = $null
    $script:Cache.Initialized = $true
    return [pscustomobject]@{ Provider='Jsonl'; Path=$p; Loaded=$dict.Count; SizeMB=$lenMB }
  }
}

function Get-CacheInfo {
  [CmdletBinding()] param()
  if (-not $script:Cache.Initialized) { throw "Llama New-FileIndex primero." }
  [pscustomobject]@{
    Provider = $script:Cache.Provider
    Path     = $script:Cache.Path
    Mode     = if ($script:Cache.Conn) { 'SQLite' } else { 'JSONL' }
    Entries  = if ($script:Cache.Conn) { $null } else { $script:Cache.Dict.Count }
  }
}

function Get-CachedEntry {
  <#
    .SYNOPSIS
      Busca entrada que coincida EXACTAMENTE con path + size + mtime_utc.
    .OUTPUTS
      Hashtable con campos {path,size_bytes,mtime_utc,mini_hash,sha256,seen_utc} o $null
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][int64]$Size,
    [Parameter(Mandatory)][string]$MtimeUtc
  )
  if (-not $script:Cache.Initialized) { throw "Llama New-FileIndex primero." }
  if ($script:Cache.Conn) {
    if ($script:Cache.Provider -eq 'Sqlite-Microsoft') {
      $cmd = $script:Cache.Conn.CreateCommand()
      $cmd.CommandText = 'SELECT path,size_bytes,mtime_utc,mini_hash,sha256,seen_utc FROM files WHERE path=$p AND size_bytes=$s AND mtime_utc=$m'
      $cmd.Parameters.AddWithValue('$p',$Path) | Out-Null
      $cmd.Parameters.AddWithValue('$s',$Size) | Out-Null
      $cmd.Parameters.AddWithValue('$m',$MtimeUtc) | Out-Null
      $r = $cmd.ExecuteReader()
      if ($r.Read()) {
        return @{
          path       = [string]$r.GetString(0)
          size_bytes = [int64]$r.GetInt64(1)
          mtime_utc  = [string]$r.GetString(2)
          mini_hash  = if ($r.IsDBNull(3)) { $null } else { $r.GetString(3) }
          sha256     = if ($r.IsDBNull(4)) { $null } else { $r.GetString(4) }
          seen_utc   = [string]$r.GetString(5)
        }
      } else { return $null }
    } else {
      $cmd = $script:Cache.Conn.CreateCommand()
      $cmd.CommandText = 'SELECT path,size_bytes,mtime_utc,mini_hash,sha256,seen_utc FROM files WHERE path=@p AND size_bytes=@s AND mtime_utc=@m'
      $p1=$cmd.CreateParameter(); $p1.ParameterName='@p'; $p1.Value=$Path; $cmd.Parameters.Add($p1) | Out-Null
      $p2=$cmd.CreateParameter(); $p2.ParameterName='@s'; $p2.Value=$Size; $cmd.Parameters.Add($p2) | Out-Null
      $p3=$cmd.CreateParameter(); $p3.ParameterName='@m'; $p3.Value=$MtimeUtc; $cmd.Parameters.Add($p3) | Out-Null
      $r = $cmd.ExecuteReader()
      if ($r.Read()) {
        return @{
          path       = [string]$r['path']
          size_bytes = [int64]$r['size_bytes']
          mtime_utc  = [string]$r['mtime_utc']
          mini_hash  = if ($r['mini_hash'] -is [DBNull]) { $null } else { [string]$r['mini_hash'] }
          sha256     = if ($r['sha256'] -is [DBNull]) { $null } else { [string]$r['sha256'] }
          seen_utc   = [string]$r['seen_utc']
        }
      } else { return $null }
    }
  } else {
    if ($script:Cache.Dict.TryGetValue($Path, [ref]$rec)) {
      if (($rec.size_bytes -eq $Size) -and ($rec.mtime_utc -eq $MtimeUtc)) { return $rec } else { return $null }
    } else { return $null }
  }
}

function Set-CachedEntry {
  <#
    .SYNOPSIS
      Upsert (path,size,mtime) y actualiza mini_hash / sha256 / seen_utc.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][int64]$Size,
    [Parameter(Mandatory)][string]$MtimeUtc,
    [string]$MiniHash,
    [string]$SHA256
  )
  if (-not $script:Cache.Initialized) { throw "Llama New-FileIndex primero." }
  $now = (Get-Date).ToUniversalTime().ToString('o')
  if ($script:Cache.Conn) {
    if ($script:Cache.Provider -eq 'Sqlite-Microsoft') {
      $sql = @"
INSERT INTO files(path,size_bytes,mtime_utc,mini_hash,sha256,seen_utc)
VALUES($p,$s,$m,$mh,$sha,$seen)
ON CONFLICT(path) DO UPDATE SET
  size_bytes=excluded.size_bytes,
  mtime_utc =excluded.mtime_utc,
  mini_hash =COALESCE(excluded.mini_hash, files.mini_hash),
  sha256    =COALESCE(excluded.sha256, files.sha256),
  seen_utc  =excluded.seen_utc;
"@
      $cmd = $script:Cache.Conn.CreateCommand(); $cmd.CommandText = $sql
      $cmd.Parameters.AddWithValue('$p',$Path)|Out-Null
      $cmd.Parameters.AddWithValue('$s',$Size)|Out-Null
      $cmd.Parameters.AddWithValue('$m',$MtimeUtc)|Out-Null
      $cmd.Parameters.AddWithValue('$mh',$MiniHash)|Out-Null
      $cmd.Parameters.AddWithValue('$sha',$SHA256)|Out-Null
      $cmd.Parameters.AddWithValue('$seen',$now)|Out-Null
      [void]$cmd.ExecuteNonQuery()
    } else {
      # System.Data.SQLite carece de "excluded" -> UPSERT vía INSERT OR REPLACE con merge manual
      $cmd = $script:Cache.Conn.CreateCommand()
      $cmd.CommandText = 'INSERT OR REPLACE INTO files(path,size_bytes,mtime_utc,mini_hash,sha256,seen_utc) VALUES(@p,@s,@m,@mh,@sha,@seen)'
      foreach ($kv in @{'@p'=$Path;'@s'=$Size;'@m'=$MtimeUtc;'@mh'=$MiniHash;'@sha'=$SHA256;'@seen'=$now}) {
        $p=$cmd.CreateParameter(); $p.ParameterName=$kv.Keys[0]; $p.Value=$kv.Values[0]; $cmd.Parameters.Add($p)|Out-Null
      }
      [void]$cmd.ExecuteNonQuery()
    }
  } else {
    $rec = @{
      path       = $Path
      size_bytes = $Size
      mtime_utc  = $MtimeUtc
      mini_hash  = $MiniHash
      sha256     = $SHA256
      seen_utc   = $now
    }
    $script:Cache.Dict[$Path] = $rec
    # Append línea JSON compacta
    $line = ($rec | ConvertTo-Json -Depth 4 -Compress)
    Add-Content -LiteralPath $script:Cache.Path -Value $line -Encoding UTF8
  }
}

function Touch-CachedSeen {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)
  if (-not $script:Cache.Initialized) { throw "Llama New-FileIndex primero." }
  $now = (Get-Date).ToUniversalTime().ToString('o')
  if ($script:Cache.Conn) {
    $sql = 'UPDATE files SET seen_utc=$seen WHERE path=$p'
    $cmd = $script:Cache.Conn.CreateCommand(); $cmd.CommandText=$sql
    $cmd.Parameters.AddWithValue('$seen',$now)|Out-Null
    $cmd.Parameters.AddWithValue('$p',$Path)|Out-Null
    [void]$cmd.ExecuteNonQuery()
  } else {
    if ($script:Cache.Dict.TryGetValue($Path, [ref]$rec)) {
      $rec.seen_utc = $now
      $line = ($rec | ConvertTo-Json -Depth 4 -Compress)
      Add-Content -LiteralPath $script:Cache.Path -Value $line -Encoding UTF8
    }
  }
}

function Compact-FileIndex {
  [CmdletBinding(SupportsShouldProcess)]
  param()
  if (-not $script:Cache.Initialized) { throw "Llama New-FileIndex primero." }
  if ($script:Cache.Conn) {
    if ($PSCmdlet.ShouldProcess($script:Cache.Path,'VACUUM')) {
      $cmd = $script:Cache.Conn.CreateCommand(); $cmd.CommandText = 'VACUUM;'
      [void]$cmd.ExecuteNonQuery()
    }
  } else {
    if ($PSCmdlet.ShouldProcess($script:Cache.Path,'Compact JSONL')) {
      $tmp = "$($script:Cache.Path).tmp"
      $out = New-Object System.Collections.Generic.List[string]
      foreach ($kv in $script:Cache.Dict.GetEnumerator()) {
        $out.Add( ($kv.Value | ConvertTo-Json -Depth 4 -Compress) )
      }
      Set-Content -LiteralPath $tmp -Value $out -Encoding UTF8
      Move-Item -LiteralPath $tmp -Destination $script:Cache.Path -Force
    }
  }
}

Export-ModuleMember -Function New-FileIndex, Get-CacheInfo, Get-CachedEntry, Set-CachedEntry, Touch-CachedSeen, Compact-FileIndex
