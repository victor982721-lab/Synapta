@{
  RootModule        = 'Anastasis.DeDupe.PSSARules.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'c9b0c9b4-7f69-4b78-9f6b-5f8b0b6b8e02'
  Author            = 'Víctor via ChatGPT'
  CompanyName       = 'Anastasis Revenari'
  PowerShellVersion = '7.0'
  FunctionsToExport = @(
    'Measure-RequireStrictModeAndEAPStop',
    'Measure-LiteralPathForFileCmdlets',
    'Measure-UseFileShareReadWriteForTailers',
    'Measure-InvokeDeDupePipelineContracts',
    'Measure-AvoidWriteHost',
    'Measure-RepoHasThreadJobInGUI'
  )
  PrivateData       = @{
    PSData = @{
      Tags        = @('PSScriptAnalyzer','Rules','DeDupe')
      ProjectUri  = 'https://example.invalid/dedupe'
      ReleaseNotes= 'Initial custom ruleset for DeDupe'
    }
  }
}
