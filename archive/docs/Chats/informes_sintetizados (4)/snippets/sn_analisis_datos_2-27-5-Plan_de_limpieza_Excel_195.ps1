$BASE = 'C:\'
Import-Csv .\FileList_Users_20250921_020839.csv |
  ForEach-Object { $_ | Add-Member -NotePropertyName path -NotePropertyValue (Join-Path $BASE $_.relpath) -Force; $_ } |
  Export-Csv .\FileList_with_path.csv -NoTypeInformation -Encoding utf8

pwsh -File .\filemap_sha256.ps1 -InputCsv .\FileList_with_path.csv -PathColumn path -Csv .\filemap_sha256.csv
pwsh -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun
# luego sin DryRun:
pwsh -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv