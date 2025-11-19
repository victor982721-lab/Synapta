[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TargetPath,

    [string] $TestsRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'Tests'),

    [ValidateSet('Generate', 'Run', 'GenerateAndRun')]
    [string] $Mode = 'GenerateAndRun',

    [string[]] $RuleSet,

    [switch] $IncludePrivate,

    [switch] $ForceRebuild,

    [ValidateSet('json', 'ndjson', 'text')]
    [string] $OutputFormat = 'json',

    [string] $OutFile,

    [ValidateSet('None', 'Failed', 'Error')]
    [string] $FailOn = 'Error'
)

$ErrorActionPreference = 'Stop'

$modulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Modules'
Import-Module (Join-Path $modulesRoot 'RuntimeAnalyzer.Core.psm1') -Force
Import-Module (Join-Path $modulesRoot 'RuntimeAnalyzer.Rules.psm1') -Force
Import-Module (Join-Path $modulesRoot 'RuntimeAnalyzer.PesterGen.psm1') -Force
Import-Module (Join-Path $modulesRoot 'RuntimeAnalyzer.Report.psm1') -Force

$configDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'Config'
$configPath = Join-Path -Path $configDirectory -ChildPath 'RuntimeAnalyzer.rules.json'
$resolvedTarget = Resolve-RuntimeAnalyzerPath -Path $TargetPath

if (-not (Test-Path -Path $TestsRoot)) {
    New-Item -ItemType Directory -Path $TestsRoot -Force | Out-Null
}

function Invoke-TestGeneration {
    $functions = Get-RuntimeAnalyzerFunctionInfo -TargetPath $resolvedTarget -IncludePrivate:$IncludePrivate
    if (-not $functions -or $functions.Count -eq 0) {
        throw "No se encontraron funciones en el target $resolvedTarget"
    }

    $definitions = Get-TestDefinitionsForTarget -TargetInfo $functions -RuleSet $RuleSet -TestsRoot $TestsRoot -ConfigPath $configPath
    if (-not $definitions) { $definitions = @() }
    $testFilePath = New-RuntimeAnalyzerTestFile -TargetPath $resolvedTarget -TestDefinitions $definitions -TestsRoot $TestsRoot -ForceRebuild:$ForceRebuild
    return [pscustomobject]@{
        FilePath     = $testFilePath
        TestCount    = $definitions.Count
        Definitions  = $definitions
    }
}

try {
    switch ($Mode) {
        'Generate' {
            $generationResult = Invoke-TestGeneration
            Write-Output "Pruebas generadas: $($generationResult.TestCount) en $($generationResult.FilePath)"
            exit 0
        }
        'Run' {
            $testFilePath = Get-RuntimeAnalyzerTestFilePath -TargetPath $resolvedTarget -TestsRoot $TestsRoot
            if (-not (Test-Path -Path $testFilePath -PathType Leaf)) {
                throw "No existen pruebas generadas para $resolvedTarget. Ejecute con -Mode Generate primero."
            }
            $reportResult = Invoke-RuntimeAnalyzerReport -TargetPath $resolvedTarget -TestFilePath $testFilePath -OutputFormat $OutputFormat -OutFile $OutFile -FailOn $FailOn
            exit $reportResult.ExitCode
        }
        'GenerateAndRun' {
            $generationResult = Invoke-TestGeneration
            $reportResult = Invoke-RuntimeAnalyzerReport -TargetPath $resolvedTarget -TestFilePath $generationResult.FilePath -OutputFormat $OutputFormat -OutFile $OutFile -FailOn $FailOn
            exit $reportResult.ExitCode
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
