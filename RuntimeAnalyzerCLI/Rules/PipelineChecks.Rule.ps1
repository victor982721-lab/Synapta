param()

function New-PipelineItems {
    param(
        [pscustomobject[]] $PipelineParameters,
        [int] $Count = 3
    )

    $byProperty = $PipelineParameters | Where-Object { $_.ValueFromPipelineByPropertyName }
    if ($byProperty.Count -gt 0) {
        $items = @()
        for ($i = 1; $i -le $Count; $i++) {
            $bag = [ordered]@{}
            foreach ($param in $byProperty) {
                $bag[$param.Name] = "Sample-$i"
            }
            $items += [pscustomobject]$bag
        }
        return $items
    }

    $byValue = $PipelineParameters | Where-Object { $_.ValueFromPipeline }
    if ($byValue.Count -gt 0) {
        $values = @()
        for ($i = 1; $i -le $Count; $i++) {
            $values += "Sample-$i"
        }
        return $values
    }

    return @()
}

Register-RuntimeAnalyzerRule -Name 'PipelineChecks' -Handler {
    param(
        [pscustomobject] $FunctionInfo,
        [pscustomobject] $RuleConfig,
        [pscustomobject] $Context
    )

    $pipelineParameters = $FunctionInfo.Parameters | Where-Object { $_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName }
    if (-not $pipelineParameters -or $pipelineParameters.Count -eq 0) {
        return @()
    }

    $sampleCount = if ($RuleConfig.SampleItemCount) { [int]$RuleConfig.SampleItemCount } else { 3 }
    $items = New-PipelineItems -PipelineParameters $pipelineParameters -Count $sampleCount

    $definitions = @()
    $parameters = [ordered]@{}
    foreach ($key in $Context.BaselineParameters.Keys) {
        $parameters[$key] = $Context.BaselineParameters[$key]
    }

    $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'PipelineChecks' -TestId ("{0}.PipelineChecks.Empty" -f $FunctionInfo.Name) -Description 'Pipeline vacío' -Parameters $parameters -PipelineInput @() -Mocks @() -Expected @{
        ShouldThrow    = $false
        ShouldNotThrow = $true
        ErrorType      = $null
        CustomAsserts  = @()
    }

    if ($items -and $items.Count -gt 0) {
        $definitions += New-RuntimeAnalyzerTestDefinition -FunctionName $FunctionInfo.Name -RuleName 'PipelineChecks' -TestId ("{0}.PipelineChecks.Populated" -f $FunctionInfo.Name) -Description 'Pipeline con datos' -Parameters $parameters -PipelineInput $items -Mocks @() -Expected @{
            ShouldThrow    = $false
            ShouldNotThrow = $true
            ErrorType      = $null
            CustomAsserts  = @()
        }
    }

    return $definitions
}
