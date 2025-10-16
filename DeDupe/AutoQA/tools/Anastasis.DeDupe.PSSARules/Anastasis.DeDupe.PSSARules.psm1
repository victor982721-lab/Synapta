using namespace System.Management.Automation.Language
Set-StrictMode -Version Latest

function New-Diag {
  param(
    [Parameter(Mandatory)][string]$Message,
    [Parameter(Mandatory)][string]$RuleName,
    [Parameter(Mandatory)][[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]]$Severity,
    [Parameter(Mandatory)][IScriptExtent]$Extent,
    [string]$FileName
  )
  New-Object Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord `
    ($Message, $Extent, $RuleName, $Severity, $FileName, $null, $null)
}

function Measure-RequireStrictModeAndEAPStop {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $strict = $false
  $Ast.Find({ param($n) $n -is [CommandAst] -and $n.GetCommandName() -eq 'Set-StrictMode' }, $true) | ForEach-Object {
    if ($_.CommandElements | Where-Object { $_.ToString() -match 'Latest' }) { $strict = $true }
  }
  if (-not $strict) {
    $diags += New-Diag -Message 'Add `Set-StrictMode -Version Latest` at top level.' -RuleName 'RequireStrictMode' -Severity 'Warning' -Extent $Ast.Extent -FileName $FileName
  }
  $eapSet = $Ast.Find({ param($n)
    $n -is [AssignmentStatementAst] -and
    $n.Left.ToString() -eq '$ErrorActionPreference' -and
    $n.Right.ToString().Trim("' + "'`" + '") -eq ' + " 'Stop' " + '
  }, $true)
  if (-not $eapSet) {
    $diags += New-Diag -Message 'Set `$ErrorActionPreference = ''Stop''` for reliable failures.' -RuleName 'RequireErrorActionStop' -Severity 'Warning' -Extent $Ast.Extent -FileName $FileName
  }
  $diags
}

function Measure-LiteralPathForFileCmdlets {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $cmdlets = 'Get-Content','Set-Content','Add-Content','Test-Path','Remove-Item','Copy-Item','Move-Item'
  $Ast.Find({ param($n) $n -is [CommandAst] -and $cmdlets -contains $n.GetCommandName() }, $true) | ForEach-Object {
    $hasLiteral = $_.CommandElements | Where-Object { $_ -is [CommandParameterAst] -and $_.ParameterName -eq 'LiteralPath' }
    $hasPath    = $_.CommandElements | Where-Object { $_ -is [CommandParameterAst] -and $_.ParameterName -eq 'Path' }
    if (-not $hasLiteral -and $hasPath) {
      $diags += New-Diag -Message "Use -LiteralPath instead of -Path for '$($_.GetCommandName())'." -RuleName 'PreferLiteralPath' -Severity 'Information' -Extent $_.Extent -FileName $FileName
    }
  }
  $diags
}

function Measure-UseFileShareReadWriteForTailers {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $Ast.Find({ param($n) $n -is [InvokeMemberExpressionAst] }, $true) | ForEach-Object {
    $inv = $_
    $targetType = $inv.Expression -as [TypeExpressionAst]
    if ($null -ne $targetType -and ($targetType.TypeName.FullName -in @('IO.File','System.IO.File')) -and $inv.Member.Value -eq 'Open') {
      $args = @(); if ($inv.Arguments) { $args = $inv.Arguments }
      if ($args.Count -lt 4) {
        $diags += New-Diag -Message 'Tailers should open files with FileShare.ReadWrite (4th arg).' -RuleName 'FileOpenShareReadWrite' -Severity 'Warning' -Extent $inv.Extent -FileName $FileName
      } else {
        $share = $args[3].Extent.Text
        if ($share -notmatch 'ReadWrite') {
          $diags += New-Diag -Message 'Use FileShare.ReadWrite for concurrent reading while another process writes.' -RuleName 'FileOpenShareReadWrite' -Severity 'Warning' -Extent $inv.Extent -FileName $FileName
        }
      }
    }
  }
  $diags
}

function Measure-InvokeDeDupePipelineContracts {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $Ast.Find({ param($n) $n -is [CommandAst] -and $n.GetCommandName() -eq 'Invoke-DeDupePipeline' }, $true) | ForEach-Object {
    $hasOnTick = $_.CommandElements | Where-Object { $_ -is [CommandParameterAst] -and $_.ParameterName -eq 'OnTick' }
    $hasConfirmFalse = ($_.CommandElements | Where-Object {
      $_ -is [CommandParameterAst] -and $_.ParameterName -eq 'Confirm'
    } | Where-Object { $_.Argument.Extent.Text -match ':\s*\$false$' })
    if (-not $hasOnTick) {
      $diags += New-Diag -Message 'Pass -OnTick to stream progress snapshots to `.progress`.' -RuleName 'DeDupePipelineRequiresOnTick' -Severity 'Error' -Extent $_.Extent -FileName $FileName
    }
    if (-not $hasConfirmFalse) {
      $diags += New-Diag -Message 'Explicitly set -Confirm:$false to avoid unintended prompts.' -RuleName 'DeDupePipelineConfirmFalse' -Severity 'Warning' -Extent $_.Extent -FileName $FileName
    }
  }
  $diags
}

function Measure-AvoidWriteHost {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $Ast.Find({ param($n) $n -is [CommandAst] -and $n.GetCommandName() -eq 'Write-Host' }, $true) | ForEach-Object {
    $diags += New-Diag -Message 'Avoid Write-Host in scripts; prefer Write-Information/Verbose.' -RuleName 'AvoidWriteHost' -Severity 'Information' -Extent $_.Extent -FileName $FileName
  }
  $diags
}

function Measure-RepoHasThreadJobInGUI {
  [CmdletBinding()] param([Parameter(Mandatory)][ScriptBlockAst]$Ast,[string]$FileName)
  $diags = @()
  $usesWpf = $Ast.Extent.Text -match 'PresentationFramework|System\.Windows'
  $hasThreadJob = $Ast.Find({ param($n) $n -is [CommandAst] -and $n.GetCommandName() -eq 'Start-ThreadJob' }, $true)
  if ($usesWpf -and -not $hasThreadJob) {
    $diags += New-Diag -Message 'WPF GUI should offload backend to Start-ThreadJob/CLI external to avoid UI freeze.' -RuleName 'GUIShouldUseThreadJob' -Severity 'Warning' -Extent $Ast.Extent -FileName $FileName
  }
  $diags
}

Export-ModuleMember -Function *
