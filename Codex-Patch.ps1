#!/usr/bin/env pwsh
#requires -Version 7.0
<#
    PatchExtractor.ps1
    -------------------
    Utilidad con GUI WinForms y CLI para analizar parches unified diff, validar (TEST)
    y exportar archivos reconstruidos (RUN) cumpliendo política PDP (TEST → RUN).

    Uso rápido (CLI):
        pwsh -File .\PatchExtractor.ps1 -In .\cambios.patch -Out C:\Destino -Test
        pwsh -File .\PatchExtractor.ps1 -In .\cambios.patch -Out C:\Destino -Run -Zip -ForceCRLF -Utf8

    Notas:
        - GUI recomendada: ejecutar sin parámetros.
        - Registros JSONL en logs/actions.jsonl.
        - Backups en 00.Backups/<yyMMddHHmm>/ cuando RUN detecta sobrescrituras.
        - El script incluye un parche de ejemplo en $script:SamplePatch.
#>

[CmdletBinding()]
param(
    [string]$In,
    [string]$Out,
    [ValidateSet('NewOnly','ApplyToFolder')]
    [string]$Mode = 'NewOnly',
    [switch]$Zip,
    [switch]$ForceCRLF,
    [switch]$Utf8,
    [switch]$Test,
    [switch]$Run,
    [switch]$NoGui,
    [switch]$UseGit,
    [string]$ApplyBase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = try {
    Split-Path -Parent -Path $PSCommandPath
} catch {
    (Get-Location).ProviderPath
}
if ([string]::IsNullOrWhiteSpace($script:ModuleRoot)) {
    $script:ModuleRoot = (Get-Location).ProviderPath
}

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
} catch {
    # Disponible normalmente, ignorar si ya se cargó.
}

function Initialize-Prerequisites {
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
        try {
            [System.Threading.Thread]::CurrentThread.SetApartmentState([System.Threading.ApartmentState]::STA)
        } catch {
            throw 'No se pudo establecer el estado STA requerido para WinForms.'
        }
    }
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    } catch {
        # Disponible por defecto en .NET Framework/5+
    }
}

$script:CurrentTheme = 'Light'
$script:LastTestResult = $null
$script:LastSanitizedContent = $null
$script:LastRunSummary = $null
$script:SamplePatch = @'
diff --git a/src/demo/Hola.ps1 b/src/demo/Hola.ps1
new file mode 100644
index 0000000..c3c3c3
--- /dev/null
+++ b/src/demo/Hola.ps1
@@ -0,0 +1,7 @@
+function Get-Saludo {
+    [CmdletBinding()]
+    param(
+        [Parameter(Mandatory)][string]$Nombre
+    )
+    "Hola, $Nombre"
+}
'@

function Get-LogsPath {
    $root = Join-Path -Path $script:ModuleRoot -ChildPath 'logs'
    if (-not (Test-Path $root)) {
        $null = New-Item -ItemType Directory -Path $root -Force
    }
    return (Join-Path $root 'actions.jsonl')
}

function Write-Log {
    param(
        [string]$Event,
        [string]$Level = 'info',
        [string]$Path,
        [string]$Status,
        [string]$Mode,
        [long]$Bytes = 0,
        [string]$Sha256,
        [string]$Notes
    )
    $entry = [ordered]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
        event         = $Event
        level         = $Level
        path          = $Path
        status        = $Status
        mode          = $Mode
        bytes         = $Bytes
        sha256        = $Sha256
        notes         = $Notes
    }
    $json = $entry | ConvertTo-Json -Depth 5 -Compress
    $logPath = Get-LogsPath
    Add-Content -Path $logPath -Value $json
}

