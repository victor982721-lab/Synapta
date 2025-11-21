. "$PSScriptRoot/Cortex.Common.ps1"

function Invoke-CortexAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Paths,
        [switch]$QualityGate
    )

    Assert-CortexWindowsPlatform

    $results = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path -Path $path)) {
            throw "No se encontró la ruta: $path"
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $parseErrors = @()
        Get-ChildItem -Path $path -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            if ($errors) { $parseErrors += $errors }
        }

        $pssaSummary = $null
        if (Test-CortexCommand -Name 'Invoke-ScriptAnalyzer') {
            $pssa = Invoke-ScriptAnalyzer -Path $path -Recurse -ErrorAction SilentlyContinue
            $pssaSummary = [pscustomobject]@{
                Errors   = ($pssa | Where-Object { $_.Severity -eq 'Error' }).Count
                Warnings = ($pssa | Where-Object { $_.Severity -eq 'Warning' }).Count
            }
        }

        $dotnetOutput = $null
        if (Test-CortexCommand -Name 'dotnet') {
            $proj = Get-ChildItem -Path $path -Include *.csproj,*.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($proj) {
                Invoke-CortexCommand -FilePath 'dotnet' -Arguments @('build', $proj.FullName, '-c', 'Release')
                $dotnetOutput = $proj.FullName
            }
        }

        $sw.Stop()
        $status = 'Success'
        $errorsText = ''

        if ($parseErrors.Count -gt 0) {
            $status = 'Failed'
            $errorsText = 'Errores de Parser AST detectados'
        }
        if ($QualityGate -and $pssaSummary -and $pssaSummary.Errors -gt 0) {
            $status = 'Failed'
            $errorsText = 'QualityGate falló por PSSA'
        }

        $details = if ($dotnetOutput) { $dotnetOutput } else { 'Parser/PSSA ejecutado' }

        $results += New-CortexLogEntry -RunId "analysis-$([Guid]::NewGuid().ToString('N'))" -Repo $path -Operation 'Analyze' -Status $status -DurationMs $sw.ElapsedMilliseconds -Details $details -Errors $errorsText -LogPath (Join-Path $path 'logs')
    }

    return $results
}
