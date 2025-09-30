```
<#
.SINOPSIS
    Genera un "FileMap" (árbol de directorios) bonito y eficiente para decenas de miles de archivos
    y, en paralelo, un inventario estructurado en CSV y/o JSON Lines (.jsonl) listo para análisis.

.DESCRIPCIÓN
    - Recorre un directorio raíz y escribe:
        1) Un árbol jerárquico en .md o .txt en el Escritorio del usuario activo.
        2) Un dataset tabular (CSV) y/o por líneas (NDJSON / .jsonl) con una fila por elemento.
    - Usa StreamWriter (rápido y de baja memoria) y maneja errores de acceso.
    - Compatible con PowerShell 5.1 (Windows 10). No requiere administrador.

.PARAMETROS
    -RootPath <string>      Ruta del directorio raíz a mapear. Debe existir.
    -OutputKind <md|txt>    Formato del árbol. (md por defecto).
    -MaxDepth <int>         Profundidad máxima; 0 = ilimitado. (0 por defecto).
    -IncludeHidden          Incluye Hidden/System.
    -ShowSizes              Muestra tamaño en el árbol (KB/MB/GB) y acumula total.
    -ShowDates              Muestra última modificación en el árbol.
    -ProgressInterval <int> Frecuencia de progreso (elementos). (500 por defecto).
    -EmitCsv                Genera inventario en CSV (por defecto: HABILITADO si no se especifica nada).
    -EmitJsonl              Genera inventario en JSONL (por defecto: HABILITADO si no se especifica nada).

.SALIDA (archivos en el Escritorio)
    - FileMap_<root>_<timestamp>.md|txt
    - FileList_<root>_<timestamp>.csv    (si -EmitCsv)
    - FileList_<root>_<timestamp>.jsonl  (si -EmitJsonl)

.CSV / JSONL — Esquema de columnas/campos
    relpath (ruta relativa), type (file|dir), name, ext, size_bytes, mtime_iso (local, ISO),
    depth (0 = raíz), attributes (banderas del sistema separadas por "|").

.EJEMPLOS
    # Árbol en Markdown + CSV + JSONL (por defecto ambos inventarios):
    .\New-FileMap.ps1 -RootPath 'D:\Datos' -ShowSizes -ShowDates

    # Solo árbol en texto + JSONL (sin CSV):
    .\New-FileMap.ps1 -RootPath 'C:\Proyectos' -OutputKind txt -EmitJsonl -EmitCsv:$false

    # Límite de profundidad y sin ocultos:
    .\New-FileMap.ps1 -RootPath '\\SRV01\Compartida' -MaxDepth 3

.NOTAS
    "Script Canónico" — puede ejecutarse con confianza.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$RootPath,
    [ValidateSet('md','txt')][string]$OutputKind = 'md',
    [ValidateRange(0,64)][int]$MaxDepth = 0,
    [switch]$IncludeHidden,
    [switch]$ShowSizes,
    [switch]$ShowDates,
    [ValidateRange(50,1000000)][int]$ProgressInterval = 500,
    [switch]$EmitCsv,
    [switch]$EmitJsonl
)

# --- Defaults para los inventarios ---
# Si el usuario NO especificó nada, habilitamos ambos por defecto.
if (-not $PSBoundParameters.ContainsKey('EmitCsv'))   { $EmitCsv   = $true }
if (-not $PSBoundParameters.ContainsKey('EmitJsonl')) { $EmitJsonl = $true }

$ErrorActionPreference = 'Stop'

# --- Validaciones de entrada ---
try {
    if (-not (Test-Path -LiteralPath $RootPath)) {
        throw "La ruta especificada no existe: $RootPath"
    }
    $item = Get-Item -LiteralPath $RootPath -ErrorAction Stop
    if (-not $item.PSIsContainer) { throw "La ruta debe ser un directorio: $RootPath" }
} catch {
    Write-Error ("Validación de parámetros: {0}" -f $_.Exception.Message)
    exit 1
}

# --- Utilidades ---
function Get-DesktopPath {
    try { return [Environment]::GetFolderPath('Desktop') }
    catch { return (Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop') }
}
function Format-Size { param([long]$Bytes)
    if ($Bytes -lt 1KB) { "{0} B" -f $Bytes }
    elseif ($Bytes -lt 1MB) { "{0:N2} KB" -f ($Bytes/1KB) }
    elseif ($Bytes -lt 1GB) { "{0:N2} MB" -f ($Bytes/1MB) }
    else { "{0:N2} GB" -f ($Bytes/1GB) }
}
function Is-Visible { param([System.IO.FileSystemInfo]$Info,[bool]$IncludeHidden=$false)
    if ($IncludeHidden) { return $true }
    -not ($Info.Attributes.HasFlag([IO.FileAttributes]::Hidden) -or $Info.Attributes.HasFlag([IO.FileAttributes]::System))
}
function Is-ReparsePoint { param([System.IO.FileSystemInfo]$Info)
    $Info.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)
}
function Get-ChildLists {
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$DirPath,[Parameter(Mandatory)][bool]$IncludeHidden)
    $dirs  = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    try {
        $di = New-Object System.IO.DirectoryInfo($DirPath)
        foreach($d in $di.EnumerateDirectories('*',[System.IO.SearchOption]::TopDirectoryOnly)){
            if (Is-Visible -Info $d -IncludeHidden:$IncludeHidden) {
                if (-not (Is-ReparsePoint -Info $d)) { $dirs.Add($d) }
            }
        }
        foreach($f in $di.EnumerateFiles('*',[System.IO.SearchOption]::TopDirectoryOnly)){
            if (Is-Visible -Info $f -IncludeHidden:$IncludeHidden) { $files.Add($f) }
        }
    } catch {
        Write-Verbose ("Sin acceso a: {0} ({1})" -f $DirPath, $_.Exception.Message)
    }
    @{ Dirs=$dirs; Files=$files }
}
function Build-Indent { param($HasMoreSiblings)
    if (-not $HasMoreSiblings -or $HasMoreSiblings.Count -eq 0) { return '' }
    $sb = New-Object System.Text.StringBuilder
    foreach($hasMore in $HasMoreSiblings){ if ($hasMore) { [void]$sb.Append('│   ') } else { [void]$sb.Append('    ') } }
    $sb.ToString()
}
function Get-RelativePath {
    param([string]$Base,[string]$Full)
    try {
        $b = New-Object System.Uri(($Base.TrimEnd('\')+'\'))
        $u = New-Object System.Uri($Full)
        $rel = $b.MakeRelativeUri($u).ToString()
        [System.Uri]::UnescapeDataString($rel).Replace('/','\')
    } catch { $Full }
}
# CSV helpers
function CsvEscape { param($s)
    if ($null -eq $s) { return '""' }
    $t = [string]$s -replace '"','""'
    '"' + $t + '"'
}
# JSON helpers
function JsonString { param($s)
    if ($null -eq $s) { return 'null' }
    $t = [string]$s
    $t = $t -replace '\\','\\\\'
    $t = $t -replace '"','\"'
    $t = $t -replace "`r",'\\r' -replace "`n",'\\n' -replace "`t",'\\t' -replace "`b",'\\b' -replace "`f",'\\f'
    '"' + $t + '"'
}

