$CSV = '.\FileList_Users_20250921_020839.csv'
Import-Csv $CSV |
  Select-Object *, @{n='path';e={ Join-Path 'C:\Users' $_.relpath }} |
  Export-Csv .\FileList_with_path.csv -NoTypeInformation -Encoding utf8