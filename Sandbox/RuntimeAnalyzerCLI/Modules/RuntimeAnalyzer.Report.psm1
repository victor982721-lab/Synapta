function Test-PesterAvailability {
    $module = Get-Module -ListAvailable -Name Pester -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module -or $module.Version.Major -lt 5) {
        throw 'Pester v5 or greater is required but not installed.'
    }
}

function Invoke-RuntimeAnalyzerPester {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [Parameter(Mandatory)]
        [string] $TestFilePath
    )

    Test-PesterAvailability
    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Path = @($TestFilePath)
    $configuration.Output.Verbosity = 'Detailed'
    $configuration.Run.PassThru = $true
    return Invoke-Pester -Configuration $configuration
}

function Convert-RuntimeAnalyzerResult {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [Parameter(Mandatory)]
        $PesterResult
    )

    $details = @()
    if ($PesterResult.Tests) {
        foreach ($test in $PesterResult.Tests) {
            $message = $null
            if ($test.ErrorRecord -and $test.ErrorRecord.Exception) {
                $message = $test.ErrorRecord.Exception.Message
            } elseif ($test.FailureMessage) {
                $message = $test.FailureMessage
            }

            $details += [pscustomobject]@{
                Name     = $test.Name
                Passed   = [bool]$test.Passed
                Error    = $message
                Duration = $test.Duration
            }
        }
    }

    $failed = ($details | Where-Object { -not $_.Passed }).Count
    $passed = ($details | Where-Object { $_.Passed }).Count

    return [pscustomobject]@{
        TargetPath = $TargetPath
        Total      = $details.Count
        Failed     = $failed
        Passed     = $passed
        Details    = $details
    }
}

function Format-RuntimeAnalyzerOutput {
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $Report,

        [Parameter(Mandatory)]
        [ValidateSet('json', 'ndjson', 'text')]
        [string] $OutputFormat
    )

    switch ($OutputFormat) {
        'json' { return $Report | ConvertTo-Json -Depth 5 }
        'ndjson' {
            $lines = @()
            $lines += ($Report | ConvertTo-Json -Depth 5)
            foreach ($detail in $Report.Details) {
                $lines += ($detail | ConvertTo-Json -Depth 5)
            }
            return $lines -join [Environment]::NewLine
        }
        'text' {
            $builder = New-Object System.Text.StringBuilder
            $null = $builder.AppendLine("Target: $($Report.TargetPath)")
            $null = $builder.AppendLine("Total: $($Report.Total)")
            $null = $builder.AppendLine("Passed: $($Report.Passed)")
            $null = $builder.AppendLine("Failed: $($Report.Failed)")
            foreach ($detail in $Report.Details) {
                $status = if ($detail.Passed) { '✔' } else { '✖' }
                $null = $builder.AppendLine(" - $status $($detail.Name) :: $($detail.Error)")
            }
            return $builder.ToString()
        }
    }
}

function Get-RuntimeAnalyzerExitCode {
    param(
        [pscustomobject] $Report,
        $PesterResult,
        [ValidateSet('None', 'Failed', 'Error')]
        [string] $FailOn
    )

    if ($FailOn -eq 'None') {
        return 0
    }

    $hasFailed = $Report.Failed -gt 0
    $hasErrors = $false
    if ($PesterResult -and ($PesterResult.PSObject.Properties.Name -contains 'Failed')) {
        $failedCollection = $PesterResult.Failed
        if ($failedCollection) {
            $errorWithRecord = $failedCollection | Where-Object { $_.ErrorRecord }
            if ($errorWithRecord -and $errorWithRecord.Count -gt 0) {
                $hasErrors = $true
            }
        }
    }

    if ($FailOn -eq 'Failed') {
        if ($hasFailed) { return 1 }
        return 0
    }

    if ($hasErrors) {
        return 2
    }

    if ($hasFailed) {
        return 1
    }

    return 0
}

function Invoke-RuntimeAnalyzerReport {
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [Parameter(Mandatory)]
        [string] $TestFilePath,

        [ValidateSet('json', 'ndjson', 'text')]
        [string] $OutputFormat = 'json',

        [string] $OutFile,

        [ValidateSet('None', 'Failed', 'Error')]
        [string] $FailOn = 'Error'
    )

    $pesterResult = Invoke-RuntimeAnalyzerPester -TargetPath $TargetPath -TestFilePath $TestFilePath
    $report = Convert-RuntimeAnalyzerResult -TargetPath $TargetPath -PesterResult $pesterResult
    $output = Format-RuntimeAnalyzerOutput -Report $report -OutputFormat $OutputFormat

    if ($OutFile) {
        $directory = Split-Path -Path $OutFile -Parent
        if ($directory -and -not (Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        Set-Content -Path $OutFile -Value $output -Encoding UTF8
    } else {
        Write-Output $output
    }

    $exitCode = Get-RuntimeAnalyzerExitCode -Report $report -PesterResult $pesterResult -FailOn $FailOn
    return [pscustomobject]@{
        Report   = $report
        ExitCode = $exitCode
    }
}

Export-ModuleMember -Function Invoke-RuntimeAnalyzerReport, Invoke-RuntimeAnalyzerPester, Convert-RuntimeAnalyzerResult
