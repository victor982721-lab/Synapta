```powershell
# Dedup-YSD.ps1
# Elimina duplicados (.ysd/.dcy), renombra el ejemplar conservado y registra las acciones.
# Requiere PowerShell 7+

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    # Carpeta raíz donde están los archivos del ZIP ya extraídos
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$RootPath = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA\user1_zip_extracted',

    # Si se desea conservar admin1.edb (metadatos internos del software)
    [switch]$KeepInternalEdb
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-Diacritics {
    param([Parameter(Mandatory)][string]$Text)
    $n = $Text.Normalize([Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $n.ToCharArray()) {
        $cat = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($cat -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    # Solo ASCII seguro: letras, números, punto, guion y guion bajo
    return ($sb.ToString() -replace '[^A-Za-z0-9._-]', '_')
}

function Get-DesirabilityScore {
    param([System.IO.FileInfo]$File)
    # Prioriza .ysd > .dcy, evita nombres "temp*" y preferir ASCII
    $ext = $File.Extension.ToLowerInvariant()
    $name = $File.BaseName
    $score = 0
    switch ($ext) {
        '.ysd' { $score += 0 }
        '.dcy' { $score += 5 }
        default { $score += 10 }
    }
    if ($name -match '^(?i)temp') { $score += 5 }
    if ($name -match '[^\x00-\x7F]') { $score += 2 } # no-ASCII penaliza
    return $score
}

function Infer-DateFromName {
    param([string]$BaseName)
    # yyyyMMdd
    if ($BaseName -match '\b(20\d{6})\b') {
        $y = [int]$Matches[1].Substring(0,4); $m = [int]$Matches[1].Substring(4,2); $d = [int]$Matches[1].Substring(6,2)
        if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) {
            return [datetime]::new($y,$m,$d)
        }
    }
    # yyMMdd (asumir 20yy)
    if ($BaseName -match '\b(\d{6})\b') {
        $yy = [int]$Matches[1].Substring(0,2); $m = [int]$Matches[1].Substring(2,2); $d = [int]$Matches[1].Substring(4,2)
        if ($m -ge 1 -and $m -le 12 -and $d -ge 1 -and $d -le 31) {
            $y = 2000 + $yy
            return [datetime]::new($y,$m,$d)
        }
    }
    return $null
}

# 1) Enumerar archivos candidatos
$allFiles = Get-ChildItem -LiteralPath $RootPath -File -Recurse -ErrorAction Stop
$candidates = $allFiles | Where-Object {
    $_.Extension -match '^\.(ysd|dcy|edb)$'
}

# 2) Opcional: descartar admin1.edb si no se desea conservarlo
if (-not $KeepInternalEdb) {
    $candidates = $candidates | Where-Object { $_.Name -ne 'admin1.edb' }
}

if (-not $candidates) {
    Write-Information "No se encontraron archivos .ysd/.dcy (o .edb si -KeepInternalEdb) en: $RootPath"
    return
}

# 3) Calcular SHA256 y agrupar por contenido
$hashTable = @{}
foreach ($f in $candidates) {
    $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
    $hashTable[$h.Hash] = @() + ($hashTable[$h.Hash]) + ,$f
}

# 4) Acciones y logging
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$logPath = Join-Path $RootPath ("actions_dedup_{0}.csv" -f $timestamp)
"Action,Path,Target,Hash,Notes" | Out-File -LiteralPath $logPath -Encoding UTF8

function Log {
    param([string]$Action,[string]$Path,[string]$Target,[string]$Hash,[string]$Notes)
    $line = '"' + ($Action -replace '"','""') + '","' +
                 ($Path -replace '"','""')   + '","' +
                 ($Target -replace '"','""') + '","' +
                 ($Hash -replace '"','""')   + '","' +
                 ($Notes -replace '"','""')  + '"'
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

# 5) Procesar cada grupo de duplicados
foreach ($kv in $hashTable.GetEnumerator()) {
    $hash  = $kv.Key
    $files = $kv.Value

    # Elegir "keeper" por score; si empate, el de ruta más corta y luego alfabético
    $keeper = $files | Sort-Object @{Expression={ Get-DesirabilityScore $_ }}, `
                               @{Expression={$_.FullName.Length}}, `
                               @{Expression={$_.Name}} | Select-Object -First 1

    $ext = $keeper.Extension.ToLowerInvariant()
    $base = $keeper.BaseName

    # Generar nombre ASCII seguro
    $safeBase = Remove-Diacritics $base
    $onlyAscii = $safeBase -replace '[^A-Za-z0-9._-]', '_'
    if (-not ($onlyAscii -match '[A-Za-z0-9]')) {
        # Si quedó vacío (p.ej. nombre en chino), intentar fecha → si no, usar hash
        $dt = Infer-DateFromName -BaseName $base
        if ($dt) {
            $onlyAscii = 'YSD_{0}' -f $dt.ToString('yyyy-MM-dd')
        } else {
            $onlyAscii = 'YSD_{0}' -f $hash.Substring(0,8)
        }
    } else {
        # Si el nombre sugiere fecha, estandarizar prefijo
        $dt2 = Infer-DateFromName -BaseName $base
        if ($dt2 -ne $null -and -not ($onlyAscii -like 'YSD_*')) {
            $onlyAscii = 'YSD_{0}_{1}' -f $dt2.ToString('yyyy-MM-dd'), $onlyAscii
        }
    }

    $targetName = "{0}{1}" -f $onlyAscii, $ext
    $targetPath = Join-Path $keeper.DirectoryName $targetName

    # Resolver colisiones de nombre con otros contenidos
    $suffix = 1
    while (Test-Path -LiteralPath $targetPath) {
        $existingHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
        if ($existingHash -eq $hash) {
            # Ya existe el mismo contenido con el nombre deseado → usar ese y marcar el actual como duplicado
            if ($keeper.FullName -ne $targetPath) {
                # Eliminar el keeper (porque ya hay copia idéntica con el nombre final)
                if ($PSCmdlet.ShouldProcess($keeper.FullName, "Remove duplicate (already have target)")) {
                    Remove-Item -LiteralPath $keeper.FullName -Force
                    Log -Action 'DELETE' -Path $keeper.FullName -Target $targetPath -Hash $hash -Notes 'Duplicate of existing target'
                }
                $keeper = Get-Item -LiteralPath $targetPath
            }
            break
        } else {
            # Diferente contenido → añadir sufijo
            $targetName = "{0}__{1}{2}" -f $onlyAscii, $suffix, $ext
            $targetPath = Join-Path $keeper.DirectoryName $targetName
            $suffix++
        }
    }

    # Renombrar el keeper si es necesario
    if ($keeper.FullName -ne $targetPath -and -not (Test-Path -LiteralPath $targetPath)) {
        if ($PSCmdlet.ShouldProcess($keeper.FullName, "Rename to $targetName")) {
            Rename-Item -LiteralPath $keeper.FullName -NewName $targetName -Force
            Log -Action 'RENAME' -Path $keeper.FullName -Target $targetPath -Hash $hash -Notes 'Keeper normalized to ASCII-safe name'
            $keeper = Get-Item -LiteralPath $targetPath
        }
    }

    # Borrar duplicados (todos menos el keeper)
    foreach ($f in $files) {
        if ($f.FullName -ne $keeper.FullName) {
            if ($PSCmdlet.ShouldProcess($f.FullName, "Delete duplicate")) {
                Remove-Item -LiteralPath $f.FullName -Force
                Log -Action 'DELETE' -Path $f.FullName -Target $keeper.FullName -Hash $hash -Notes 'Duplicate removed'
            }
        }
    }
}

Write-Host "Listo. Acciones registradas en: $logPath"
Write-Host "Sugerencia: abre el CSV para revisar el detalle."
```