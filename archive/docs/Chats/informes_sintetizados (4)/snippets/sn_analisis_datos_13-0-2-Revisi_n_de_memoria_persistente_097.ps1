# C:\Users\VictorFabianVeraVill\Desktop\TBEA\TBEA_NormalizeAscii.ps1
#requires -Version 7
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Root = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA',
    [string[]]$SubPaths = @('01_Software')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-ToAsciiName {
    param([string]$Name)
    # Sustituye cualquier char > 127 por "_"
    -join ($Name.ToCharArray() | ForEach-Object {
        if ([int][char]$_ -le 127) { $_ } else { '_' }
    })
}

$destRoot = Join-Path $Root 'normalized'
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

foreach ($sub in $SubPaths) {
    $src = Join-Path $Root $sub
    if (-not (Test-Path $src)) { continue }
    Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
        $relDir = Split-Path $rel -Parent
        $asciiName = Convert-ToAsciiName -Name $_.Name
        $outDir = Join-Path $destRoot $relDir
        $outPath = Join-Path $outDir $asciiName
        if ($PSCmdlet.ShouldProcess($outPath, "Copy ASCII-safe")) {
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $outPath -Force
        }
    }
}

Write-Host "Copias ASCII creadas bajo: $destRoot"