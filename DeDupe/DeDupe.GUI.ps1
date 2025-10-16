<#
DeDupe.GUI.ps1 — PowerShell 7.2+
GUI (WPF) para deduplicación con wizard visual, exploradores de rutas,
progreso en vivo (ETA/MB/s) y visor de logs JSONL.

Requisitos: sin dependencias externas (WPF/.NET)
#>

#requires -Version 7.2
using namespace System
using namespace System.IO
using namespace System.Windows
using namespace System.Windows.Controls
using namespace System.Windows.Threading
using namespace System.Windows.Media

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$base = Split-Path -Parent $PSCommandPath
$modDir = Join-Path $base 'Modules'
$mods = @('DeDuPe.Metrics.Ultra','DeDuPe.Logging','DeDuPe.Grouping','DeDuPe.DedupeByHash','DeDuPe.Quarantine','DeDuPe.Pipeline')
foreach ($m in $mods) { Import-Module (Join-Path $modDir ("{0}.psd1" -f $m)) -Force }

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

function Browse-Folder { $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; if ($dlg.ShowDialog() -eq 'OK') { return $dlg.SelectedPath } }
function Browse-FileSave { param([string]$Filter='JSON files|*.json|All files|*.*') $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter=$Filter; if ($dlg.ShowDialog() -eq 'OK') { return $dlg.FileName } }

$win = New-Object Window
$win.Title = 'DeDupe — GUI'
$win.Width = 900; $win.Height = 680

$grid = New-Object Grid
$grid.Margin = '12'
for ($i=0; $i -lt 8; $i++){ [void]$grid.RowDefinitions.Add((New-Object RowDefinition)) }
$grid.RowDefinitions[0].Height = 'Auto'
$grid.RowDefinitions[1].Height = 'Auto'
$grid.RowDefinitions[2].Height = 'Auto'
$grid.RowDefinitions[3].Height = 'Auto'
$grid.RowDefinitions[4].Height = 'Auto'
$grid.RowDefinitions[5].Height = 'Auto'
$grid.RowDefinitions[6].Height = 'Auto'
$grid.RowDefinitions[7].Height = '*'

# Tema oscuro
$bc = New-Object BrushConverter
$bg   = [SolidColorBrush]$bc.ConvertFrom('#FF1E1E1E')
$fg   = [SolidColorBrush]$bc.ConvertFrom('#FFE0E0E0')
$bg2  = [SolidColorBrush]$bc.ConvertFrom('#FF2A2A2A')
$acc  = [SolidColorBrush]$bc.ConvertFrom('#FF3A96DD')
$win.Background = $bg
$win.Foreground = $fg

function New-LabeledPath {
  param([Parameter(Mandatory)][string]$label,[Parameter(Mandatory)][string]$default)
  $sp = New-Object StackPanel; $sp.Orientation='Horizontal'; $sp.Margin='0,6,0,0'
  $lbl = New-Object TextBlock; $lbl.Text = $label; $lbl.Width=160; $lbl.VerticalAlignment='Center'
  $tb  = New-Object TextBox;  $tb.Text = $default; $tb.Width=520
  $btn = New-Object Button;   $btn.Content='Browse…'; $btn.Margin='6,0,0,0'
  $null = $sp.Children.Add($lbl)
  $null = $sp.Children.Add($tb)
  $null = $sp.Children.Add($btn)
  return [pscustomobject]@{ Panel=$sp; Text=$tb; Button=$btn }
}

$defData  = if (Test-Path 'C:\.CODEX\.DATA') { 'C:\.CODEX\.DATA' } else { (Get-Location).Path }
$defQ     = Join-Path $env:LOCALAPPDATA 'DeDupe\Quarantine'
$defLog   = Join-Path $env:LOCALAPPDATA 'DeDupe\logs\actions.jsonl'
$defOut   = Join-Path $env:LOCALAPPDATA ('DeDupe\reports\DeDupe_Summary_{0}.json' -f (Get-Date).ToString('yyyyMMdd_HHmmss'))

$row=0
$src = New-LabeledPath 'Ruta origen:' $defData
[Grid]::SetRow($src.Panel,$row)
$null = $grid.Children.Add($src.Panel)
$row++
$qpn = New-LabeledPath 'Cuarentena:' $defQ
[Grid]::SetRow($qpn.Panel,$row)
$null = $grid.Children.Add($qpn.Panel)
$row++
$lpn = New-LabeledPath 'Ruta log JSONL:' $defLog
[Grid]::SetRow($lpn.Panel,$row)
$null = $grid.Children.Add($lpn.Panel)
$row++

