@{
  RootModule        = 'DeDupe.Pipeline.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'b1d2c3e4-f567-48ab-9abc-0de1f2345678'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Pipeline completo: Enumeración → Hashing con progreso → Dedupe → Cuarentena → Resumen, con métricas en tiempo real y JSONL.'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('Resolve-LogPathSafe','Get-DeDupeFiles','Format-ProgressLine','Invoke-DeDupePipeline')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
  RequiredModules   = @('DeDuPe.Metrics.Ultra','DeDuPe.Logging','DeDuPe.Grouping','DeDuPe.DedupeByHash','DeDuPe.Quarantine')
}
