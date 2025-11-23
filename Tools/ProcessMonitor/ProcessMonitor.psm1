function Get-SafeProcessPropertyValue {
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Process]$Process,
        [Parameter(Mandatory)]
        [string]$PropertyName
    )

    & {
        trap {
            return $null
        }
        return $Process.$PropertyName
    }
}

function Format-Decimal {
    param([object]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return "{0:N2}" -f $Value
}

function Shorten-Path {
    param(
        [string]$Path,
        [int]$MaxLength = 38
    )

    if (-not $Path) {
        return ''
    }

    if ($Path.Length -le $MaxLength) {
        return $Path
    }

    return '...' + $Path.Substring($Path.Length - ($MaxLength - 3))
}

function Get-ThresholdColor {
    param(
        [double]$Value,
        [double]$Warn,
        [double]$Alert,
        [ConsoleColor]$DefaultColor
    )

    if ($null -ne $Alert -and $Value -ge $Alert) {
        return 'Red'
    }

    if ($null -ne $Warn -and $Value -ge $Warn) {
        return 'Yellow'
    }

    return $DefaultColor
}

function Determine-ProcessCategory {
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Process]$Process,
        [string]$Path
    )

    $name = $Process.ProcessName.ToLowerInvariant()
    $lowerPath = ($Path ?? '').ToLowerInvariant()

    $rules = @(
        @{Category='Security'; Names=@('msmpeng','microsoftsecurityapp','ekrn'); Paths=@('microsoft defender','windows defender','microsoft security')},
        @{Category='Browser'; Names=@('chrome','msedge','firefox','brave'); Paths=@('google\\chrome','microsoft\\edge','mozilla')},
        @{Category='Shell'; Names=@('pwsh','powershell','cmd','WindowsTerminal','wt'); Paths=@('powershell','windows terminal')},
        @{Category='System'; Names=@('explorer','dwm','winlogon','csrss','svchost'); Paths=@('windows\\system32','windows\\syswow64')},
        @{Category='Office'; Paths=@('officeclicktorun','microsoft office','onenote','word','excel','powerpnt')},
        @{Category='VM'; Names=@('vmsrvc','vmware','vmtools'); Paths=@('vmware','virtualbox','hyper-v')},
        @{Category='Media'; Names=@('spotify','vlc'); Paths=@('spotify','vlc')},
        @{Category='Database'; Names=@('sql','postgres','redis','mongod'); Paths=@('sql server','postgresql','redis')},
        @{Category='Other'; Names=@(); Paths=@()}
    )

    foreach ($rule in $rules) {
        if ($rule.Names -and ($rule.Names -contains $name)) {
            return $rule.Category
        }
        foreach ($pathFragment in $rule.Paths) {
            if ($pathFragment -and $lowerPath.Contains($pathFragment)) {
                return $rule.Category
            }
        }
    }

    return 'Other'
}

function Write-ProcessMonitorTable {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Rows,
        [double]$MemoryWarnPercent = 5,
        [double]$MemoryAlertPercent = 25,
        [double]$CpuWarnPercent = 5,
        [double]$CpuAlertPercent = 20
    )

    if (-not $Rows) {
        return
    }

    $formatList = @(
        @{Label='Name'; Format='{0,-18} '},
        @{Label='Category'; Format='{0,-10} '},
        @{Label='PID'; Format='{0,7} '},
        @{Label='Memory MB'; Format='{0,10} '},
        @{Label='Mem %'; Format='{0,9} '},
        @{Label='Delta MB'; Format='{0,11} '},
        @{Label='CPU %'; Format='{0,10} '},
        @{Label='Native'; Format='{0,6} '},
        @{Label='Path'; Format='{0,-38}'}
    )

    Write-Host ('-' * 120) -ForegroundColor DarkGray
    foreach ($col in $formatList) {
        Write-Host -NoNewline ($col.Format -f $col.Label) -ForegroundColor Cyan
    }
    Write-Host
    Write-Host ('-' * 120) -ForegroundColor DarkGray

    foreach ($row in $Rows) {
        $status = if ($row.IsNative) { 'Native' } else { '' }
        $memoryMBDisplay = Format-Decimal ($row.'Memory (MB)')
        $memoryPercentDisplay = Format-Decimal ($row.'Memory (%)')
        $memoryDeltaDisplay = Format-Decimal ($row.'Memory Delta (MB)')
        $cpuPercentDisplay = Format-Decimal ($row.'CPU (%)')

        $shortPath = Shorten-Path -Path $row.Path -MaxLength 38
        $baseColor = if ($row.IsNative) { 'DarkGreen' } else { 'White' }
        $memoryColor = Get-ThresholdColor -Value $row.'Memory (%)' -Warn $MemoryWarnPercent -Alert $MemoryAlertPercent -DefaultColor $baseColor
        $cpuColor = Get-ThresholdColor -Value $row.'CPU (%)' -Warn $CpuWarnPercent -Alert $CpuAlertPercent -DefaultColor $baseColor
        $deltaColor = if ($row.'Memory Delta (MB)' -ge 100) { 'Yellow' } elseif ($row.'Memory Delta (MB)' -le -100) { 'DarkCyan' } else { $baseColor }

        Write-Host -NoNewline ($formatList[0].Format -f $row.Name) -ForegroundColor $baseColor
        Write-Host -NoNewline ($formatList[1].Format -f $row.Category) -ForegroundColor $baseColor
        Write-Host -NoNewline ($formatList[2].Format -f $row.Id) -ForegroundColor $baseColor
        Write-Host -NoNewline ($formatList[3].Format -f $memoryMBDisplay) -ForegroundColor $memoryColor
        Write-Host -NoNewline ($formatList[4].Format -f $memoryPercentDisplay) -ForegroundColor $memoryColor
        Write-Host -NoNewline ($formatList[5].Format -f $memoryDeltaDisplay) -ForegroundColor $deltaColor
        Write-Host -NoNewline ($formatList[6].Format -f $cpuPercentDisplay) -ForegroundColor $cpuColor
        Write-Host -NoNewline ($formatList[7].Format -f $status) -ForegroundColor $baseColor
        Write-Host ($formatList[8].Format -f $shortPath) -ForegroundColor $baseColor
    }

    Write-Host ('-' * 120) -ForegroundColor DarkGray
    Write-Host 'Native rows fade away; yellow/red values flag high memory/CPU while dark cyan highlights big drops.' -ForegroundColor DarkGray
}
function Write-ProcessMonitorDetailRow {
    param(
        [string]$Label,
        $Value,
        [ConsoleColor]$ValueColor = 'White'
    )

    $formattedValue = if ($null -eq $Value -or $Value -eq '') { '<n/a>' } else { $Value }
    Write-Host -NoNewline ("{0,-20}: " -f $Label) -ForegroundColor DarkGray
    Write-Host $formattedValue -ForegroundColor $ValueColor
}

function Write-ProcessMonitorDetail {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Rows
    )

    if (-not $Rows) {
        return
    }

    $separator = '-' * 80
    foreach ($row in $Rows) {
        $headerColor = if ($row.IsNative) { 'Gray' } else { 'Cyan' }
        Write-Host $separator -ForegroundColor DarkGray
        Write-Host ("{0} (PID {1})" -f $row.Name, $row.Id) -ForegroundColor $headerColor
        Write-ProcessMonitorDetailRow 'Category' $row.Category 'Cyan'
        Write-ProcessMonitorDetailRow 'Memory MB' (Format-Decimal $row.'Memory (MB)') 'Yellow'
        Write-ProcessMonitorDetailRow 'Memory %' (Format-Decimal $row.'Memory (%)') 'Yellow'
        Write-ProcessMonitorDetailRow 'Memory Delta (MB)' (Format-Decimal $row.'Memory Delta (MB)') 'Yellow'
        Write-ProcessMonitorDetailRow 'CPU (s)' (Format-Decimal $row.'CPU (s)') 'Magenta'
        Write-ProcessMonitorDetailRow 'CPU (%)' (Format-Decimal $row.'CPU (%)') 'Magenta'
        Write-ProcessMonitorDetailRow 'IsNative' $row.IsNative 'Gray'
        Write-ProcessMonitorDetailRow 'Threads' $row.Threads 'White'
        Write-ProcessMonitorDetailRow 'Handles' $row.Handles 'White'
        Write-ProcessMonitorDetailRow 'StartTime' $row.StartTime 'DarkGray'
        Write-ProcessMonitorDetailRow 'Path' $row.Path 'DarkGray'
        Write-ProcessMonitorDetailRow 'ProcessKey' $row.ProcessKey 'DarkGray'
        Write-Host ''
    }
    Write-Host $separator -ForegroundColor DarkGray
    Write-Host 'Use -ReturnObjects if you need the data programmatically.' -ForegroundColor DarkGray
}

