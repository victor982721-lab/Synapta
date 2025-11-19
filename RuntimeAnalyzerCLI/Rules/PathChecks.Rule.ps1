param()

Register-RuntimeAnalyzerRule -Name 'PathChecks' -Handler {
    param(
        [pscustomobject] $FunctionInfo,
        [pscustomobject] $RuleConfig,
        [pscustomobject] $Context
    )

    $definitions = @()
    $mockCommand = if ($RuleConfig.MockCommand) { $RuleConfig.MockCommand } else { 'Test-Path' }

    foreach ($parameter in $FunctionInfo.Parameters) {
        if ($parameter.Name -notmatch '(?i)(Path|File|Directory|Root)') {
            continue
        }

        $invalidParameters = [ordered]@{}
        foreach ($key in $Context.BaselineParameters.Keys) {
            $invalidParameters[$key] = $Context.BaselineParameters[$key]
        }
        $invalidParameters[$parameter.Name] = "Z:\\invalid\\$([guid]::NewGuid().Guid)"

        $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'PathChecks' -TestId ("{0}.PathChecks.Invalid-{1}" -f $FunctionInfo.Name, $parameter.Name) -Description "Ruta inexistente para $($parameter.Name)" -Parameters $invalidParameters -PipelineInput $null -Mocks @() -Expected @{
            ShouldThrow    = $true
            ShouldNotThrow = $false
            ErrorType      = 'System.IO.IOException'
            CustomAsserts  = @()
        }

        $validParameters = [ordered]@{}
        foreach ($key in $Context.BaselineParameters.Keys) {
            $validParameters[$key] = $Context.BaselineParameters[$key]
        }
        $validParameters[$parameter.Name] = 'C:\\Temp\\valid.txt'

        $mockDefinition = @(
            [pscustomobject]@{
                CommandName = $mockCommand
                ScriptBlock = 'return $true'
                ModuleName  = $null
            }
        )

        $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'PathChecks' -TestId ("{0}.PathChecks.Valid-{1}" -f $FunctionInfo.Name, $parameter.Name) -Description "Ruta válida para $($parameter.Name)" -Parameters $validParameters -PipelineInput $null -Mocks $mockDefinition -Expected @{
            ShouldThrow    = $false
            ShouldNotThrow = $true
            ErrorType      = $null
            CustomAsserts  = @()
        }
    }

    return $definitions
}
