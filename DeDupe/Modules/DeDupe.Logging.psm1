using namespace System.IO
Set-StrictMode -Version Latest

$script:Loggers = @{}

function New-JsonlLogger {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$RotateAtMB = 768
  )
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) { [Directory]::CreateDirectory($dir) | Out-Null }
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType File -Path $Path -Force | Out-Null }
  $obj = [pscustomobject]@{ Path = (Resolve-Path -LiteralPath $Path).Path; RotateAtBytes = [int64]$RotateAtMB * 1MB }
  $script:Loggers[$obj.Path] = $obj
  return $obj
}

function ConvertTo-PlainObject {
  param([Parameter(Mandatory)][AllowNull()]$Input,[int]$Depth=3)
  if ($null -eq $Input) { return $null }
  if ($Depth -le 0) { return ($Input.ToString()) }
  if ($Input -is [string] -or $Input -is [int] -or $Input -is [long] -or $Input -is [double] -or $Input -is [bool]) { return $Input }
  if ($Input -is [datetime]) { return $Input.ToUniversalTime().ToString('o') }
  if ($Input -is [System.IO.FileInfo]) { return $Input.FullName }
  if ($Input -is [System.Array]) { return @($Input | ForEach-Object { ConvertTo-PlainObject -Input $_ -Depth ($Depth-1) }) }
  if ($Input -is [System.Collections.IDictionary]) {
    $h = @{}
    foreach ($k in $Input.Keys) { $h[[string]$k] = ConvertTo-PlainObject -Input $Input[$k] -Depth ($Depth-1) }
    return $h
  }
  if ($Input -is [System.Collections.IEnumerable] -and -not ($Input -is [string])) {
    $arr = @(); foreach ($it in $Input) { $arr += ,(ConvertTo-PlainObject -Input $it -Depth ($Depth-1)) }; return $arr
  }
  try {
    $props = @{}
    $Input | Get-Member -MemberType NoteProperty,Property | ForEach-Object { $n=$_.Name; $props[$n] = ConvertTo-PlainObject -Input ($Input.$n) -Depth ($Depth-1) }
    if ($props.Count -gt 0) { return $props }
  } catch {}
  return ($Input.ToString())
}

function Write-Jsonl {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Logger,
    [Parameter(Mandatory)][object]$Data
  )
  $path = if ($Logger -is [string]) { $Logger } else { $Logger.Path }
  if (-not $path) { throw 'Logger inválido' }
  try {
    $san = ConvertTo-PlainObject -Input $Data -Depth 5
    $json = $san | ConvertTo-Json -Compress -Depth 8
  } catch {
    $json = '{"_serialize_error":"true"}'
  }
  Add-Content -LiteralPath $path -Value $json -Encoding UTF8
  try {
    $fi = [FileInfo]::new($path)
    $rot = if ($Logger.RotateAtBytes) { [int64]$Logger.RotateAtBytes } else { 0 }
    if ($rot -gt 0 -and $fi.Length -gt $rot) {
      $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
      $bak = "$path.$ts"
      Move-Item -LiteralPath $path -Destination $bak -Force
      New-Item -ItemType File -Path $path -Force | Out-Null
    }
  } catch {}
}

function Close-JsonlLogger {
  [CmdletBinding()]
  param([Parameter(Mandatory)]$Logger)
  $path = if ($Logger -is [string]) { $Logger } else { $Logger.Path }
  if ($path -and $script:Loggers.ContainsKey($path)) { $null = $script:Loggers.Remove($path) }
}

Export-ModuleMember -Function New-JsonlLogger, Write-Jsonl, Close-JsonlLogger
