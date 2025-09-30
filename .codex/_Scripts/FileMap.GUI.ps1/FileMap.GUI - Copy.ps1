#Requires -Version 7.0
<#
  FileMap.GUI.ps1 — GUI y CLI para mapear carpetas/archivos y validar calidad
  Cambios clave:
    - Refactorización modular y configuración inicial declarativa.
    - Barra de progreso + ETA integrada y alimentada desde un BackgroundWorker.
    - Hashing y fingerprints paralelos mediante runspace pool reutilizable.
    - Nuevo modo CLI (-Headless) y modo CI (-ValidateOnly) para pipelines.
    - Integración automática de PSScriptAnalyzer + Pester (con cobertura) y exporte de resultados de calidad.
    - Exportes en CSV, JSON y Markdown con resumen de calidad.
    - Manejo robusto de errores y logging en GUI.
    - Comentarios explicativos sobre progreso/ETA y paralelismo para mantenimiento futuro.
#>

[CmdletBinding(DefaultParameterSetName = 'Gui')]
param(
    [Parameter(ParameterSetName = 'Validation', Mandatory)]
    [switch]$ValidateOnly,

    [Parameter(ParameterSetName = 'Cli', Mandatory)]
    [switch]$Headless,
    [Parameter(ParameterSetName = 'Cli', Mandatory)]
    [string]$RootPath,
    [Parameter(ParameterSetName = 'Cli', Mandatory)]
    [string]$OutDir,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$IncludeHidden,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$IncludeRoot,
    [Parameter(ParameterSetName = 'Cli')]
    [int]$MaxDepth = 0,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$DeepContentHash,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$FileContentHash,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$DoFolderMap,
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$DoFileMap,
    [Parameter(ParameterSetName = 'Cli')]
    [ValidateSet('Error','Warning','Information')]
    [string]$Severity = 'Error',
    [Parameter(ParameterSetName = 'Cli')]
    [string[]]$ExportFormat = @('CSV','JSON','Markdown'),
    [Parameter(ParameterSetName = 'Cli')]
    [switch]$SkipQuality
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------ Configuración global ------------------------
$script:DefaultThrottleLimit = [Math]::Max(2, [Environment]::ProcessorCount)
$script:DefaultProgressStages = 'Enumeración','Hash archivos','Fingerprint carpetas','Exportes'
$script:UiCulture = [System.Globalization.CultureInfo]::CurrentUICulture
$script:ScriptRoot = Split-Path -LiteralPath $PSCommandPath -Parent

# ------------------------ Utilidades de logging ------------------------
function Write-VerboseLog {
    param(
        [Parameter(Mandatory)][string]$Message,
        [System.Windows.Forms.TextBox]$TextBox
    )
    $timestamp = (Get-Date).ToString('HH:mm:ss')
    $line = "[$timestamp] $Message"
    if ($TextBox) {
        $TextBox.Invoke([Action]{ param($tb, $msg) $tb.AppendText($msg + [Environment]::NewLine) }, @($TextBox, $line)) | Out-Null
    } else {
        Write-Host $line
    }
}

# ------------------------ Controles WinForms (helpers) ------------------------
function New-Button($text, $x, $y, $w, $h) { $b=New-Object System.Windows.Forms.Button
    $b.Text=$text; $b.Location=New-Object System.Drawing.Point($x,$y)
    $b.Size=New-Object System.Drawing.Size($w,$h); $b }
function New-Label($text, $x, $y, $w, $h) { $l=New-Object System.Windows.Forms.Label
    $l.Text=$text; $l.Location=New-Object System.Drawing.Point($x,$y)
    $l.Size=New-Object System.Drawing.Size($w,$h); $l }
function New-TextBox($x, $y, $w, $h) { $t=New-Object System.Windows.Forms.TextBox
    $t.Location=New-Object System.Drawing.Point($x,$y)
    $t.Size=New-Object System.Drawing.Size($w,$h); $t }
function New-Checkbox($text, $x, $y, $checked=$false) { $c=New-Object System.Windows.Forms.CheckBox
    $c.Text=$text; $c.Location=New-Object System.Drawing.Point($x,$y)
    $c.AutoSize=$true; $c.Checked=$checked; $c }
function New-GroupBox($text, $x, $y, $w, $h) { $g=New-Object System.Windows.Forms.GroupBox
    $g.Text=$text; $g.Location=New-Object System.Drawing.Point($x,$y)
    $g.Size=New-Object System.Drawing.Size($w,$h); $g }
function New-Radio($text, $x, $y, $checked=$false) { $r=New-Object System.Windows.Forms.RadioButton
    $r.Text=$text; $r.Location=New-Object System.Drawing.Point($x,$y)
    $r.AutoSize=$true; $r.Checked=$checked; $r }
function New-Combo($x,$y,$w,$h,$items,$selIdx=0) {
    $c=New-Object System.Windows.Forms.ComboBox
    $c.Location=New-Object System.Drawing.Point($x,$y)
    $c.Size=New-Object System.Drawing.Size($w,$h)
    $null=$c.Items.AddRange($items); $c.SelectedIndex=$selIdx; $c.DropDownStyle='DropDownList'; $c
}

# ------------------------ Utilidades core ------------------------
function Get-Sha256Hex([string]$text) {
    $sha=[System.Security.Cryptography.SHA256]::Create()
    try { ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') }) -join '' }
    finally { $sha.Dispose() }
}
function Escape-FormatString([string]$s) {
    if ($null -eq $s) { return "" }
    return $s.Replace('{','{{').Replace('}','}}')
}
function Try-GetFileIdHex([string]$path) {
    try {
        $out = & fsutil file queryfileid $path 2>$null
        if ($LASTEXITCODE -eq 0 -and $out) { return ($out -split '\s+')[-1] } else { return $null }
    } catch { return $null }
}
function Format-Bytes([long]$bytes) {
    if ($bytes -ge 1GB) { '{0:N2} GB' -f ($bytes/1GB) }
    elseif ($bytes -ge 1MB) { '{0:N2} MB' -f ($bytes/1MB) }
    elseif ($bytes -ge 1KB) { '{0:N0} KB' -f ($bytes/1KB) }
    else { '{0:N0} B' -f $bytes }
}

# ------------------------ Paralelismo: runspace pool reutilizable ------------------------
function Invoke-ParallelForEach {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$InputObject,
        [Parameter(Mandatory)][scriptblock]$ProcessScript,
        [int]$ThrottleLimit = $script:DefaultThrottleLimit,
        [scriptblock]$ProgressCallback
    )
    $pool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
    $pool.ApartmentState = 'MTA'
    $pool.ThreadOptions = 'ReuseThread'
    $pool.Open()

    $jobs = New-Object System.Collections.Generic.List[object]
    $index = 0
    foreach ($item in $InputObject) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        $ps.AddScript($ProcessScript).AddArgument($item) | Out-Null
        $async = $ps.BeginInvoke()
        $jobs.Add([pscustomobject]@{ Index = $index; PowerShell = $ps; Async = $async })
        $index++
    }

    $results = New-Object System.Collections.ArrayList
    $total = [double]$jobs.Count
    $completed = 0

    while ($jobs.Count -gt 0) {
        $handles = @()
        foreach ($j in $jobs) { $handles += $j.Async.AsyncWaitHandle }
        if ($handles.Count -eq 0) { break }
        [System.Threading.WaitHandle]::WaitAny($handles, 250) | Out-Null
        for ($i = $jobs.Count - 1; $i -ge 0; $i--) {
            $job = $jobs[$i]
            if ($job.Async.IsCompleted) {
                try {
                    $result = $job.PowerShell.EndInvoke($job.Async)
                    foreach ($r in $result) { [void]$results.Add($r) }
                } catch {
                    [void]$results.Add([pscustomobject]@{ Error = $_; Item = $null })
                } finally {
                    $job.PowerShell.Dispose()
                    $jobs.RemoveAt($i)
                    $completed++
                    if ($ProgressCallback) {
                        $percent = if ($total -eq 0) { 0 } else { [Math]::Floor(($completed / $total) * 100) }
                        $null = $ProgressCallback.Invoke($completed, $total, $percent)
                    }
                }
            }
        }
    }

    $pool.Close(); $pool.Dispose()
    return $results.ToArray()
}

