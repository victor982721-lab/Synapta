$BASE = 'C:\'
Import-Csv .\FileList_Users_20250921_020839.csv |
  ForEach-Object { $_ | Add-Member -NotePropertyName path -NotePropertyValue (Join-Path $BASE $_.relpath) -Force; $_ } |
  Export-Csv .\FileList_with_path.csv -NoTypeInformation -Encoding utf8