@{
  RootModule        = 'DeDupe.Cache.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = '2f5b7c3e-8a42-4d7b-bf7c-4e1a9d2c7b33'
  Author            = 'Víctor Vera'
  CompanyName       = 'Anastasis Revenari'
  Description       = 'Índice incremental de hashes: SQLite si está disponible; fallback JSONL/DICT. Evita re-hash por (size,mtime).'
  PowerShellVersion = '7.5'
  FunctionsToExport = @(
    'New-FileIndex','Get-CacheInfo','Get-CachedEntry','Set-CachedEntry','Touch-CachedSeen','Compact-FileIndex'
  )
  CmdletsToExport   = @()
  VariablesToExport = @()
  AliasesToExport   = @()
}
