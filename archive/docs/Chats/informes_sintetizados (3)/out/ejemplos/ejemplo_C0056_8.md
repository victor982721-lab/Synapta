```
Set-StrictMode -Version Latest

function Resolve-RepoRoot {
    [CmdletBinding()]
    param(
        [string]$RepoRoot
    )
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        if ($env:ANASTASIS_REPO_ROOT) {
            $RepoRoot = $env:ANASTASIS_REPO_ROOT
        } else {
            $home = [Environment]::GetFolderPath('UserProfile')
            $RepoRoot = Join-Path $home 'Desktop\Anastasis_Revenari'
        }
    }
    if (-not (Test-Path $RepoRoot)) {
        throw "RepoRoot no encontrado: $RepoRoot"
    }
    return (Resolve-Path $RepoRoot).Path
}

function New-IncrementalBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )
    $full = Resolve-Path $Path -ErrorAction Stop
    $file = Get-Item $full
    $backupDir = Join-Path $file.DirectoryName 'Backups'
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $ext = [System.IO.Path]::GetExtension($file.Name)
    $n = 1
    while ($true) {
        $candidate = Join-Path $backupDir ("{0}_{1}.bak" -f $baseName, $n)
        if (-not (Test-Path $candidate)) { break }
        $n++
    }
    Copy-Item -LiteralPath $file.FullName -Destination $candidate -Force
    return $candidate
}

function Write-ChangeLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TargetPath,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter()][string]$Summary = ''
    )
    $full = Resolve-Path $TargetPath -ErrorAction Stop
    $file = Get-Item $full
    $clDir = Join-Path $file.DirectoryName 'Changelogs'
    if (-not (Test-Path $clDir)) { New-Item -ItemType Directory -Path $clDir | Out-Null }
    $ts = Get-Date -AsUtc
    $nameSafe = $file.Name -replace '[^A-Za-z0-9\.\-_]','_'
    $clName = '{0:yyyyMMdd_HHmmss}_{1}_{2}.md' -f $ts, $nameSafe, $Mode
    $clPath = Join-Path $clDir $clName
    $content = @"
# Changelog Entry
- UTC: $($ts.ToString('u'))
- File: $($file.FullName)
- Mode: $Mode
- Summary: $Summary
"@
    $content | Out-File -FilePath $clPath -Encoding UTF8 -Force
    return $clPath
}

function Set-FileContentAppend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [string]$Summary = 'Append content'
    )
    $backup = New-IncrementalBackup -Path $Path
    Add-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    $cl = Write-ChangeLog -TargetPath $Path -Mode 'Append' -Summary $Summary
    [pscustomobject]@{ Backup=$backup; Changelog=$cl; Path=(Resolve-Path $Path).Path }
}

function Set-FileContentReplaceBetweenMarkers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$StartMarker,
        [Parameter(Mandatory)][string]$EndMarker,
        [Parameter(Mandatory)][string]$NewContent,
        [switch]$IncludeMarkers,
        [string]$Summary = 'Replace between markers'
    )
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $sm = [Regex]::Escape($StartMarker)
    $em = [Regex]::Escape($EndMarker)

    $pattern = if ($IncludeMarkers) {
        "(?s)$sm.*?$em"
    } else {
        "(?s)(?<=${sm}).*?(?=${em})"
    }

    if (-not ([Regex]::IsMatch($text, $pattern))) {
        throw "Marcadores no encontrados en $Path"
    }

    $backup = New-IncrementalBackup -Path $Path
    if ($IncludeMarkers) {
        $replacement = "$StartMarker`r`n$NewContent`r`n$EndMarker"
    } else {
        $replacement = $NewContent
    }
    $newText = [Regex]::Replace($text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
    $newText | Out-File -FilePath $Path -Encoding UTF8 -Force
    $cl = Write-ChangeLog -TargetPath $Path -Mode 'ReplaceBetweenMarkers' -Summary $Summary
    [pscustomobject]@{ Backup=$backup; Changelog=$cl; Path=(Resolve-Path $Path).Path }
}

function Ensure-BootstrapImport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot
    )
    $bootstrap = Join-Path $RepoRoot 'scripts\bootstrap.ps1'
    if (-not (Test-Path $bootstrap)) { return $false }
    $line = '. "$PSScriptRoot\HereStrings-Utils.ps1"'
    $content = Get-Content -LiteralPath $bootstrap -Raw -Encoding UTF8
    if ($content -notmatch [regex]::Escape('HereStrings-Utils.ps1')) {
        Add-Content -LiteralPath $bootstrap -Value "`r`n# Import utilities for here-strings`r`n$line`r`n" -Encoding UTF8
        return $true
    }
    return $false
}
```