$opts = New-Object StackPanel; $opts.Orientation='Horizontal'; $opts.Margin='0,8,0,0'
function New-Check([string]$t,[bool]$v){ $c=New-Object CheckBox; $c.Content=$t; $c.IsChecked=$v; $c.Margin='0,0,16,0'; return $c }
$chkRecurse = New-Check 'Recursivo' $true
$chkVerify  = New-Check 'Verificar (byte a byte)' $true
$chkHidden  = New-Check 'Incluir ocultos' $false
$opts.Children.Add($chkRecurse); $opts.Children.Add($chkVerify); $opts.Children.Add($chkHidden)
[Grid]::SetRow($opts,$row); $grid.Children.Add($opts) | Out-Null
$row++

$opts2 = New-Object StackPanel; $opts2.Orientation='Horizontal'; $opts2.Margin='0,8,0,0'
function New-Label([string]$t){ $tb=New-Object TextBlock; $tb.Text=$t; $tb.Margin='0,0,6,0'; $tb.VerticalAlignment='Center'; $tb.Foreground=$fg; return $tb }
function New-Combo([string[]]$items,[int]$idx){ $cb=New-Object ComboBox; $items | ForEach-Object { [void]$cb.Items.Add($_) }; $cb.SelectedIndex=$idx; $cb.Width=140; $cb.Margin='0,0,16,0'; return $cb }
function New-TextBox([string]$text,[int]$w){ $t=New-Object TextBox; $t.Text=$text; $t.Width=$w; $t.Margin='0,0,16,0'; $t.Background=$bg2; $t.Foreground=$fg; return $t }
$opts2.Children.Add((New-Label 'Conservar:')); $cmbKeep   = New-Combo @('Oldest','Newest','ShortestPath') 0; $opts2.Children.Add($cmbKeep)
$opts2.Children.Add((New-Label 'Diseño:'));    $cmbLayout = New-Combo @('BySize','Flat') 0; $opts2.Children.Add($cmbLayout)
$opts2.Children.Add((New-Label 'DOP:'));       $txtDop    = New-TextBox '0' 50; $opts2.Children.Add($txtDop)
$opts2.Children.Add((New-Label 'Bloque KB:')); $txtBlk    = New-TextBox '1024' 60; $opts2.Children.Add($txtBlk)
[Grid]::SetRow($opts2,$row); $grid.Children.Add($opts2) | Out-Null
$row++

$prog = New-Object StackPanel; $prog.Orientation='Vertical'; $prog.Margin='0,8,0,0'
$bar = New-Object ProgressBar; $bar.Minimum=0; $bar.Maximum=100; $bar.Height=18; $bar.Foreground=$acc
$lblProg = New-Object TextBlock; $lblProg.Text='ETA —'; $lblProg.Margin='0,6,0,0'; $lblProg.Foreground=$fg
$prog.Children.Add($bar); $prog.Children.Add($lblProg)
[Grid]::SetRow($prog,$row); $grid.Children.Add($prog) | Out-Null
$row++

$btns = New-Object StackPanel; $btns.Orientation='Horizontal'; $btns.Margin='0,10,0,0'
$btnDry = New-Object Button; $btnDry.Content='Simulación'; $btnDry.Width=140; $btnDry.Background=$bg2; $btnDry.Foreground=$fg
$btnRun = New-Object Button; $btnRun.Content='Ejecutar';  $btnRun.Margin='8,0,0,0'; $btnRun.Width=140; $btnRun.Background=$bg2; $btnRun.Foreground=$fg
$btnExportChk = New-Object CheckBox; $btnExportChk.Content='Exportar resumen JSON'; $btnExportChk.Margin='16,6,0,0'; $btnExportChk.IsChecked=$false; $btnExportChk.Foreground=$fg
$btnExportPath = New-Object TextBox; $btnExportPath.Text=$defOut; $btnExportPath.Width=320; $btnExportPath.Margin='8,0,0,0'
$btnExportBrowse = New-Object Button; $btnExportBrowse.Content='…'; $btnExportBrowse.Width=28; $btnExportBrowse.Margin='6,0,0,0'
$btns.Children.Add($btnDry); $btns.Children.Add($btnRun); $btns.Children.Add($btnExportChk); $btns.Children.Add($btnExportPath); $btns.Children.Add($btnExportBrowse)
[Grid]::SetRow($btns,$row); $grid.Children.Add($btns) | Out-Null
$row++