# ------------------------ Módulos / Dependencias ------------------------
function Ensure-Module {
    param([Parameter(Mandatory)][string]$Name,[string]$MinVersion='0.0.0')
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        try {
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            }
            if ((Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue).InstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
            }
            Install-Module -Name $Name -Scope CurrentUser -Force -MinimumVersion $MinVersion -ErrorAction Stop | Out-Null
            Import-Module $Name -Force
            return $true
        } catch {
            return $false
        }
    } else {
        Import-Module $Name -Force | Out-Null
        return $true
    }
}

# ------------------------ Calidad: PSSA + Pester ------------------------
function Invoke-CodeQuality {
    param(
        [string]$ScriptRoot,
        [ValidateSet('Error','Warning','Information')][string]$Severity='Error',
        [switch]$RunPSSA,
        [switch]$RunPester,
        [string]$PssaSettingsPath = (Join-Path $ScriptRoot 'PSScriptAnalyzerSettings.psd1'),
        [string]$TestsPath        = (Join-Path $ScriptRoot 'FileMap.Tests.ps1'),
        [string[]]$CoveragePath   = @(Join-Path $ScriptRoot 'FileMap.GUI.ps1')
    )
    $result = [ordered]@{
        PSSA   = $null
        Pester = $null
    }

    if ($RunPSSA) {
        if (-not (Ensure-Module -Name 'PSScriptAnalyzer' -MinVersion '1.21.0')) {
            throw "No se pudo cargar/instalar PSScriptAnalyzer."
        }
        $pssaParams = @{
            Path     = $ScriptRoot
            Recurse  = $true
            ErrorAction = 'SilentlyContinue'
        }
        if (Test-Path -LiteralPath $PssaSettingsPath) {
            $pssaParams['Settings'] = $PssaSettingsPath
        } else {
            $pssaParams['Severity'] = $Severity
        }
        $diagnostics = @(Invoke-ScriptAnalyzer @pssaParams)
        $result.PSSA = [pscustomobject]@{
            Count       = $diagnostics.Count
            Errors      = @($diagnostics | Where-Object Severity -eq 'Error')
            Warnings    = @($diagnostics | Where-Object Severity -eq 'Warning')
            Information = @($diagnostics | Where-Object Severity -eq 'Information')
            HasErrors   = ($diagnostics | Where-Object Severity -eq 'Error').Count -gt 0
            Diagnostics = $diagnostics
        }
    }

    if ($RunPester) {
        if (-not (Ensure-Module -Name 'Pester' -MinVersion '5.5.0')) {
            throw "No se pudo cargar/instalar Pester."
        }
        if (-not (Test-Path -LiteralPath $TestsPath)) {
            throw "No hay archivo de pruebas Pester en: $TestsPath"
        }

        $config = [PesterConfiguration]::Default
        $config.Run.Path           = $TestsPath
        $config.Run.PassThru       = $true
        $config.Output.Verbosity   = 'Detailed'
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path    = $CoveragePath

        $pesterResult = Invoke-Pester -Configuration $config
        $result.Pester = [pscustomobject]@{
            Passed    = $pesterResult.PassedCount
            Failed    = $pesterResult.FailedCount
            Skipped   = $pesterResult.SkippedCount
            Result    = $pesterResult.Result
            Coverage  = $pesterResult.CodeCoverage
        }
    }

    return [pscustomobject]$result
}

