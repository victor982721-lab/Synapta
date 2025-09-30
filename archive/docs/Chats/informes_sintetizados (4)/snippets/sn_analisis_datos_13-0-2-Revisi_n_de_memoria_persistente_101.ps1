# C:\Users\VictorFabianVeraVill\Desktop\TBEA\TBEA_AuditDriverExe.ps1
#requires -Version 7
[CmdletBinding()]
param(
    [string]$Root = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$exe = Join-Path $Root '01_Software\01_Drives_(Hl-340).exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "No existe: $exe" }

$ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
$hash = Get-FileHash -LiteralPath $exe -Algorithm SHA256

[PSCustomObject]@{
    File = $exe
    ProductName = $ver.ProductName
    FileVersion = $ver.FileVersion
    ProductVersion = $ver.ProductVersion
    CompanyName = $ver.CompanyName
    SHA256 = $hash.Hash
} | Tee-Object -Variable meta | Format-List

$meta | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $Root 'logs\driver_meta.json')