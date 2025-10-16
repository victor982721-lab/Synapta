@{
  RootModule        = 'DeDupe.Grouping.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '0c2a6e87-53a4-4c9b-8f0e-9c0d0a1c3e77'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Agrupa registros de hash por tamaño y hash, listo para deduplicación.'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('Group-BySizeHash')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
}
