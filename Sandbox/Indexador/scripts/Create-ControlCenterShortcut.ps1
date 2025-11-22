param(
    [string]$ShortcutName = "Indexador Control Center.lnk",
    [string]$TargetScript = ".\scripts\IndexadorControlCenter.ps1"
)

$desktop = [Environment]::GetFolderPath("Desktop")
$linkPath = Join-Path $desktop $ShortcutName
$scriptPath = Resolve-Path $TargetScript

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($linkPath)
$shortcut.TargetPath = "pwsh.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.WorkingDirectory = Split-Path $scriptPath
$shortcut.IconLocation = "$($PSHome)\pwsh.exe,0"
$shortcut.Save()

Write-Host "Acceso creado en el escritorio:" $linkPath
