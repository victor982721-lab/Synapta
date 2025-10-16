@{
  RootModule        = 'DeDupe.Logging.psm1'
  ModuleVersion     = '1.0.1'
  GUID              = '7f9b0caa-9a64-4a34-9a7e-3d0f4f7a2b12'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Adaptador JSONL que delega en DeDupe.Metrics.Ultra (Write-Jsonl compatible con -Logger/-Data).'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('New-JsonlLogger','Write-Jsonl','Close-JsonlLogger')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
  RequiredModules   = @('DeDupe.Metrics.Ultra')
}