function Show-TopMemoryProcesses {
    <#
    .SYNOPSIS
    Lista los procesos en orden de consumo de memoria incluyendo porcentaje y detalles.

    .PARAMETER Top
    Cantidad de procesos a mostrar.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 200)]
        [int]$Top = 20,
        [double]$MinMemoryMB = $null,
        [double]$MinCpuPercent = $null,
        [switch]$HideNative,
        [switch]$Detalle,
        [double]$MemoryWarnPercent = 5,
        [double]$MemoryAlertPercent = 25,
        [double]$CpuWarnPercent = 5,
        [double]$CpuAlertPercent = 20,
        [switch]$ReturnObjects
    )

    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMemoryMB = if ($osInfo.TotalVisibleMemorySize) {
        [math]::Round($osInfo.TotalVisibleMemorySize / 1KB, 2)
    } else {
        0
    }

    $currentTime = Get-Date
    $programFileLocations = @()
    foreach ($envName in 'ProgramFiles','ProgramFiles(x86)','ProgramW6432') {
        $value = [Environment]::GetEnvironmentVariable($envName)
        if ($value) {
            $programFileLocations += $value
        }
    }
    $programFileLocations = $programFileLocations | Sort-Object -Unique

    $programRoots = foreach ($root in $programFileLocations) {
        Join-Path $root 'Microsoft'
        Join-Path $root 'Windows Defender'
        Join-Path $root 'Microsoft Defender'
    }

    $processRoots = @(
        $env:SystemRoot,
        $env:WINDIR,
        (Join-Path $env:SystemRoot 'System32'),
        (Join-Path $env:SystemRoot 'SysWOW64')
    ) + $programRoots | Where-Object { $_ } | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique

    $fallbackNativeNames = @(
        'msmpeng',
        'memory compression',
        'memorycompression'
    )

    $snapshotDir = Join-Path $env:LOCALAPPDATA 'ProcessMonitor'
    $snapshotPath = Join-Path $snapshotDir 'lastSnapshot.json'
    $previousMemory = @{}

    if (Test-Path $snapshotPath) {
        try {
            $previousMemoryEntries = Get-Content -Raw $snapshotPath | ConvertFrom-Json
            foreach ($entry in $previousMemoryEntries) {
                if ($entry.ProcessKey) {
                    $previousMemory[$entry.ProcessKey] = $entry.MemoryMB
                }
            }
        } catch {
            # ignore corrupted snapshot
        }
    }

    $processList = Get-Process |
        Sort-Object WS -Descending |
        Select-Object -First $Top |
        ForEach-Object {
            $memoryMB = [math]::Round($_.WS / 1MB, 2)
            $memoryPercent = if ($totalMemoryMB -gt 0) {
                [math]::Round(($memoryMB / $totalMemoryMB) * 100, 2)
            } else {
                0
            }

            $startTime = Get-SafeProcessPropertyValue -Process $_ -PropertyName 'StartTime'

            $cpuPercent = 0
            if ($startTime -and $_.CPU) {
                $elapsedSeconds = (New-TimeSpan -Start $startTime -End $currentTime).TotalSeconds
                if ($elapsedSeconds -gt 0) {
                    $cpuPercent = [math]::Round(($_.CPU / $elapsedSeconds / [Environment]::ProcessorCount) * 100, 2)
                }
            }

            $path = Get-SafeProcessPropertyValue -Process $_ -PropertyName 'Path'
            $pathKey = if ($path) { $path.ToLowerInvariant() } else { 'unknown' }
            $processKey = "$($_.ProcessName)|$pathKey"
            $isNative = $false
            if ($path) {
                foreach ($root in $processRoots) {
                    if ($root -and $pathKey.StartsWith($root)) {
                        $isNative = $true
                        break
                    }
                }
            }

            $processNameLower = $_.ProcessName.ToLowerInvariant()
            if (-not $isNative -and $fallbackNativeNames -contains $processNameLower) {
                $isNative = $true
            }

            $category = Determine-ProcessCategory -Process $_ -Path $path

            $previousValue = 0
            if ($previousMemory.ContainsKey($processKey)) {
                $previousValue = $previousMemory[$processKey]
            }
            $memoryDelta = [math]::Round($memoryMB - $previousValue, 2)

            [PSCustomObject]@{
                Name            = $_.ProcessName
                Id              = $_.Id
                Threads         = $_.Threads.Count
                Handles         = $_.HandleCount
                'Memory (MB)'   = $memoryMB
                'Memory (%)'    = $memoryPercent
                'Memory Delta (MB)' = $memoryDelta
                'CPU (s)'       = if ($_.CPU) { [math]::Round($_.CPU, 2) } else { 0 }
                'CPU (%)'       = $cpuPercent
                IsNative        = $isNative
                Category        = $category
                StartTime       = $startTime
                Path            = $path
                ProcessKey      = $processKey
            }
        }

    if (-not (Test-Path $snapshotDir)) {
        New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
    }

    $snapshotData = $processList | Select-Object ProcessKey, @{Name='MemoryMB';Expression={$_.'Memory (MB)'}}
    $snapshotData | ConvertTo-Json -Depth 3 | Set-Content -Path $snapshotPath -Force

    $displayList = $processList | Where-Object {
        ($MinMemoryMB -eq $null -or $_.'Memory (MB)' -ge $MinMemoryMB) -and
        ($MinCpuPercent -eq $null -or $_.'CPU (%)' -ge $MinCpuPercent) -and
        (-not $HideNative -or -not $_.IsNative)
    }

    $displayList = @($displayList)

    if ($Detalle) {
        Write-ProcessMonitorDetail -Rows $displayList
    } else {
        Write-ProcessMonitorTable -Rows $displayList `
            -MemoryWarnPercent $MemoryWarnPercent `
            -MemoryAlertPercent $MemoryAlertPercent `
            -CpuWarnPercent $CpuWarnPercent `
            -CpuAlertPercent $CpuAlertPercent
    }

    if ($ReturnObjects) {
        return $displayList
    }
}

Export-ModuleMember -Function Show-TopMemoryProcesses
