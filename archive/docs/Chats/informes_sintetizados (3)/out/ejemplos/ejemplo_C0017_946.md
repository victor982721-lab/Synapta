```powershell
# C:\Users\VictorFabianVeraVill\Desktop\TBEA\TBEA_LaunchYSD.ps1
#requires -Version 7
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
param(
    [ValidateSet('300AN','300ANPlus')]
    [string]$Edition = '300AN',
    [string]$Root = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$swDir = Join-Path $Root '01_Software'
$dir300AN = Join-Path $swDir '300AN'
$dirYSD   = Join-Path $swDir 'YSD_300AN'

$exe = if ($Edition -eq '300ANPlus') {
    Join-Path $dir300AN 'YSD300AN-P2406.exe'
} else {
    Join-Path $dirYSD   'YSD300AN.exe'
}

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "No se encontró el ejecutable esperado para $Edition: $exe"
}

# Rutas de respaldo y logs (todo dentro de TBEA)
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $Root "backups\$Edition\$timestamp"
$logDir    = Join-Path $Root "logs"
$tmpDir    = Join-Path $Root "tmp\$Edition\$timestamp"
$workDir   = Split-Path -Path $exe -Parent

$null = New-Item -ItemType Directory -Force -Path $backupDir,$logDir,$tmpDir

# Respaldo de configuraciones conocidas
$patterns = @('*.ini','dcc*','dcy*','read*','user*','data','OCX')
foreach ($pat in $patterns) {
    Get-ChildItem -LiteralPath $workDir -Filter $pat -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $dest = Join-Path $backupDir ($_.FullName.Substring($workDir.Length).TrimStart('\'))
        $destDir = Split-Path $dest -Parent
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        if ($PSCmdlet.ShouldProcess($_.FullName, "Backup to $dest")) {
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        }
    }
}

# Transcript (log)
$transcript = Join-Path $logDir "YSD_${Edition}_$timestamp.log"
Start-Transcript -Path $transcript -Append | Out-Null

# Preparar arranque con variables TEMP/TMP confinadas a TBEA
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exe
$psi.WorkingDirectory = $workDir
$psi.UseShellExecute = $false
$psi.Environment['TEMP'] = $tmpDir
$psi.Environment['TMP']  = $tmpDir

Write-Host "Iniciando $Edition → $exe"
$proc = [System.Diagnostics.Process]::Start($psi)
$null = $proc.WaitForExit()

Stop-Transcript | Out-Null

# Diff de cambios en ini básicos (si existen antes y después)
function Get-IniSnapshot($dir,$suffix){
    Get-ChildItem -LiteralPath $dir -Filter '*.ini' -File -ErrorAction SilentlyContinue |
    ForEach-Object {
        [PSCustomObject]@{
            File = $_.Name
            Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            Size = $_.Length
            MTime= $_.LastWriteTimeUtc
            Suffix = $suffix
        }
    }
}

$before = Get-IniSnapshot -dir $backupDir -suffix 'before'
$after  = Get-IniSnapshot -dir $workDir  -suffix 'after'
$report = Join-Path $logDir "YSD_${Edition}_ini_changes_$timestamp.csv"
$before + $after | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $report

Write-Host "Listo. Backup: $backupDir"
Write-Host "Log: $transcript"
Write-Host "Cambios INI: $report"
```