$logs = New-Object TextBox; $logs.Margin='0,10,0,0'; $logs.VerticalScrollBarVisibility='Auto'; $logs.TextWrapping='NoWrap'; $logs.AcceptsReturn=$true; $logs.Background=$bg2; $logs.Foreground=$fg
[Grid]::SetRow($logs,$row); $grid.Children.Add($logs) | Out-Null

$win.Content = $grid

$src.Button.Add_Click({ $p=Browse-Folder; if($p){ $src.Text.Text=$p } })
$qpn.Button.Add_Click({ $p=Browse-Folder; if($p){ $qpn.Text.Text=$p } })
$lpn.Button.Add_Click({ $p=Browse-Folder; if($p){ $lpn.Text.Text=(Join-Path $p 'actions.jsonl') } })
$btnExportBrowse.Add_Click({ $p=Browse-FileSave; if($p){ $btnExportPath.Text=$p } })

function Update-UIProgress([object]$snap){
  if ($null -eq $snap) { return }
  $pct = if ($snap.Percent) { [int][math]::Floor($snap.Percent) } else { 0 }
  $eta = if ($snap.ETA) { "$($snap.ETA)s" } else { '—' }
  $mbs = if ($snap.MBps) { "{0} MB/s" -f $snap.MBps } else { '0 MB/s' }
  $bar.Value = [Math]::Max(0,[Math]::Min(100,$pct))
  $lblProg.Text = "{0} | ETA {1} | {2} done" -f $mbs, $eta, $snap.ItemsDone
}

function Append-LogLine([string]$line){ if (-not [string]::IsNullOrWhiteSpace($line)) { $logs.AppendText($line + [Environment]::NewLine); $logs.ScrollToEnd() } }

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(750)
$lastSize = 0L
$timer.Add_Tick({
  try {
    $p = $lpn.Text.Text
    if ([string]::IsNullOrWhiteSpace($p) -or -not (Test-Path -LiteralPath $p)) { return }
    $fi = [FileInfo]::new($p)
    if ($fi.Length -le $lastSize) { return }
    $fs = [File]::Open($p,'Open','Read','ReadWrite'); try { $fs.Position = $lastSize; $sr = New-Object IO.StreamReader($fs); while(-not $sr.EndOfStream){ Append-LogLine ($sr.ReadLine()) } } finally { $lastSize = $fi.Length; $fs.Dispose() }
  } catch { }
})

function Run-Job([bool]$apply){
  try {
    $path=$src.Text.Text; $q=$qpn.Text.Text; $log=$lpn.Text.Text
    $keep=$cmbKeep.SelectedItem; $layout=$cmbLayout.SelectedItem
    $dop=[int]$txtDop.Text; $blk=[int]$txtBlk.Text
    $recurse=[bool]$chkRecurse.IsChecked; $verify=[bool]$chkVerify.IsChecked; $hidden=[bool]$chkHidden.IsChecked

    $logs.Clear()
    # posiciona tail al final del archivo actual para no prellenar
    try { if (Test-Path -LiteralPath $log) { $lastSize = ([IO.FileInfo]$log).Length } else { $lastSize = 0 } } catch { $lastSize = 0 }
    if (-not $timer.IsEnabled) { $timer.Start() }

    $tick = { param($s)
      $null = $win.Dispatcher.BeginInvoke([Action]{ Update-UIProgress $s })
    }
    $sum = Invoke-DeDupePipeline -Path $path -Recurse:$recurse -IncludeHidden:$hidden -AllowZeroByte:$false -Keep $keep -QuarantinePath $q -LogPath $log -QuarantineLayout $layout -DegreeOfParallelism $dop -BlockSizeKB $blk -ReportIntervalMs 500 -Verify:$verify -Run:$apply -OnTick $tick -Confirm:$false
    if ($btnExportChk.IsChecked) {
      $out = $btnExportPath.Text; $dir = Split-Path -Parent $out; if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
      ($sum | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $out -Encoding UTF8
      Append-LogLine ("Saved summary: $out")
    }
  } catch {
    [System.Windows.MessageBox]::Show($_.Exception.Message,'Error','OK','Error') | Out-Null
  }
}

$btnDry.Add_Click({ Run-Job $false })
$btnRun.Add_Click({ Run-Job $true })

[void]$win.ShowDialog()
