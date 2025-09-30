# Crea el script New-FileMap.GUI.v2.ps1 en tu Escritorio\PowerShell
$dir = Join-Path $env:USERPROFILE 'Desktop\PowerShell'
$new = Join-Path $dir 'New-FileMap.GUI.v2.ps1'
New-Item -ItemType Directory -Path $dir -Force | Out-Null

$code = @'
<#
New-FileMap.GUI.v2.ps1
- GUI redimensionable (Maximizado por defecto), con tema Claro/Oscuro.
- FileMap + inventario CSV/JSONL con metadatos opcionales (hash, dueño, etc.)
- Procesamiento por bloques con progreso.
- Reportes Top-N por tamaño y antigüedad.
- Guarda "Sesión" (NDJSON) tras el escaneo y permite CARGAR resultados previos.
- Acciones: mover duplicados por SHA hash (deja 1 por grupo) a una carpeta destino.
#>

[CmdletBinding()]
param(
  [switch] $NoGui,
  [string] $RootPath,
  [string] $OutDir,
  [switch] $IncludeTree,
  [ValidateSet('md','txt')][string] $OutputKind = 'md',
  [switch] $EmitCsv,
  [switch] $EmitJsonl,
  [switch] $IncludeHidden,
  [switch] $ComputeHash,
  [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')][string] $HashAlgorithm = 'SHA256',
  [switch] $WithOwner,
  [int] $BlockSize = 5000,
  [int] $ProgressInterval = 500,
  [int] $MaxDepth = 0, # 0 = sin límite (árbol)
  [string] $ExcludeDirs = ".git,node_modules,.venv,venv,env,.env,__pycache__",
  [string] $ExcludeExt  = ".tmp,.log,.bak,.map,.pyc,.class",
  [int] $TopN = 100,
  [switch] $TopBySize,
  [switch] $TopByAge,
  [switch] $FollowSymlinks
)

function Get-DesktopPath { try { [Environment]::GetFolderPath('Desktop') } catch { Join-Path $env:USERPROFILE 'Desktop' } }
function NowStamp { (Get-Date -Format 'yyyyMMdd_HHmmss') }

# ---------- THEME ----------
function Apply-Theme([System.Windows.Forms.Control]$ctrl, [string]$mode) {
  $dark = ($mode -eq 'Dark')
  $bg  = if ($dark) { [System.Drawing.Color]::FromArgb(18,18,18) } else { [System.Drawing.SystemColors]::Control }
  $fg  = if ($dark) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
  $tb  = if ($dark) { [System.Drawing.Color]::FromArgb(32,32,32) } else { [System.Drawing.Color]::White }
  $btn = if ($dark) { [System.Drawing.Color]::FromArgb(45,45,45) } else { [System.Drawing.SystemColors]::Control }

  $ctrl.BackColor = $bg; $ctrl.ForeColor = $fg
  foreach($c in $ctrl.Controls){
    try {
      $c.ForeColor = $fg
      if ($c -is [System.Windows.Forms.TextBox]) { $c.BackColor = $tb }
      elseif ($c -is [System.Windows.Forms.ComboBox]) { $c.BackColor = $tb }
      elseif ($c -is [System.Windows.Forms.NumericUpDown]) { $c.BackColor = $tb }
      elseif ($c -is [System.Windows.Forms.Button]) { $c.BackColor = $btn; $c.FlatStyle='Flat'; $c.FlatAppearance.BorderColor = $fg }
      if ($c.Controls.Count) { Apply-Theme $c $mode }
    } catch {}
  }
}

# --------------- CORE ---------------
function Split-List([string]$s){ if ([string]::IsNullOrWhiteSpace($s)) { @() } else { $s.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } } }
function Update-ProgressGui([int]$percent,[string]$status){
  if ($null -ne $global:__gui) {
    try { $global:__gui.pb.Value = [Math]::Clamp($percent,0,100); $global:__gui.lbl.Text = $status; [System.Windows.Forms.Application]::DoEvents() } catch {}
  } else { Write-Progress -Activity "Procesando" -Status $status -PercentComplete $percent }
}

$script:LastRows = @()
$script:LastRoot = ""
$script:LastOut  = ""

function New-FileMapCore {
  param(
    [Parameter(Mandatory)][string] $RootPath,
    [Parameter(Mandatory)][string] $OutDir,
    [switch] $IncludeTree,
    [ValidateSet('md','txt')][string] $OutputKind = 'md',
    [switch] $EmitCsv,
    [switch] $EmitJsonl,
    [switch] $IncludeHidden,
    [switch] $ComputeHash,
    [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')][string] $HashAlgorithm = 'SHA256',
    [switch] $WithOwner,
    [int] $BlockSize = 5000,
    [int] $ProgressInterval = 500,
    [int] $MaxDepth = 0,
    [string] $ExcludeDirs = ".git,node_modules,.venv,venv,env,.env,__pycache__",
    [string] $ExcludeExt  = ".tmp,.log,.bak,.map,.pyc,.class",
    [int] $TopN = 100,
    [switch] $TopBySize,
    [switch] $TopByAge,
    [switch] $FollowSymlinks
  )

  if (-not (Test-Path -LiteralPath $RootPath)) { throw "La ruta especificada no existe: $RootPath" }
  $rootItem = Get-Item -LiteralPath $RootPath -ErrorAction Stop
  if (-not $rootItem.PSIsContainer) { throw "La ruta debe ser un directorio: $RootPath" }
  if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

  $exDirs = Split-List $ExcludeDirs
  $exExts = (Split-List $ExcludeExt | ForEach-Object { $_.ToLowerInvariant() })

  $ts = NowStamp
  $rootName = Split-Path -Path $RootPath -Leaf
  if ([string]::IsNullOrWhiteSpace($rootName)) { $rootName = ($RootPath -replace '[:\\\/]','_') }
  $baseName = ("{0}_{1}" -f ($rootName -replace '[^\w\.-]','_'), $ts)

  $treeFile = Join-Path $OutDir ("FileMap_{0}.{1}" -f $baseName, $OutputKind)
  $csvFile  = Join-Path $OutDir ("FileList_{0}.csv"   -f $baseName)
  $jsonFile = Join-Path $OutDir ("FileList_{0}.jsonl" -f $baseName)
  $session  = Join-Path $OutDir ("Session_{0}.jsonl"  -f $baseName)

  $gci = @{ LiteralPath=$RootPath; Recurse=$true; Force=$true; ErrorAction='SilentlyContinue' }
  if (-not $FollowSymlinks) { $gci['Attributes'] = '!ReparsePoint' }

  $all = @(Get-ChildItem @gci -File)

  function Skip-File([string]$p){
    $low = $p.ToLowerInvariant()
    foreach($d in $exDirs){ if ($low -like "*\{0}\*" -f $d.ToLowerInvariant()) { return $true } }
    $ext = [System.IO.Path]::GetExtension($low)
    if ($exExts -contains $ext) { return $true }
    $fi = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
    if (-not $IncludeHidden) { if ($fi.Attributes.HasFlag([IO.FileAttributes]::Hidden) -or $fi.Attributes.HasFlag([IO.FileAttributes]::System)) { return $true } }
    return $false
  }

  $files = @($all | Where-Object { -not (Skip-File $_.FullName) })
  $total = $files.Count
  if ($total -eq 0 -and -not $IncludeTree) { Write-Host "No se encontraron archivos tras filtros."; return }

  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $swCsv = $null; $swJson = $null; $swTree = $null; $swSession = $null

  $headers = @('fullpath','relpath','type','name','ext','size_bytes','sha256','ctime_utc','mtime_utc','atime_utc','age_days','attributes','is_hidden','is_readonly')
  if ($WithOwner) { $headers += 'owner' }
  if ($EmitCsv)   { $swCsv  = New-Object System.IO.StreamWriter($csvFile,  $false, $utf8); $swCsv.WriteLine(($headers -join ',')) }
  if ($EmitJsonl) { $swJson = New-Object System.IO.StreamWriter($jsonFile, $false, $utf8) }
  $swSession = New-Object System.IO.StreamWriter($session, $false, $utf8)

  $script:LastRows = @(); $script:LastRoot = $RootPath; $script:LastOut = $OutDir
  $topSize = New-Object System.Collections.Generic.List[object]
  $topAge  = New-Object System.Collections.Generic.List[object]

  function Consider-TopSize($p,$s){ if ($TopBySize){ $obj=[pscustomobject]@{fullpath=$p;size=[int64]$s}; $topSize.Add($obj); if ($topSize.Count -gt $TopN){ $topSize = @($topSize | Sort-Object size -Desc)[0..($TopN-1)] } } }
  function Consider-TopAge($p,[datetime]$m){ if ($TopByAge){ $age=(New-TimeSpan -Start $m -End (Get-Date).ToUniversalTime()).TotalDays; $obj=[pscustomobject]@{fullpath=$p;age_days=[math]::Round($age,2);mtime_utc=$m}; $topAge.Add($obj); if ($topAge.Count -gt $TopN){ $topAge = @($topAge | Sort-Object age_days -Desc)[0..($TopN-1)] } } }

  $processed = 0
  for ($off=0; $off -lt $total; $off += $BlockSize) {
    $end = [Math]::Min($off + $BlockSize - 1, $total - 1)
    $batch = $files[$off..$end]; $i=0
    foreach ($fi in $batch) {
      $i++; $processed++
      $pct = if ($total){ [int](($processed/$total)*100) } else { 100 }
      if ($i -eq 1 -or ($i % [Math]::Max(50,[int]($ProgressInterval/10)) -eq 0) -or ($processed -eq $total)) {
        Update-ProgressGui $pct ("{0} / {1}" -f $processed,$total)
      }
      try {
        $full = $fi.FullName
        $rel  = [System.IO.Path]::GetRelativePath($RootPath, $full)
        $isHidden = (($fi.Attributes -band [IO.FileAttributes]::Hidden) -ne 0)
        $isRO     = (($fi.Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0)
        $hash = ""
        if ($ComputeHash) { try { $hash = (Get-FileHash -LiteralPath $full -Algorithm $HashAlgorithm -ErrorAction Stop).Hash.ToLower() } catch { $hash = "<err>" } }
        $row = [pscustomobject]@{
          fullpath   = $full
          relpath    = $rel
          type       = "file"
          name       = $fi.Name
          ext        = $fi.Extension.ToLowerInvariant().Trim()
          size_bytes = [int64]$fi.Length
          sha256     = $hash
          ctime_utc  = $fi.CreationTimeUtc.ToString("yyyy-MM-dd HH:mm:ss")
          mtime_utc  = $fi.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm:ss")
          atime_utc  = $fi.LastAccessTimeUtc.ToString("yyyy-MM-dd HH:mm:ss")
          age_days   = [Math]::Round(((Get-Date).ToUniversalTime() - $fi.LastWriteTimeUtc).TotalDays,2)
          attributes = $fi.Attributes.ToString()
          is_hidden  = $isHidden
          is_readonly= $isRO
        }
        if ($WithOwner) { try { $row | Add-Member owner ((Get-Acl -LiteralPath $full).Owner) } catch { $row | Add-Member owner "<err>" } }
        $script:LastRows += $row
        if ($swCsv)  { $swCsv.WriteLine(($headers | % { $row.$_ } | % { if($_ -match '[,"\r\n]'){ '"' + ($_ -replace '"','""') + '"' } else { $_ } } -join ',')) }
        if ($swJson) { $swJson.WriteLine(($row | ConvertTo-Json -Compress -Depth 6)) }
        $swSession.WriteLine(($row | ConvertTo-Json -Compress -Depth 6))
        Consider-TopSize $full $fi.Length
        Consider-TopAge  $full $fi.LastWriteTimeUtc
      } catch { continue }
    }
  }

  foreach($w in @($swCsv,$swJson,$swSession)){ if ($w){ try { $w.Flush(); $w.Dispose() } catch {} } }

  if ($IncludeTree) {
    $Chars = @{ Pipe='│   '; Space='    '; Tee='├── '; Elbow='└── '; Root='┬─ ' }
    $swTree = New-Object System.IO.StreamWriter($treeFile, $false, $utf8)
    if ($OutputKind -eq 'md') { $swTree.WriteLine("# FileMap - $RootPath"); $swTree.WriteLine(); $swTree.WriteLine('```') } else { $swTree.WriteLine("FileMap - $RootPath") }
    function Build-Indent([bool[]]$arr){ if (-not $arr -or $arr.Count -eq 0){''}else{ ($arr | ForEach-Object { if($_){'│   '}else{'    '} }) -join '' } }
    function Write-Tree([string]$cur,[int]$depth,[bool[]]$anc){
      if ($MaxDepth -gt 0 -and $depth -ge $MaxDepth) { return }
      try { $di=[System.IO.DirectoryInfo]$cur; $dirs=@($di.EnumerateDirectories('*','TopDirectoryOnly')); $files=@($di.EnumerateFiles('*','TopDirectoryOnly')) } catch { return }
      $children=@(); $children+= $dirs | % { @{Kind='Dir';Info=$_} }; $children+= $files | % { @{Kind='File';Info=$_} }
      for($i=0;$i -lt $children.Count;$i++){
        $ch=$children[$i]; $last=($i -eq $children.Count-1); $indent=Build-Indent $anc; $branch= if($last){$Chars.Elbow}else{$Chars.Tee}
        if($ch.Kind -eq 'Dir'){ $swTree.WriteLine("{0}{1}[DIR] {2}" -f $indent,$branch,$ch.Info.Name); Write-Tree $ch.Info.FullName ($depth+1) ($anc + @(( -not $last ))) }
        else { $swTree.WriteLine("{0}{1}{2}" -f $indent,$branch,$ch.Info.Name) }
      }
    }
    $swTree.WriteLine("{0}[DIR] {1}" -f $Chars.Root,$RootPath); Write-Tree $RootPath 0 @()
    if ($OutputKind -eq 'md') { $swTree.WriteLine('```') }
    $swTree.Flush(); $swTree.Dispose()
  }

  if ($TopBySize -and $topSize.Count -gt 0) { ($topSize | Sort-Object size -Desc | Select-Object fullpath,size) | Export-Csv (Join-Path $OutDir ("Top{0}_by_size_{1}.csv" -f $TopN,$ts)) -NoTypeInformation -Encoding UTF8 }
  if ($TopByAge  -and $topAge.Count  -gt 0) { ($topAge  | Sort-Object age_days -Desc | Select-Object fullpath,age_days,mtime_utc) | Export-Csv (Join-Path $OutDir ("Top{0}_by_age_{1}.csv"  -f $TopN,$ts)) -NoTypeInformation -Encoding UTF8 }

  Update-ProgressGui 100 "Listo"
  Write-Host "CSV: $csvFile"; Write-Host "JSONL: $jsonFile"; Write-Host "Árbol: $treeFile"; Write-Host "Sesión: $session"
  return @{ Csv=$csvFile; Jsonl=$jsonFile; Tree=$treeFile; Session=$session }
}

function Load-Results-From-File([string]$path){
  if (-not (Test-Path -LiteralPath $path)) { throw "No existe: $path" }
  $ext = ([System.IO.Path]::GetExtension($path)).ToLowerInvariant()
  if ($ext -eq '.csv') { @(Import-Csv -LiteralPath $path -Encoding UTF8) }
  elseif ($ext -eq '.jsonl' -or $ext -eq '.ndjson') { $rows=New-Object System.Collections.Generic.List[object]; Get-Content -LiteralPath $path | % { if($_.Trim()){ try { $rows.Add($_ | ConvertFrom-Json) } catch {} } }; @($rows) }
  else { throw "Formato no soportado: $ext" }
}

function Action-Move-DuplicatesByHash {
  param(
    [Parameter(Mandatory)][object[]]$Rows,
    [Parameter(Mandatory)][string]$DestRoot,
    [ValidateSet('OldestMtime','Alphabetical')][string]$KeepBy = 'OldestMtime',
    [switch]$TakeOwnership
  )
  if (-not (Test-Path -LiteralPath $DestRoot)) { New-Item -ItemType Directory -Path $DestRoot | Out-Null }
  $DestRootResolved = (Resolve-Path -LiteralPath $DestRoot).Path

  function Ensure-Access([string]$p) {
    if (-not $TakeOwnership) { return }
    try { & takeown.exe /F "$p" /D Y | Out-Null } catch { }
    try { & icacls.exe  "$p" /grant Administrators:F /C   | Out-Null } catch { }
  }
  function UniqueDest([string]$dir,[string]$name){
    $t=Join-Path $dir $name; if (-not (Test-Path -LiteralPath $t)) { return $t }
    $stem=[System.IO.Path]::GetFileNameWithoutExtension($name); $ext=[System.IO.Path]::GetExtension($name); $i=1
    while($true){ $cand=Join-Path $dir ("{0} ({1}){2}" -f $stem,$i,$ext); if(-not (Test-Path -LiteralPath $cand)){return $cand}; $i++ }
  }
  function PickKeeper($items){
    $items=@($items)
    if($KeepBy -eq 'Alphabetical'){ return ($items | Sort-Object @{Expression='fullpath';Descending=$false})[0] }
    else {
      $withTimes=@( foreach($it in $items){ try{ $fi=Get-Item -LiteralPath $it.fullpath -ErrorAction Stop } catch{ continue }; [pscustomobject]@{ fullpath=$it.fullpath; mtime=$fi.LastWriteTimeUtc } } )
      if((@($withTimes).Count)-eq 0){ return ($items | Sort-Object fullpath)[0] }
      return ($withTimes | Sort-Object @{Expression='mtime';Descending=$false}, @{Expression='fullpath';Descending=$false})[0]
    }
  }

  $withHash = @($Rows | Where-Object { $_.sha256 -and $_.sha256 -ne "" -and $_.sha256 -ne "<err>" })
  $groups = $withHash | Group-Object sha256
  foreach($g in $groups){
    $items=@($g.Group | Where-Object { Test-Path -LiteralPath $_.fullpath -PathType Leaf })
    if($items.Count -le 1){ continue }
    $keeper=PickKeeper $items
    $groupDir=Join-Path $DestRoot $g.Name
    if(-not (Test-Path -LiteralPath $groupDir)){ New-Item -ItemType Directory -Path $groupDir | Out-Null }
    foreach($it in $items){
      $src=$it.fullpath
      if($src -eq $keeper.fullpath){ continue }
      try{
        $resolved=(Resolve-Path -LiteralPath $src -ErrorAction SilentlyContinue).Path
        if($resolved -and ($resolved -like "$DestRootResolved*")){ continue }
        Ensure-Access $src
        $dest=UniqueDest -dir $groupDir -name ([System.IO.Path]::GetFileName($src))
        Move-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
        Write-Host "[MOVIDO] $src -> $dest"
      } catch {
        Write-Host "[ERROR] No se pudo mover: $src  ($($_.Exception.Message))" -ForegroundColor Red
      }
    }
  }
  Write-Host "Destino: $DestRoot"
}

# --------------- GUI ---------------
if (-not $NoGui) {
  Add-Type -AssemblyName System.Windows.Forms | Out-Null
  Add-Type -AssemblyName System.Drawing | Out-Null

  $form = New-Object System.Windows.Forms.Form
  $form.Text = "New-FileMap v2"
  $form.WindowState = 'Maximized'
  $font = New-Object System.Drawing.Font("Segoe UI",9)
  $form.Font = $font

  function Add-Label($txt,$x,$y){ $l=New-Object System.Windows.Forms.Label; $l.Text=$txt; $l.Left=$x; $l.Top=$y; $l.AutoSize=$true; $form.Controls.Add($l); $l }
  function Add-Text($x,$y,$w){ $t=New-Object System.Windows.Forms.TextBox; $t.Left=$x; $t.Top=$y; $t.Width=$w; $t.Anchor='Top,Left,Right'; $form.Controls.Add($t); $t }
  function Add-Btn($txt,$x,$y,$w){ $b=New-Object System.Windows.Forms.Button; $b.Text=$txt; $b.Left=$x; $b.Top=$y; $b.Width=$w; $b.Anchor='Top,Right'; $form.Controls.Add($b); $b }
  function Add-Check($txt,$x,$y){ $c=New-Object System.Windows.Forms.CheckBox; $c.Text=$txt; $c.Left=$x; $c.Top=$y; $c.AutoSize=$true; $form.Controls.Add($c); $c }
  function Add-Drop($x,$y,$w,$items){ $d=New-Object System.Windows.Forms.ComboBox; $d.Left=$x; $d.Top=$y; $d.Width=$w; $d.DropDownStyle='DropDownList'; $items | % { [void]$d.Items.Add($_) }; $d.SelectedIndex=0; $form.Controls.Add($d); $d }
  function Add-Num($x,$y,$w,$min,$max,$val){ $n=New-Object System.Windows.Forms.NumericUpDown; $n.Left=$x; $n.Top=$y; $n.Width=$w; $n.Minimum=$min; $n.Maximum=$max; $n.Value=$val; $form.Controls.Add($n); $n }
  function Browse-Folder(){ $fb=New-Object System.Windows.Forms.FolderBrowserDialog; if($fb.ShowDialog() -eq 'OK'){ return $fb.SelectedPath } return $null }
  function Browse-OpenFile(){ $fd=New-Object System.Windows.Forms.OpenFileDialog; $fd.Filter="CSV/JSONL|*.csv;*.jsonl|Todos|*.*"; if($fd.ShowDialog() -eq 'OK'){ return $fd.FileName } return $null }

  Add-Label "Tema:" 20 12 | Out-Null
  $ddTheme = Add-Drop 65 8 120 @('Light','Dark'); $ddTheme.SelectedItem='Light'

  Add-Label "Ruta raíz:" 200 12 | Out-Null
  $tbRoot = Add-Text 275 8  900
  $btnRoot = Add-Btn "Examinar..." 1200 7 120
  $btnRoot.Add_Click({ $p=Browse-Folder; if($p){ $tbRoot.Text=$p } })

  Add-Label "Salida en:" 20 44 | Out-Null
  $tbOut = Add-Text 95 40  1030
  $btnOut = Add-Btn "Examinar..." 1200 39 120
  $btnOut.Add_Click({ $p=Browse-Folder; if($p){ $tbOut.Text=$p } })
  $tbOut.Text = Get-DesktopPath

  $cbTree   = Add-Check "Generar árbol (MD/TXT)" 20 80; $cbTree.Checked=$true
  Add-Label "Formato:" 210 82 | Out-Null
  $ddKind   = Add-Drop 270 78 70 @('md','txt')
  $cbCsv    = Add-Check "CSV" 360 80; $cbCsv.Checked=$true
  $cbJsonl  = Add-Check "JSONL" 420 80; $cbJsonl.Checked=$true

  $cbHash   = Add-Check "Hash" 20 110
  Add-Label "Algoritmo:" 80 112 | Out-Null
  $ddAlg    = Add-Drop 150 108 100 @('SHA256','MD5','SHA1','SHA384','SHA512'); $ddAlg.SelectedItem='SHA256'
  $cbOwner  = Add-Check "Dueño (Owner)" 270 110
  $cbHidden = Add-Check "Incluir ocultos/Sistema" 400 110
  $cbFollow = Add-Check "Seguir symlinks" 600 110

  Add-Label "MaxDepth:" 20 145 | Out-Null
  $numDepth = Add-Num 90 140 60 0 64 0
  Add-Label "BlockSize:" 165 145 | Out-Null
  $numBlock = Add-Num 235 140 70 100 500000 5000
  Add-Label "Progreso cada:" 320 145 | Out-Null
  $numProg  = Add-Num 420 140 70 50 1000000 500

  Add-Label "Excluir carpetas (coma):" 20 175 | Out-Null
  $tbExDirs = Add-Text 200 171 1000; $tbExDirs.Text=".git,node_modules,.venv,venv,env,.env,__pycache__"
  Add-Label "Excluir extensiones (coma):" 20 205 | Out-Null
  $tbExExt  = Add-Text 200 201 1000; $tbExExt.Text=".tmp,.log,.bak,.map,.pyc,.class"

  $cbTopSize = Add-Check "Top-N por tamaño" 20 231
  $cbTopAge  = Add-Check "Top-N por antigüedad" 160 231
  Add-Label "N:" 330 233 | Out-Null
  $numTop    = Add-Num 355 228 70 1 100000 100

  $grpY = 265
  $btnRun  = Add-Btn "Ejecutar" 20 $grpY 150
  $btnOpen = Add-Btn "Abrir carpeta de salida" 180 $grpY 210; $btnOpen.Enabled=$false
  $btnClose = Add-Btn "Cerrar" 400 $grpY 120; $btnClose.Add_Click({ $form.Close() })

  $pb = New-Object System.Windows.Forms.ProgressBar
  $pb.Left=20; $pb.Top=($grpY+35); $pb.Width=1200; $pb.Height=22; $pb.Minimum=0; $pb.Maximum=100; $pb.Anchor='Top,Left,Right'
  $form.Controls.Add($pb)
  $lbl = New-Object System.Windows.Forms.Label
  $lbl.Left=20; $lbl.Top=($grpY+62); $lbl.Width=1200; $lbl.Height=18; $lbl.AutoSize=$false; $lbl.Text=""; $lbl.Anchor='Top,Left,Right'
  $form.Controls.Add($lbl)

  $gy = $grpY + 95
  $sep = New-Object System.Windows.Forms.Label; $sep.Left=20; $sep.Top=$gy; $sep.Width=1200; $sep.Height=1; $sep.BorderStyle='Fixed3D'; $sep.Anchor='Top,Left,Right'; $form.Controls.Add($sep)
  $gy += 10
  $btnLoad = Add-Btn "Cargar resultados..." 20 $gy 180
  $btnMoveDup = Add-Btn "Mover duplicados por hash" 210 $gy 220; $btnMoveDup.Enabled=$false
  Add-Label "Destino acciones:" 450 ($gy+3) | Out-Null
  $tbActDest = Add-Text 560 $gy 640; $tbActDest.Text = (Join-Path (Get-DesktopPath) "Duplicates_SHA256")
  Add-Label "Conservar:" 20 ($gy+38) | Out-Null
  $ddKeep = Add-Drop 85 ($gy+34) 150 @('OldestMtime','Alphabetical')
  $cbOwn  = Add-Check "Tomar ownership" 250 ($gy+36)

  $ddTheme.Add_SelectedIndexChanged({ Apply-Theme $form $ddTheme.SelectedItem })
  Apply-Theme $form $ddTheme.SelectedItem

  function GUI-Run {
    $p = @{
      RootPath         = $tbRoot.Text.Trim()
      OutDir           = $tbOut.Text.Trim()
      IncludeTree      = $cbTree.Checked
      OutputKind       = $ddKind.SelectedItem
      EmitCsv          = $cbCsv.Checked
      EmitJsonl        = $cbJsonl.Checked
      IncludeHidden    = $cbHidden.Checked
      ComputeHash      = $cbHash.Checked
      HashAlgorithm    = $ddAlg.SelectedItem
      WithOwner        = $cbOwner.Checked
      BlockSize        = [int]$numBlock.Value
      ProgressInterval = [int]$numProg.Value
      MaxDepth         = [int]$numDepth.Value
      ExcludeDirs      = $tbExDirs.Text
      ExcludeExt       = $tbExExt.Text
      TopN             = [int]$numTop.Value
      TopBySize        = $cbTopSize.Checked
      TopByAge         = $cbTopAge.Checked
      FollowSymlinks   = $cbFollow.Checked
    }
    if (-not (Test-Path -LiteralPath $p.RootPath)) { [System.Windows.Forms.MessageBox]::Show("La ruta raíz no existe."); return }
    if ([string]::IsNullOrWhiteSpace($p.OutDir)) { $p.OutDir = Get-DesktopPath }

    foreach($c in $form.Controls){ try { $c.Enabled = $false } catch {} }
    $global:__gui = @{ pb=$pb; lbl=$lbl }
    $null = New-FileMapCore @p
    foreach($c in $form.Controls){ try { $c.Enabled = $true } catch {} }
    $btnOpen.Enabled = $true
    $btnMoveDup.Enabled = ($script:LastRows.Count -gt 0 -and ($script:LastRows | ? { $_.sha256 } | Measure-Object).Count -gt 0)
  }

  $btnRun.Add_Click({ GUI-Run })
  $btnOpen.Add_Click({ if ($tbOut.Text) { Start-Process explorer.exe $tbOut.Text } })
  $btnLoad.Add_Click({ $f=Browse-OpenFile; if($f){ try { $script:LastRows = @(Load-Results-From-File $f); $btnMoveDup.Enabled = ($script:LastRows.Count -gt 0) } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) } } })
  $btnMoveDup.Add_Click({
    try{
      $dest = $tbActDest.Text.Trim(); if(-not $dest){ $dest = Join-Path (Get-DesktopPath) "Duplicates_SHA256" }
      Action-Move-DuplicatesByHash -Rows $script:LastRows -DestRoot $dest -KeepBy $ddKeep.SelectedItem -TakeOwnership:$cbOwn.Checked
      [System.Windows.Forms.MessageBox]::Show("Listo. Revisa:`n$dest")
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) }
  })

  $form.Add_Shown({ $form.Activate() })
  [void]$form.ShowDialog()
  return
}

# --------------- CLI (NoGui) ---------------
if ($NoGui) {
  if ([string]::IsNullOrWhiteSpace($RootPath)) { throw "-RootPath es obligatorio en modo -NoGui" }
  if ([string]::IsNullOrWhiteSpace($OutDir))   { $OutDir = Get-DesktopPath }
  New-FileMapCore @PSBoundParameters | Out-Null
}
'@

Set-Content -LiteralPath $new -Encoding UTF8 -Value $code
Write-Host "✔ Script creado en: $new"