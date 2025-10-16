@{
  RootModule        = 'DeDupe.Quarantine.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'e4f9c3b2-7a6d-4a3b-8c9d-1a0b2c3d4e5f'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Cuarentena de archivos con mismo tamaño y distinto hash: mantiene 1 por tamaño y mueve el resto (Flat/BySize).'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('Move-ToQuarantine')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
  RequiredModules   = @('DeDupe.Logging')
}