# ------------------------ Markdown ------------------------
function New-Markdown {
    param(
        [Parameter(Mandatory)][string]$root,
        [array]$dirs,
        [array]$files,
        [switch]$ForFolderMap,
        [switch]$ForFileMap,
        [pscustomobject]$Quality
    )

    function _FmtBytes([long]$b) {
        if     ($b -ge 1GB) { '{0:N2} GB' -f ($b/1GB) }
        elseif ($b -ge 1MB) { '{0:N2} MB' -f ($b/1MB) }
        elseif ($b -ge 1KB) { '{0:N0} KB' -f ($b/1KB) }
        else                { '{0:N0} B'  -f $b }
    }

    $totalDirs  = if ($dirs)  { $dirs.Count }  else { 0 }
    $totalFiles = if ($files) { $files.Count } else { 0 }
    $totalBytes = if ($files) { ($files | Measure-Object TamanoBytes -Sum).Sum } else { ($dirs | Measure-Object TotalBytes -Sum).Sum }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Filemap — ' + [IO.Path]::GetFileName($root))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('_Generado_: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('**Resumen:** {0} carpetas, {1} archivos, {2} totales.' -f $totalDirs, $totalFiles, (_FmtBytes $totalBytes)))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('**Leyenda:** 📁 carpeta · 📄 archivo · tamaños acumulados por carpeta.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Árbol')
    [void]$sb.AppendLine('```text')

    $byParent=@{}
    foreach ($d in ($dirs | Sort-Object Ruta)) {
        $parent=Split-Path $d.Ruta -Parent
        if (-not $byParent.ContainsKey($parent)) { $byParent[$parent]=New-Object System.Collections.ArrayList }
        [void]$byParent[$parent].Add($d)
    }

    function Write-Node([string]$path,[string]$prefix) {
        $children=@($byParent[$path]); if (-not $children) { return }
        for ($i=0; $i -lt $children.Count; $i++) {
            $c=$children[$i]; $isLast=($i -eq $children.Count-1)
            $branch= if ($isLast) { '└──' } else { '├──' }
            $nextPrefix= if ($isLast) { "$prefix    " } else { "$prefix│   " }
            $line=('{0} 📁 {1}  —  ({2} archivos, {3} carpetas, {4})' -f $branch,$c.Carpeta,$c.Archivos,$c.Subcarpetas,$c.'TotalTamaño')
            [void]$sb.AppendLine($prefix + $line)

            if ($ForFileMap) {
                $filesHere=@($files | Where-Object { (Split-Path $_.RutaArchivo -Parent) -eq $c.Ruta })
                foreach ($fa in $filesHere) {
                    [void]$sb.AppendLine(('{0}    ├── 📄 {1}  —  {2}' -f $prefix, $fa.NombreArchivo, $fa.TamanoLegible))
                }
            }
            Write-Node -path $c.Ruta -prefix $nextPrefix
        }
    }

    Write-Node -path (Split-Path $root -Parent) -prefix ''
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')

    [void]$sb.AppendLine('## Top 15 archivos por tamaño')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Archivo | Tamaño | Ext | Modificado |')
    [void]$sb.AppendLine('|---|---:|:--:|:--|')
    $top = if ($files) { $files | Sort-Object TamanoBytes -Descending | Select-Object -First 15 } else { @() }
    foreach ($t in $top) {
        $rel=($t.RelPathDesdeRaiz -replace '\\','/')
        [void]$sb.AppendLine(('| `{0}` | {1} | {2} | {3:yyyy-MM-ddTHH:mm:ss} |' -f $rel, $t.TamanoLegible, ($t.Extension -replace '^\.', ''), $t.UltimaModificacion))
    }

    if ($Quality) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Calidad del código (PSScriptAnalyzer + Pester)')
        if ($Quality.PSSA) {
            $errCount = @($Quality.PSSA.Errors).Count
            $warnCount = @($Quality.PSSA.Warnings).Count
            $infoCount = @($Quality.PSSA.Information).Count
            [void]$sb.AppendLine(('* **PSSA:** {0} errores · {1} advertencias · {2} info' -f $errCount,$warnCount,$infoCount))
            if ($errCount -gt 0) {
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine('### Errores PSSA')
                [void]$sb.AppendLine('| RuleName | Message | ScriptName | Line |')
                [void]$sb.AppendLine('|---|---|---|---:|')
                foreach ($d in $Quality.PSSA.Errors) {
                    [void]$sb.AppendLine(("| {0} | {1} | {2} | {3} |" -f $d.RuleName, ($d.Message -replace '\|','\|'), $d.ScriptName, $d.Line))
                }
            }
        }
        if ($Quality.Pester) {
            [void]$sb.AppendLine(('* **Pester:** Passed={0}, Failed={1}, Skipped={2}, Result={3}' -f $Quality.Pester.Passed,$Quality.Pester.Failed,$Quality.Pester.Skipped,$Quality.Pester.Result))
            if ($Quality.Pester.Coverage) {
                $cov = $Quality.Pester.Coverage
                $pct = if ($cov) { '{0:P1}' -f ($cov.NumberOfCommandsExecuted / [double][Math]::Max(1, $cov.NumberOfCommandsAnalyzed)) } else { 'N/A' }
                [void]$sb.AppendLine(('* **Cobertura (aprox):** {0}' -f $pct))
            }
        }
    }

    return $sb.ToString()
}

# ------------------------ Helpers de progreso ------------------------
function New-ProgressReporter {
    param(
        [scriptblock]$Callback
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    return [pscustomobject]@{
        StartTime = Get-Date
        Stopwatch = $stopwatch
        Callback  = $Callback
        Report = {
            param($stage,$current,$total,[string]$message)
            $self = $this
            if (-not $self.Callback) { return }
            $percent = if ($total -le 0) { 0 } else { [Math]::Floor(($current / [double]$total) * 100) }
            $elapsed = $self.Stopwatch.Elapsed
            $eta = if ($percent -gt 0) {
                $remaining = [TimeSpan]::FromSeconds(($elapsed.TotalSeconds / [Math]::Max($percent,1)) * (100 - $percent))
                $remaining
            } else { [TimeSpan]::Zero }
            $null = $self.Callback.Invoke([pscustomobject]@{
                Stage    = $stage
                Current  = $current
                Total    = $total
                Percent  = $percent
                Message  = $message
                Elapsed  = $elapsed
                ETA      = $eta
            })
        }
    }
}
# ------------------------ Mapeo (filemap/foldermap) ------------------------
function New-FileReportRecord {
    param(
        [System.IO.FileInfo]$File,
        [switch]$ComputeContentHash,
        [string]$Root
    )
    $acl = Get-Acl -LiteralPath $File.FullName -ErrorAction SilentlyContinue
    $ownerName=$acl.Owner
    $ownerSid=try { ([System.Security.Principal.NTAccount]$ownerName).Translate([System.Security.Principal.SecurityIdentifier]).Value } catch { $null }
    $contentSha256 = $null
    if ($ComputeContentHash) {
        try { $contentSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName -ErrorAction Stop).Hash }
        catch { $contentSha256 = $null }
    }
    return [PSCustomObject]@{
        CarpetaPadre=$File.Directory.Name; RutaCarpetaPadre=$File.Directory.FullName
        NombreArchivo=$File.Name; RutaArchivo=$File.FullName
        RelPathDesdeRaiz=[IO.Path]::GetRelativePath($Root, $File.FullName)
        Extension=$File.Extension; TamanoBytes=[long]$File.Length; TamanoLegible=(Format-Bytes $File.Length)
        Creacion=$File.CreationTime; UltimaModificacion=$File.LastWriteTime; UltimoAcceso=$File.LastAccessTime
        Atributos=$File.Attributes.ToString()
        EsOculto=[bool]($File.Attributes -band [IO.FileAttributes]::Hidden)
        EsReparsePoint=[bool]($File.Attributes -band [IO.FileAttributes]::ReparsePoint)
        Owner=$ownerName; OwnerSID=$ownerSid
        NTFS_FileIdHex=Try-GetFileIdHex $File.FullName
        PathSha256=Get-Sha256Hex ($File.FullName.ToLowerInvariant())
        ContentSha256=$contentSha256
    }
}

