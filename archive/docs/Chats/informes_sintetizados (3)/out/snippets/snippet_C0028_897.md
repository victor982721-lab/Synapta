```powershell
# 1) CSV + JSONL + Árbol MD desde C:\Users
pwsh -File .\filemap_plus.ps1 `
  -RootPath "C:\Users" `
  -OutCsv ".\filemap_sha256.csv" `
  -OutJsonl ".\filemap_sha256.jsonl" `
  -OutTree ".\FileMap.md"

# 2) Sin hash (más veloz), sólo metadatos
pwsh -File .\filemap_plus.ps1 -RootPath "C:\Users" -NoHash -OutCsv ".\filemap_meta.csv" -OutTree ".\FileMap.txt" -OutputKind txt

# 3) Con dueño y bloque más grande
pwsh -File .\filemap_plus.ps1 -RootPath "C:\Users" -WithOwner -BlockSize 10000 -OutCsv ".\filemap_owner.csv"
```