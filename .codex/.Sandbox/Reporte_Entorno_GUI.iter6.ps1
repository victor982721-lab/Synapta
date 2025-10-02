# Ws-Studio :: PowerShell Environment Report + GUI (WPF)
# Iteración 6:
# - Añadido: Snapshot extendido (procesos, servicios, tareas, red, firewall, programas, eventos, historial PS, perfil, SecretManagement, admins locales, certificados, autoruns, hashes de binarios).
# - Añadido: Exportación a Markdown (.md) además de .txt y .json.
# - TXT: se mantiene legible; detalles extendidos opcionales. JSON siempre incluye todo. MD con resumen claro y bloques de datos.
# - TEST acumulativo con auto-APPLY si no hay errores. Respaldo .bak verificado por tamaño.
# - Ruta por defecto (GUI y -NoGui): C:\Users\VictorFabianVeraVill\.mnt\Scripts\System_Snapshots\PowerShell+\GUI\

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param([switch]$NoGui)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Timestamp { Get-Date -Format 'yyMMddHHmm' }
function Out-Utf8NoBom { param([string]$Path,[string]$Content) $enc = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($Path, $Content, $enc) }
function Section { param([string]$Title) $line=('='*80); return "`r`n$line`r`n== $Title`r`n$line`r`n" }
function MdH2 { param([string]$Title) return "`r`n## $Title`r`n" }
function Fmt-MdTable { param($rows,[string[]]$Columns)
  if(-not $rows){ return "`r`n_(sin datos)_" }
  $cols = if($Columns){ $Columns } else { ($rows | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) }
  $header = '|' + ($cols -join '|') + '|'
  $sep    = '|' + (($cols | ForEach-Object { '---' }) -join '|') + '|'
  $lines  = foreach($r in $rows){ '|' + ($cols | ForEach-Object { ($r.$_ -as [string]) -replace '\r?\n',' ' }) -join '|' + '|' }
  return "`r`n$header`r`n$sep`r`n" + ($lines -join "`r`n") + "`r`n"
}
function Safe-Backup { param([Parameter(Mandatory=$true)][string]$Path)
  if(Test-Path -LiteralPath $Path){
    $stamp=New-Timestamp
    $bak=('{0}.{1}.bak' -f $Path,$stamp)
    Copy-Item -LiteralPath $Path -Destination $bak -Force
    $src=Get-Item -LiteralPath $Path; $dst=Get-Item -LiteralPath $bak
    if($src.Length -ne $dst.Length){ throw "Backup verification failed: $($src.Name) vs $($dst.Name) size mismatch." }
    return $bak
  }
  return $null
}

