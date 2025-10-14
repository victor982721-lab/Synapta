param(
    [ValidateSet('TEST', 'RUN')]
    [string]$Mode = 'TEST',
    [ValidateSet('3.11', '3.12', '3.13')]
    [string]$PreferredPython = '3.12',
    [switch]$CleanMachinePath
)

$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$backupDir = '00.Backups'
$logDir = 'logs'

New-Item -ItemType Directory -Force -Path $backupDir, $logDir | Out-Null
$logFile = Join-Path $logDir 'actions.jsonl'

function Write-Log {
    param(
        [string]$Action,
        [hashtable]$Details
    )

    $entry = [ordered]@{
        ts      = $timestamp
        mode    = $Mode
        action  = $Action
        details = $Details
    }

    ($entry | ConvertTo-Json -Compress) | Out-File -FilePath $logFile -Append -Encoding utf8
}

reg export HKCU\Environment (Join-Path $backupDir ("HKCU_Environment_{0}.reg" -f $timestamp)) /y | Out-Null

if ($CleanMachinePath) {
    $machinePathBackup = Join-Path $backupDir ("HKLM_Environment_{0}.reg" -f $timestamp)
    reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' $machinePathBackup /y | Out-Null
}

function Split-List {
    param([string]$Value)
    ($Value -split ';') | Where-Object { $_ }
}

function Normalize-Path {
    param([string]$Path)

    try {
        if (Test-Path $Path) {
            (Get-Item $Path).FullName.TrimEnd('\')
        }
        else {
            $Path.TrimEnd('\')
        }
    }
    catch {
        $Path
    }
}

$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

$userEntries = (Split-List -Value $userPath) | ForEach-Object { Normalize-Path -Path $_ }
$machineEntries = (Split-List -Value $machinePath) | ForEach-Object { Normalize-Path -Path $_ }

$pythonToken = 'Python' + ($PreferredPython -replace '\.', '')
$removePatterns = @('\\.venv\\Scripts$', 'Python311', 'Python313')
if ($PreferredPython -ne '3.12') {
    $removePatterns += 'Python312'
}

function Clean-Entries {
    param(
        [string[]]$Entries,
        [string[]]$MachineEntries
    )

    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $result = New-Object 'System.Collections.Generic.List[string]'

    foreach ($entry in $Entries) {
        if (-not $entry) { continue }

        $shouldRemove = $false
        foreach ($pattern in $removePatterns) {
            if ($entry -match $pattern) {
                Write-Log -Action 'drop.path' -Details @{ path = $entry }
                $shouldRemove = $true
                break
            }
        }
        if ($shouldRemove) { continue }

        if ($MachineEntries -contains $entry) { continue }
        if (-not $seen.Add($entry)) { continue }
        $result.Add($entry)
    }

    return $result
}

$cleanUserEntries = Clean-Entries -Entries $userEntries -MachineEntries $machineEntries
$newUserPath = ($cleanUserEntries -join ';')

Write-Log -Action 'plan.user.path' -Details @{ to = $newUserPath }

if ($Mode -eq 'TEST') {
    Write-Host 'TEST: simulación sin cambios.'
    exit 0
}

[Environment]::SetEnvironmentVariable('PATH', $newUserPath, 'User')
[Environment]::SetEnvironmentVariable('TEMP', "$env:USERPROFILE\AppData\Local\Temp", 'User')
[Environment]::SetEnvironmentVariable('TMP', "$env:USERPROFILE\AppData\Local\Temp", 'User')

Write-Log -Action 'apply.user.path' -Details @{ to = $newUserPath }
Write-Host 'RUN: Cambios aplicados correctamente.'
