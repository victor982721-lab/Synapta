param()

Register-RuntimeAnalyzerRule -Name 'NullChecks' -Handler {
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $FunctionInfo,

        [pscustomobject] $RuleConfig,

        [pscustomobject] $Context
    )

    $definitions = @()
    foreach ($parameter in $FunctionInfo.Parameters) {
        if ($parameter.IsMandatory -or $parameter.IsSwitch) {
            continue
        }

        $parameters = [ordered]@{}
        foreach ($key in $Context.BaselineParameters.Keys) {
            $parameters[$key] = $Context.BaselineParameters[$key]
        }
        $parameters[$parameter.Name] = $null

        $testId = "{0}.NullChecks.Param-{1}" -f $FunctionInfo.Name, $parameter.Name
        $description = "Valida nulos para {0}" -f $parameter.Name

        $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'NullChecks' -TestId $testId -Description $description -Parameters $parameters -PipelineInput $null -Mocks @() -Expected @{
            ShouldThrow    = $false
            ShouldNotThrow = $true
            ErrorType      = $null
            CustomAsserts  = @()
        }
    }

    return $definitions
}