function Get-EnvReport {
  $meta = [ordered]@{
    Timestamp=(Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')
    ComputerName=$env:COMPUTERNAME
    User="$env:USERDOMAIN\$env:USERNAME"
    OS=(Get-CimInstance Win32_OperatingSystem | Select-Object -First 1 Caption,Version,BuildNumber)
    PSVersion=$PSVersionTable.PSVersion.ToString()
    PSEdition=$PSVersionTable.PSEdition
    PSHome=$PSHOME
    ProfilePaths=@{
      CurrentUserAllHosts=$PROFILE.CurrentUserAllHosts
      CurrentUserCurrent=$PROFILE
      AllUsersAllHosts=$PROFILE.AllUsersAllHosts
      AllUsersCurrent=$PROFILE.AllUsersCurrentHost
    }
    ExecutionPolicy=(Get-ExecutionPolicy -List | ForEach-Object { [pscustomobject]@{ Scope=[string]$_.Scope; ExecutionPolicy=([string]$_.ExecutionPolicy) } })
    PSModulePath=($env:PSModulePath -split ';' | Where-Object { $_ } | Sort-Object)
    PSRepositories=@(Get-PSRepository -ErrorAction Ignore | Select-Object Name,SourceLocation,InstallationPolicy)
  }

  $wsmanSummary=@{ TestWSManOK=$false; Auth=$null; Listeners=$null }
  try{ $null=Test-WSMan -ComputerName localhost -ErrorAction Stop; $wsmanSummary.TestWSManOK=$true }catch{ $wsmanSummary.TestWSManOK=$false }
  try{
    $wsAuth=Get-ChildItem WSMan:\localhost\Service\Auth -ErrorAction Ignore | Select-Object Name,Value
    $wsListeners=Get-ChildItem WSMan:\localhost\Listener -ErrorAction Ignore | ForEach-Object {
      $t=$null;$a=$null; foreach($key in $_.Keys){ if($key -match '^Transport=(.+)$'){ $t=$Matches[1] } elseif($key -match '^Address=(.+)$'){ $a=$Matches[1] } }
      $port=$null;$enabled=$null
      try{
        $children=Get-ChildItem -LiteralPath $_.PSPath -ErrorAction Stop
        foreach($c in $children){ if($c.Name -eq 'Port'){ $port=$c.Value } elseif($c.Name -eq 'Enabled'){ $enabled=$c.Value } }
      }catch{}
      [pscustomobject]@{ Transport=$t; Address=$a; Port=$port; Enabled=$enabled }
    }
    $wsmanSummary.Auth=$wsAuth; $wsmanSummary.Listeners=$wsListeners
  }catch{}

  function Get-ToolInfo { param([string]$Name,[string[]]$ArgsVersion=@('--version'))
    $cmd=Get-Command $Name -ErrorAction Ignore
    if(-not $cmd){ return $null }
    $verOut=$null; try{ $verOut=& $cmd.Source $ArgsVersion 2>&1 | Select-Object -First 1 }catch{ $verOut=$null }
    if($Name -eq 'python3'){ if(($cmd.Source -match 'WindowsApps') -or ([string]$verOut -match 'Python was not found')){ return $null } }
    $verText=[string]$verOut
    if($Name -eq 'dotnet' -and ([string]::IsNullOrWhiteSpace($verText) -or $verText -match 'could not be loaded' -or $verText -match 'is not recognized')){
      try{ $info=& $cmd.Source --info 2>&1; $line=$info | Where-Object { $_ -match 'Version\s*:\s*([^\s]+)' } | Select-Object -First 1; if($line){ $verText=($line -replace '.*Version\s*:\s*','').Trim() } }catch{}
      if([string]::IsNullOrWhiteSpace($verText)){ try{ $fvi=[System.Diagnostics.FileVersionInfo]::GetVersionInfo($cmd.Source); $verText=$fvi.FileVersion }catch{} }
    }
    [pscustomobject]@{ Name=$Name; Path=$cmd.Source; Version=$verText }
  }

  $toolNames=@(
    @{N='git';A=@('--version')},
    @{N='pwsh';A=@('--version')},
    @{N='powershell';A=@('-NoLogo','-NoProfile','-NonInteractive','-Command','$PSVersionTable.PSVersion.ToString()')},
    @{N='python';A=@('--version')},
    @{N='python3';A=@('--version')},
    @{N='node';A=@('--version')},
    @{N='npm';A=@('--version')},
    @{N='java';A=@('-version')},
    @{N='javac';A=@('-version')},
    @{N='dotnet';A=@('--version')},
    @{N='winget';A=@('--version')},
    @{N='choco';A=@('--version')},
    @{N='az';A=@('--version')},
    @{N='aws';A=@('--version')},
    @{N='kubectl';A=@('version','--client','--short')},
    @{N='terraform';A=@('version')},
    @{N='pipx';A=@('--version')},
    @{N='cargo';A=@('--version')},
    @{N='gh';A=@('--version')}
  )
  $toolchain=foreach($t in $toolNames){ $ti=Get-ToolInfo -Name $t.N -ArgsVersion $t.A; if($ti){ $ti } }

  $modulesAll=@(Get-Module -ListAvailable | Select-Object Name,Version,ModuleBase | Sort-Object Name,Version -Descending)
  $installedModules=@(); if(Get-Command Get-InstalledModule -ErrorAction Ignore){ $installedModules=@(Get-InstalledModule | Select-Object Name,Version,Repository | Sort-Object Name) }
  $packages=@(Get-Package | Select-Object Name,Version,ProviderName | Sort-Object Name)
  $hotfix=@(Get-HotFix | Sort-Object InstalledOn | Select-Object HotFixID,Description,InstalledOn)

  $envFocus='JAVA_HOME','TESSDATA_PREFIX','OneDrive','OMP_THEME_NAME','POSH_SHELL','POSH_SHELL_VERSION'
  $envSlice=foreach($k in $envFocus){ [pscustomobject]@{ Name=$k; Value=(Get-Item env:$k -ErrorAction Ignore).Value } }

  function Get-ProfileInfo { param([string]$Path)
    $exists=Test-Path -LiteralPath $Path
    $obj=[ordered]@{ Path=$Path; Exists=$exists; Length=$null; LastWriteTime=$null; SHA256=$null }
    if($exists){ $fi=Get-Item -LiteralPath $Path; $obj.Length=$fi.Length; $obj.LastWriteTime=$fi.LastWriteTime; try{ $h=Get-FileHash -Algorithm SHA256 -LiteralPath $Path; $obj.SHA256=$h.Hash }catch{ $obj.SHA256=$null } }
    [pscustomobject]$obj
  }
  $profilesInfo=@(
    Get-ProfileInfo -Path $meta.ProfilePaths.CurrentUserAllHosts
    Get-ProfileInfo -Path $meta.ProfilePaths.CurrentUserCurrent
    Get-ProfileInfo -Path $meta.ProfilePaths.AllUsersAllHosts
    Get-ProfileInfo -Path $meta.ProfilePaths.AllUsersCurrent
  )

  $pathParts=($env:Path -split ';' | Where-Object { $_ -and $_.Trim() })
  $seen=@{};$dups=@(); foreach($p in $pathParts){ $k=$p.ToLowerInvariant(); if($seen.ContainsKey($k)){ $dups+=$p } else { $seen[$k]=$true } }
  $missing=$pathParts | Where-Object { -not (Test-Path -LiteralPath $_) }

  $base=[ordered]@{
    Meta=$meta
    WSMan=$wsmanSummary
    Toolchain= $toolchain | ForEach-Object { [pscustomobject]@{ Name=$_.Name; Path=$_.Path; Version=[string]$_.Version } }
    EnvFocus=$envSlice
    ModulesAll=$modulesAll
    InstalledModules=$installedModules
    Packages=$packages
    Hotfixes=$hotfix
    ProfilesInfo=$profilesInfo
    PathAnalysis=@{ Existing=@($pathParts | Where-Object { Test-Path -LiteralPath $_ }); Missing=@($missing); Duplicates=@($dups | Select-Object -Unique) }
  }
  return $base
}

function Get-ExtendedSnapshot {
  $ext = [ordered]@{}
  # Procesos con firma
  try{
    $ext.Processes = Get-Process | Select-Object Id, ProcessName, Path -ErrorAction SilentlyContinue | ForEach-Object {
      $p=$_; $sig=$null; if($p.Path){ try{ $sig=Get-AuthenticodeSignature -FilePath $p.Path -ErrorAction SilentlyContinue }catch{} }
      [pscustomobject]@{ Id=$p.Id; Name=$p.ProcessName; Path=$p.Path; SignatureStatus=($sig.Status) }
    }
  }catch{ $ext.Processes = "Error: $($_.Exception.Message)" }

  # Servicios + cuenta
  try{
    $ext.Services = Get-WmiObject -Class Win32_Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, State, StartMode, StartName
  }catch{ $ext.Services = "Error: $($_.Exception.Message)" }

  # Tareas programadas
  try{ $ext.ScheduledTasks = Get-ScheduledTask | Select-Object TaskName, TaskPath, State, @{n='UserId';e={$_.Principal.UserId}} }catch{ $ext.ScheduledTasks = "Error: $($_.Exception.Message)" }

  # Red
  try{ $ext.NetListening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess, State }catch{}
  try{ $ext.NetActive    = Get-NetTCPConnection -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess }catch{}

  # Firewall
  try{ $ext.FirewallProfiles = Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction }catch{}
  try{ $ext.FirewallRules    = Get-NetFirewallRule   | Select-Object DisplayName, Direction, Action, Enabled, Profile }catch{}

  # Programas instalados (registry)
  $ext.InstalledPrograms = @()
  foreach($p in @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )){
    try{
      Get-ItemProperty $p -ErrorAction SilentlyContinue | ForEach-Object {
        $ext.InstalledPrograms += [pscustomobject]@{
          DisplayName=$_.DisplayName; DisplayVersion=$_.DisplayVersion; Publisher=$_.Publisher; InstallDate=$_.InstallDate; InstallLocation=$_.InstallLocation
        }
      }
    }catch{}
  }

  # Eventos recientes
  try{
    $ext.Events = @{
      System      = (Get-WinEvent -LogName System -MaxEvents 150 -ErrorAction SilentlyContinue | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message)
      Application = (Get-WinEvent -LogName Application -MaxEvents 150 -ErrorAction SilentlyContinue | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message)
    }
  }catch{ $ext.Events = "Error: $($_.Exception.Message)" }

  # Historial de PowerShell (PSReadLine)
  try{
    $psrl = (Get-PSReadlineOption).HistorySavePath
    if($psrl -and (Test-Path $psrl)){ $ext.PowerShellHistory = [ordered]@{ Path=$psrl; Last500=(Get-Content $psrl -ErrorAction SilentlyContinue | Select-Object -Last 500) } }
    else{ $ext.PowerShellHistory = "No PSReadLine history available." }
  }catch{ $ext.PowerShellHistory = "Error: $($_.Exception.Message)" }

  # Contenido de perfil actual (si existe)
  try{
    $cur = $PROFILE
    if(Test-Path $cur){
      $ext.ProfileContent = [ordered]@{
        Path=$cur; Length=(Get-Item $cur).Length; LastWriteTime=(Get-Item $cur).LastWriteTime
        SHA256=(Get-FileHash -Path $cur -Algorithm SHA256).Hash
        Content=(Get-Content $cur -ErrorAction SilentlyContinue)
      }
    } else {
      $ext.ProfileContent = "Profile not present at $cur"
    }
  }catch{ $ext.ProfileContent = "Error: $($_.Exception.Message)" }

  # SecretManagement / SecretStore
  try{ $ext.SecretVaults = (Get-SecretVault -ErrorAction SilentlyContinue) }catch{ $ext.SecretVaults = "Error: $($_.Exception.Message)" }

  # Admins locales
  try{ $ext.LocalAdmins = Get-LocalGroupMember -Group Administrators -ErrorAction SilentlyContinue | Select-Object Name, ObjectClass }catch{ $ext.LocalAdmins = "Error: $($_.Exception.Message)" }

  # Certificados
  try{ $ext.Certificates = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Select-Object Subject, Thumbprint, NotAfter, NotBefore }catch{ $ext.Certificates = "Error: $($_.Exception.Message)" }

  # WSMan config
  try{ $ext.WSManConfig = Get-WSManInstance -ResourceURI winrm/config -ErrorAction SilentlyContinue }catch{ $ext.WSManConfig = "Error: $($_.Exception.Message)" }

  # Hash de binarios críticos
  $critical = @(
    (Get-Command pwsh -ErrorAction SilentlyContinue).Path,
    (Get-Command powershell -ErrorAction SilentlyContinue).Path,
    (Get-Command git -ErrorAction SilentlyContinue).Path
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
  $ext.FileHashes = @()
  foreach($c in $critical){
    try{ $h=Get-FileHash -Path $c -Algorithm SHA256 -ErrorAction SilentlyContinue; $ext.FileHashes += [pscustomobject]@{ Path=$c; SHA256=$h.Hash; Length=(Get-Item $c).Length } }catch{}
  }

  # Autoruns
  $runkeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
  )
  $ext.AutoRuns = @{}
  foreach($k in $runkeys){ try{ $ext.AutoRuns[$k] = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue }catch{} }

  $startupFolders = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp")
  $ext.StartupFolders = @{}
  foreach($s in $startupFolders){ if(Test-Path $s){ $ext.StartupFolders[$s] = Get-ChildItem -Path $s -ErrorAction SilentlyContinue | Select-Object Name, FullName } }

  return $ext
}

