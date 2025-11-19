function ConvertTo-PowerShellLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Value
    )

    if ($null -eq $Value) {
        return '$null'
    }

    if ($Value -is [pscustomobject]) {
        $table = @{}
        foreach ($property in $Value.PSObject.Properties) {
            $table[$property.Name] = $property.Value
        }
        return ConvertTo-PowerShellLiteral -Value $table
    }

    if ($Value -is [string]) {
        $escaped = $Value -replace "'", "''"
        return "'$escaped'"
    }

    if ($Value -is [bool]) {
        return $(if ($Value) { '$true' } else { '$false' })
    }

    if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value.ToString()
    }

    if ($Value -is [datetime]) {
        return "[datetime]'$($Value.ToString('o'))'"
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $items = foreach ($key in $Value.Keys) {
            $child = ConvertTo-PowerShellLiteral -Value $Value[$key]
            "{0} = {1}" -f $key, $child
        }
        return "@{ {0} }" -f ($items -join '; ')
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @()
        foreach ($entry in $Value) {
            $items += ConvertTo-PowerShellLiteral -Value $entry
        }
        return "@({0})" -f ($items -join ', ')
    }

    return ("'" + ($Value.ToString() -replace "'", "''") + "'")
}

function Get-RuntimeAnalyzerTestFileName {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath
    )

    $normalized = $TargetPath.ToLowerInvariant()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($bytes)
    $hex = -join ($hash | ForEach-Object { $_.ToString('x2') })
    return "Runtime_{0}.Tests.ps1" -f $hex.Substring(0, 16)
}

function Get-RuntimeAnalyzerTestFilePath {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [Parameter(Mandatory)]
        [string] $TestsRoot
    )

    $generatedRoot = Join-Path -Path $TestsRoot -ChildPath 'Generated'
    if (-not (Test-Path -Path $generatedRoot)) {
        New-Item -ItemType Directory -Path $generatedRoot -Force | Out-Null
    }

    $fileName = Get-RuntimeAnalyzerTestFileName -TargetPath $TargetPath
    return Join-Path -Path $generatedRoot -ChildPath $fileName
}

function New-RuntimeAnalyzerTestFile {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [pscustomobject[]] $TestDefinitions,

        [Parameter(Mandatory)]
        [string] $TestsRoot,

        [switch] $ForceRebuild
    )

    if (-not $TestDefinitions) {
        $TestDefinitions = @()
    }

    $testFilePath = Get-RuntimeAnalyzerTestFilePath -TargetPath $TargetPath -TestsRoot $TestsRoot
    $testDirectory = Split-Path -Path $testFilePath -Parent
    if (-not (Test-Path -Path $testDirectory)) {
        New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null
    }

    if ($ForceRebuild -and (Test-Path -Path $testFilePath)) {
        Remove-Item -Path $testFilePath -Force
    }

    $builder = New-Object System.Text.StringBuilder
    $null = $builder.AppendLine("param([string]`$TargetPath)")
    $null = $builder.AppendLine('. (Join-Path -Path $PSScriptRoot -ChildPath ''../Helpers/RuntimeAnalyzer.Helpers.ps1'')')

    $targetName = Split-Path -Path $TargetPath -Leaf
    $null = $builder.AppendLine("Describe 'Runtime analyzer for $targetName' {")
    $null = $builder.AppendLine('    BeforeAll {')
    $null = $builder.AppendLine("        if (`$TargetPath -like '*.psm1') {")
    $null = $builder.AppendLine('            Import-Module -Name $TargetPath -Force')
    $null = $builder.AppendLine('        } else {')
    $null = $builder.AppendLine('            . $TargetPath')
    $null = $builder.AppendLine('        }')
    $null = $builder.AppendLine('    }')

    foreach ($definition in $TestDefinitions) {
        $parametersLiteral = ConvertTo-PowerShellLiteral -Value $definition.Input.Parameters
        $pipelineLiteral = ConvertTo-PowerShellLiteral -Value $definition.Input.Pipeline
        $mocksLiteral = ConvertTo-PowerShellLiteral -Value $definition.Input.Mocks
        $customAssertsLiteral = ConvertTo-PowerShellLiteral -Value $definition.Expected.CustomAsserts
        $errorTypeLiteral = $null
        if ($definition.Expected.ErrorType) {
            $errorTypeLiteral = "[{0}]" -f ($definition.Expected.ErrorType.Trim('[', ']'))
        }

        $null = $builder.AppendLine("    It '$($definition.TestId) - $($definition.Description)' {")
        $null = $builder.AppendLine("        `$params = $parametersLiteral")
        $null = $builder.AppendLine("        `$pipelineInput = $pipelineLiteral")
        $null = $builder.AppendLine("        `$mocks = $mocksLiteral")
        $null = $builder.AppendLine('        if ($mocks -and $mocks.Count -gt 0) {')
        $null = $builder.AppendLine('            Invoke-RuntimeAnalyzerMocks -Mocks $mocks')
        $null = $builder.AppendLine('        }')
        $null = $builder.AppendLine("        `$invocation = { Invoke-RuntimeAnalyzerTarget -FunctionName '$($definition.FunctionName)' -Parameters `$params -PipelineInput `$pipelineInput }")
        if ($definition.Expected.ShouldThrow) {
            if ($errorTypeLiteral) {
                $null = $builder.AppendLine("        `$invocation | Should -Throw -ExceptionType $errorTypeLiteral")
            } else {
                $null = $builder.AppendLine('        $invocation | Should -Throw')
            }
        } else {
            $null = $builder.AppendLine('        { $result = & $invocation } | Should -Not -Throw')
            $null = $builder.AppendLine('        if ($result -and $null -ne $result) { $null = $result }')
            $null = $builder.AppendLine('        foreach ($assert in ' + $customAssertsLiteral + ') {')
            $null = $builder.AppendLine('            Invoke-RuntimeAnalyzerCustomAssert -Result $result -Script $assert')
            $null = $builder.AppendLine('        }')
        }
        $null = $builder.AppendLine('    }')
    }

    $null = $builder.AppendLine('}')

    Set-Content -Path $testFilePath -Value $builder.ToString() -Encoding UTF8
    return $testFilePath
}

Export-ModuleMember -Function Get-RuntimeAnalyzerTestFileName, Get-RuntimeAnalyzerTestFilePath, New-RuntimeAnalyzerTestFile
