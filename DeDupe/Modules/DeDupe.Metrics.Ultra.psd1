@{
  RootModule        = 'DeDupe.Metrics.Ultra.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'f9b3a6c1-4c3e-4a6a-9b7e-2a1f5d7c9e11'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Métricas de alto rendimiento (ETA/MB/s), canal paralelo con backpressure, JSONL writer y autotune I/O.'
  PowerShellVersion = '7.5'
  FunctionsToExport = @(
    'Initialize-HiResMetrics','Update-HiResMetrics','Get-HiResSnapshot','Start-ProgressTicker','Stop-ProgressTicker',
    'Optimize-ThreadPool','Use-BackgroundMode','New-BoundedChannel','Invoke-ParallelChannel','Complete-Channel',
    'New-JsonlWriter','Write-Jsonl','Close-JsonlWriter','Get-AvgDiskQueueLength','Get-RecommendedDOP','Copy-ItemWithETA'
  )
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
}
