```powershell
# Dedup-YSD-FromFilemap.ps1
# - Lee filemap CSV (relpath) para localizar archivos .ysd/.dcy (y opcionalmente admin1.edb)
# - Calcula SHA256, conserva 1 por contenido (prioriza .ysd, evita temp*), renombra a ASCII seguro y elimina duplicados
# - Registra acciones en CSV
# Requiere: PowerShell 7+

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    # Ruta al filemap CSV (con columnas: relpath,type,name,ext,size_bytes,mtime_iso,depth,attributes)
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$FileMap,

    # Raíz base donde viven los relpath del CSV. Si no se indica, se intenta autodetectar.
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$RootPath,

    # Raíces candidatas para autodetección si -RootPath no se pasa.
    [string[]]$CandidateRoots = @(
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA\user1_zip_extracted'),
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'TBEA'),
        ([Environment]::GetFolderPath('Desktop')),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'),
        (Get-Location).Path
    ),

    # Incluir/eliminar admin1.edb (metadatos internos del programa)
    [switch]$KeepInternalEdb
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-Diacritics([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
    $n = $Text.Normalize([Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $n.ToCharArray()) {
        $cat = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($cat -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
    }
    ($sb.ToString() -replace '[^A-Za-z0-9._-]', '_')
}

function Get-DesirabilityScore([System.IO.FileInfo]$File) {
    $ext = $File.Extension.ToLowerInvariant()
    $name = $File.BaseName
    $score = 0
    switch ($ext) {
        '.ysd' { $score += 0 }
        '.dcy' { $score += 5 }
        default { $score += 10 }
    }
    if ($name -match '^(?i)temp') { $score += 5 }
    if ($name -match '[^\x00-\x7F]') { $score += 2 }
    return $score
}

function Infer-DateFromName([string]$BaseName) {
    if ($BaseName -match '\b(20\d{6})\b') {
        $y = [int]$Matches[1].Substring(0,4); $m = [int]$Matches[1].Substring(4,2); $d = [int]$Matches[1].Substring(6,2)
        if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) { return [datetime]::new($y,$m,$d) }
    }
    if ($BaseName -match '\b(\d{6})\b') {
        $yy = [int]$Matches[1].Substring(0,2); $m = [int]$Matches[1].Substring(2,2); $d = [int]$Matches[1].Substring(4,2)
        if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) { return [datetime]::new(2000+$yy,$m,$d) }
    }
    return $null
}

function Resolve-RootFromFilemap([object[]]$Rows, [string[]]$Candidates) {
    foreach ($root in $Candidates) {
        try {
            if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
            # si al menos uno de los relpath existe bajo esta raíz, la adoptamos
            foreach ($r in $Rows) {
                $p = Join-Path $root ($r.relpath -replace '^[\\/]+','' )
                if (Test-Path -LiteralPath $p -PathType Leaf) { return $root }
            }
        } catch { continue }
    }
    return $null
}

# 1) Leer CSV
$rows = Import-Csv -LiteralPath $FileMap

if (-not $RootPath) {
    $RootPath = Resolve-RootFromFilemap -Rows $rows -Candidates $CandidateRoots
    if (-not $RootPath) {
        throw "No se pudo autodetectar la raíz. Pasa -RootPath apuntando a la carpeta que contiene los relpath del CSV."
    }
}

# 2) Construir lista de archivos objetivo a partir del CSV
$targets = foreach ($r in $rows) {
    $ext = ($r.ext ?? '').ToString()
    if ($ext -and ($ext[0] -ne '.')) { $ext = ".$ext" }
    $isData = $ext -match '^\.(ysd|dcy)$'
    $isEdb  = ($r.name -eq 'admin1.edb') -or ($ext -eq '.edb')
    if ($isData -or ($isEdb -and $KeepInternalEdb)) {
        $rel = ($r.relpath ?? '').ToString()
        $rel = $rel -replace '^[\\/]+',''
        $abs = Join-Path $RootPath $rel
        [pscustomobject]@{
            relpath = $rel
            abspath = $abs
            ext     = $ext.ToLowerInvariant()
        }
    }
}

if (-not $targets) {
    Write-Error "El filemap no contiene .ysd/.dcy (o admin1.edb con -KeepInternalEdb)."
    return
}

# 3) Verificar existencia y separar faltantes
$existing = @()
$missing  = @()
foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t.abspath -PathType Leaf) { $existing += $t } else { $missing += $t }
}

if ($missing.Count -gt 0) {
    Write-Warning ("{0} archivos del CSV no se encontraron bajo la raíz: {1}" -f $missing.Count, $RootPath)
    $missing | ForEach-Object { Write-Host " - faltante: $($_.relpath)" }
}

if ($existing.Count -eq 0) {
    Write-Error "No hay archivos presentes para procesar."
    return
}

# 4) Calcular SHA256 y agrupar por contenido
$byHash = @{}
foreach ($t in $existing) {
    $fi = Get-Item -LiteralPath $t.abspath
    $h  = Get-FileHash -LiteralPath $fi.FullName -Algorithm SHA256
    $rec = [pscustomobject]@{ File=$fi; Hash=$h.Hash }
    $byHash[$h.Hash] = @() + ($byHash[$h.Hash]) + ,$rec
}

# 5) Logging
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$logPath   = Join-Path $RootPath ("actions_dedup_{0}.csv" -f $timestamp)
"Action,Path,Target,Hash,Notes" | Out-File -LiteralPath $logPath -Encoding UTF8
function Log([string]$Action,[string]$Path,[string]$Target,[string]$Hash,[string]$Notes) {
    $line = '"' + ($Action -replace '"','""') + '","' +
                 ($Path -replace '"','""')   + '","' +
                 ($Target -replace '"','""') + '","' +
                 ($Hash -replace '"','""')   + '","' +
                 ($Notes -replace '"','""')  + '"'
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

# 6) Procesar cada grupo de duplicados
foreach ($entry in $byHash.GetEnumerator()) {
    $hash  = $entry.Key
    $files = $entry.Value | ForEach-Object { $_.File }

    # Elegir keeper
    $keeper = $files | Sort-Object `
        @{Expression={ Get-DesirabilityScore $_ }}, `
        @{Expression={$_.FullName.Length}}, `
        @{Expression={$_.Name}} | Select-Object -First 1

    $ext  = $keeper.Extension.ToLowerInvariant()
    $base = $keeper.BaseName

    # Normalizar nombre → ASCII seguro + fecha si aplica
    $safeBase = Remove-Diacritics $base
    $safeBase = if ($safeBase) { $safeBase } else { '' }
    $safeBase = $safeBase -replace '[^A-Za-z0-9._-]', '_'
    if (-not ($safeBase -match '[A-Za-z0-9]')) {
        $dt = Infer-DateFromName $base
        if ($dt) { $safeBase = 'YSD_{0}' -f $dt.ToString('yyyy-MM-dd') }
        else     { $safeBase = 'YSD_{0}' -f $hash.Substring(0,8) }
    } else {
        $dt2 = Infer-DateFromName $base
        if ($dt2 -ne $null -and -not ($safeBase -like 'YSD_*')) {
            $safeBase = 'YSD_{0}_{1}' -f $dt2.ToString('yyyy-MM-dd'), $safeBase
        }
    }

    $targetName = "$safeBase$ext"
    $targetPath = Join-Path $keeper.DirectoryName $targetName

    # Resolver colisiones
    $suffix = 1
    while (Test-Path -LiteralPath $targetPath) {
        $existingHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
        if ($existingHash -eq $hash) {
            if ($keeper.FullName -ne $targetPath) {
                if ($PSCmdlet.ShouldProcess($keeper.FullName, "Remove duplicate (already have target)")) {
                    Remove-Item -LiteralPath $keeper.FullName -Force
                    Log 'DELETE' $keeper.FullName $targetPath $hash 'Duplicate of existing target'
                }
                $keeper = Get-Item -LiteralPath $targetPath
            }
            break
        } else {
            $targetName = "{0}__{1}{2}" -f $safeBase, $suffix, $ext
            $targetPath = Join-Path $keeper.DirectoryName $targetName
            $suffix++
        }
    }

    # Renombrar keeper si procede
    if ($keeper.FullName -ne $targetPath -and -not (Test-Path -LiteralPath $targetPath)) {
        if ($PSCmdlet.ShouldProcess($keeper.FullName, "Rename to $targetName")) {
            Rename-Item -LiteralPath $keeper.FullName -NewName $targetName -Force
            Log 'RENAME' $keeper.FullName $targetPath $hash 'Keeper normalized to ASCII-safe name'
            $keeper = Get-Item -LiteralPath $targetPath
        }
    }

    # Eliminar duplicados restantes
    foreach ($f in $files) {
        if ($f.FullName -ne $keeper.FullName) {
            if ($PSCmdlet.ShouldProcess($f.FullName, "Delete duplicate")) {
                Remove-Item -LiteralPath $f.FullName -Force
                Log 'DELETE' $f.FullName $keeper.FullName $hash 'Duplicate removed'
            }
        }
    }
}

Write-Host "Listo. Registro de acciones: $logPath"
```