function New-FolderReportRecord {
    param(
        [System.IO.DirectoryInfo]$Directory,
        [System.IO.FileInfo[]]$FilesInDir,
        [System.IO.DirectoryInfo[]]$DirsInDir,
        [switch]$DeepContentHash,
        [string]$Root
    )

    $dirItem=Get-Item -LiteralPath $Directory.FullName -ErrorAction SilentlyContinue
    $attrs=$dirItem.Attributes

    $totalBytes=($FilesInDir | Measure-Object Length -Sum).Sum
    $count=$FilesInDir.Count
    $subdirs=$DirsInDir.Count
    $avgBytes= if ($count){ [double]$totalBytes/$count } else { 0 }

    $largest=$FilesInDir | Sort-Object Length -Descending | Select-Object -First 1
    $newest =$FilesInDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $oldest =$FilesInDir | Sort-Object LastWriteTime | Select-Object -First 1

    $sb=[System.Text.StringBuilder]::new()
    foreach ($f in ($FilesInDir | Sort-Object FullName)) {
        $rel=[IO.Path]::GetRelativePath($Directory.FullName,$f.FullName)
        $relEsc=Escape-FormatString ($rel.ToLowerInvariant())
        if ($DeepContentHash) {
            try {
                $fh=(Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName -ErrorAction Stop).Hash
                [void]$sb.AppendLine(("{0}|{1}" -f $relEsc,$fh))
            } catch {
                [void]$sb.AppendLine(("{0}|ERROR" -f $relEsc))
            }
        } else {
            [void]$sb.AppendLine(("{0}|{1}|{2}" -f $relEsc,$f.Length,$f.LastWriteTimeUtc.Ticks))
        }
    }
    $folderFingerprint=Get-Sha256Hex $sb.ToString()

    $acl=Get-Acl -LiteralPath $Directory.FullName -ErrorAction SilentlyContinue
    $ownerName=$acl.Owner
    $ownerSid=try { ([System.Security.Principal.NTAccount]$ownerName).Translate([System.Security.Principal.SecurityIdentifier]).Value } catch { $null }

    $topExt = if ($FilesInDir) {
        ( $FilesInDir | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 5 |
          ForEach-Object { "{0}:{1}" -f $_.Name, $_.Count } ) -join '; '
    } else { $null }

    return [PSCustomObject]@{
        Carpeta=$Directory.Name; Ruta=$Directory.FullName; RelPathDesdeRaiz=[IO.Path]::GetRelativePath($Root,$Directory.FullName)
        PathSha256=Get-Sha256Hex ($Directory.FullName.ToLowerInvariant())
        FolderFingerprintSha256=$folderFingerprint
        ModoFingerprint= if ($DeepContentHash){ 'Contenido' } else { 'Metadatos (rápido)' }
        Archivos=$count; Subcarpetas=$subdirs
        TotalBytes=[long]$totalBytes; TotalTamaño=(Format-Bytes $totalBytes)
        PromedioBytesPorArchivo=[double]$avgBytes; PromedioTamañoPorArchivo=(Format-Bytes $avgBytes)
        ArchivoMasGrande=$largest.Name
        ArchivoMasGrandeBytes= if ($largest) { [long]$largest.Length } else { 0 }
        ArchivoMasGrandeTamaño= if ($largest) { (Format-Bytes $largest.Length) } else { '0 B' }
        ArchivoMasGrandeSha256= if ($largest){ (Get-FileHash -Algorithm SHA256 -LiteralPath $largest.FullName -ErrorAction SilentlyContinue).Hash } else { $null }
        ArchivoMasReciente=$newest.Name; ArchivoMasAntiguo=$oldest.Name
        UltimaModificacionCarpeta=$dirItem.LastWriteTime; UltimoAccesoCarpeta=$dirItem.LastAccessTime; CreacionCarpeta=$dirItem.CreationTime
        Owner=$ownerName; OwnerSID=$ownerSid
        Atributos=$attrs.ToString(); EsOculta=[bool]($attrs -band [IO.FileAttributes]::Hidden); EsReparsePoint=[bool]($attrs -band [IO.FileAttributes]::ReparsePoint)
        ExtensionesTop5=$topExt; NTFS_FileIdHex=Try-GetFileIdHex $Directory.FullName
    }
}

