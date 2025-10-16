@{
  RootModule        = 'DeDupe.DedupeByHash.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '9a8b7c6d-5e4f-4a3b-9c2d-1e0f9a8b7c6d'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Elimina duplicados exactos por hash, con opción de verificación byte-a-byte y logging JSONL.'
  PowerShellVersion = '7.5'
  FunctionsToExport = @('Remove-DuplicatesByHash')
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
  RequiredModules   = @('DeDupe.Logging')  # opcional, pero así Write-Jsonl ya está
}
