$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot 'DeDuPe.ps1'
if (-not (Test-Path $scriptPath)) {
  $envPath = $env:DEDUPE_CLI_PATH
  if ($envPath) { $scriptPath = $envPath }
}

Describe 'CLI (DeDuPe.ps1) contrato -NonInteractive' {
  It 'Localiza DeDuPe.ps1' {
    Test-Path $scriptPath | Should -BeTrue
  }

  It 'Declara -NonInteractive y usa -OnTick + -Confirm:$false en Invoke-DeDupePipeline' -Skip:(-not (Test-Path $scriptPath)) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)
    $hasNonInteractive = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'NonInteractive' }, $true)
    $hasNonInteractive | Should -Not -BeNullOrEmpty

    $calls = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-DeDupePipeline' }, $true)
    $calls | Should -Not -BeNullOrEmpty
    foreach($c in $calls){
      $onTick = $c.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'OnTick' }
      $confirmFalse = $c.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'Confirm' -and $_.Extent.Text -match ':\s*\$false' }
      $onTick | Should -Not -BeNullOrEmpty
      $confirmFalse | Should -Not -BeNullOrEmpty
    }
  }
}