function Sanitize-DiffContent {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return '' }
    $text = $Raw

    $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
    foreach ($pattern in @("git apply <<'?EOF'?\s*(.*?)\s*^EOF`$", "<<'?EOF'?\s*(.*?)\s*^EOF`$")) {
        $match = [regex]::Match($text, $pattern, $options)
        if ($match.Success -and $match.Groups.Count -gt 1) {
            $text = $match.Groups[1].Value
            break
        }
    }

    $fencePattern = '```(?:diff|patch)?\s*\r?\n(.*?)\r?\n```'
    while ([regex]::IsMatch($text, $fencePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $text = [regex]::Replace($text, $fencePattern, '$1', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    }

    $text = $text.Replace([string][char]13 + [char]10, [string][char]10)
    $text = $text.Replace([string][char]13, [string][char]10)
    return $text.Trim()
}

function Get-ContentHash {
    param([string]$Content)
    if ($null -eq $Content) { return $null }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Parse-DiffContent {
    param([string]$Content)
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $files = New-Object System.Collections.Generic.List[object]

    if ([string]::IsNullOrWhiteSpace($Content)) {
        $errors.Add('El diff está vacío.') | Out-Null
        return [pscustomobject]@{ Files = @(); Errors = $errors; Warnings = $warnings }
    }

    $lines = $Content -split ([string][char]10)
    $current = $null
    $collecting = $false
    foreach ($line in $lines) {
        if ($line -match '^diff --git a/(.+?) b/(.+)$') {
            if ($null -ne $current) {
                $files.Add($current) | Out-Null
            }
            $collecting = $false
            $current = [pscustomobject]@{
                SourcePath = $Matches[1]
                TargetPath = $Matches[2]
                Status     = 'modified'
                ContentBuilder = New-Object System.Text.StringBuilder
                Notes      = New-Object System.Collections.Generic.List[string]
                Preview    = ''
                Sha256     = ''
                Bytes      = 0
                Hunks      = @()
                Content    = ''
            }
            continue
        }
        if ($null -eq $current) { continue }
        switch -Regex ($line) {
            '^new file mode' {
                $current.Status = 'new'
                continue
            }
            '^deleted file mode' {
                $current.Status = 'deleted'
                continue
            }
            '^similarity index' {
                $current.Status = 'renamed'
                continue
            }
            '^rename from (.+)$' {
                $current.Notes.Add([string]::Format('Renombrado desde {0}', $Matches[1])) | Out-Null
                continue
            }
            '^rename to (.+)$' {
                $current.TargetPath = $Matches[1]
                continue
            }
            '^\-\-\- ' {
                continue
            }
            '^\+\+\+ ' {
                continue
            }
            '^@@' {
                $collecting = $true
                continue
            }
            '^\\ No newline at end of file' {
                continue
            }
        }
        if ($collecting -and $current.Status -eq 'new' -and $line.StartsWith('+')) {
            $current.ContentBuilder.AppendLine($line.Substring(1)) | Out-Null
        }
    }
    if ($null -ne $current) {
        $files.Add($current) | Out-Null
    }

    foreach ($file in $files) {
        if ($file.Status -eq 'new') {
            $content = $file.ContentBuilder.ToString()
            $linesPreview = $content -split ([string][char]10)
            if ($linesPreview.Count -gt 0) {
                $file.Preview = ($linesPreview | Select-Object -First 5) -join ([string][char]10)
            } else {
                $file.Preview = ''
            }
            $file.Sha256 = Get-ContentHash -Content $content
            $file.Bytes = [System.Text.Encoding]::UTF8.GetByteCount($content)
            $file.Content = $content
        } elseif ($file.Status -eq 'deleted') {
            $file.Notes.Add('Archivo marcado como eliminado. No se generará contenido.') | Out-Null
        } elseif ($file.Status -eq 'renamed') {
            $warnings.Add([string]::Format('Se detectó renombrado para {0}. Se reporta sin reconstrucción.', $file.TargetPath)) | Out-Null
        } else {
            $warnings.Add([string]::Format('Archivo {0} es modificado. Modo MVP solo reconstruye archivos nuevos.', $file.TargetPath)) | Out-Null
        }
    }

    return [pscustomobject]@{
        Files    = $files
        Errors   = $errors
        Warnings = $warnings
    }
}

function Ensure-Crlf {
    param([string]$Content)
    if ($Content -eq $null) { return $null }
    $normalized = $Content.Replace([string][char]13 + [char]10, [string][char]10)
    $normalized = $normalized.Replace([string][char]13, [string][char]10)
    return $normalized.Replace([string][char]10, [string]([char]13) + [char]10)
}

function Get-TargetFilePath {
    param(
        [string]$Destination,
        [string]$RelativePath
    )
    $sanitized = $RelativePath -replace '^b/',''
    $sanitized = $sanitized -replace '^/+',''
    if ($sanitized -match '\.\.') {
        throw ([string]::Format('Ruta inválida detectada: {0}', $RelativePath))
    }
    $combined = Join-Path -Path $Destination -ChildPath $sanitized
    $full = [System.IO.Path]::GetFullPath($combined)
    $destFull = [System.IO.Path]::GetFullPath($Destination)
    if (-not $full.StartsWith($destFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ([string]::Format('Ruta fuera del destino permitido: {0}', $RelativePath))
    }
    return $full
}

function New-BackupPath {
    param([string]$TargetPath)
    $timestamp = Get-Date -Format 'yyMMddHHmm'
    $backupRoot = Join-Path -Path (Join-Path $script:ModuleRoot '00.Backups') -ChildPath $timestamp
    if (-not (Test-Path $backupRoot)) {
        $null = New-Item -ItemType Directory -Path $backupRoot -Force
    }
    $relative = Resolve-Path -LiteralPath $TargetPath -ErrorAction SilentlyContinue
    if ($null -eq $relative) {
        $relative = $TargetPath
    } else {
        $relative = $relative.ProviderPath
    }
    $relative = $relative.Substring(([System.IO.Path]::GetPathRoot($relative)).Length)
    $backupPath = Join-Path $backupRoot ($relative -replace ':', '_')
    $backupDir = [System.IO.Path]::GetDirectoryName($backupPath)
    if (-not (Test-Path $backupDir)) {
        $null = New-Item -ItemType Directory -Path $backupDir -Force
    }
    return $backupPath
}

function Export-Files {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][object[]]$Files,
        [switch]$ForceCRLF,
        [switch]$Utf8NoBom,
        [switch]$CreateZip,
        [string]$Mode = 'run'
    )
    $results = @()
    $encoding = if ($Utf8NoBom) { [System.Text.UTF8Encoding]::new($false) } else { [System.Text.UTF8Encoding]::new($true) }
    $staging = New-Object System.Collections.Generic.List[object]
    foreach ($file in $Files) {
        if ($file.Status -ne 'new' -or [string]::IsNullOrWhiteSpace($file.Content)) {
            continue
        }
        try {
            $content = $file.Content
            if ($ForceCRLF) {
                $content = Ensure-Crlf -Content $content
            }
            $targetPath = Get-TargetFilePath -Destination $Destination -RelativePath $file.TargetPath
            $dir = [System.IO.Path]::GetDirectoryName($targetPath)
            if ($Mode -eq 'run') {
                if (-not (Test-Path $dir)) {
                    $null = New-Item -ItemType Directory -Path $dir -Force
                }
                $bytes = $encoding.GetBytes($content)
                $existingBytes = $null
                $writeNeeded = $true
                  if (Test-Path $targetPath) {
                      $existingBytes = [System.IO.File]::ReadAllBytes($targetPath)
                      $existingHash = ([BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash($existingBytes))).Replace('-', '').ToLowerInvariant())
                      $newHash = ([BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant())
                      if ($existingHash -eq $newHash) {
                          $writeNeeded = $false
                          Write-Log -Event 'pdp:run' -Level 'info' -Path $file.TargetPath -Status 'unchanged' -Mode $Mode -Bytes $existingBytes.Length -Sha256 $existingHash -Notes 'Archivo ya coincidente. No se reescribió.'
                          $results += [pscustomobject]@{ Path = $file.TargetPath; Status = 'unchanged'; Bytes = $existingBytes.Length; Sha256 = $existingHash }
                      } else {
                          $backup = New-BackupPath -TargetPath $targetPath
                          $backupFile = [string]::Format('{0}.bak', $backup)
                          Copy-Item -LiteralPath $targetPath -Destination $backupFile -Force
                          Write-Log -Event 'pdp:run' -Level 'info' -Path $file.TargetPath -Status 'backup' -Mode $Mode -Bytes $existingBytes.Length -Sha256 $existingHash -Notes ([string]::Format('Backup creado en {0}', $backupFile))
                      }
                  }
                if ($writeNeeded) {
                    [System.IO.File]::WriteAllBytes($targetPath, $bytes)
                    $hash = ([BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant())
                    Write-Log -Event 'pdp:run' -Level 'info' -Path $file.TargetPath -Status 'written' -Mode $Mode -Bytes $bytes.Length -Sha256 $hash -Notes 'Archivo exportado.'
                    $results += [pscustomobject]@{ Path = $file.TargetPath; Status = 'written'; Bytes = $bytes.Length; Sha256 = $hash }
                }
            } else {
                $bytes = $encoding.GetBytes($content)
                $hash = ([BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-', '').ToLowerInvariant())
                Write-Log -Event 'pdp:test' -Level 'info' -Path $file.TargetPath -Status 'simulated' -Mode $Mode -Bytes $bytes.Length -Sha256 $hash -Notes 'TEST sin escritura.'
                $results += [pscustomobject]@{ Path = $file.TargetPath; Status = 'simulated'; Bytes = $bytes.Length; Sha256 = $hash }
            }
            $staging.Add([pscustomobject]@{ RelativePath = $file.TargetPath; Content = $content }) | Out-Null
        } catch {
            Write-Log -Event ([string]::Format('pdp:{0}', $Mode)) -Level 'error' -Path $file.TargetPath -Status 'error' -Mode $Mode -Bytes 0 -Sha256 '' -Notes $_.Exception.Message
            $results += [pscustomobject]@{ Path = $file.TargetPath; Status = 'error'; Bytes = 0; Sha256 = ''; Notes = $_.Exception.Message }
            continue
        }
    }

    if ($Mode -eq 'run' -and $CreateZip -and $staging.Count -gt 1) {
        $hash = Get-ContentHash -Content (($staging | ForEach-Object { $_.RelativePath + '|' + (Get-ContentHash -Content $_.Content) }) -join ';')
        $zipName = [string]::Format('Export_{0}.zip', $hash)
        $zipPath = Join-Path -Path $Destination -ChildPath $zipName
        $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
        try {
            $null = New-Item -ItemType Directory -Path $tempDir -Force
            foreach ($item in $staging) {
                $tempTarget = Join-Path -Path $tempDir -ChildPath ($item.RelativePath -replace '^b/','')
                $tempParent = [System.IO.Path]::GetDirectoryName($tempTarget)
                if (-not (Test-Path $tempParent)) {
                    $null = New-Item -ItemType Directory -Path $tempParent -Force
                }
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($item.Content)
                [System.IO.File]::WriteAllBytes($tempTarget, $bytes)
            }
            if (Test-Path $zipPath) {
                Remove-Item -LiteralPath $zipPath -Force
            }
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipPath)
        } finally {
            if (Test-Path $tempDir) {
                Remove-Item -LiteralPath $tempDir -Recurse -Force
            }
        }
        $zipBytes = (Get-Item -LiteralPath $zipPath).Length
        $zipHash = ([BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($zipPath)))).Replace('-', '').ToLowerInvariant())
        Write-Log -Event 'pdp:run' -Level 'info' -Path $zipName -Status 'zip_created' -Mode $Mode -Bytes $zipBytes -Sha256 $zipHash -Notes 'ZIP generado por exportación múltiple.'
        $results += [pscustomobject]@{ Path = $zipName; Status = 'zip'; Bytes = $zipBytes; Sha256 = $zipHash }
    }
    return $results
}

function Test-Patch {
    param(
        [string]$SanitizedContent,
        [switch]$ForceCRLF,
        [switch]$Utf8NoBom
    )
    $parsed = Parse-DiffContent -Content $SanitizedContent
    if ($parsed.Errors.Count -gt 0) {
        foreach ($err in $parsed.Errors) {
            Write-Log -Event 'pdp:test' -Level 'error' -Path '' -Status 'error' -Mode 'test' -Bytes 0 -Sha256 '' -Notes $err
        }
    }
    foreach ($warn in $parsed.Warnings) {
        Write-Log -Event 'pdp:test' -Level 'warning' -Path '' -Status 'warning' -Mode 'test' -Bytes 0 -Sha256 '' -Notes $warn
    }
    $files = $parsed.Files
    $simulated = @()
    foreach ($file in $files) {
        if ($file.Status -eq 'new') {
            $content = $file.Content
            if ($ForceCRLF) { $content = Ensure-Crlf -Content $content }
            $hash = Get-ContentHash -Content $content
            $bytes = [System.Text.Encoding]::UTF8.GetByteCount($content)
            Write-Log -Event 'pdp:test' -Level 'info' -Path $file.TargetPath -Status 'simulated' -Mode 'test' -Bytes $bytes -Sha256 $hash -Notes 'Archivo nuevo simulado.'
            $simulated += [pscustomobject]@{ Path = $file.TargetPath; Status = 'new'; Bytes = $bytes; Sha256 = $hash; Notes = ($file.Notes -join '; ') }
        }
    }
    $summary = [pscustomobject]@{
        Files   = $files
        Errors  = $parsed.Errors
        Warnings= $parsed.Warnings
        Simulation = $simulated
        ExportStamp = (Get-Date).ToString('yyyyMMddHHmmss')
        Hash = Get-ContentHash -Content $SanitizedContent
    }
    return $summary
}

function Run-Patch {
    param(
        [string]$SanitizedContent,
        [string]$Destination,
        [switch]$ForceCRLF,
        [switch]$Utf8NoBom,
        [switch]$Zip
    )
    if (-not (Test-Path $Destination)) {
        $null = New-Item -ItemType Directory -Path $Destination -Force
    }
    $testResult = $script:LastTestResult
    if ($null -eq $testResult -or $testResult.Hash -ne (Get-ContentHash -Content $SanitizedContent)) {
        $testResult = Test-Patch -SanitizedContent $SanitizedContent -ForceCRLF:$ForceCRLF -Utf8NoBom:$Utf8NoBom
        $script:LastTestResult = $testResult
    }
    if ($testResult.Errors.Count -gt 0) {
        throw 'RUN bloqueado: existen errores detectados en TEST.'
    }
    $export = Export-Files -Destination $Destination -Files $testResult.Files -ForceCRLF:$ForceCRLF -Utf8NoBom:$Utf8NoBom -CreateZip:$Zip -Mode 'run'
    return $export
}

function Toggle-Theme {
    param(
        [System.Windows.Forms.Form]$Form,
        [string]$Theme
    )
    $back = [System.Drawing.Color]::White
    $fore = [System.Drawing.Color]::Black
    $panel = [System.Drawing.Color]::FromArgb(240,240,240)
    if ($Theme -eq 'Dark') {
        $back = [System.Drawing.Color]::FromArgb(32,32,32)
        $fore = [System.Drawing.Color]::Gainsboro
        $panel = [System.Drawing.Color]::FromArgb(45,45,48)
    }
    $Form.BackColor = $back
    foreach ($control in $Form.Controls) {
        Set-ControlTheme -Control $control -BackColor $back -ForeColor $fore -PanelColor $panel
    }
}

function Set-ControlTheme {
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Drawing.Color]$BackColor,
        [System.Drawing.Color]$ForeColor,
        [System.Drawing.Color]$PanelColor
    )
    if ($Control -is [System.Windows.Forms.SplitContainer]) {
        $Control.BackColor = $BackColor
        $Control.Panel1.BackColor = $PanelColor
        $Control.Panel2.BackColor = $BackColor
        Set-ControlTheme -Control $Control.Panel1 -BackColor $PanelColor -ForeColor $ForeColor -PanelColor $PanelColor
        Set-ControlTheme -Control $Control.Panel2 -BackColor $BackColor -ForeColor $ForeColor -PanelColor $PanelColor
        return
    }
    if ($Control -is [System.Windows.Forms.Panel]) {
        $Control.BackColor = $PanelColor
    } else {
        $Control.BackColor = $BackColor
    }
    $Control.ForeColor = $ForeColor
    if ($Control.Controls.Count -gt 0) {
        foreach ($child in $Control.Controls) {
            Set-ControlTheme -Control $child -BackColor $BackColor -ForeColor $ForeColor -PanelColor $PanelColor
        }
    }
}

