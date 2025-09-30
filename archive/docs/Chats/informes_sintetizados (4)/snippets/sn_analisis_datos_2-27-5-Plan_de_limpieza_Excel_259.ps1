# --- CREA New-FileMap.GUI.v6.4.ps1 EN TU CARPETA ---
$dstDir = 'C:\Users\VictorFabianVeraVill\Desktop\PowerShell'
$dst    = Join-Path $dstDir 'New-FileMap.GUI.v6.4.ps1'
if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

$code = @'
# New-FileMap.GUI.v6.4.ps1 — corrige selector de rutas (Carpeta…/Archivo… SIEMPRE visibles)
# UI con TableLayoutPanel (auto-ajuste DPI/ancho). Rutas SOLO con explorador (no editables).
# Mantiene funciones: FileMap→CSV (+extras opcionales), Acciones limitadas a C:\Users\, AutoStrings.

[CmdletBinding()] param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  $exe = (Get-Process -Id $PID).Path
  & $exe -NoProfile -ExecutionPolicy Bypass -STA -File $PSCommandPath
  exit
}

# ---------- Utilidades ----------
function Get-DesktopPath { try { [Environment]::GetFolderPath('Desktop') } catch { Join-Path $env:USERPROFILE 'Desktop' } }
function NowStamp { Get-Date -Format 'yyyyMMdd_HHmmss' }
function Ensure-Dir([string]$p){ if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function CsvEscape([string]$s){ if ($null -eq $s) { return '""' }; '"' + ($s -replace '"','""') + '"' }
function ToIso([datetime]$d){ if ($null -eq $d) { "" } else { $d.ToString("s") } }
function Simple-Mime([string]$ext){
  $e = ($ext ?? '').ToLower().TrimStart('.')
  $m=@{ txt='text/plain'; md='text/markdown'; csv='text/csv'; json='application/json'; xml='application/xml'
        pdf='application/pdf'; doc='application/msword'; docx='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        xls='application/vnd.ms-excel'; xlsx='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        ppt='application/vnd.ms-powerpoint'; pptx='application/vnd.openxmlformats-officedocument.presentationml.presentation'
        jpg='image/jpeg'; jpeg='image/jpeg'; png='image/png'; gif='image/gif'; webp='image/webp'; bmp='image/bmp'
        zip='application/zip'; '7z'='application/x-7z-compressed'; rar='application/vnd.rar'
        exe='application/vnd.microsoft.portable-executable'; dll='application/x-msdownload'
        ps1='text/x-powershell'; py='text/x-python'; js='text/javascript'; html='text/html' }
  return $m[$e]
}
function Atomic-WriteCsv([string]$dest,[string[]]$lines){
  $dir = Split-Path -Path $dest -Parent; Ensure-Dir $dir
  $tmp = "$dest.tmp"; $bak = "$dest.bak"
  if (Test-Path -LiteralPath $dest) { try { Move-Item $dest $bak -Force -ErrorAction Stop } catch {} }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $sw = New-Object System.IO.StreamWriter($tmp,$false,$enc)
  foreach($ln in $lines){ $sw.WriteLine($ln) }
  $sw.Flush(); $sw.Dispose()
  Move-Item $tmp $dest -Force
  $dest
}
function Ensure-Under-Users([string]$p){
  $full=[System.IO.Path]::GetFullPath($p); $allowed=[System.IO.Path]::GetFullPath('C:\Users\')
  $full.StartsWith($allowed,[System.StringComparison]::OrdinalIgnoreCase)
}
function File-SHA256([string]$p){ try { (Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch { "" } }
function RelPath([string]$base,[string]$full){
  try{
    $b = New-Object System.Uri(($base.TrimEnd('\')+'\'))
    $u = New-Object System.Uri($full)
    [System.Uri]::UnescapeDataString($b.MakeRelativeUri($u).ToString()).Replace('/','\')
  } catch { $full }
}

# ---------- FileMap → CSV ----------
function New-FileMapCsv {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RootPath, [Parameter(Mandatory)][string]$OutDir,
    [switch]$IncludeHidden,[switch]$Recurse,[string[]]$ExcludeExt=@('.tmp','.log','.bak','.map','.pyc','.class'),
    [int]$BlockSize=5000,[int]$ProgressEvery=500,
    [switch]$ComputeHash,[ValidateSet('SHA256','SHA1','SHA384','SHA512')][string]$HashAlgorithm='SHA256',
    [switch]$AddOwner,[switch]$AddAttributes,[switch]$AddADS,[switch]$AddReparse,[switch]$AddSignature,[switch]$AddZoneId
  )
  if (-not (Test-Path -LiteralPath $RootPath)) { throw "No existe: $RootPath" }
  Ensure-Dir $OutDir
  $rootItem = Get-Item -LiteralPath $RootPath -ErrorAction Stop
  $base = if ($rootItem.PSIsContainer) { $RootPath } else { Split-Path -Parent $RootPath }
  $rootName = Split-Path -Leaf $base; if ([string]::IsNullOrWhiteSpace($rootName)) { $rootName = ($base -replace '[:\\\/]','_') }
  $csv = Join-Path $OutDir ("FileList_{0}_{1}.csv" -f ($rootName -replace '[^\w\.-]','_'), (NowStamp))

  if ($rootItem.PSIsContainer){
    $args=@{ LiteralPath=$RootPath; File=$true; Force=$true; ErrorAction='SilentlyContinue' }
    if ($Recurse){ $args['Recurse']=$true }
    $items=@(Get-ChildItem @args)
  } else { $items=@($rootItem) }

  function Pass($fi){
    if (-not $IncludeHidden){
      if ($fi.Attributes.HasFlag([IO.FileAttributes]::Hidden) -or $fi.Attributes.HasFlag([IO.FileAttributes]::System)) { return $false }
    }
    if ($fi.PSIsContainer){ return $false }
    $ext = $fi.Extension.ToLower()
    if ($ExcludeExt -and ($ExcludeExt -contains $ext)){ return $false }
    $true
  }

  $items=@($items | Where-Object { Pass $_ })

  $common = @('relpath','name','ext','is_dir','size_bytes','mtime_iso','ctime_iso','atime_iso','mime','sha256','depth','top','parent')
  $extras = @()
  if ($AddOwner)      { $extras += 'owner' }
  if ($AddAttributes) { $extras += 'attributes' }
  if ($AddADS)        { $extras += 'streams_count' }
  if ($AddReparse)    { $extras += 'is_reparse' }
  if ($AddSignature)  { $extras += 'sign_status','publisher' }
  if ($AddZoneId)     { $extras += 'zone_id' }
  $headers = @($common + $extras) -join ','
  $lines=@($headers)

  $total=$items.Count; $done=0
  foreach ($batch in $items | ForEach-Object -Begin { $buf=@() } -Process { $buf+=$_; if($buf.Count -ge $BlockSize){ ,$buf; $buf=@() } } -End { if($buf.Count){ ,$buf } }){
    foreach($fi in $batch){
      $done++
      if (($done % [Math]::Max(1,$ProgressEvery)) -eq 0 -or $done -eq $total){
        $pct = if($total){ [int](($done/$total)*100) } else { 100 }
        Write-Progress -Activity 'Mapeando' -Status "$done / $total" -PercentComplete $pct
      }
      $full=$fi.FullName
      $rel = RelPath $base $full; if ([string]::IsNullOrWhiteSpace($rel)) { $rel='.' }
      $ext=$fi.Extension.ToLower().TrimStart('.')
      $row = @(
        CsvEscape $rel; CsvEscape $fi.Name; CsvEscape $ext; "False"; "$([int64]$fi.Length)";
        CsvEscape (ToIso $fi.LastWriteTime); CsvEscape (ToIso $fi.CreationTime); CsvEscape (ToIso $fi.LastAccessTime);
        CsvEscape (Simple-Mime $ext);
        CsvEscape ($(if($ComputeHash){ (Get-FileHash -LiteralPath $full -Algorithm $HashAlgorithm -ErrorAction SilentlyContinue).Hash.ToLower() } else { "" }));
        "$((($rel -split '\\').Length)-1)"; CsvEscape (($rel -split '\\' | Select-Object -First 1));
        CsvEscape ((Split-Path $rel -Parent) ?? "")
      )

      if ($AddOwner)      { $row += (CsvEscape (try{ (Get-Acl -LiteralPath $full -ErrorAction Stop).Owner }catch{""})) }
      if ($AddAttributes) { $row += (CsvEscape ($fi.Attributes.ToString().Replace(', ','|'))) }
      if ($AddADS)        { $row += ("" + (try{ (Get-Item -LiteralPath $full -Stream * -ErrorAction Stop | Measure-Object).Count }catch{0})) }
      if ($AddReparse)    { $row += ("" + $fi.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) }
      if ($AddSignature)  {
        if ($ext -in @('exe','dll')) {
          $sig = try { Get-AuthenticodeSignature -FilePath $full -ErrorAction Stop } catch { $null }
          $row += (CsvEscape (if($sig){$sig.Status.ToString()}else{''}))
          $row += (CsvEscape (if($sig -and $sig.SignerCertificate){$sig.SignerCertificate.Subject}else{''}))
        } else { $row += '""'; $row += '""' }
      }
      if ($AddZoneId)     {
        $z = try{ $zpath="$full`:Zone.Identifier"; if(Test-Path -LiteralPath $zpath){ (Get-Content -LiteralPath $zpath | ?{$_ -match '^ZoneId='} | % {$_ -replace 'ZoneId=',''} | Select-Object -First 1) }else{""} }catch{""}
        $row += (CsvEscape $z)
      }

      $lines += ($row -join ',')
    }
  }
  $final = Atomic-WriteCsv $csv $lines
  Write-Progress -Activity 'Mapeando' -Completed
  $final
}

# ---------- AutoStrings (igual que v6.2/v6.3, abreviado) ----------
Add-Type -AssemblyName System.Runtime
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}
function File-SHA([string]$p){ try{ (Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() }catch{""} }
function Test-UTF8-Run([byte[]]$b,[int]$i){ $n=$b.Length;$start=$i;while($i -lt $n){$x=$b[$i];if($x -le 0x7F){$i++}elseif(($x -band 0xE0)-eq 0xC0){if($i+1 -ge $n -or ($b[$i+1]-band 0xC0)-ne 0x80){break};$i+=2}elseif(($x -band 0xF0)-eq 0xE0){if($i+2 -ge $n -or ($b[$i+1]-band 0xC0)-ne 0x80 -or ($b[$i+2]-band 0xC0)-ne 0x80){break};$i+=3}elseif(($x -band 0xF8)-eq 0xF0){if($i+3 -ge $n -or ($b[$i+1]-band 0xC0)-ne 0x80 -or ($b[$i+2]-band 0xC0)-ne 0x80 -or ($b[$i+3]-band 0xC0)-ne 0x80){break};$i+=4}else{break};if($i -lt $n -and $b[$i] -in 0x00..0x08 + 0x0B + 0x0C + 0x0E..0x1F){break}};$len=$i-$start;if($len -ge 8){@{ok=$true;len=$len}}else{@{ok=$false;len=0}}}
function Extract-UTF8([byte[]]$bytes){$r=New-Object 'System.Collections.Generic.List[object]';$i=0;$n=$bytes.Length;while($i -lt $n){$p=Test-UTF8-Run $bytes $i;if($p.ok){$len=$p.len;try{$t=[Text.Encoding]::UTF8.GetString($bytes,$i,$len);if($t.Length -ge 4 -and $t -match '\S{2,}'){$r.Add([pscustomobject]@{encoding='utf8';offset=$i;byte_len=$len;text=$t;confidence=0.9})}}catch{};$i+=$len}else{$i++}} ,$r}
function Extract-UTF16LE([byte[]]$b){$r=New-Object 'System.Collections.Generic.List[object]';$i=0;$n=$b.Length;while($i -lt $n-1){$s=$i;while($i -lt $n-1){$lo=$b[$i];$hi=$b[$i+1];if($lo -eq 0 -and $hi -eq 0){break};if($lo -in 0x00..0x08+0x0B+0x0C+0x0E..0x1F -and $hi -eq 0){break};$i+=2};$len=$i-$s;if($len -ge 8){try{$t=[Text.Encoding]::Unicode.GetString($b,$s,$len);if($t.Length -ge 4){$r.Add([pscustomobject]@{encoding='utf16le';offset=$s;byte_len=$len;text=$t;confidence=0.9})}}catch{}}else{$i++}} ,$r}
function Extract-UTF16BE([byte[]]$b){$r=New-Object 'System.Collections.Generic.List[object]';$i=1;$n=$b.Length;while($i -lt $n){$s=$i-1;while($i -lt $n){$hi=$b[$i-1];$lo=$b[$i];if($hi -eq 0 -and $lo -eq 0){break};if($hi -in 0x00..0x08+0x0B+0x0C+0x0E..0x1F -and $lo -eq 0){break};$i+=2};$len=$i-$s;if($len -ge 8){try{$t=[Text.Encoding]::BigEndianUnicode.GetString($b,$s,$len);if($t.Length -ge 4){$r.Add([pscustomobject]@{encoding='utf16be';offset=$s;byte_len=$len;text=$t;confidence=0.85})}}catch{}}else{$i++}} ,$r}
function Extract-CP936([byte[]]$b){$enc=[Text.Encoding]::GetEncoding(936);$r=New-Object 'System.Collections.Generic.List[object]';$i=0;$n=$b.Length;while($i -lt $n-1){$b1=$b[$i];$b2=$b[$i+1];if(($b1 -ge 0x81 -and $b1 -le 0xFE) -and ($b2 -ge 0x40 -and $b2 -le 0xFE -and $b2 -ne 0x7F)){$s=$i;$p=0;while($i -lt $n-1){$x1=$b[$i];$x2=$b[$i+1];if(($x1 -ge 0x81 -and $x1 -le 0xFE) -and ($x2 -ge 0x40 -and $x2 -le 0xFE -and $x2 -ne 0x7F)){$p++;$i+=2}else{break}};$len=$i-$s;if($p -ge 2){try{$t=$enc.GetString($b,$s,$len);if($t -match '[\p{IsCJKUnifiedIdeographs}]'){$r.Add([pscustomobject]@{encoding='cp936';offset=$s;byte_len=$len;text=$t;confidence=0.9})}}catch{}}}else{$i++}} ,$r}
function Is-GB18030-4($a,$b,$c,$d){($a -ge 0x81 -and $a -le 0xFE) -and ($b -ge 0x30 -and $b -le 0x39) -and ($c -ge 0x81 -and $c -le 0xFE) -and ($d -ge 0x30 -and $d -le 0x39)}
function Extract-GB18030([byte[]]$b){$enc=[Text.Encoding]::GetEncoding(54936);$r=New-Object 'System.Collections.Generic.List[object]';$i=0;$n=$b.Length;while($i -lt $n){$s=$i;$ok=$false;if($b[$i] -le 0x7F){while($i -lt $n -and $b[$i] -le 0x7F){$i++};$ok=($i-$s -ge 6)}elseif($i+1 -lt $n -and ($b[$i] -ge 0x81 -and $b[$i] -le 0xFE) -and ($b[$i+1] -ge 0x40 -and $b[$i+1] -le 0xFE -and $b[$i+1] -ne 0x7F)){$i+=2;while($i+1 -lt $n -and ($b[$i] -ge 0x81 -and $b[$i] -le 0xFE) -and ($b[$i+1] -ge 0x40 -and $b[$i+1] -le 0xFE -and $b[$i+1] -ne 0x7F)){$i+=2};$ok=($i-$s -ge 4)}elseif($i+3 -lt $n -and (Is-GB18030-4 $b[$i] $b[$i+1] $b[$i+2] $b[$i+3])){$i+=4;while($i+3 -lt $n -and (Is-GB18030-4 $b[$i] $b[$i+1] $b[$i+2] $b[$i+3])){$i+=4};$ok=($i-$s -ge 8)}else{$i++};if($ok){$len=$i-$s;try{$t=$enc.GetString($b,$s,$len);if($t -match '[\p{IsCJKUnifiedIdeographs}]'){$r.Add([pscustomobject]@{encoding='gb18030';offset=$s;byte_len=$len;text=$t;confidence=0.95})}}catch{}}} ,$r}
function Classify-Lang([string]$t){ if ($t -match '[\p{IsCJKUnifiedIdeographs}]'){ 'zh' } elseif ($t -match '[A-Za-z]{4,}'){ 'en' } else { 'heuristic' } }
function Rel([string]$base,[string]$full){ try{ $b=New-Object Uri(($base.TrimEnd('\')+'\')); $u=New-Object Uri($full); [Uri]::UnescapeDataString($b.MakeRelativeUri($u).ToString()).Replace('/','\') }catch{$full} }
function AutoStrings([string]$target,[switch]$Recurse,[string]$OutDir){
  if (-not (Test-Path -LiteralPath $target)) { throw "No existe: $target" }
  if (-not $OutDir){ $OutDir = Join-Path (Split-Path -Parent $PSCommandPath) "_out/ysd-catalog" }
  Ensure-Dir $OutDir
  $ts=NowStamp; $csv=Join-Path $OutDir "ysd-catalog_${ts}.csv"
  $rows = New-Object System.Collections.Generic.List[string]
  $rows.Add('file_path,relpath,name,ext,size_bytes,sha256,encoding,offset,byte_len,classifier,confidence,text,timestamp')
  $root = Get-Item -LiteralPath $target
  if ($root.PSIsContainer){
    $args=@{ LiteralPath=$target; File=$true; Force=$true; ErrorAction='SilentlyContinue' }
    if ($Recurse){ $args['Recurse']=$true }
    $files = @(Get-ChildItem @args | ? { $_.Extension -match '\.(exe|dll|ysd|dcy)$' })
  } else { $files=@($root) }
  foreach($f in $files){
    [byte[]]$bytes = try { [IO.File]::ReadAllBytes($f.FullName) } catch { @() }
    if ($bytes.Length -eq 0){ continue }
    $sha = File-SHA $f.FullName
    $found = @(); $found += Extract-UTF8 $bytes; $found += Extract-UTF16LE $bytes; $found += Extract-UTF16BE $bytes; $found += Extract-CP936 $bytes; $found += Extract-GB18030 $bytes
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($s in ($found | Sort-Object offset)){
      if (-not $s){ continue }
      $key="$($s.offset)|$([string]::Copy($s.text))"
      if ($seen.Add($key)){
        $cls = Classify-Lang $s.text
        $rel = if ($root.PSIsContainer){ (Rel $target $f.FullName) } else { $f.Name }
        $line = @(
          CsvEscape $f.FullName; CsvEscape $rel; CsvEscape $f.Name; CsvEscape ($f.Extension.TrimStart('.').ToLower());
          "$($f.Length)"; CsvEscape $sha; CsvEscape $s.encoding; "$($s.offset)"; "$($s.byte_len)";
          CsvEscape $cls; "$([Math]::Round(($s.confidence ?? 0.85),2))";
          CsvEscape ($s.text.Substring(0,[Math]::Min($s.text.Length,600)));
          CsvEscape (Get-Date -Format 's')
        ) -join ','
        $rows.Add($line)
      }
    }
  }
  Atomic-WriteCsv $csv $rows
}

# ---------- UI ----------
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Drawing | Out-Null

function Apply-Theme($ctrl,$mode){
  $dark = ($mode -eq 'Dark')
  $bg  = if ($dark) {[Drawing.Color]::FromArgb(18,18,18)} else {[SystemColors]::Control}
  $fg  = if ($dark) {[Drawing.Color]::White} else {[Drawing.Color]::Black}
  $tb  = if ($dark) {[Drawing.Color]::FromArgb(32,32,32)} else {[Drawing.Color]::White}
  $bd  = if ($dark) {[Drawing.Color]::FromArgb(70,70,70)} else {[Drawing.Color]::FromArgb(180,180,180)}
  $ctrl.BackColor=$bg; $ctrl.ForeColor=$fg
  foreach($c in $ctrl.Controls){
    try{
      $c.ForeColor=$fg
      if($c -is [Windows.Forms.TextBox]){ $c.ReadOnly=$true; $c.BackColor=$tb; $c.BorderStyle='FixedSingle'; $c.TabStop=$false }
      if($c -is [Windows.Forms.Button]){ $c.FlatStyle='Flat'; $c.FlatAppearance.BorderColor=$bd }
      if($c -is [Windows.Forms.ComboBox]){ $c.FlatStyle='Flat'; $c.BackColor=$tb }
    }catch{}
    if($c.Controls.Count){ Apply-Theme $c $mode }
  }
}

function Pick-Folder(){
  try { $fbd = New-Object Windows.Forms.FolderBrowserDialog; $fbd.Description='Elige una carpeta'; $fbd.RootFolder='MyComputer'
        if($fbd.ShowDialog() -eq 'OK'){ return $fbd.SelectedPath } } catch {}
  try { $sh = New-Object -ComObject Shell.Application; $f = $sh.BrowseForFolder(0,'Elige una carpeta',0,17); if($f){ return $f.Self.Path } } catch {}
  return $null
}
function Pick-File($filter="Todos|*.*"){ $fd=New-Object Windows.Forms.OpenFileDialog; $fd.Filter=$filter; $fd.Multiselect=$false; if($fd.ShowDialog() -eq 'OK'){ $fd.FileName } }

$form = New-Object Windows.Forms.Form
$form.Text = 'New-FileMap v6.4 (CSV + AutoStrings)'
$form.WindowState = 'Maximized'
$form.Font = New-Object Drawing.Font('Segoe UI',10.5)

# Tema
$lblTheme = New-Object Windows.Forms.Label; $lblTheme.Text='Tema:'; $lblTheme.AutoSize=$true; $lblTheme.Margin='8,10,4,4'
$ddTheme  = New-Object Windows.Forms.ComboBox; $ddTheme.DropDownStyle='DropDownList'; @('Light','Dark') | % { [void]$ddTheme.Items.Add($_) }; $ddTheme.SelectedItem='Dark'
$flTop    = New-Object Windows.Forms.FlowLayoutPanel; $flTop.Dock='Top'; $flTop.Height=36; $flTop.WrapContents=$false; $flTop.AutoSize=$true; $flTop.AutoSizeMode='GrowAndShrink'
$flTop.Controls.AddRange(@($lblTheme,$ddTheme))
$form.Controls.Add($flTop)

# Grupo 1
$gb1 = New-Object Windows.Forms.GroupBox; $gb1.Text='1) FileMap → CSV'; $gb1.Dock='Top'; $gb1.Height=300
$tlp = New-Object Windows.Forms.TableLayoutPanel
$tlp.Dock='Fill'; $tlp.Padding='8,8,8,8'; $tlp.ColumnCount=4; $tlp.RowCount=6
$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',90)))
$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',110)))
$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',110)))

# Fila Ruta raíz (Label + TextBox + [Carpeta…] + [Archivo…])
$lblRoot = New-Object Windows.Forms.Label; $lblRoot.Text='Ruta raíz:'; $lblRoot.AutoSize=$true
$tbRoot  = New-Object Windows.Forms.TextBox; $tbRoot.Dock='Fill'
$btnRootFolder = New-Object Windows.Forms.Button; $btnRootFolder.Text='Carpeta…'
$btnRootFile   = New-Object Windows.Forms.Button; $btnRootFile.Text='Archivo…'
$btnRootFolder.Add_Click({ $p=Pick-Folder; if($p){ $tbRoot.Text=$p } })
$btnRootFile.Add_Click({ $p=Pick-File 'Todos|*.*'; if($p){ $tbRoot.Text=$p } })
$tlp.Controls.Add($lblRoot,0,0); $tlp.Controls.Add($tbRoot,1,0); $tlp.Controls.Add($btnRootFolder,2,0); $tlp.Controls.Add($btnRootFile,3,0)

# Fila Salida
$lblOut = New-Object Windows.Forms.Label; $lblOut.Text='Salida en:'; $lblOut.AutoSize=$true
$tbOut  = New-Object Windows.Forms.TextBox; $tbOut.Text=(Get-DesktopPath); $tbOut.Dock='Fill'
$btnOut = New-Object Windows.Forms.Button; $btnOut.Text='Examinar…'; $btnOut.Add_Click({ $p=Pick-Folder; if($p){ $tbOut.Text=$p } })
$tlp.Controls.Add($lblOut,0,1); $tlp.Controls.Add($tbOut,1,1); $tlp.SetColumnSpan($tbOut,2); $tlp.Controls.Add($btnOut,3,1)

# Fila opciones (ocultos/recursivo/bloques/progreso/hash)
$pnOpts = New-Object Windows.Forms.FlowLayoutPanel; $pnOpts.Dock='Fill'; $pnOpts.WrapContents=$false; $pnOpts.AutoSize=$true
$cbHidden = New-Object Windows.Forms.CheckBox; $cbHidden.Text='Incluir ocultos/Sistema'
$cbRecur  = New-Object Windows.Forms.CheckBox; $cbRecur.Text='Recursivo'; $cbRecur.Checked=$true
$lblB = New-Object Windows.Forms.Label; $lblB.Text='BlockSize:'; $numB=New-Object Windows.Forms.NumericUpDown; $numB.Minimum=100; $numB.Maximum=500000; $numB.Value=5000; $numB.Width=90
$lblP = New-Object Windows.Forms.Label; $lblP.Text='Progreso cada:'; $numP=New-Object Windows.Forms.NumericUpDown; $numP.Minimum=50; $numP.Maximum=1000000; $numP.Value=500; $numP.Width=90
$cbHash = New-Object Windows.Forms.CheckBox; $cbHash.Text='Hash'
$lblAlg = New-Object Windows.Forms.Label; $lblAlg.Text='Algoritmo:'; $ddAlg=New-Object Windows.Forms.ComboBox; $ddAlg.DropDownStyle='DropDownList'; @('SHA256','SHA1','SHA384','SHA512')|%{[void]$ddAlg.Items.Add($_)}; $ddAlg.SelectedItem='SHA256'; $ddAlg.Width=100
$pnOpts.Controls.AddRange(@($cbHidden,$cbRecur,$lblB,$numB,$lblP,$numP,$cbHash,$lblAlg,$ddAlg))
$tlp.Controls.Add((New-Object Windows.Forms.Label),0,2); $tlp.Controls.Add($pnOpts,1,2); $tlp.SetColumnSpan($pnOpts,3)

# Fila Exclusiones
$lblEx = New-Object Windows.Forms.Label; $lblEx.Text='Excluir extensiones:'; $lblEx.AutoSize=$true
$txtEx = New-Object Windows.Forms.TextBox; $txtEx.Dock='Fill'
$btnEx = New-Object Windows.Forms.Button; $btnEx.Text='Configurar…'
$defaultExt = @('.tmp','.log','.bak','.map','.pyc','.class'); $txtEx.Text=($defaultExt -join ',')
$btnEx.Add_Click({
  $dlg=New-Object Windows.Forms.Form; $dlg.Text='Exclusiones'; $dlg.Width=420; $dlg.Height=420; $dlg.StartPosition='CenterParent'
  $clb=New-Object Windows.Forms.CheckedListBox; $clb.CheckOnClick=$true; $clb.Left=10; $clb.Top=10; $clb.Width=380; $clb.Height=300
  foreach($e in @('.tmp','.log','.bak','.map','.pyc','.class','.7z','.rar','.iso','.dll','.obj','.pdb')){ [void]$clb.Items.Add($e, ($txtEx.Text -split ',' | %{$_.Trim()} | ? {$_} | %{$_ -eq $e}) -contains $true) }
  $tbC=New-Object Windows.Forms.TextBox; $tbC.Left=10; $tbC.Top=320; $tbC.Width=380
  $ok=New-Object Windows.Forms.Button; $ok.Text='Aceptar'; $ok.Left=230; $ok.Top=350; $cancel=New-Object Windows.Forms.Button; $cancel.Text='Cancelar'; $cancel.Left=315; $cancel.Top=350
  $ok.Add_Click({ $sel=@(); for($i=0;$i -lt $clb.Items.Count;$i++){ if($clb.GetItemChecked($i)){ $sel+=[string]$clb.Items[$i] } }; if($tbC.Text.Trim()){ $sel += ($tbC.Text.Split(',') | %{$_.Trim()} | ?{$_}) }; $txtEx.Text=($sel | Select-Object -Unique -join ','); $dlg.Close() })
  $cancel.Add_Click({ $dlg.Close() }); $dlg.Controls.AddRange(@($clb,$tbC,$ok,$cancel)); [void]$dlg.ShowDialog($form)
})
$tlp.Controls.Add($lblEx,0,3); $tlp.Controls.Add($txtEx,1,3); $tlp.SetColumnSpan($txtEx,2); $tlp.Controls.Add($btnEx,3,3)

# Fila extras
$pnX = New-Object Windows.Forms.FlowLayoutPanel; $pnX.Dock='Fill'; $pnX.WrapContents=$false; $pnX.AutoSize=$true
$cbOwn=New-Object Windows.Forms.CheckBox; $cbOwn.Text='Owner'
$cbAttr=New-Object Windows.Forms.CheckBox; $cbAttr.Text='Attributes'
$cbADS=New-Object Windows.Forms.CheckBox; $cbADS.Text='ADS'
$cbRep=New-Object Windows.Forms.CheckBox; $cbRep.Text='Reparse'
$cbSig=New-Object Windows.Forms.CheckBox; $cbSig.Text='Firma (EXE/DLL)'
$cbZon=New-Object Windows.Forms.CheckBox; $cbZon.Text='ZoneId'
$pnX.Controls.AddRange(@($cbOwn,$cbAttr,$cbADS,$cbRep,$cbSig,$cbZon))
$tlp.Controls.Add((New-Object Windows.Forms.Label),0,4); $tlp.Controls.Add($pnX,1,4); $tlp.SetColumnSpan($pnX,3)

# Fila botones
$btnMap = New-Object Windows.Forms.Button; $btnMap.Text='Mapear → CSV'; $btnOpen=New-Object Windows.Forms.Button; $btnOpen.Text='Abrir carpeta de salida'; $btnOpen.Enabled=$false
$flBtns=New-Object Windows.Forms.FlowLayoutPanel; $flBtns.Dock='Fill'; $flBtns.WrapContents=$false; $flBtns.AutoSize=$true; $flBtns.Controls.AddRange(@($btnMap,$btnOpen))
$pb = New-Object Windows.Forms.ProgressBar; $pb.Dock='Fill'
$tlp.Controls.Add((New-Object Windows.Forms.Label),0,5); $tlp.Controls.Add($flBtns,1,5); $tlp.SetColumnSpan($flBtns,2); $tlp.Controls.Add($pb,3,5)

$gb1.Controls.Add($tlp); $form.Controls.Add($gb1)

# Grupo 2 (Acciones)
$gb2 = New-Object Windows.Forms.GroupBox; $gb2.Text='2) Acciones (seguras en C:\Users\)'; $gb2.Dock='Top'; $gb2.Height=120
$tlp2 = New-Object Windows.Forms.TableLayoutPanel; $tlp2.Dock='Fill'; $tlp2.Padding='8,8,8,8'; $tlp2.ColumnCount=4
$tlp2.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',170)))
$tlp2.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',210)))
$tlp2.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
$tlp2.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',120)))
$btnLoad = New-Object Windows.Forms.Button; $btnLoad.Text='Cargar CSV...'
$btnDup  = New-Object Windows.Forms.Button; $btnDup.Text='Mover duplicados (hash)'; $btnDup.Enabled=$false
$lblDest = New-Object Windows.Forms.Label; $lblDest.Text='Destino acciones:'; $lblDest.AutoSize=$true
$tbDest  = New-Object Windows.Forms.TextBox; $tbDest.Text=(Join-Path (Get-DesktopPath) 'Duplicates_SHA256'); $tbDest.Dock='Fill'
$btnDest = New-Object Windows.Forms.Button; $btnDest.Text='Examinar…'; $btnDest.Add_Click({ $p=Pick-Folder; if($p){ $tbDest.Text=$p } })
$tlp2.Controls.Add($btnLoad,0,0); $tlp2.Controls.Add($btnDup,1,0); $tlp2.Controls.Add($lblDest,0,1)
$tlp2.Controls.Add($tbDest,1,1); $tlp2.SetColumnSpan($tbDest,2); $tlp2.Controls.Add($btnDest,3,1)
$gb2.Controls.Add($tlp2); $form.Controls.Add($gb2)

# Grupo 3 (Analizador)
$gb3 = New-Object Windows.Forms.GroupBox; $gb3.Text='3) Analizador de binarios (AutoStrings)'; $gb3.Dock='Fill'
$tlp3 = New-Object Windows.Forms.TableLayoutPanel; $tlp3.Dock='Fill'; $tlp3.Padding='8,8,8,8'; $tlp3.ColumnCount=4
$tlp3.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',90)))
$tlp3.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
$tlp3.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',110)))
$tlp3.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',110)))
$lblObj = New-Object Windows.Forms.Label; $lblObj.Text='Objetivo:'; $lblObj.AutoSize=$true
$tbXT  = New-Object Windows.Forms.TextBox; $tbXT.Dock='Fill'
$btnXTFile = New-Object Windows.Forms.Button; $btnXTFile.Text='Archivo…'
$btnXTDir  = New-Object Windows.Forms.Button; $btnXTDir.Text='Carpeta…'
$btnXTFile.Add_Click({ $p=Pick-File 'EXE/DLL/YSD/DCY|*.exe;*.dll;*.ysd;*.dcy|Todos|*.*'; if($p){ $tbXT.Text=$p } })
$btnXTDir.Add_Click({ $p=Pick-Folder; if($p){ $tbXT.Text=$p } })
$tlp3.Controls.Add($lblObj,0,0); $tlp3.Controls.Add($tbXT,1,0); $tlp3.Controls.Add($btnXTFile,2,0); $tlp3.Controls.Add($btnXTDir,3,0)
$cbRecX = New-Object Windows.Forms.CheckBox; $cbRecX.Text='Recurse (subcarpetas)'; $cbRecX.Checked=$true
$btnRunX = New-Object Windows.Forms.Button; $btnRunX.Text='Ejecutar analizador → CSV'
$tlp3.Controls.Add((New-Object Windows.Forms.Label),0,1); $tlp3.Controls.Add($cbRecX,1,1); $tlp3.Controls.Add($btnRunX,1,2)
$gb3.Controls.Add($tlp3); $form.Controls.Add($gb3)

# Tema
$ddTheme.Add_SelectedIndexChanged({ Apply-Theme $form $ddTheme.SelectedItem })
Apply-Theme $form $ddTheme.SelectedItem

# Estado
$global:__lastRows=@(); $global:__lastBase=""

# Eventos
$btnMap.Add_Click({
  if (-not $tbRoot.Text.Trim()){ [Windows.Forms.MessageBox]::Show('Selecciona ruta (Carpeta o Archivo).'); return }
  if (-not (Test-Path -LiteralPath $tbRoot.Text)){ [Windows.Forms.MessageBox]::Show('La ruta no existe.'); return }
  if (-not (Test-Path -LiteralPath $tbOut.Text)){ [Windows.Forms.MessageBox]::Show('Selecciona carpeta de salida.'); return }
  foreach($c in $form.Controls){ try{$c.Enabled=$false}catch{} }
  try{
    $csv = New-FileMapCsv -RootPath $tbRoot.Text.Trim() -OutDir $tbOut.Text.Trim() -IncludeHidden:$cbHidden.Checked `
          -Recurse:$cbRecur.Checked -ExcludeExt ($txtEx.Text -split ',' | %{$_.Trim()} | ?{$_}) -BlockSize $numB.Value -ProgressEvery $numP.Value `
          -ComputeHash:$cbHash.Checked -HashAlgorithm $ddAlg.SelectedItem `
          -AddOwner:$cbOwn.Checked -AddAttributes:$cbAttr.Checked -AddADS:$cbADS.Checked -AddReparse:$cbRep.Checked -AddSignature:$cbSig.Checked -AddZoneId:$cbZon.Checked
    $rootItem = Get-Item -LiteralPath $tbRoot.Text
    if ($rootItem.PSIsContainer) { $global:__lastBase = $tbRoot.Text } else { $global:__lastBase = Split-Path -Parent $tbRoot.Text }
    $global:__lastRows = @(Import-Csv -LiteralPath $csv -Encoding UTF8)
    $btnOpen.Enabled=$true; $btnDup.Enabled=($global:__lastRows | ? { $_.sha256 } | Measure-Object).Count -gt 0
    [Windows.Forms.MessageBox]::Show("CSV generado:`n$csv`nFilas: $($global:__lastRows.Count)")
  } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message) }
  foreach($c in $form.Controls){ try{$c.Enabled=$true}catch{} }
})
$btnOpen.Add_Click({ if ($tbOut.Text){ Start-Process explorer.exe $tbOut.Text } })

function Browse-CSV(){ $dlg=New-Object Windows.Forms.OpenFileDialog; $dlg.Filter='CSV|*.csv|Todos|*.*'; if($dlg.ShowDialog() -eq 'OK'){ $dlg.FileName } }
$btnLoad.Add_Click({
  $f = Browse-CSV; if ($f){ try{ $global:__lastRows=@(Import-Csv -LiteralPath $f -Encoding UTF8); $btnDup.Enabled=($global:__lastRows | ? { $_.sha256 } | Measure-Object).Count -gt 0 } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message) } }
})
$btnDup.Add_Click({
  try{
    if ($global:__lastRows.Count -eq 0){ [Windows.Forms.MessageBox]::Show('Carga o genera un CSV primero.'); return }
    if (-not (Ensure-Under-Users $tbDest.Text)){ [Windows.Forms.MessageBox]::Show('Acciones limitadas a C:\Users\. Cambia el destino.'); return }
    $groups = $global:__lastRows | ? { $_.sha256 } | Group-Object sha256
    foreach($g in $groups){
      $items=@($g.Group); if ($items.Count -le 1){ continue }
      $destGroup = Join-Path $tbDest.Text $g.Name; Ensure-Dir $destGroup
      $keep = ($items | Sort-Object mtime_iso)[0]
      foreach($x in $items){
        if ($x -eq $keep){ continue }
        $src = Join-Path $global:__lastBase $x.relpath
        if (-not (Ensure-Under-Users $src)) { continue }
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $t = Join-Path $destGroup $x.name
        if (Test-Path -LiteralPath $t){ $stem=[IO.Path]::GetFileNameWithoutExtension($t); $ext=[IO.Path]::GetExtension($t); $k=1; do{ $t = Join-Path $destGroup ("{0} ({1}){2}" -f $stem,$k,$ext); $k++ } while (Test-Path -LiteralPath $t) }
        try{ Move-Item -LiteralPath $src -Destination $t -Force -ErrorAction Stop } catch {}
      }
    }
    [Windows.Forms.MessageBox]::Show("Duplicados movidos a:`n$($tbDest.Text)")
  } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message) }
})

$btnRunX.Add_Click({
  try{
    $target = if ($tbXT.Text){ $tbXT.Text } else { $tbRoot.Text }
    if (-not (Test-Path -LiteralPath $target)){ [Windows.Forms.MessageBox]::Show('Selecciona objetivo del analizador.'); return }
    $out = AutoStrings -target $target -Recurse:$cbRecX.Checked
    [Windows.Forms.MessageBox]::Show("Analizador completado.`nCSV: $out")
  } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message) }
})

[void]$form.ShowDialog()
return
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($dst, $code, $utf8NoBom)
try { Unblock-File -LiteralPath $dst } catch {}
"✔ Archivo creado en: $dst"
"Ejecuta:  pwsh -ExecutionPolicy Bypass -File `"$dst`""