# --- Preparación de archivos de salida ---
$desktop = Get-DesktopPath
$rootName = Split-Path -Path $RootPath -Leaf
if ([string]::IsNullOrWhiteSpace($rootName)) { $rootName = ($RootPath -replace '[:\\\/]','_') }
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$baseName = ("{0}_{1}" -f ($rootName -replace '[^\w\.-]','_'), $ts)
$treeFile = Join-Path $desktop ("FileMap_{0}.{1}" -f $baseName, $OutputKind)
$csvFile  = Join-Path $desktop ("FileList_{0}.csv"   -f $baseName)
$jsonFile = Join-Path $desktop ("FileList_{0}.jsonl" -f $baseName)

# Contadores globales
$script:DirCount = 0L
$script:FileCount = 0L
$script:EntryCounter = 0L
$script:TotalBytes = 0L

# Caracteres de dibujo
$Chars = @{ Pipe='│   '; Space='    '; Tee='├── '; Elbow='└── '; Root='┬─ ' }

# Escritura eficiente
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$swTree = $null; $swCsv = $null; $swJson = $null

try {
    # Abrir escritores
    $swTree = New-Object System.IO.StreamWriter($treeFile, $false, $utf8NoBom)
    if ($EmitCsv)   { $swCsv  = New-Object System.IO.StreamWriter($csvFile,  $false, $utf8NoBom) }
    if ($EmitJsonl) { $swJson = New-Object System.IO.StreamWriter($jsonFile, $false, $utf8NoBom) }

    # Cabecera árbol
    if ($OutputKind -eq 'md') {
        $swTree.WriteLine([string]::Format('# FileMap - {0}', $RootPath))
        $swTree.WriteLine()
        $swTree.WriteLine([string]::Format('Generado: {0:yyyy-MM-dd HH:mm:ss} | Equipo: {1} | PowerShell: {2}', (Get-Date), $env:COMPUTERNAME, $PSVersionTable.PSVersion.ToString()))
        $swTree.WriteLine()
        $swTree.WriteLine('```')
    } else {
        $swTree.WriteLine([string]::Format('FileMap - {0}', $RootPath))
        $swTree.WriteLine([string]::Format('Generado: {0:yyyy-MM-dd HH:mm:ss} | Equipo: {1} | PowerShell: {2}', (Get-Date), $env:COMPUTERNAME, $PSVersionTable.PSVersion.ToString()))
        $swTree.WriteLine()
    }

    # Cabecera CSV
    if ($swCsv) {
        $swCsv.WriteLine('relpath,type,name,ext,size_bytes,mtime_iso,depth,attributes')
    }

    # Funciones para registrar filas en CSV/JSONL
    function Write-InventoryRows {
        param(
            [ValidateSet('dir','file')][string]$Kind,
            [System.IO.FileSystemInfo]$Info,
            [int]$Depth
        )
        $rel = Get-RelativePath -Base $RootPath -Full $Info.FullName
        if ([string]::IsNullOrWhiteSpace($rel)) { $rel = '.' }
        $name = $Info.Name
        $ext  = ''
        $size = 0
        if ($Kind -eq 'file') {
            $fi = [System.IO.FileInfo]$Info
            $ext = $fi.Extension.TrimStart('.').ToLowerInvariant()
            $size = [int64]$fi.Length
        }
        $mtime = $Info.LastWriteTime.ToString('s')  # ISO sin zona
        $attrs = $Info.Attributes.ToString().Replace(', ','|')

        if ($swCsv) {
            $swCsv.WriteLine(('{0},{1},{2},{3},{4},{5},{6},{7}' -f
                (CsvEscape $rel), (CsvEscape $Kind), (CsvEscape $name), (CsvEscape $ext),
                $size, (CsvEscape $mtime), $Depth, (CsvEscape $attrs)))
        }
        if ($swJson) {
            $swJson.WriteLine(
                '{' +
                '"relpath":'+(JsonString $rel)+','+
                '"type":'+(JsonString $Kind)+','+
                '"name":'+(JsonString $name)+','+
                '"ext":'+(JsonString $ext)+','+
                '"size_bytes":'+$size+','+
                '"mtime_iso":'+(JsonString $mtime)+','+
                '"depth":'+$Depth+','+
                '"attributes":'+(JsonString $attrs)+
                '}'
            )
        }
    }

    # Nodo raíz (árbol + inventarios)
    $rootMod = ''
    if ($ShowDates) { $rootMod = [string]::Format('  (mod: {0:yyyy-MM-dd HH:mm})', (Get-Item -LiteralPath $RootPath).LastWriteTime) }
    $rootLine = [string]::Format('{0}[DIR] {1}{2}', $Chars.Root, $RootPath, $rootMod)
    $swTree.WriteLine((Build-Indent @()) + $rootLine)
    $script:DirCount++
    Write-InventoryRows -Kind dir -Info $item -Depth 0

    # Recorrido recursivo
    function Write-Tree {
        param(
            [Parameter(Mandatory)][string]$CurrentPath,
            [Parameter(Mandatory)][int]$Depth,
            [Parameter(Mandatory)]$AncestorsHasMore
        )

        if ($MaxDepth -gt 0 -and $Depth -ge $MaxDepth) { return }

        $lists = Get-ChildLists -DirPath $CurrentPath -IncludeHidden:$IncludeHidden.IsPresent
        $dirs  = $lists.Dirs
        $files = $lists.Files

        $children = New-Object System.Collections.Generic.List[object]
        foreach($d in $dirs){ [void]$children.Add(@{ Kind='Dir'; Info=$d }) }
        foreach($f in $files){ [void]$children.Add(@{ Kind='File'; Info=$f }) }

        $count = $children.Count
        for ($i=0; $i -lt $count; $i++) {
            $child = $children[$i]
            $isLast = ($i -eq $count - 1)
            $indent = Build-Indent -HasMoreSiblings $AncestorsHasMore
            $branch = if ($isLast) { $Chars.Elbow } else { $Chars.Tee }
            $childDepth = $Depth + 1

            if ($child.Kind -eq 'Dir') {
                $script:DirCount++; $script:EntryCounter++
                $dirInfo = [System.IO.DirectoryInfo]$child.Info
                $name = $dirInfo.Name
                $meta = ''
                if ($ShowDates) { $meta = [string]::Format(' (mod: {0:yyyy-MM-dd HH:mm})', $dirInfo.LastWriteTime) }

                $swTree.WriteLine([string]::Format('{0}{1}[DIR] {2}{3}', $indent, $branch, $name, $meta))
                Write-InventoryRows -Kind dir -Info $dirInfo -Depth $childDepth

                if (($script:EntryCounter % $ProgressInterval) -eq 0) {
                    Write-Progress -Activity 'Generando FileMap' -Status ([string]::Format('Procesados: {0:N0} elementos', $script:EntryCounter))
                }

                $nextAncestors = $AncestorsHasMore + @(( -not $isLast ))
                Write-Tree -CurrentPath $dirInfo.FullName -Depth $childDepth -AncestorsHasMore $nextAncestors
            }
            else {
                $script:FileCount++; $script:EntryCounter++
                $fileInfo = [System.IO.FileInfo]$child.Info
                $name = $fileInfo.Name
                $metaParts = New-Object System.Collections.Generic.List[string]
                if ($ShowSizes) { $script:TotalBytes += $fileInfo.Length; [void]$metaParts.Add((Format-Size $fileInfo.Length)) }
                if ($ShowDates) { [void]$metaParts.Add([string]::Format('mod: {0:yyyy-MM-dd HH:mm}', $fileInfo.LastWriteTime)) }
                $meta = if ($metaParts.Count -gt 0) { ' - ' + [string]::Join(' | ', $metaParts.ToArray()) } else { '' }

                $swTree.WriteLine([string]::Format('{0}{1}{2}{3}', $indent, $branch, $name, $meta))
                Write-InventoryRows -Kind file -Info $fileInfo -Depth $childDepth

                if (($script:EntryCounter % $ProgressInterval) -eq 0) {
                    Write-Progress -Activity 'Generando FileMap' -Status ([string]::Format('Procesados: {0:N0} elementos', $script:EntryCounter))
                }
            }
        }
    }

    Write-Tree -CurrentPath $item.FullName -Depth 0 -AncestorsHasMore @()

    # Pie y resumen del árbol
    if ($OutputKind -eq 'md') { $swTree.WriteLine('```'); $swTree.WriteLine() }
    $summaryTail = if ($ShowSizes) { ', total archivos: ' + (Format-Size $script:TotalBytes) } else { '' }
    $swTree.WriteLine([string]::Format('Resumen: {0:N0} directorios, {1:N0} archivos{2}.', $script:DirCount, $script:FileCount, $summaryTail))

    # Mensajes
    Write-Host ("✔ FileMap generado en: {0}" -f $treeFile)
    if ($swCsv)  { Write-Host ("✔ CSV generado en:     {0}" -f $csvFile) }
    if ($swJson) { Write-Host ("✔ JSONL generado en:   {0}" -f $jsonFile) }
    Write-Host '   Sugerencia: usa una fuente monoespaciada para apreciar la estructura.'
}
catch {
    Write-Error ("Error durante la generación: {0}" -f $_.Exception.Message)
    foreach($w in @($swTree,$swCsv,$swJson)){ if ($w){ try { $w.Flush(); $w.Dispose() } catch {} } }
    exit 1
}
finally {
    foreach($w in @($swTree,$swCsv,$swJson)){ if ($w){ try { $w.Flush(); $w.Dispose() } catch {} } }
    Write-Progress -Activity 'Generando FileMap' -Completed
}

# Enlaces ASCII finales (útiles para copiar/pegar o redirigir)
""
"OUTPUT => $treeFile"
if ($EmitCsv)   { "OUTPUT => $csvFile" }
if ($EmitJsonl) { "OUTPUT => $jsonFile" }
```