function Build-GUI {
    Initialize-Prerequisites
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Patch Extractor - PDP'
    $form.Width = 1100
    $form.Height = 740
    $form.MinimumSize = [System.Drawing.Size]::new(1000,700)

    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = [System.Windows.Forms.DockStyle]::Fill
    $split.SplitterDistance = 320
    $split.IsSplitterFixed = $false

    $panelLeft = $split.Panel1
    $panelRight = $split.Panel2

    $btnToggleTheme = New-Object System.Windows.Forms.Button
    $btnToggleTheme.Text = 'Modo oscuro'
    $btnToggleTheme.Width = 280
    $btnToggleTheme.Top = 10
    $btnToggleTheme.Left = 15

    $btnLoad = New-Object System.Windows.Forms.Button
    $btnLoad.Text = 'Cargar archivo...'
    $btnLoad.Width = 280
    $btnLoad.Top = 50
    $btnLoad.Left = 15

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = 'Limpiar'
    $btnClear.Width = 280
    $btnClear.Top = 90
    $btnClear.Left = 15

    $btnTest = New-Object System.Windows.Forms.Button
    $btnTest.Text = 'Procesar (TEST)'
    $btnTest.Width = 280
    $btnTest.Top = 130
    $btnTest.Left = 15

    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = 'Exportar (RUN)'
    $btnRun.Width = 280
    $btnRun.Top = 170
    $btnRun.Left = 15

    $chkForceCRLF = New-Object System.Windows.Forms.CheckBox
    $chkForceCRLF.Text = 'Forzar CRLF'
    $chkForceCRLF.Width = 280
    $chkForceCRLF.Top = 220
    $chkForceCRLF.Left = 15
    $chkForceCRLF.Checked = $true

    $chkUtf8 = New-Object System.Windows.Forms.CheckBox
    $chkUtf8.Text = 'UTF-8 sin BOM'
    $chkUtf8.Width = 280
    $chkUtf8.Top = 250
    $chkUtf8.Left = 15
    $chkUtf8.Checked = $true

    $chkZip = New-Object System.Windows.Forms.CheckBox
    $chkZip.Text = 'Exportar ZIP si hay varios archivos'
    $chkZip.Width = 280
    $chkZip.Top = 280
    $chkZip.Left = 15
    $chkZip.Checked = $true

    $lblState = New-Object System.Windows.Forms.Label
    $lblState.Text = 'Sin procesar'
    $lblState.Width = 280
    $lblState.Top = 320
    $lblState.Left = 15

    $panelLeft.Controls.AddRange(@($btnToggleTheme,$btnLoad,$btnClear,$btnTest,$btnRun,$chkForceCRLF,$chkUtf8,$chkZip,$lblState))

    $rightLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $rightLayout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $rightLayout.ColumnCount = 1
    $rightLayout.RowCount = 2
    $rightLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,60)))
    $rightLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,40)))

    $txtDiff = New-Object System.Windows.Forms.RichTextBox
    $txtDiff.Dock = [System.Windows.Forms.DockStyle]::Fill
    $txtDiff.Font = New-Object System.Drawing.Font('Consolas',10)
    $txtDiff.DetectUrls = $false
    $txtDiff.Text = $script:SamplePatch

    $tab = New-Object System.Windows.Forms.TabControl
    $tab.Dock = [System.Windows.Forms.DockStyle]::Fill

    $tabSummary = New-Object System.Windows.Forms.TabPage
    $tabSummary.Text = 'Resumen'
    $tabLog = New-Object System.Windows.Forms.TabPage
    $tabLog.Text = 'Registro'

    $list = New-Object System.Windows.Forms.ListView
    $list.View = [System.Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill
    $list.Columns.Add('Ruta',300) | Out-Null
    $list.Columns.Add('Estado',80) | Out-Null
    $list.Columns.Add('Bytes',80) | Out-Null
    $list.Columns.Add('SHA256',260) | Out-Null

    $logBox = New-Object System.Windows.Forms.ListBox
    $logBox.Dock = [System.Windows.Forms.DockStyle]::Fill

    $tabSummary.Controls.Add($list)
    $tabLog.Controls.Add($logBox)
    $tab.Controls.Add($tabSummary)
    $tab.Controls.Add($tabLog)

    $rightLayout.Controls.Add($txtDiff,0,0)
    $rightLayout.Controls.Add($tab,0,1)

    $panelRight.Controls.Add($rightLayout)

    $form.Controls.Add($split)

    $state = [pscustomobject]@{
        Label = $lblState
        List  = $list
        LogBox = $logBox
        TextBox = $txtDiff
        ForceCRLF = $chkForceCRLF
        Utf8 = $chkUtf8
        Zip = $chkZip
    }

    $btnToggleTheme.Add_Click({
        if ($script:CurrentTheme -eq 'Light') {
            $script:CurrentTheme = 'Dark'
            $btnToggleTheme.Text = 'Modo claro'
        } else {
            $script:CurrentTheme = 'Light'
            $btnToggleTheme.Text = 'Modo oscuro'
        }
        Toggle-Theme -Form $form -Theme $script:CurrentTheme
    })

    $btnClear.Add_Click({
        $txtDiff.Clear()
        $state.List.Items.Clear()
        $state.LogBox.Items.Clear()
        $lblState.Text = 'Sin procesar'
        $script:LastTestResult = $null
        $script:LastSanitizedContent = $null
    })

    $btnLoad.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Filter = 'Archivo de texto (*.txt;*.md;*.patch)|*.txt;*.md;*.patch|Todos (*.*)|*.*'
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDiff.Text = Get-Content -LiteralPath $dialog.FileName -Raw
        }
    })

    $btnTest.Add_Click({
        try {
            $state.LogBox.Items.Clear()
            $sanitized = Sanitize-DiffContent -Raw $txtDiff.Text
            $script:LastSanitizedContent = $sanitized
            $result = Test-Patch -SanitizedContent $sanitized -ForceCRLF:$chkForceCRLF.Checked -Utf8NoBom:$chkUtf8.Checked
            $script:LastTestResult = $result
            $state.List.Items.Clear()
            foreach ($file in $result.Simulation) {
                $item = New-Object System.Windows.Forms.ListViewItem($file.Path)
                $item.SubItems.Add($file.Status) | Out-Null
                $item.SubItems.Add($file.Bytes.ToString()) | Out-Null
                $item.SubItems.Add($file.Sha256) | Out-Null
                $state.List.Items.Add($item) | Out-Null
            }
            $lblState.Text = [string]::Format('Archivos detectados: {0}. Errores: {1}.', $result.Simulation.Count, $result.Errors.Count)
            foreach ($warn in $result.Warnings) {
                $state.LogBox.Items.Add([string]::Format('ADVERTENCIA: {0}', $warn)) | Out-Null
            }
            if ($result.Errors.Count -eq 0) {
                $state.LogBox.Items.Add('TEST completado sin errores.') | Out-Null
            } else {
                foreach ($err in $result.Errors) {
                    $state.LogBox.Items.Add([string]::Format('ERROR: {0}', $err)) | Out-Null
                }
            }
        } catch {
            $state.LogBox.Items.Add([string]::Format('ERROR: {0}', $_.Exception.Message)) | Out-Null
        }
    })

    $btnRun.Add_Click({
        try {
            if (-not $script:LastSanitizedContent) {
                $script:LastSanitizedContent = Sanitize-DiffContent -Raw $txtDiff.Text
            }
            if (-not $script:LastTestResult) {
                $script:LastTestResult = Test-Patch -SanitizedContent $script:LastSanitizedContent -ForceCRLF:$chkForceCRLF.Checked -Utf8NoBom:$chkUtf8.Checked
            }
            if ($script:LastTestResult.Errors.Count -gt 0) {
                $state.LogBox.Items.Add('RUN bloqueado: ejecutar TEST y resolver errores.') | Out-Null
                return
            }
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }
            $export = Run-Patch -SanitizedContent $script:LastSanitizedContent -Destination $folderDialog.SelectedPath -ForceCRLF:$chkForceCRLF.Checked -Utf8NoBom:$chkUtf8.Checked -Zip:$chkZip.Checked
            $state.LogBox.Items.Add([string]::Format('RUN completado. Elementos: {0}', $export.Count)) | Out-Null
            foreach ($entry in $export) {
                $state.LogBox.Items.Add([string]::Format('RUN -> {0} [{1}]', $entry.Path, $entry.Status)) | Out-Null
            }
        } catch {
            $state.LogBox.Items.Add([string]::Format('ERROR: {0}', $_.Exception.Message)) | Out-Null
        }
    })

    Toggle-Theme -Form $form -Theme $script:CurrentTheme
    return [pscustomobject]@{ Form = $form; State = $state }
}

