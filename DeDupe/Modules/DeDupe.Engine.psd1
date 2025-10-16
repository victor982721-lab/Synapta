@{
  RootModule        = 'DeDupe.Engine.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '884b3a0a-7d2b-4a12-9f9b-3b8e0d4c1a77'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Hot-path en C# para hashing SHA-256, comparación de streams con progreso e identificación física (FileId/Hardlinks).'
  PowerShellVersion = '7.5'
  FunctionsToExport = @(
    'Invoke-EngineHash','Test-EngineStreamsEqual','Get-EngineMiniHash',
    'Get-EngineFileId','Test-EngineSameFile','New-EngineHardLink'
  )
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
}
