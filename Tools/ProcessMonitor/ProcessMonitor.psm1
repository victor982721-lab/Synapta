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

function Write-ProcessMonitorTable {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Rows
    )

    if (-not $Rows) {
        return
    }

    $lineFormat = '{0,-18}{1,8}{2,9}{3,9}{4,12}{5,12}{6,17}{7,11}{8,11}{9,9}{10,-20}{11}'
    $header = $lineFormat -f 'Name','Pid','Threads','Handles','Memory MB','Memory %','Memory Delta','CPU s','CPU %','Native','StartTime','Path'
    Write-Host $header -ForegroundColor Gray
    Write-Host ('-' * $header.Length) -ForegroundColor DarkGray

    foreach ($row in $Rows) {
        $status = if ($row.IsNative) { 'Native' } else { '' }
        $startTimeDisplay = if ($row.StartTime) { $row.StartTime.ToString('g') } else { '' }
        $memoryMBDisplay = Format-Decimal ($row.'Memory (MB)')
        $memoryPercentDisplay = Format-Decimal ($row.'Memory (%)')
        $memoryDeltaDisplay = Format-Decimal ($row.'Memory Delta (MB)')
        $cpuSecondsDisplay = Format-Decimal ($row.'CPU (s)')
        $cpuPercentDisplay = Format-Decimal ($row.'CPU (%)')

        $values = @(
            $row.Name,
            $row.Id,
            $row.Threads,
            $row.Handles,
            $memoryMBDisplay,
            $memoryPercentDisplay,
            $memoryDeltaDisplay,
            $cpuSecondsDisplay,
            $cpuPercentDisplay,
            $status,
            $startTimeDisplay,
            $row.Path
        )
        $line = $lineFormat -f $values
        $color = if ($row.IsNative) { 'Gray' } else { 'White' }
        Write-Host $line -ForegroundColor $color
    }

    Write-Host 'Native processes appear dimmed.' -ForegroundColor DarkGray
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

    Write-ProcessMonitorTable -Rows $processList

    if ($ReturnObjects) {
        return $processList
    }
}

Export-ModuleMember -Function Show-TopMemoryProcesses