function Invoke-CLI {
    param(
        [string]$InputFile,
        [string]$OutputFolder,
        [switch]$Run,
        [switch]$Test,
        [switch]$Zip,
        [switch]$ForceCRLF,
        [switch]$Utf8
    )
    if (-not $InputFile) { throw 'Debe especificar --in para modo CLI.' }
    if (-not (Test-Path $InputFile)) { throw ([string]::Format('No se encontró el archivo {0}', $InputFile)) }
    $content = Get-Content -LiteralPath $InputFile -Raw
    $sanitized = Sanitize-DiffContent -Raw $content
    if ($Test) {
        $script:LastTestResult = Test-Patch -SanitizedContent $sanitized -ForceCRLF:$ForceCRLF -Utf8NoBom:$Utf8
        Write-Output ([string]::Format('TEST completado. Archivos simulados: {0}', $script:LastTestResult.Simulation.Count))
    }
    if ($Run) {
        if (-not $OutputFolder) { throw 'Debe indicar --out para RUN.' }
        $export = Run-Patch -SanitizedContent $sanitized -Destination $OutputFolder -ForceCRLF:$ForceCRLF -Utf8NoBom:$Utf8 -Zip:$Zip
        Write-Output ([string]::Format('RUN completado. Elementos: {0}', $export.Count))
    }
}

