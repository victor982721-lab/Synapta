$CSV = '.\FileList_Users_20250921_020839.csv'
Import-Csv $CSV |
  ForEach-Object { $_ | Add-Member -NotePropertyName path -NotePropertyValue (Join-Path 'C:\Users' $_.relpath) -Force; $_ } |
  Export-Csv .\FileList_with_path.csv -NoTypeInformation -Encoding utf8

pwsh -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 -InputCsv .\FileList_with_path.csv -PathColumn path -Csv .\filemap_sha256.csv
pwsh -ExecutionPolicy Bypass -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun