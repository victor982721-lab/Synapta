@{
  Severity        = @('Error','Warning','Information')
  ExcludeRules    = @('PSUseDeclaredVarsMoreThanAssignments')
  IncludeRules    = @(
    'PSUseConsistentIndentation',
    'PSUseConsistentWhitespace',
    'PSAlignAssignmentStatement',
    'PSUseCorrectCasing',
    'PSAvoidUsingCmdletAliases',
    'PSAvoidUsingWriteHost',
    'PSUseApprovedVerbs',
    'PSUseBOMForUnicodeEncodedFile',
    'PSAvoidGlobalVars',
    'PSAvoidUsingPositionalParameters',
    'PSUseShouldProcessForStateChangingFunctions'
  )
  Rules           = @{
    PSUseConsistentIndentation = @{ Enable=$true; Kind='space'; IndentationSize=2; PipelineIndentation='IncreaseIndentationForFirstPipeline' }
    PSPlaceOpenBrace           = @{ Enable=$true; OnSameLine=$true; NewLineAfter=$true; IgnoreOneLineBlock=$true }
    PSAvoidUsingPositionalParameters = @{ Enable=$true }
  }
  CustomRulePath  = @('.\tools\Anastasis.DeDupe.PSSARules')
}
