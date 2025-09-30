#requires -Version 7.0
# 1) Resolver repo (permite override por env var)
$RepoRoot = if ($env:ANASTASIS_REPO_ROOT) { $env:ANASTASIS_REPO_ROOT } else { 'C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari' }
Set-Location -LiteralPath $RepoRoot

# 2) Backup incremental
$Target = 'scripts\bootstrap.ps1'
$Backups = Join-Path (Split-Path -Parent $Target) 'Backups'
New-Item -ItemType Directory -Force -Path $Backups | Out-Null
$BaseName = [IO.Path]::GetFileName($Target)
$Existing = Get-ChildItem -Path $Backups -Filter "$BaseName*.bak" -ErrorAction SilentlyContinue
$Idx = if ($Existing) { ($Existing.Name | ForEach-Object { ($_ -split '\.bak')[0] -replace '.*_','' } | Where-Object { $_ -match '^\d+$' } | Measure-Object -Maximum).Maximum + 1 } else { 1 }
Copy-Item -LiteralPath $Target -Destination (Join-Path $Backups "$BaseName" + "_$Idx.bak") -Force

# 3) ReplaceBetweenMarkers (convención AR)
$Start = '#region AR:BOOT'
$End   = '#endregion AR:BOOT'
$New   = @'
# contenido nuevo aquí (demo)
'@
$text = Get-Content -LiteralPath $Target -Raw
if ($text -match [regex]::Escape($Start) -and $text -match [regex]::Escape($End)) {
  $pattern = "(?s)" + [regex]::Escape($Start) + ".*?" + [regex]::Escape($End)
  $replacement = "$Start`r`n$New`r`n$End"
  $text = [regex]::Replace($text, $pattern, $replacement, 'Singleline')
} else {
  $text += "`r`n`r`n$Start`r`n$New`r`n$End"
}
Set-Content -LiteralPath $Target -Value $text -Encoding UTF8

# 4) Changelog
$clDir = 'Changelogs'
New-Item -ItemType Directory -Force -Path $clDir | Out-Null
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$entry = @"
[$stamp] File=$Target; Mode=ReplaceBetweenMarkers; Region=AR:BOOT; Summary=Actualización de bloque.
"@
Add-Content -LiteralPath (Join-Path $clDir "$stamp.md") -Value $entry -Encoding UTF8

# 5) Quality Gate
& 'scripts\Invoke-SerintraQualityGate.ps1' -ErrorAction Stop