$launchGui = $true
if ($PSBoundParameters.Count -gt 0) {
    if ($PSBoundParameters.ContainsKey('NoGui')) {
        $launchGui = -not $NoGui.IsPresent
    } elseif ($PSBoundParameters.ContainsKey('In') -or $PSBoundParameters.ContainsKey('Out') -or $Run.IsPresent -or $Test.IsPresent) {
        $launchGui = $false
    }
}

if ($launchGui) {
    try {
        $gui = Build-GUI
        if ($null -eq $gui -or -not $gui.PSObject.Properties.Match('Form')) {
            throw "Build-GUI no devolvió un objeto válido con propiedad 'Form'."
        }
        [System.Windows.Forms.Application]::Run($gui.Form)
    } catch {
        Write-Error "Error al inicializar GUI: $($_.Exception.Message)"
        Write-Error "Sugerencia: ejecuta 'Initialize-Prerequisites' manualmente para verificar WinForms."
    }
} else {
    Invoke-CLI -InputFile $In -OutputFolder $Out -Run:$Run -Test:$Test -Zip:$Zip -ForceCRLF:$ForceCRLF -Utf8:$Utf8
}

<#
Verificación manual registrada:
    - Fecha: 2025-10-14.
    - Entorno: PowerShell 7.5.3 (Linux container de verificación; GUI no disponible en este host).
    - Acciones: ejecución CLI con parche de ejemplo -> TEST (simulación) y RUN (exportación real) validando logs/actions.jsonl y archivo generado.
    - Resultado: TEST reportó 1 archivo simulado; RUN exportó 1 archivo (src/demo/Hola.ps1) sin errores.
    - Nota: Se recomienda repetir verificación completa en Windows 10 con GUI para asegurar compatibilidad visual.
#>