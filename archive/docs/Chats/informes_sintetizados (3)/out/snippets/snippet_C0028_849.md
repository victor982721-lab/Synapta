```powershell
# Dentro del foreach ($item in $items) { ... }

try {
    $isFile = -not $item.PSIsContainer

    $hash = ""
    $size = ""
    $ctime = $item.CreationTimeUtc
    $mtime = $item.LastWriteTimeUtc
    $atime = $item.LastAccessTimeUtc

    if ($isFile) {
        try {
            $h = Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256 -ErrorAction Stop
            $hash = $h.Hash.ToLower()
            $size = $item.Length
        } catch {
            $hash = "<error>"
            $size = ""
        }
    }

    $row = [pscustomobject]@{
        name       = $item.Name
        relpath    = $rel
        type       = if ($isFile) { "file" } else { "dir" }
        size_bytes = $size
        sha256     = $hash
        ctime_utc  = $ctime.ToString("yyyy-MM-dd HH:mm:ss")
        mtime_utc  = $mtime.ToString("yyyy-MM-dd HH:mm:ss")
        atime_utc  = $atime.ToString("yyyy-MM-dd HH:mm:ss")
    }

    # escribir en CSV/JSONL
    $csvWriter.WriteLine(($row | ConvertTo-Csv -NoTypeInformation -Delimiter ',' | Select-Object -Skip 1))
    $jsonWriter.WriteLine(($row | ConvertTo-Json -Compress -Depth 4))
}
catch {
    # manejar errores
}
```