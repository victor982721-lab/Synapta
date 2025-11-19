function Invoke-RuntimeAnalyzerMocks {
    param(
        [Parameter(Mandatory)]
        [object[]] $Mocks
    )

    foreach ($mock in ($Mocks | Where-Object { $_ })) {
        $commandName = $mock.CommandName
        if (-not $commandName) {
            continue
        }

        $scriptBlockText = if ($mock.ScriptBlock) { $mock.ScriptBlock } else { 'return $null' }
        $scriptBlock = [scriptblock]::Create($scriptBlockText)
        if ($mock.Parameters -is [hashtable]) {
            Mock -CommandName $commandName @mock.Parameters -MockWith $scriptBlock
        } elseif ($mock.ModuleName) {
            Mock -CommandName $commandName -ModuleName $mock.ModuleName -MockWith $scriptBlock
        } else {
            Mock -CommandName $commandName -MockWith $scriptBlock
        }
    }
}

function Invoke-RuntimeAnalyzerTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $FunctionName,

        [hashtable] $Parameters,

        [object] $PipelineInput
    )

    $invokeParams = @{}
    if ($Parameters) {
        $invokeParams = $Parameters
    }

    if ($PSBoundParameters.ContainsKey('PipelineInput') -and $null -ne $PipelineInput) {
        return $PipelineInput | & $FunctionName @invokeParams
    }

    return & $FunctionName @invokeParams
}

function Invoke-RuntimeAnalyzerCustomAssert {
    param(
        [Parameter(Mandatory)]
        [object] $Result,

        [Parameter(Mandatory)]
        [string] $Script
    )

    $assertBlock = [scriptblock]::Create($Script)
    & $assertBlock -ArgumentList $Result | Out-Null
}
