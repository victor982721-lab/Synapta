$script:RuleRegistry = @{}
$script:RulesLoaded = $false

function Register-RuntimeAnalyzerRule {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [scriptblock] $Handler
    )

    $script:RuleRegistry[$Name] = $Handler
}

function Import-RuntimeAnalyzerRuleScripts {
    if ($script:RulesLoaded) {
        return
    }

    $rulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '..'
    $rulesPath = Join-Path -Path $rulesRoot -ChildPath 'Rules'
    foreach ($ruleFile in Get-ChildItem -Path $rulesPath -Filter '*.Rule.ps1' -File -ErrorAction SilentlyContinue) {
        . $ruleFile.FullName
    }

    $script:RulesLoaded = $true
}

function Get-RuntimeAnalyzerRuleConfiguration {
    param(
        [string] $ConfigPath
    )

    if (-not $ConfigPath) {
        $configRoot = Join-Path -Path $PSScriptRoot -ChildPath '..'
        $configFolder = Join-Path -Path $configRoot -ChildPath 'Config'
        $ConfigPath = Join-Path -Path $configFolder -ChildPath 'RuntimeAnalyzer.rules.json'
    }

    if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
        return [pscustomobject]@{
            DefaultRuleSet = @('NullChecks', 'TypeChecks', 'PathChecks', 'PipelineChecks', 'Smoke')
            Rules          = @{}
        }
    }

    $json = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
    return $json | ConvertFrom-Json
}

function Get-RuntimeAnalyzerDefaultValue {
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $ParameterInfo
    )

    $name = $ParameterInfo.Name
    $typeName = $null
    if ($ParameterInfo.Type) {
        $typeName = $ParameterInfo.Type.Trim('[', ']').ToLowerInvariant()
    }

    if ($name -match '(?i)(Path|Root|Directory|Folder)') {
        return 'C:\\Temp'
    }
    if ($name -match '(?i)(File)') {
        return 'C:\\Temp\\file.txt'
    }

    switch ($typeName) {
        'int' { return 1 }
        'int32' { return 1 }
        'int64' { return 1 }
        'double' { return 1.5 }
        'decimal' { return 1.5 }
        'string' { return 'sample' }
        'datetime' { return [datetime]::UtcNow }
        'bool' { return $true }
        'switch' { return $true }
        'boolean' { return $true }
        'timespan' { return [timespan]::FromMinutes(1) }
        'guid' { return [guid]::NewGuid() }
        'pscredential' { return 'runtime' }
    }

    return 'sample'
}

function Get-RuntimeAnalyzerBaselineParameters {
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $FunctionInfo
    )

    $parameters = [ordered]@{}
    foreach ($parameter in $FunctionInfo.Parameters) {
        $parameters[$parameter.Name] = Get-RuntimeAnalyzerDefaultValue -ParameterInfo $parameter
    }

    return $parameters
}

function New-RuntimeAnalyzerTestDefinition {
    param(
        [Parameter(Mandatory)]
        [string] $FunctionName,

        [Parameter(Mandatory)]
        [string] $RuleName,

        [Parameter(Mandatory)]
        [string] $TestId,

        [Parameter(Mandatory)]
        [string] $Description,

        [hashtable] $Parameters,

        [object] $PipelineInput,

        [object[]] $Mocks,

        [hashtable] $Expected
    )

    return [pscustomobject]@{
        FunctionName = $FunctionName
        RuleName     = $RuleName
        TestId       = $TestId
        Description  = $Description
        Input        = [pscustomobject]@{
            Parameters = $Parameters
            Pipeline   = $PipelineInput
            Mocks      = $Mocks
        }
        Expected     = $Expected
    }
}

function Get-TestDefinitionsForTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]] $TargetInfo,

        [string[]] $RuleSet,

        [string] $ConfigPath,

        [string] $TestsRoot
    )

    Import-RuntimeAnalyzerRuleScripts
    $config = Get-RuntimeAnalyzerRuleConfiguration -ConfigPath $ConfigPath

    if (-not $RuleSet -or $RuleSet.Count -eq 0) {
        $RuleSet = $config.DefaultRuleSet
    }

    $activeRules = @()
    foreach ($name in $RuleSet) {
        if (-not $script:RuleRegistry.ContainsKey($name)) {
            continue
        }

        $ruleConfig = $null
        if ($config.Rules -and ($config.Rules.PSObject.Properties.Name -contains $name)) {
            $ruleConfig = $config.Rules.$name
        }

        if ($ruleConfig -and $ruleConfig.Enabled -eq $false) {
            continue
        }

        $activeRules += [pscustomobject]@{
            Name    = $name
            Handler = $script:RuleRegistry[$name]
            Config  = $ruleConfig
        }
    }

    $definitions = @()
    foreach ($functionInfo in $TargetInfo) {
        foreach ($rule in $activeRules) {
            $context = [pscustomobject]@{
                TestsRoot          = $TestsRoot
                RuleName           = $rule.Name
                BaselineParameters = Get-RuntimeAnalyzerBaselineParameters -FunctionInfo $functionInfo
            }

            $ruleDefinitions = & $rule.Handler -FunctionInfo $functionInfo -RuleConfig $rule.Config -Context $context
            if ($ruleDefinitions) {
                $definitions += $ruleDefinitions
            }
        }
    }

    return $definitions
}

Export-ModuleMember -Function Register-RuntimeAnalyzerRule, Get-TestDefinitionsForTarget, Get-RuntimeAnalyzerDefaultValue, Get-RuntimeAnalyzerBaselineParameters, New-RuntimeAnalyzerTestDefinition
