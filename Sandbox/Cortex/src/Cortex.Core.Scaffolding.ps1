. "$PSScriptRoot/Cortex.Common.ps1"

function Invoke-CortexScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')][string]$ProjectType,
        [Parameter(Mandatory)][string]$Output,
        [string]$TemplatesOverride
    )

    Assert-CortexWindowsPlatform

    $targetRoot = Join-Path $Output $ProjectName
    $docs = Join-Path $targetRoot 'Documentos'
    $scripts = Join-Path $targetRoot 'Scripts'
    $src = Join-Path $targetRoot 'src'
    $entregable = Join-Path $targetRoot 'Entregable'
    $srcNet = Join-Path $targetRoot 'SrcNet'

    foreach ($dir in @($docs, $scripts, $src, $entregable, $srcNet)) {
        if (-not (Test-Path -Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    $templates = $CortexTemplates
    if ($TemplatesOverride -and (Test-Path -Path $TemplatesOverride)) {
        Get-ChildItem -Path $TemplatesOverride -File | ForEach-Object {
            $templates[$_.Name] = Get-Content -Path $_.FullName -Raw -Encoding UTF8
        }
    }

    foreach ($key in $templates.Keys) {
        $content = Expand-CortexTemplate -Content $templates[$key] -ProjectName $ProjectName -ProjectType $ProjectType
        switch ($key) {
            'AGENTS.md' { Write-CortexFileIfMissing -Path (Join-Path $targetRoot 'AGENTS.md') -Content $content }
            'README.md' { Write-CortexFileIfMissing -Path (Join-Path $targetRoot 'README.md') -Content $content }
            'Procedimiento.md' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Procedimiento.md') -Content $content }
            'Informe.md' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Informe.md') -Content $content }
            'Solicitud.md' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Solicitud.md') -Content $content }
            'Artefactos.csv' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Artefactos.csv') -Content $content }
            'Modulos.csv' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Modulos.csv') -Content $content }
            'Bitacora.md' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Bitacora.md') -Content $content }
            'Cortex_Plan_Schema.md' { Write-CortexFileIfMissing -Path (Join-Path $docs 'Cortex_Plan_Schema.md') -Content $content }
            'table_hierarchy.json' { Write-CortexFileIfMissing -Path (Join-Path $docs 'table_hierarchy.json') -Content $content }
            'table_hierarchy_template.json' { Write-CortexFileIfMissing -Path (Join-Path $docs 'table_hierarchy_template.json') -Content $content }
        }
    }

    $csprojPath = Join-Path $srcNet "$ProjectName.csproj"
    if (-not (Test-Path -Path $csprojPath)) {
        $tfm = '<TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>'
        $ui = if ($ProjectType -eq 'DotNet-UI') { '<UseWPF>true</UseWPF>' } else { '' }
        @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    $tfm
    $ui
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
"@ | Out-File -FilePath $csprojPath -Encoding utf8
    }

    $programPath = Join-Path $srcNet 'Program.cs'
    if (-not (Test-Path -Path $programPath)) {
        @"
using System;

namespace $ProjectName
{
    internal static class Program
    {
        static int Main(string[] args)
        {
            Console.WriteLine("{{{0}}} ejecutado desde Cortex scaffolding.", "$ProjectName");
            return 0;
        }
    }
}
"@ | Out-File -FilePath $programPath -Encoding utf8
    }

    $mainPs1 = Join-Path $scripts "$ProjectName.ps1"
    if (-not (Test-Path -Path $mainPs1)) {
        @"
param(
    [string]$Message = 'Hello from Cortex'
)
Write-Host "${ProjectName}: $Message"
"@ | Out-File -FilePath $mainPs1 -Encoding utf8
    }

    return $targetRoot
}