function Invoke-Scan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$OutDir,
        [switch]$IncludeHidden,
        [switch]$IncludeRoot,
        [int]$MaxDepth = 0,
        [switch]$DeepContentHash,
        [switch]$FileContentHash,
        [switch]$DoFolderMap,
        [switch]$DoFileMap,
        [pscustomobject]$Quality = $null,
        [scriptblock]$ProgressCallback
    )

    $progressReporter = New-ProgressReporter -Callback $ProgressCallback

    $root=(Resolve-Path -LiteralPath $RootPath).Path
    $out =(Resolve-Path -LiteralPath $OutDir).Path

    $progressReporter.Report.Invoke('Enumeración',0,1,'Preparando enumeración...') | Out-Null

    $depthParam=@{}
    if ($MaxDepth -gt 0) { $depthParam['Depth']=$MaxDepth }

    $fileArgsAll=@{ LiteralPath=$root; File=$true; Recurse=$true; Force=$IncludeHidden; ErrorAction='SilentlyContinue' }
    $dirArgsAll =@{ LiteralPath=$root; Directory=$true; Recurse=$true; Force=$IncludeHidden; ErrorAction='SilentlyContinue' }
    if ($depthParam.Count){ $fileArgsAll['Depth']=$MaxDepth; $dirArgsAll['Depth']=$MaxDepth }

    $allFiles=@(Get-ChildItem @fileArgsAll)
    $allDirs=@()
    if ($IncludeRoot){ $allDirs += (Get-Item -LiteralPath $root -ErrorAction SilentlyContinue) }
    $allDirs += Get-ChildItem @dirArgsAll

    $progressReporter.Report.Invoke('Enumeración',$allFiles.Count,$allFiles.Count,'Enumeración finalizada') | Out-Null

    $folderReport=@(); $fileReport=@()

    if ($DoFileMap) {
        $progressReporter.Report.Invoke('Hash archivos',0,[Math]::Max(1,$allFiles.Count),'Procesando archivos...') | Out-Null
        $processFile = {
            param($fileInfo)
            try {
                return New-FileReportRecord -File $fileInfo -ComputeContentHash:$using:FileContentHash -Root $using:root
            } catch {
                return [pscustomobject]@{ Error = $_; RutaArchivo = $fileInfo.FullName }
            }
        }
        $fileResults = Invoke-ParallelForEach -InputObject $allFiles -ProcessScript $processFile -ThrottleLimit $script:DefaultThrottleLimit -ProgressCallback {
            param($current,$total,$percent)
            $msg = "Procesados $current de $total"
            $null = $progressReporter.Report.Invoke('Hash archivos',$current,$total,$msg)
        }
        $fileReport = @($fileResults | Where-Object { -not $_.Error })
        $errors = $fileResults | Where-Object Error
        foreach ($err in $errors) {
            Write-Warning "Error procesando archivo $($err.RutaArchivo): $($err.Error.Exception.Message)"
        }
    }

    if ($DoFolderMap) {
        $progressReporter.Report.Invoke('Fingerprint carpetas',0,[Math]::Max(1,$allDirs.Count),'Procesando carpetas...') | Out-Null
        $folderList = New-Object System.Collections.Generic.List[object]
        $idx = 0
        foreach ($d in $allDirs) {
            $idx++
            $prefix=($d.FullName.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar)
            $filesInDir=@(
                $allFiles | Where-Object {
                    $_.FullName.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase) -or
                    $_.Directory.FullName.Equals($d.FullName,[System.StringComparison]::OrdinalIgnoreCase)
                }
            )
            $dirsInDir=@(
                $allDirs | Where-Object {
                    $_.FullName.StartsWith($prefix,[System.StringComparison]::OrdinalIgnoreCase) -and
                    $_.FullName -ne $d.FullName
                }
            )
            $folderList.Add([pscustomobject]@{ Dir=$d; Files=$filesInDir; Dirs=$dirsInDir }) | Out-Null
            $progressReporter.Report.Invoke('Fingerprint carpetas',$idx,$allDirs.Count,"Enumerando carpeta $($d.FullName)") | Out-Null
        }

        $processFolder = {
            param($tuple)
            try {
                return New-FolderReportRecord -Directory $tuple.Dir -FilesInDir $tuple.Files -DirsInDir $tuple.Dirs -DeepContentHash:$using:DeepContentHash -Root $using:root
            } catch {
                return [pscustomobject]@{ Error = $_; Ruta = $tuple.Dir.FullName }
            }
        }

        $folderResults = Invoke-ParallelForEach -InputObject $folderList -ProcessScript $processFolder -ThrottleLimit ([Math]::Max(2, [Math]::Floor($script:DefaultThrottleLimit/2))) -ProgressCallback {
            param($current,$total,$percent)
            $msg = "Procesadas $current de $total"
            $null = $progressReporter.Report.Invoke('Fingerprint carpetas',$current,$total,$msg)
        }
        $folderReport = @($folderResults | Where-Object { -not $_.Error })
        $fErrors = $folderResults | Where-Object Error
        foreach ($err in $fErrors) {
            Write-Warning "Error procesando carpeta $($err.Ruta): $($err.Error.Exception.Message)"
        }
    }

    $progressReporter.Report.Invoke('Exportes',0,1,'Generando archivos de salida...') | Out-Null

    $exports=[ordered]@{}
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $baseName = (Split-Path $root -Leaf) + "_$ts"

    if ($DoFolderMap -and $folderReport) {
        $folderCsv = Join-Path $out ("foldermap_{0}.csv" -f $baseName)
        $folderJson= Join-Path $out ("foldermap_{0}.json" -f $baseName)
        $folderReport | Sort-Object TotalBytes -Descending | Export-Csv $folderCsv -NoTypeInformation -Encoding UTF8
        $folderReport | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $folderJson -Encoding UTF8
        $exports['FolderCSV']=$folderCsv; $exports['FolderJSON']=$folderJson
    }
    if ($DoFileMap -and $fileReport) {
        $fileCsv = Join-Path $out ("filemap_{0}.csv" -f $baseName)
        $fileJson= Join-Path $out ("filemap_{0}.json" -f $baseName)
        $fileReport | Export-Csv $fileCsv -NoTypeInformation -Encoding UTF8
        $fileReport | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $fileJson -Encoding UTF8
        $exports['FileCSV']=$fileCsv; $exports['FileJSON']=$fileJson
    }

    if ($DoFolderMap -or $DoFileMap) {
        $mdText = New-Markdown -root $root -dirs $folderReport -files $fileReport -ForFolderMap:$DoFolderMap -ForFileMap:$DoFileMap -Quality:$Quality
        $mdPath = Join-Path $out ("filemap_{0}.md" -f $baseName)
        $mdText | Out-File -LiteralPath $mdPath -Encoding UTF8
        $exports['Markdown'] = $mdPath
    }

    $progressReporter.Report.Invoke('Exportes',1,1,'Exportes completados') | Out-Null

    return [PSCustomObject]@{
        RootPath = $root; OutDir = $out; Exports = $exports
        FolderCount = $folderReport.Count; FileCount = $fileReport.Count
        TotalBytes = if ($folderReport) { ($folderReport | Measure-Object TotalBytes -Sum).Sum } else { ($fileReport | Measure-Object TamanoBytes -Sum).Sum }
        FolderReport = $folderReport
        FileReport = $fileReport
    }
}
function Invoke-ScanWhatIf {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [switch]$IncludeHidden,
        [switch]$IncludeRoot,
        [int]$MaxDepth = 0,
        [switch]$DeepContentHash,
        [switch]$FileContentHash,
        [switch]$DoFolderMap,
        [switch]$DoFileMap
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $info = [pscustomobject]@{
        RootPath=$null; TotalDirs=0; TotalFiles=0
        WouldHashFiles=[bool]$FileContentHash; WouldHashFolders=[bool]$DeepContentHash
        DoFolderMap=[bool]$DoFolderMap; DoFileMap=[bool]$DoFileMap
    }

    try { $root = (Resolve-Path -LiteralPath $RootPath -ErrorAction Stop).Path; $info.RootPath=$root }
    catch { $errors.Add("RootPath inválido: $RootPath — $($_.Exception.Message)"); Write-Host "Ruta raíz inválida." -ForegroundColor Red; return }

    $depth=@{}; if ($MaxDepth -gt 0) { $depth['Depth']=$MaxDepth }

    try {
        $dArgs=@{ LiteralPath=$root; Directory=$true; Recurse=$true; Force=$IncludeHidden; ErrorAction='Stop' }
        if ($depth.Count){ $dArgs['Depth']=$MaxDepth }
        $dirs=@(Get-ChildItem @dArgs)
        if ($IncludeRoot){ try { $dirs = ,(Get-Item -LiteralPath $root -ErrorAction Stop) + $dirs } catch { $errors.Add("No se pudo leer la carpeta raíz: $($_.Exception.Message)") } }
        $info.TotalDirs=$dirs.Count
    } catch { $errors.Add("Enumeración de carpetas fallida: $($_.Exception.Message)"); $dirs=@() }

    try {
        $fArgs=@{ LiteralPath=$root; File=$true; Recurse=$true; Force=$IncludeHidden; ErrorAction='Stop' }
        if ($depth.Count){ $fArgs['Depth']=$MaxDepth }
        $files=@(Get-ChildItem @fArgs)
        $info.TotalFiles=$files.Count
    } catch { $errors.Add("Enumeración de archivos fallida: $($_.Exception.Message)"); $files=@() }

    if ($DoFileMap -and $FileContentHash) {
        foreach ($f in $files | Select-Object -First 50) {
            try { $null = Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName -ErrorAction Stop }
            catch { $errors.Add("Hash de archivo falló: '$($f.FullName)' — $($_.Exception.Message)") }
        }
    }
    if ($DoFolderMap -and $DeepContentHash) {
        foreach ($d in $dirs | Select-Object -First 5) {
            try {
                $ff=@(Get-ChildItem -LiteralPath $d.FullName -File -Recurse -Force:$IncludeHidden -ErrorAction Stop)
                foreach ($x in $ff | Select-Object -First 25) {
                    try { $null = Get-FileHash -Algorithm SHA256 -LiteralPath $x.FullName -ErrorAction Stop }
                    catch { $errors.Add("Hash (fingerprint) falló: '$($x.FullName)' — $($_.Exception.Message)") }
                }
            } catch { $errors.Add("Enumeración fingerprint falló en '$($d.FullName)' — $($_.Exception.Message)") }
        }
    }

    Write-Host "=== WHAT-IF ===" -ForegroundColor Cyan
    Write-Host ("Raíz: {0}" -f $info.RootPath)
    Write-Host ("Carpetas: {0} | Archivos: {1}" -f $info.TotalDirs, $info.TotalFiles)
    Write-Host ("FolderMap: {0} | FileMap: {1}" -f $info.DoFolderMap, $info.DoFileMap)
    Write-Host ("Hash carpetas (contenido): {0} | Hash archivos (contenido): {1}" -f $info.WouldHashFolders, $info.WouldHashFiles)
    if ($errors.Count -gt 0) {
        Write-Host ("--- Errores capturados: {0} ---" -f $errors.Count) -ForegroundColor Yellow
        foreach ($e in $errors) { Write-Host " • $e" -ForegroundColor Red }
    } else {
        Write-Host "Sin errores capturados." -ForegroundColor Green
    }
    return $info
}

