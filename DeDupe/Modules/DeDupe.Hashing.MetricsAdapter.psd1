@{
  RootModule        = 'DeDupe.Hashing.MetricsAdapter.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'd1a2b3c4-5678-49ab-9cde-112233445566'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Adapter para hashing con progreso por bloque (ETA/MB/s/%) integrando DeDupe.Metrics.Ultra.'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('Get-FileHashStreamingWithMetrics','Get-HashRecordsParallelWithMetrics')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
}
