param()

Register-RuntimeAnalyzerRule -Name 'Smoke' -Handler {
    param(
        [pscustomobject] $FunctionInfo,
        [pscustomobject] $RuleConfig,
        [pscustomobject] $Context
    )

    if (-not $FunctionInfo.IsExported) {
        return @()
    }

    $parameters = [ordered]@{}
    foreach ($key in $Context.BaselineParameters.Keys) {
        $parameters[$key] = $Context.BaselineParameters[$key]
    }

    $testId = "{0}.Smoke" -f $FunctionInfo.Name
    $description = 'Prueba básica de humo'

    return New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'Smoke' -TestId $testId -Description $description -Parameters $parameters -PipelineInput $null -Mocks @() -Expected @{
        ShouldThrow    = $false
        ShouldNotThrow = $true
        ErrorType      = $null
        CustomAsserts  = @()
    }
}
