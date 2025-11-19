param()

function Get-InvalidTypeValue {
    param(
        [pscustomobject] $Parameter
    )

    $typeName = $Parameter.Type
    if (-not $typeName) {
        return $null
    }

    $typeName = $typeName.Trim('[', ']').ToLowerInvariant()
    switch ($typeName) {
        'int' { return 'invalid-number' }
        'int32' { return 'invalid-number' }
        'int64' { return 'invalid-number' }
        'double' { return 'invalid-number' }
        'decimal' { return 'invalid-number' }
        'datetime' { return 'not-a-date' }
        'bool' { return 'not-a-bool' }
        'boolean' { return 'not-a-bool' }
        'timespan' { return '00:00:not-valid' }
        'guid' { return 'not-a-guid' }
        default { return @{ unexpected = $true } }
    }
}

Register-RuntimeAnalyzerRule -Name 'TypeChecks' -Handler {
    param(
        [pscustomobject] $FunctionInfo,
        [pscustomobject] $RuleConfig,
        [pscustomobject] $Context
    )

    $definitions = @()
    foreach ($parameter in $FunctionInfo.Parameters) {
        if (-not $parameter.Type -or $parameter.IsSwitch) {
            continue
        }

        $invalidValue = Get-InvalidTypeValue -Parameter $parameter
        if ($null -eq $invalidValue) {
            continue
        }

        $parameters = [ordered]@{}
        foreach ($key in $Context.BaselineParameters.Keys) {
            $parameters[$key] = $Context.BaselineParameters[$key]
        }
        $parameters[$parameter.Name] = $invalidValue

        $testId = "{0}.TypeChecks.Param-{1}" -f $FunctionInfo.Name, $parameter.Name
        $description = "Valida tipos incorrectos para {0}" -f $parameter.Name

        $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'TypeChecks' -TestId $testId -Description $description -Parameters $parameters -PipelineInput $null -Mocks @() -Expected @{
            ShouldThrow    = $true
            ShouldNotThrow = $false
            ErrorType      = 'System.Exception'
            CustomAsserts  = @()
        }
    }

    return $definitions
}