# ------------------------ GUI ------------------------
function Start-FileMapGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "File/Folder Map — PowerShell 7 (con PSSA + Pester)"
    $form.Size = New-Object System.Drawing.Size(880, 780)
    $form.StartPosition = "CenterScreen"

    $form.Controls.Add((New-Label "Carpeta a mapear:" 15,20,140,20))
    $tbRoot = New-TextBox 160 18 600 24; $form.Controls.Add($tbRoot)
    $btnPickRoot = New-Button "Examinar..." 775 17 75 26; $form.Controls.Add($btnPickRoot)

    $form.Controls.Add((New-Label "Carpeta de salida:" 15,55,140,20))
    $tbOut = New-TextBox 160 53 600 24; $form.Controls.Add($tbOut)
    $btnPickOut = New-Button "Examinar..." 775 52 75 26; $form.Controls.Add($btnPickOut)

    $grpWhat = New-GroupBox "¿Qué generar?" 15 90 280 100
    $rbFolder = New-Radio "Foldermap (carpetas)" 15 25 $true
    $rbFile   = New-Radio "Filemap (archivos)" 15 50 $false
    $rbBoth   = New-Radio "Ambos" 15 75 $false
    $grpWhat.Controls.AddRange(@($rbFolder,$rbFile,$rbBoth)); $form.Controls.Add($grpWhat)

    $grpOpts = New-GroupBox "Opciones de mapeo" 310 90 540 100
    $cbHidden = New-Checkbox "Incluir ocultos/sistema" 15 25 $true
    $cbRoot   = New-Checkbox "Incluir carpeta raíz" 220 25 $true
    $cbDeep   = New-Checkbox "Fingerprint por CONTENIDO (lento)" 15 50 $false
    $cbFileH  = New-Checkbox "SHA-256 de CONTENIDO por archivo (muy lento)" 15 75 $false
    $lblDepth = New-Label "Profundidad (0 = sin límite):" 360 25 180 20
    $numDepth = New-Object System.Windows.Forms.NumericUpDown
    $numDepth.Location = New-Object System.Drawing.Point(540,22)
    $numDepth.Size = New-Object System.Drawing.Size(60,22); $numDepth.Minimum=0; $numDepth.Maximum=100; $numDepth.Value=0
    $grpOpts.Controls.AddRange(@($cbHidden,$cbRoot,$cbDeep,$cbFileH,$lblDepth,$numDepth)); $form.Controls.Add($grpOpts)

    $grpQual = New-GroupBox "Calidad (PSSA + Pester)" 15 200 845 95
    $cbPSSA  = New-Checkbox "Validar con PSScriptAnalyzer" 15 25 $true
    $cbPester= New-Checkbox "Correr pruebas Pester" 220 25 $true
    $lblSev  = New-Label "Severidad mínima (PSSA):" 15 55 170 20
    $cbSev   = New-Combo 185 52 140 24 @('Error','Warning','Information') 0
    $grpQual.Controls.AddRange(@($cbPSSA,$cbPester,$lblSev,$cbSev)); $form.Controls.Add($grpQual)

    $grpExp = New-GroupBox "Exportar como" 15 305 845 70
    $cbCSV = New-Checkbox "CSV" 15 25 $true
    $cbJSON = New-Checkbox "JSON" 80 25 $true
    $cbMD = New-Checkbox "Markdown (.md)" 160 25 $true
    $grpExp.Controls.AddRange(@($cbCSV,$cbJSON,$cbMD)); $form.Controls.Add($grpExp)

    $btnRun   = New-Button "Ejecutar" 15 390 120 32
    $btnWhat  = New-Button "Probar (WhatIf)" 145 390 140 32
    $btnQual  = New-Button "Validar código" 295 390 140 32
    $btnOpen  = New-Button "Abrir salida" 445 390 120 32
    $btnExit  = New-Button "Cerrar" 720 390 120 32
    $form.Controls.AddRange(@($btnRun,$btnWhat,$btnQual,$btnOpen,$btnExit))

    $tbLog = New-Object System.Windows.Forms.TextBox
    $tbLog.Location = New-Object System.Drawing.Point(15,435)
    $tbLog.Multiline = $true; $tbLog.ScrollBars='Vertical'
    $tbLog.ReadOnly = $true; $tbLog.Size = New-Object System.Drawing.Size(845,220)
    $form.Controls.Add($tbLog)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(15, 665)
    $progressBar.Size = New-Object System.Drawing.Size(845, 22)
    $progressBar.Style = 'Continuous'
    $form.Controls.Add($progressBar)

    $lblProgress = New-Label "Listo." 15 695 820 25
    $form.Controls.Add($lblProgress)

    $btnPickRoot.Add_Click({
        $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description="Selecciona la carpeta raíz a mapear"
        if ($dlg.ShowDialog() -eq 'OK') { $tbRoot.Text = $dlg.SelectedPath }
    })
    $btnPickOut.Add_Click({
        $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description="Selecciona la carpeta de salida"
        if ($dlg.ShowDialog() -eq 'OK') { $tbOut.Text = $dlg.SelectedPath }
    })
    $btnOpen.Add_Click({ if ((Test-Path -LiteralPath $tbOut.Text)) { ii $tbOut.Text } })
    $btnExit.Add_Click({ $form.Close() })

    $stopwatch = [System.Diagnostics.Stopwatch]::new()
    $bgWorker = New-Object System.ComponentModel.BackgroundWorker
    $bgWorker.WorkerReportsProgress = $true
    $bgWorker.WorkerSupportsCancellation = $true

    # BackgroundWorker lanza Invoke-Scan en un hilo aparte para mantener la GUI fluida.
    # ReportProgress invoca el callback que viene de New-ProgressReporter, calculando ETA
    # y porcentaje con base en los conteos actuales. El procesamiento intensivo (hashing,
    # fingerprint) ocurre en paralelo dentro de Invoke-Scan mediante runspace pool.
    $bgWorker.add_DoWork({
        param($sender,$e)
        $stopwatch.Restart()
        $args = $e.Argument
        $callback = {
            param($state)
            $sender.ReportProgress([Math]::Min(100,[Math]::Max(0,$state.Percent)), $state)
        }
        try {
            $quality = $null
            if ($args.RunQuality) {
                $quality = Invoke-CodeQuality -ScriptRoot $args.Root -Severity $args.Severity -RunPSSA:$args.RunPSSA -RunPester:$args.RunPester
                if ($quality.PSSA -and $quality.PSSA.HasErrors -and $args.RunPSSA) {
                    throw "Errores PSSA detectados. Corrige antes de ejecutar."
                }
                if ($quality.Pester -and $quality.Pester.Failed -gt 0 -and $args.RunPester) {
                    throw "Pruebas Pester fallidas."
                }
            }
            $result = Invoke-Scan -RootPath $args.Root -OutDir $args.OutDir -IncludeHidden:$args.IncludeHidden -IncludeRoot:$args.IncludeRoot -MaxDepth $args.MaxDepth -DeepContentHash:$args.DeepContentHash -FileContentHash:$args.FileContentHash -DoFolderMap:$args.DoFolderMap -DoFileMap:$args.DoFileMap -Quality $quality -ProgressCallback $callback
            $e.Result = [pscustomobject]@{ Result = $result; Quality = $quality }
        } catch {
            $e.Result = [pscustomobject]@{ Error = $_ }
        }
    })

    $bgWorker.add_ProgressChanged({
        param($sender,$e)
        if ($e.UserState) {
            $state = $e.UserState
            $progressBar.Value = [Math]::Min(100,[Math]::Max(0,$state.Percent))
            $etaText = if ($state.Percent -gt 0 -and $state.ETA -ne [TimeSpan]::Zero) { "ETA: {0}" -f $state.ETA.ToString('hh\:mm\:ss') } else { 'Calculando...' }
            $lblProgress.Text = "[{0}%] {1} — {2}" -f $state.Percent, $state.Stage, $etaText
        }
    })

    $bgWorker.add_RunWorkerCompleted({
        param($sender,$e)
        $stopwatch.Stop()
        if ($e.Result -and $e.Result.Error) {
            Write-VerboseLog -Message "[ERROR] $($e.Result.Error.Exception.Message)" -TextBox $tbLog
            $lblProgress.Text = "Error: $($e.Result.Error.Exception.Message)"
        } elseif ($e.Result) {
            $result = $e.Result.Result
            $quality = $e.Result.Quality
            if ($quality) {
                Write-VerboseLog -Message ("PSSA: " + $(if ($quality.PSSA) { $quality.PSSA.Count } else { 'N/A' })) -TextBox $tbLog
                if ($quality.Pester) {
                    Write-VerboseLog -Message ("Pester => Passed:$($quality.Pester.Passed) Failed:$($quality.Pester.Failed) Result:$($quality.Pester.Result)") -TextBox $tbLog
                }
            }
            Write-VerboseLog -Message "Root: $($result.RootPath)" -TextBox $tbLog
            Write-VerboseLog -Message "Salida: $($result.OutDir)" -TextBox $tbLog
            Write-VerboseLog -Message "Carpetas: $($result.FolderCount) | Archivos: $($result.FileCount) | Total: $(Format-Bytes $result.TotalBytes)" -TextBox $tbLog
            foreach ($k in $result.Exports.Keys) {
                Write-VerboseLog -Message "$k => $($result.Exports[$k])" -TextBox $tbLog
            }
            $lblProgress.Text = "Completado en $($stopwatch.Elapsed.ToString('hh\:mm\:ss'))."
        }
        $progressBar.Value = 0
    })

    function Run-Validation([string]$root,[bool]$runPssa,[bool]$runPester,[string]$severity) {
        try {
            $qual = Invoke-CodeQuality -ScriptRoot $root -Severity $severity -RunPSSA:$runPssa -RunPester:$runPester
            Write-VerboseLog -Message ("PSSA: " + $(if ($qual.PSSA) { $qual.PSSA.Count } else { 'N/A' })) -TextBox $tbLog
            if ($qual.PSSA -and $qual.PSSA.HasErrors -and $runPssa) {
                Write-VerboseLog -Message "Hay errores PSSA (severidad Error)." -TextBox $tbLog
            }
            if ($qual.Pester) {
                Write-VerboseLog -Message ("Pester => Passed:{0} Failed:{1} Skipped:{2} Result:{3}" -f $qual.Pester.Passed,$qual.Pester.Failed,$qual.Pester.Skipped,$qual.Pester.Result) -TextBox $tbLog
            }
            return $qual
        } catch {
            Write-VerboseLog -Message "[ERROR VALIDACIÓN] $($_.Exception.Message)" -TextBox $tbLog
            return $null
        }
    }

    $btnRun.Add_Click({
        try {
            $tbLog.Clear()
            $root=$tbRoot.Text; $out=$tbOut.Text
            if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { Write-VerboseLog -Message "Selecciona una carpeta raíz válida." -TextBox $tbLog; return }
            if ([string]::IsNullOrWhiteSpace($out)  -or -not (Test-Path -LiteralPath $out))  { Write-VerboseLog -Message "Selecciona una carpeta de salida válida." -TextBox $tbLog; return }

            $doFolder = $rbFolder.Checked -or $rbBoth.Checked
            $doFile   = $rbFile.Checked   -or $rbBoth.Checked
            if (-not ($doFolder -or $doFile)) { Write-VerboseLog -Message "Selecciona al menos un tipo (Foldermap/Filemap)." -TextBox $tbLog; return }

            $args = [pscustomobject]@{
                Root=$root; OutDir=$out; IncludeHidden=$cbHidden.Checked; IncludeRoot=$cbRoot.Checked; MaxDepth=[int]$numDepth.Value
                DeepContentHash=$cbDeep.Checked; FileContentHash=$cbFileH.Checked
                DoFolderMap=$doFolder; DoFileMap=$doFile
                RunQuality=($cbPSSA.Checked -or $cbPester.Checked)
                RunPSSA=$cbPSSA.Checked; RunPester=$cbPester.Checked; Severity=$cbSev.SelectedItem
            }
            if (-not $bgWorker.IsBusy) {
                $lblProgress.Text = "Inicializando..."
                $bgWorker.RunWorkerAsync($args)
            } else {
                Write-VerboseLog -Message "Ya hay una ejecución en progreso." -TextBox $tbLog
            }
        } catch {
            Write-VerboseLog -Message "[ERROR] $($_.Exception.Message)" -TextBox $tbLog
        }
    })

    $btnWhat.Add_Click({
        try {
            $tbLog.Clear()
            $root=$tbRoot.Text; if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { Write-VerboseLog -Message "Selecciona una carpeta raíz válida." -TextBox $tbLog; return }
            $doFolder = $rbFolder.Checked -or $rbBoth.Checked
            $doFile   = $rbFile.Checked   -or $rbBoth.Checked
            if (-not ($doFolder -or $doFile)) { Write-VerboseLog -Message "Selecciona al menos un tipo (Foldermap/Filemap)." -TextBox $tbLog; return }

            $info = Invoke-ScanWhatIf -RootPath $root -IncludeHidden:($cbHidden.Checked) -IncludeRoot:($cbRoot.Checked) -MaxDepth ([int]$numDepth.Value) -DeepContentHash:($cbDeep.Checked) -FileContentHash:($cbFileH.Checked) -DoFolderMap:$doFolder -DoFileMap:$doFile

            if ($info) {
                Write-VerboseLog -Message ("Raíz: {0}" -f $info.RootPath) -TextBox $tbLog
                Write-VerboseLog -Message ("Carpetas: {0} | Archivos: {1}" -f $info.TotalDirs, $info.TotalFiles) -TextBox $tbLog
                Write-VerboseLog -Message ("FolderMap: {0} | FileMap: {1}" -f $info.DoFolderMap, $info.DoFileMap) -TextBox $tbLog
                Write-VerboseLog -Message ("Hash carpetas: {0} | Hash archivos: {1}" -f $info.WouldHashFolders, $info.WouldHashFiles) -TextBox $tbLog
            }
        } catch {
            Write-VerboseLog -Message "[ERROR WHAT-IF] $($_.Exception.Message)" -TextBox $tbLog
        }
    })

    $btnQual.Add_Click({
        try {
            $root=$tbRoot.Text
            if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) { Write-VerboseLog -Message "Selecciona una carpeta raíz válida." -TextBox $tbLog; return }
            $null = Run-Validation -root $root -runPssa:$cbPSSA.Checked -runPester:$cbPester.Checked -severity $cbSev.SelectedItem
        } catch {
            Write-VerboseLog -Message "[ERROR VALIDAR] $($_.Exception.Message)" -TextBox $tbLog
        }
    })

    $tbRoot.Text=(Get-Location).Path
    $tbOut.Text =(Get-Location).Path

    [void]$form.ShowDialog()
}
# Evitar ejecución automática al dot-sourcear (p. ej., desde Pester)
if ($MyInvocation.InvocationName -eq '.') { return }

# ------------------------ Entrada principal ------------------------
try {
    switch ($PSCmdlet.ParameterSetName) {
        'Validation' {
            try {
                $qual = Invoke-CodeQuality -ScriptRoot $script:ScriptRoot -Severity 'Error' -RunPSSA -RunPester
                $hasPssaErrors = ($qual.PSSA -and $qual.PSSA.HasErrors)
                $hasPesterFail = ($qual.Pester -and $qual.Pester.Failed -gt 0)
                if ($hasPssaErrors -or $hasPesterFail) { exit 1 } else { exit 0 }
            } catch {
                Write-Error $_
                exit 2
            }
        }
        'Cli' {
            $doFolder = $DoFolderMap.IsPresent -or (-not $DoFileMap.IsPresent)
            $doFile   = $DoFileMap.IsPresent -or (-not $DoFolderMap.IsPresent)
            $quality = $null
            if (-not $SkipQuality) {
                $quality = Invoke-CodeQuality -ScriptRoot $script:ScriptRoot -Severity $Severity -RunPSSA -RunPester
                if ($quality.PSSA -and $quality.PSSA.HasErrors) {
                    throw "Errores PSSA detectados."
                }
                if ($quality.Pester -and $quality.Pester.Failed -gt 0) {
                    throw "Pruebas Pester fallidas."
                }
            }
            $result = Invoke-Scan -RootPath $RootPath -OutDir $OutDir -IncludeHidden:$IncludeHidden -IncludeRoot:$IncludeRoot -MaxDepth $MaxDepth -DeepContentHash:$DeepContentHash -FileContentHash:$FileContentHash -DoFolderMap:$doFolder -DoFileMap:$doFile -Quality $quality
            $exports = $result.Exports.Clone()
            if ($ExportFormat -notcontains 'CSV')  { $exports.Keys | Where-Object { $_ -like '*CSV' }  | ForEach-Object { Remove-Item -LiteralPath $exports[$_] -ErrorAction SilentlyContinue; $exports.Remove($_) } }
            if ($ExportFormat -notcontains 'JSON') { $exports.Keys | Where-Object { $_ -like '*JSON' } | ForEach-Object { Remove-Item -LiteralPath $exports[$_] -ErrorAction SilentlyContinue; $exports.Remove($_) } }
            if ($ExportFormat -notcontains 'Markdown' -and $exports.Contains('Markdown')) { Remove-Item -LiteralPath $exports['Markdown'] -ErrorAction SilentlyContinue; $exports.Remove('Markdown') }
            $result.Exports = $exports
            $result | ConvertTo-Json -Depth 6
        }
        default {
            Start-FileMapGui
        }
    }
} catch {
    Write-Error $_
    exit 1
}