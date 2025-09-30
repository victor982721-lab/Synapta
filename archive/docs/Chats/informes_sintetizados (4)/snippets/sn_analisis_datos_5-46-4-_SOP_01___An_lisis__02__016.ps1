param([string]$Dir="/mnt/data")
$Manifest = Join-Path $Dir "manifest.json"
$Artifacts = (Get-Content $Manifest -Raw | ConvertFrom-Json).artifacts
$ErrorActionPreference='Stop'
foreach($a in $Artifacts){
  $calc = (Get-FileHash -Algorithm SHA256 -Path $a.path).Hash.ToLower()
  if($calc -ne $a.sha256.ToLower()){ throw "Mismatch: $($a.path)" }
}
"OK"