function Build-TextReport {
  param(
    [Parameter(Mandatory=$true)][hashtable]$Data,
    [switch]$IncludeFullLists,[switch]$IncludeEnvFull,[switch]$IncludeQuickPaths,
    [hashtable]$Extended = $null,[switch]$IncludeExtendedDetails
  )
  $sb=New-Object System.Text.StringBuilder
  $meta=$Data.Meta

  $null=$sb.AppendLine((Section 'Resumen'))
  $null=$sb.AppendLine("Timestamp  : $($meta.Timestamp)")
  $null=$sb.AppendLine("Usuario    : $($meta.User)")
  $null=$sb.AppendLine("Equipo     : $($meta.ComputerName)")
  $null=$sb.AppendLine("SO         : $($meta.OS.Caption) (Build $($meta.OS.BuildNumber))")
  $null=$sb.AppendLine("PSVersion  : $($meta.PSVersion) ($($meta.PSEdition))")
  $null=$sb.AppendLine("PSHOME     : $($meta.PSHome)")
  if($IncludeQuickPaths){ $null=$sb.AppendLine("PWD        : $((Get-Location).Path)"); $null=$sb.AppendLine("HOME       : $HOME"); $null=$sb.AppendLine("SystemRoot : $env:SystemRoot"); $null=$sb.AppendLine("USERPROFILE: $env:USERPROFILE") }

  $null=$sb.AppendLine((Section 'Perfiles y ExecutionPolicy'))
  $meta.ProfilePaths.GetEnumerator() | ForEach-Object { $exists=Test-Path $_.Value; $state= if($exists){'[EXISTS]'} else {'[MISSING]'}; $null=$sb.AppendLine(" - $($_.Key): $($_.Value) $state") }
  $null=$sb.AppendLine(($meta.ExecutionPolicy | Format-Table -AutoSize | Out-String -Width 4096))

  $null=$sb.AppendLine((Section 'PSModulePath')); $null=$sb.AppendLine(($meta.PSModulePath | ForEach-Object { " - $_" } | Out-String))
  $null=$sb.AppendLine((Section 'Repositorios PS')); if($meta.PSRepositories){ $null=$sb.AppendLine(($meta.PSRepositories | Format-Table -AutoSize | Out-String -Width 4096)) } else { $null=$sb.AppendLine("No se detectaron repos configurados.") }

  $null=$sb.AppendLine((Section 'WSMan / Remoting'))
  $w=$Data.WSMan
  if($w){ $status = if($w.TestWSManOK){'OK'} else {'FAIL'}; $null=$sb.AppendLine("Test-WSMan localhost: $status"); if($w.Auth){ $null=$sb.AppendLine("Auth:"); $null=$sb.AppendLine(($w.Auth | Format-Table Name,Value -AutoSize | Out-String -Width 4096)) }; if($w.Listeners){ $null=$sb.AppendLine("Listeners:"); $null=$sb.AppendLine(($w.Listeners | Format-Table Transport,Address,Port,Enabled -AutoSize | Out-String -Width 4096)) } }

  $null=$sb.AppendLine((Section 'Toolchain detectado')); $null=$sb.AppendLine(($Data.Toolchain | Format-Table Name,Version,Path -AutoSize | Out-String -Width 4096))

  $null=$sb.AppendLine((Section 'Variables de entorno clave')); $null=$sb.AppendLine(($Data.EnvFocus | Format-Table Name,Value -AutoSize | Out-String -Width 4096))
  if($IncludeEnvFull){ $null=$sb.AppendLine((Section 'Variables de entorno (completo)')); $null=$sb.AppendLine((Get-ChildItem Env: | Sort-Object Name | Format-Table Name,Value -Wrap -AutoSize | Out-String -Width 4096)) }

  $null=$sb.AppendLine((Section 'Perfiles (hash y metadatos)')); $null=$sb.AppendLine(($Data.ProfilesInfo | Format-Table Path,Exists,Length,LastWriteTime,SHA256 -AutoSize | Out-String -Width 4096))

  $null=$sb.AppendLine((Section 'Módulos instalados')); $null=$sb.AppendLine(($Data.ModulesAll | Format-Table Name,Version,ModuleBase -AutoSize | Out-String -Width 4096))
  $null=$sb.AppendLine((Section 'Módulos PSGallery')); if($Data.InstalledModules.Count -gt 0){ $null=$sb.AppendLine(($Data.InstalledModules | Format-Table Name,Version,Repository -AutoSize | Out-String -Width 4096)) } else { $null=$sb.AppendLine("Sin registros de Get-InstalledModule.") }
  $null=$sb.AppendLine((Section 'Paquetes (PackageManagement)')); $null=$sb.AppendLine(($Data.Packages | Format-Table Name,Version,ProviderName -AutoSize | Out-String -Width 4096))
  $null=$sb.AppendLine((Section 'Hotfixes Windows')); $null=$sb.AppendLine(($Data.Hotfixes | Format-Table HotFixID,Description,InstalledOn -AutoSize | Out-String -Width 4096))

  $null=$sb.AppendLine((Section 'PATH (sanity check)')); $pa=$Data.PathAnalysis; if($pa){ $null=$sb.AppendLine('Directorios faltantes:'); $null=$sb.AppendLine(($pa.Missing | ForEach-Object { ' - ' + $_ } | Out-String)); $null=$sb.AppendLine('Duplicados:'); $null=$sb.AppendLine(($pa.Duplicates | ForEach-Object { ' - ' + $_ } | Out-String)) }

  if($Extended){
    $null=$sb.AppendLine((Section 'Snapshot extendido (resumen)'))
    $summary=@(
      ('Procesos         : ' + ($(if($Extended.Processes -is [System.Collections.IEnumerable]){($Extended.Processes | Measure-Object).Count}else{'0'}))),
      ('Servicios        : ' + ($(if($Extended.Services -is [System.Collections.IEnumerable]){($Extended.Services | Measure-Object).Count}else{'0'}))),
      ('Tareas programadas: ' + ($(if($Extended.ScheduledTasks -is [System.Collections.IEnumerable]){($Extended.ScheduledTasks | Measure-Object).Count}else{'0'}))),
      ('Puertos en escucha: ' + ($(if($Extended.NetListening -is [System.Collections.IEnumerable]){($Extended.NetListening | Measure-Object).Count}else{'0'}))),
      ('Reglas firewall  : ' + ($(if($Extended.FirewallRules -is [System.Collections.IEnumerable]){($Extended.FirewallRules | Measure-Object).Count}else{'0'})))
    ); $summary | ForEach-Object { $null=$sb.AppendLine($_) }

    if($IncludeExtendedDetails){
      $null=$sb.AppendLine((Section 'Procesos (Id, Name, Path, Firma)')); if($Extended.Processes -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.Processes | Sort-Object Name | Format-Table Id,Name,Path,SignatureStatus -Wrap -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Servicios')); if($Extended.Services -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.Services | Sort-Object DisplayName | Format-Table Name,DisplayName,State,StartMode,StartName -Wrap -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Tareas programadas')); if($Extended.ScheduledTasks -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.ScheduledTasks | Sort-Object TaskPath,TaskName | Format-Table TaskPath,TaskName,State,UserId -Wrap -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Red - escuchando')); if($Extended.NetListening -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.NetListening | Sort-Object LocalPort | Format-Table LocalAddress,LocalPort,OwningProcess,State -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Firewall - perfiles')); if($Extended.FirewallProfiles){ $null=$sb.AppendLine(($Extended.FirewallProfiles | Format-Table Name,Enabled,DefaultInboundAction,DefaultOutboundAction -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Firewall - reglas')); if($Extended.FirewallRules -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.FirewallRules | Sort-Object DisplayName | Format-Table DisplayName,Direction,Action,Enabled,Profile -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Programas instalados')); if($Extended.InstalledPrograms -is [System.Collections.IEnumerable]){ $null=$sb.AppendLine(($Extended.InstalledPrograms | Sort-Object DisplayName | Format-Table DisplayName,DisplayVersion,Publisher,InstallDate -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Eventos (System últimos 150)')); if($Extended.Events.System){ $null=$sb.AppendLine(($Extended.Events.System | Select-Object TimeCreated,ProviderName,Id,LevelDisplayName | Format-Table -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Historial PowerShell')); if($Extended.PowerShellHistory -is [hashtable]){ $null=$sb.AppendLine("Ruta: " + $Extended.PowerShellHistory.Path); $null=$sb.AppendLine(($Extended.PowerShellHistory.Last500 | Out-String)) }
      $null=$sb.AppendLine((Section 'Perfil actual (hash + contenido)')); if($Extended.ProfileContent -is [hashtable]){ $null=$sb.AppendLine("Path: " + $Extended.ProfileContent.Path); $null=$sb.AppendLine("SHA256: " + $Extended.ProfileContent.SHA256); $null=$sb.AppendLine(($Extended.ProfileContent.Content | Out-String)) }
      $null=$sb.AppendLine((Section 'SecretManagement - Vaults')); if($Extended.SecretVaults){ $null=$sb.AppendLine(($Extended.SecretVaults | Format-Table Name,ModuleName,VaultParameters -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Administradores locales')); if($Extended.LocalAdmins){ $null=$sb.AppendLine(($Extended.LocalAdmins | Format-Table Name,ObjectClass -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Certificados (LM\My)')); if($Extended.Certificates){ $null=$sb.AppendLine(($Extended.Certificates | Format-Table Subject,Thumbprint,NotBefore,NotAfter -AutoSize | Out-String -Width 4096)) }
      $null=$sb.AppendLine((Section 'Autoruns (Run keys)')); if($Extended.AutoRuns){ $Extended.AutoRuns.GetEnumerator() | ForEach-Object { $null=$sb.AppendLine("["+$_.Key+"]"); $null=$sb.AppendLine(($_.Value | Format-List * | Out-String -Width 4096)) } }
      $null=$sb.AppendLine((Section 'Startup Folders')); if($Extended.StartupFolders){ $Extended.StartupFolders.GetEnumerator() | ForEach-Object { $null=$sb.AppendLine("["+$_.Key+"]"); $null=$sb.AppendLine(($_.Value | Format-Table Name,FullName -AutoSize | Out-String -Width 4096)) } }
      $null=$sb.AppendLine((Section 'Hashes de binarios críticos')); if($Extended.FileHashes){ $null=$sb.AppendLine(($Extended.FileHashes | Format-Table Path,Length,SHA256 -AutoSize | Out-String -Width 4096)) }
    }
  }
  $sb.ToString()
}

function Build-MarkdownReport {
  param(
    [Parameter(Mandatory=$true)][hashtable]$Data,
    [hashtable]$Extended = $null,[switch]$IncludeExtendedDetails,[switch]$IncludeQuickPaths
  )
  $sb=New-Object System.Text.StringBuilder
  $m=$Data.Meta
  $null=$sb.AppendLine("# Snapshot de entorno PowerShell")
  $null=$sb.AppendLine()
  $null=$sb.AppendLine("> Generado: **$($m.Timestamp)** en **$($m.ComputerName)** por **$($m.User)**, PS **$($m.PSVersion)** ($($m.PSEdition))")
  if($IncludeQuickPaths){ $null=$sb.AppendLine("`PWD=$((Get-Location).Path)`  `HOME=$HOME`  `SystemRoot=$env:SystemRoot`") }

  $null=$sb.AppendLine((MdH2 'WSMan / Remoting'))
  if($Data.WSMan.TestWSManOK){ $null=$sb.AppendLine("- Test-WSMan: OK") } else { $null=$sb.AppendLine("- Test-WSMan: FAIL") }
  if($Data.WSMan.Auth){ $null=$sb.AppendLine("**Auth**:"); $null=$sb.AppendLine((Fmt-MdTable -rows $Data.WSMan.Auth -Columns @('Name','Value'))) }
  if($Data.WSMan.Listeners){ $null=$sb.AppendLine("**Listeners**:"); $null=$sb.AppendLine((Fmt-MdTable -rows $Data.WSMan.Listeners -Columns @('Transport','Address','Port','Enabled'))) }

  $null=$sb.AppendLine((MdH2 'Toolchain'))
  $null=$sb.AppendLine((Fmt-MdTable -rows $Data.Toolchain -Columns @('Name','Version','Path')))

  $null=$sb.AppendLine((MdH2 'Perfiles'))
  $null=$sb.AppendLine((Fmt-MdTable -rows $Data.ProfilesInfo -Columns @('Path','Exists','Length','LastWriteTime','SHA256')))

  $null=$sb.AppendLine((MdH2 'Módulos (disponibles)'))
  $null=$sb.AppendLine((Fmt-MdTable -rows $Data.ModulesAll -Columns @('Name','Version','ModuleBase')))

  if($Extended){
    $null=$sb.AppendLine((MdH2 'Snapshot extendido (resumen)'))
    $rows=@(
      [pscustomobject]@{ Item='Procesos';         Count=($(if($Extended.Processes -is [System.Collections.IEnumerable]){($Extended.Processes | Measure-Object).Count}else{0})) },
      [pscustomobject]@{ Item='Servicios';        Count=($(if($Extended.Services -is [System.Collections.IEnumerable]){($Extended.Services | Measure-Object).Count}else{0})) },
      [pscustomobject]@{ Item='Tareas';           Count=($(if($Extended.ScheduledTasks -is [System.Collections.IEnumerable]){($Extended.ScheduledTasks | Measure-Object).Count}else{0})) },
      [pscustomobject]@{ Item='Puertos listen';   Count=($(if($Extended.NetListening -is [System.Collections.IEnumerable]){($Extended.NetListening | Measure-Object).Count}else{0})) },
      [pscustomobject]@{ Item='Reglas firewall';  Count=($(if($Extended.FirewallRules -is [System.Collections.IEnumerable]){($Extended.FirewallRules | Measure-Object).Count}else{0})) }
    )
    $null=$sb.AppendLine((Fmt-MdTable -rows $rows -Columns @('Item','Count')))

    if($IncludeExtendedDetails){
      $null=$sb.AppendLine((MdH2 'Procesos (top 50 por nombre)'))
      if($Extended.Processes -is [System.Collections.IEnumerable]){
        $null=$sb.AppendLine((Fmt-MdTable -rows ($Extended.Processes | Sort-Object Name | Select-Object -First 50) -Columns @('Id','Name','Path','SignatureStatus')))
      }
      $null=$sb.AppendLine((MdH2 'Servicios (muestra 50)'))
      if($Extended.Services -is [System.Collections.IEnumerable]){
        $null=$sb.AppendLine((Fmt-MdTable -rows ($Extended.Services | Sort-Object DisplayName | Select-Object -First 50) -Columns @('Name','DisplayName','State','StartMode','StartName')))
      }
      $null=$sb.AppendLine((MdH2 'Tareas programadas (muestra 50)'))
      if($Extended.ScheduledTasks -is [System.Collections.IEnumerable]){
        $null=$sb.AppendLine((Fmt-MdTable -rows ($Extended.ScheduledTasks | Sort-Object TaskPath,TaskName | Select-Object -First 50) -Columns @('TaskPath','TaskName','State','UserId')))
      }
      $null=$sb.AppendLine((MdH2 'Hashes de binarios críticos'))
      if($Extended.FileHashes){
        $null=$sb.AppendLine((Fmt-MdTable -rows $Extended.FileHashes -Columns @('Path','Length','SHA256')))
      }
    }
  }
  $sb.ToString()
}

function Build-JsonReport {
  param(
    [Parameter(Mandatory=$true)][hashtable]$Data,
    [hashtable]$Extended = $null,[switch]$IncludeEnvFull,[switch]$IncludeQuickPaths
  )
  $jsonObj=[ordered]@{
    Meta=$Data.Meta; WSMan=$Data.WSMan; Toolchain=$Data.Toolchain; EnvFocus=$Data.EnvFocus
    ModulesAll=$Data.ModulesAll; InstalledModules=$Data.InstalledModules; Packages=$Data.Packages
    Hotfixes=$Data.Hotfixes; ProfilesInfo=$Data.ProfilesInfo; PathAnalysis=$Data.PathAnalysis
  }
  if($IncludeEnvFull){ $jsonObj.EnvAll = Get-ChildItem Env: | Sort-Object Name | Select-Object Name,Value }
  if($IncludeQuickPaths){ $jsonObj.QuickPaths = @{ PWD=(Get-Location).Path; HOME=$HOME; SystemRoot=$env:SystemRoot; USERPROFILE=$env:USERPROFILE } }
  if($Extended){ $jsonObj.Extended = $Extended }
  $jsonObj | ConvertTo-Json -Depth 7
}

function Run-TestAndMaybeApply {
  param(
    [Parameter(Mandatory=$true)][string]$OutDir,
    [switch]$ExportTxt,[switch]$ExportJson,[switch]$ExportMd,
    [switch]$IncludeFullLists,[switch]$IncludeEnvFull,[switch]$IncludeQuickPaths,
    [switch]$ExtendedSnapshot,[switch]$IncludeExtendedDetails,
    [scriptblock]$ConsoleWriter,[switch]$ApplyOnSuccess
  )
  if(-not $ConsoleWriter){ $ConsoleWriter={ param($msg,[switch]$Warn,[switch]$Err) if($Err){Write-Host $msg -ForegroundColor Red}elseif($Warn){Write-Host $msg -ForegroundColor Yellow}else{Write-Host $msg} } }

  $ConsoleWriter.Invoke("[TEST] Simulación iniciada...")
  $data=$null; $ext=$null
  $testErrors=New-Object System.Collections.Generic.List[string]
  $prevPref=$ErrorActionPreference; $ErrorActionPreference='Continue'; $Error.Clear()

  try{ $data=Get-EnvReport }catch{ $testErrors.Add("Get-EnvReport: $($_.Exception.Message)") }
  if($ExtendedSnapshot){
    try{ $ext=Get-ExtendedSnapshot }catch{ $testErrors.Add("Get-ExtendedSnapshot: $($_.Exception.Message)") }
  }

  try{ if(-not (Test-Path -LiteralPath $OutDir)){ $ConsoleWriter.Invoke("Directorio no existe y se creará en APPLY: $OutDir") } }catch{ $testErrors.Add("Validación de directorio: $($_.Exception.Message)") }

  $txt=$null;$json=$null;$md=$null
  try{ if($ExportTxt){ $txt=Build-TextReport -Data $data -IncludeFullLists:$IncludeFullLists -IncludeEnvFull:$IncludeEnvFull -IncludeQuickPaths:$IncludeQuickPaths -Extended $ext -IncludeExtendedDetails:$IncludeExtendedDetails } }catch{ $testErrors.Add("Build-TextReport: $($_.Exception.Message)") }
  try{ if($ExportJson){ $json=Build-JsonReport -Data $data -Extended $ext -IncludeEnvFull:$IncludeEnvFull -IncludeQuickPaths:$IncludeQuickPaths } }catch{ $testErrors.Add("Build-JsonReport: $($_.Exception.Message)") }
  try{ if($ExportMd){ $md=Build-MarkdownReport -Data $data -Extended $ext -IncludeExtendedDetails:$IncludeExtendedDetails -IncludeQuickPaths:$IncludeQuickPaths } }catch{ $testErrors.Add("Build-MarkdownReport: $($_.Exception.Message)") }

  try{ if($txt){ $null=$txt.Length } }catch{ $testErrors.Add("TXT length: $($_.Exception.Message)") }
  try{ if($json){ $null=$json.Length } }catch{ $testErrors.Add("JSON length: $($_.Exception.Message)") }
  try{ if($md){ $null=$md.Length } }catch{ $testErrors.Add("MD length: $($_.Exception.Message)") }

  $txtPath = Join-Path $OutDir 'PowerShell_CustomReport.txt'
  $jsonPath= Join-Path $OutDir 'PowerShell_CustomReport.json'
  $mdPath  = Join-Path $OutDir 'PowerShell_CustomReport.md'

  try{ if($ExportTxt -and (Test-Path $txtPath)){ $null=(Get-Item $txtPath).Length } }catch{ $testErrors.Add("TXT existente: $($_.Exception.Message)") }
  try{ if($ExportJson -and (Test-Path $jsonPath)){ $null=(Get-Item $jsonPath).Length } }catch{ $testErrors.Add("JSON existente: $($_.Exception.Message)") }
  try{ if($ExportMd -and (Test-Path $mdPath)){ $null=(Get-Item $mdPath).Length } }catch{ $testErrors.Add("MD existente: $($_.Exception.Message)") }

  $ErrorActionPreference=$prevPref
  if($Error.Count -gt 0){ foreach($e in $Error){ $testErrors.Add($e.ToString()) } }

  if($testErrors.Count -gt 0){
    $ConsoleWriter.Invoke("[TEST] Se detectaron $($testErrors.Count) error(es).",$true)
    foreach($m in $testErrors){ $ConsoleWriter.Invoke(" - $m",$false,$true) }
    $ConsoleWriter.Invoke("[TEST] Abortado sin escritura.",$true)
    return
  }

  $extNote = if($ExtendedSnapshot){ " | Ext: ON" } else { "" }
  $ConsoleWriter.Invoke("[TEST] OK. Módulos: $($data.ModulesAll.Count) | Hotfixes: $($data.Hotfixes.Count) | Paquetes: $($data.Packages.Count) | Toolchain: $($data.Toolchain.Count)$extNote")

  if(-not $ApplyOnSuccess){ return }

  $ConsoleWriter.Invoke("[APPLY] Procediendo a escritura real...")
  if(-not (Test-Path -LiteralPath $OutDir)){ New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

  if($ExportTxt){ if($PSCmdlet.ShouldProcess($txtPath,'Escribir TXT con respaldo .bak')){ $bak=$null; if(Test-Path $txtPath){ $bak=Safe-Backup -Path $txtPath }; Out-Utf8NoBom -Path $txtPath -Content $txt; $ConsoleWriter.Invoke("TXT escrito en: $txtPath"); if($bak){ $ConsoleWriter.Invoke("Respaldo creado: $bak") } } }
  if($ExportJson){ if($PSCmdlet.ShouldProcess($jsonPath,'Escribir JSON con respaldo .bak')){ $bakJ=$null; if(Test-Path $jsonPath){ $bakJ=Safe-Backup -Path $jsonPath }; Out-Utf8NoBom -Path $jsonPath -Content $json; $ConsoleWriter.Invoke("JSON escrito en: $jsonPath"); if($bakJ){ $ConsoleWriter.Invoke("Respaldo creado: $bakJ") } } }
  if($ExportMd){ if($PSCmdlet.ShouldProcess($mdPath,'Escribir MD con respaldo .bak')){ $bakM=$null; if(Test-Path $mdPath){ $bakM=Safe-Backup -Path $mdPath }; Out-Utf8NoBom -Path $mdPath -Content $md; $ConsoleWriter.Invoke("MD escrito en: $mdPath"); if($bakM){ $ConsoleWriter.Invoke("Respaldo creado: $bakM") } } }

  $ConsoleWriter.Invoke("[DONE] Todo listo.")
}

function Show-EnvReportGui {
  Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
  Add-Type -AssemblyName System.Windows.Forms
  $xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Ws-Studio | Reporte de Entorno" Height="660" Width="900" WindowStartupLocation="CenterScreen" ResizeMode="CanResize">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
      <TextBlock Text="Carpeta de exportación:" VerticalAlignment="Center" Margin="0,0,8,0"/>
      <TextBox x:Name="txtPath" Width="640" HorizontalAlignment="Left"/>
      <Button x:Name="btnBrowse" Content="Examinar..." Width="110" Margin="8,0,0,0"/>
    </StackPanel>

    <Expander Grid.Row="1" Header="Opciones de exportación" IsExpanded="False" Margin="0,0,0,8">
      <StackPanel Margin="8">
        <StackPanel Orientation="Horizontal">
          <CheckBox x:Name="chkExportTxt"  IsChecked="True"  Content="TXT (legible para humanos)"/>
          <CheckBox x:Name="chkExportJson" IsChecked="True"  Content="JSON (para comparar y automatizar)" Margin="16,0,0,0"/>
          <CheckBox x:Name="chkExportMd"   IsChecked="True"  Content="Markdown (.md) para documentación" Margin="16,0,0,0"/>
        </StackPanel>
        <Separator Margin="0,6,0,6"/>
        <CheckBox x:Name="chkFullLists"  Content="Incluir listas completas (Aliases, Cmdlets, Funciones). Más largo y verboso."/>
        <CheckBox x:Name="chkEnvFull"    Content="Incluir variables de entorno completas (Env:). Útil para clonar entorno."/>
        <CheckBox x:Name="chkQuickPaths" Content="Agregar rutas rápidas (PWD, HOME, SystemRoot, USERPROFILE)."/>
        <TextBlock Text="No soy desarrollador wey, solo quiero picar botones y que las cosas funcionen." Foreground="#888" Margin="0,6,0,0"/>
      </StackPanel>
    </Expander>

    <Expander Grid.Row="2" Header="Snapshot extendido (procesos, servicios, red, eventos, programas, etc.)" IsExpanded="False" Margin="0,0,0,8">
      <StackPanel Margin="8">
        <CheckBox x:Name="chkExtended" IsChecked="True" Content="Capturar snapshot extendido"/>
        <CheckBox x:Name="chkExtDetails" Content="Incluir detalles extendidos en TXT/MD (podría ser largo)"/>
      </StackPanel>
    </Expander>

    <DockPanel Grid.Row="3" LastChildFill="False" Margin="0,0,0,8">
      <TextBlock Text="Consola:" VerticalAlignment="Center" DockPanel.Dock="Left"/>
      <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
        <Button x:Name="btnCopy" Content="Copiar consola" Width="130" Margin="0,0,8,0"/>
        <Button x:Name="btnRun"  Content="Ejecutar" Width="100"/>
      </StackPanel>
    </DockPanel>

    <TextBox x:Name="txtConsole" Grid.Row="4" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" IsReadOnly="True" FontFamily="Consolas" FontSize="12" Height="280"/>
  </Grid>
</Window>
"@

  $reader=New-Object System.Xml.XmlNodeReader ([xml]$xaml)
  $window=[Windows.Markup.XamlReader]::Load($reader)

  $txtPath=$window.FindName('txtPath')
  $btnBrowse=$window.FindName('btnBrowse')
  $chkExportTxt=$window.FindName('chkExportTxt')
  $chkExportJson=$window.FindName('chkExportJson')
  $chkExportMd=$window.FindName('chkExportMd')
  $chkFullLists=$window.FindName('chkFullLists')
  $chkEnvFull=$window.FindName('chkEnvFull')
  $chkQuickPaths=$window.FindName('chkQuickPaths')
  $chkExtended=$window.FindName('chkExtended')
  $chkExtDetails=$window.FindName('chkExtDetails')
  $btnCopy=$window.FindName('btnCopy')
  $btnRun=$window.FindName('btnRun')
  $txtConsole=$window.FindName('txtConsole')

  $defaultExport='C:\Users\VictorFabianVeraVill\.mnt\Scripts\System_Snapshots\PowerShell+\GUI\'
  $txtPath.Text=$defaultExport

  $ConsoleWriter={ param($msg,[switch]$Warn,[switch]$Err)
    $prefix=if($Err){'[ERR] '}elseif($Warn){'[WARN] '}else{''}
    $line="$prefix$msg`r`n"
    $txtConsole.AppendText($line) | Out-Null
    $txtConsole.ScrollToEnd()
    if($Err){Write-Host $msg -ForegroundColor Red}elseif($Warn){Write-Host $msg -ForegroundColor Yellow}else{Write-Host $msg}
  }

  $btnBrowse.Add_Click({
    $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description="Selecciona la carpeta de exportación"
    $dlg.SelectedPath=if([string]::IsNullOrWhiteSpace($txtPath.Text)){ $defaultExport } else { $txtPath.Text }
    if($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ $txtPath.Text=$dlg.SelectedPath }
  })
  $btnCopy.Add_Click({ [System.Windows.Clipboard]::SetText($txtConsole.Text); $ConsoleWriter.Invoke("Consola copiada al portapapeles.") })

  $btnRun.Add_Click({
    $outDir=$txtPath.Text.Trim()
    if([string]::IsNullOrWhiteSpace($outDir)){ $ConsoleWriter.Invoke("Ruta de exportación vacía. Escribe una o usa Examinar.",$true); return }

    Run-TestAndMaybeApply -OutDir $outDir `
      -ExportTxt:$($chkExportTxt.IsChecked) `
      -ExportJson:$($chkExportJson.IsChecked) `
      -ExportMd:$($chkExportMd.IsChecked) `
      -IncludeFullLists:$($chkFullLists.IsChecked) `
      -IncludeEnvFull:$($chkEnvFull.IsChecked) `
      -IncludeQuickPaths:$($chkQuickPaths.IsChecked) `
      -ExtendedSnapshot:$($chkExtended.IsChecked) `
      -IncludeExtendedDetails:$($chkExtDetails.IsChecked) `
      -ConsoleWriter $ConsoleWriter -ApplyOnSuccess
  })

  $window.ShowDialog() | Out-Null
}

if($NoGui){
  $outDir='C:\Users\VictorFabianVeraVill\.mnt\Scripts\System_Snapshots\PowerShell+\GUI\'
  Run-TestAndMaybeApply -OutDir $outDir -ExportTxt -ExportJson -ExportMd -ExtendedSnapshot -IncludeQuickPaths -ConsoleWriter { param($m,[switch]$w,[switch]$e) if($e){Write-Host $m -ForegroundColor Red}elseif($w){Write-Host $m -ForegroundColor Yellow}else{Write-Host $m} } -ApplyOnSuccess
}else{
  Show-EnvReportGui
}
