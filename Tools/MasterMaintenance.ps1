#requires -Version 7.0
#requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string[]]$Step,
    [string[]]$SkipStep,
    [string]$LogRoot = (Join-Path $env:USERPROFILE 'MasterMaintenanceLogs'),
    [switch]$SkipDefender,
    [switch]$NoTranscript,
    [int]$MaxHashErrors = 50,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:SkipDefenderRequested = $SkipDefender.IsPresent
$script:MaxHashErrorLimit     = $MaxHashErrors

if (-not $IsWindows) {
    throw 'Este script está diseñado para Windows. Aborta para evitar efectos inesperados.'
}

$script:Timestamp        = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:SessionStart     = Get-Date
$script:LogDirectory     = $LogRoot
$script:LogFile          = Join-Path $LogDirectory "MasterMaintenance_$Timestamp.jsonl"
$script:TranscriptFile   = Join-Path $LogDirectory "Transcript_$Timestamp.txt"
$script:ProgressActivity = 'Mantenimiento maestro'
$script:HeartbeatTimer   = $null
$script:HeartbeatEvent   = $null
$script:LiveProgress     = $null

function Initialize-Logging {
    if (-not (Test-Path -Path $script:LogDirectory)) {
        $null = New-Item -Path $script:LogDirectory -ItemType Directory -Force
    }

    if (-not $NoTranscript) {
        try {
            Start-Transcript -Path $script:TranscriptFile -Append | Out-Null
        }
        catch {
            Write-Warning "No se pudo iniciar el Transcript: $($_.Exception.Message)"
        }
    }
}

function Write-JsonLog {
    param(
        [Parameter(Mandatory)] [string] $Type,
        [hashtable] $Data
    )

    $entry = [PSCustomObject]@{
        Time = (Get-Date).ToString('o')
        Type = $Type
        Data = $Data
    }

    try {
        $entry | ConvertTo-Json -Depth 8 -Compress | Add-Content -Path $script:LogFile -Encoding utf8
    }
    catch {
        Write-Warning "Fallo al escribir en el log: $($_.Exception.Message)"
    }
}

function Show-LiveProgress {
    param(
        [Parameter(Mandatory)] [string] $StepName,
        [Parameter(Mandatory)] [int] $StepIndex,
        [Parameter(Mandatory)] [int] $TotalSteps
    )

    Close-LiveProgress

    $script:LiveProgress = [ordered]@{
        StepName     = $StepName
        StepIndex    = $StepIndex
        TotalSteps   = $TotalSteps
        SessionStart = $script:SessionStart
        StepStart    = Get-Date
        StepPercent  = 0
        Status       = 'Inicializando'
    }

    $script:HeartbeatTimer = New-Object System.Timers.Timer
    $script:HeartbeatTimer.Interval = 1750
    $script:HeartbeatTimer.AutoReset = $true

    $script:HeartbeatEvent = Register-ObjectEvent -InputObject $script:HeartbeatTimer -EventName Elapsed -SourceIdentifier 'MasterMaintenanceHeartbeat' -Action {
        $data = $script:LiveProgress
        if (-not $data) { return }

        $sessionElapsed = (Get-Date) - $data.SessionStart
        $stepPercent    = [math]::Min([math]::Max($data.StepPercent, 0), 100)
        $basePercent    = (($data.StepIndex - 1) / [double]$data.TotalSteps) * 100
        $overallPercent = [math]::Min(100, $basePercent + ($stepPercent / $data.TotalSteps))

        $statusText = if ($data.Status) { " | $($data.Status)" } else { '' }
        $rateText   = if ($data.Contains('Throughput') -and $data.Throughput) { " | $($data.Throughput)" } else { '' }

        Write-Progress -Activity $script:ProgressActivity -Status (
            'Paso {0}/{1}: {2} | sesión {3:hh\:mm\:ss} | paso {4:N0}% | total {5:N0}%{6}{7}' -f $data.StepIndex, $data.TotalSteps, $data.StepName, $sessionElapsed, $stepPercent, $overallPercent, $statusText, $rateText
        ) -PercentComplete $overallPercent -Id 0
    }

    $script:HeartbeatTimer.Start()
}

function Set-LiveProgressState {
    param(
        [int] $StepPercent,
        [string] $Status,
        [string] $Throughput
    )

    if (-not $script:LiveProgress) { return }

    if ($PSBoundParameters.ContainsKey('StepPercent')) {
        $script:LiveProgress.StepPercent = [math]::Min([math]::Max($StepPercent, 0), 100)
    }
    if ($PSBoundParameters.ContainsKey('Status')) {
        $script:LiveProgress.Status = $Status
    }
    if ($PSBoundParameters.ContainsKey('Throughput')) {
        if ($Throughput) {
            $script:LiveProgress.Throughput = $Throughput
        }
        elseif ($script:LiveProgress.Contains('Throughput')) {
            $script:LiveProgress.Remove('Throughput') | Out-Null
        }
    }
}

function Close-LiveProgress {
    if ($script:HeartbeatTimer) {
        $script:HeartbeatTimer.Stop()
        $script:HeartbeatTimer.Dispose()
        $script:HeartbeatTimer = $null
    }

    if ($script:HeartbeatEvent) {
        Unregister-Event -SourceIdentifier 'MasterMaintenanceHeartbeat' -ErrorAction SilentlyContinue
        $script:HeartbeatEvent = $null
    }

    Write-Progress -Activity $script:ProgressActivity -Completed -Id 0
}

function Invoke-MaintenanceStep {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Action,
        [Parameter(Mandatory)] [int] $Index,
        [Parameter(Mandatory)] [int] $Total
    )

    $percentStart = [math]::Floor((($Index - 1) / [double]$Total) * 100)
    Write-Progress -Activity $script:ProgressActivity -Status "Preparando $Name" -PercentComplete $percentStart -Id 1

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-JsonLog -Type 'StepStart' -Data @{ Name = $Name; Index = $Index; Total = $Total }

    Show-LiveProgress -StepName $Name -StepIndex $Index -TotalSteps $Total
    Set-LiveProgressState -StepPercent 2 -Status 'Ejecutando'

    try {
        & $Action
        $stopwatch.Stop()
        Set-LiveProgressState -StepPercent 100 -Status 'Completado'
        Write-JsonLog -Type 'StepEnd' -Data @{ Name = $Name; DurationMs = $stopwatch.ElapsedMilliseconds }
        $percentDone = [math]::Floor(($Index / [double]$Total) * 100)
        Write-Progress -Activity $script:ProgressActivity -Status "$Name completado" -PercentComplete $percentDone -Id 1
    }
    catch {
        $stopwatch.Stop()
        Set-LiveProgressState -Status "Error: $($_.Exception.Message)"
        Write-JsonLog -Type 'StepError' -Data @{ Name = $Name; DurationMs = $stopwatch.ElapsedMilliseconds; Error = $_.Exception.Message }
        Write-Warning "Paso $Name falló: $($_.Exception.Message)"
    }
    finally {
        Close-LiveProgress
    }
}

function Invoke-ExternalCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $FilePath,
        [string[]] $ArgumentList,
        [switch] $TreatNonZeroAsError
    )

    if (-not (Test-Path -Path $FilePath -PathType Leaf) -and ($FilePath -notmatch '^(sfc.exe|dism.exe|netsh.exe|winmgmt.exe)$')) {
        Write-JsonLog -Type 'ExternalCommand' -Data @{ Name = $Name; FilePath = $FilePath; Skipped = $true; Reason = 'No encontrado' }
        return
    }

    if (-not $PSCmdlet.ShouldProcess($FilePath, "Ejecutar $Name")) {
        Write-JsonLog -Type 'ExternalCommand' -Data @{ Name = $Name; FilePath = $FilePath; Skipped = $true; Reason = 'WhatIf/Confirm' }
        return
    }

    Write-Progress -Activity $script:ProgressActivity -Status "$Name" -PercentComplete -1 -Id 2
    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -Wait -NoNewWindow
    Write-Progress -Activity $script:ProgressActivity -Status "$Name" -Completed -Id 2

    $entry = @{ Name = $Name; FilePath = $FilePath; Args = ($ArgumentList -join ' '); ExitCode = $process.ExitCode }

    if ($TreatNonZeroAsError -and $process.ExitCode -ne 0) {
        Write-JsonLog -Type 'ExternalCommandError' -Data $entry
        throw "El comando $Name devolvió código $($process.ExitCode)"
    }

    Write-JsonLog -Type 'ExternalCommand' -Data $entry
}

function Get-SystemDiagnostic {
    [CmdletBinding()]
    param()
    $cs   = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor
    $disk = Get-PhysicalDisk
    $gpu  = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    $net  = Get-NetAdapter -ErrorAction SilentlyContinue

    Write-JsonLog -Type 'Diagnostics' -Data @{
        ComputerSystem = $cs  | Select-Object Manufacturer, Model, TotalPhysicalMemory
        OperatingSystem= $os  | Select-Object Caption, Version, OSArchitecture, LastBootUpTime
        Processor      = $cpu | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        PhysicalDisk   = $disk| Select-Object FriendlyName, MediaType, Size, HealthStatus
        Video          = $gpu | Select-Object Name, DriverVersion, AdapterRAM
        NetAdapter     = $net | Select-Object Name, Status, LinkSpeed, MacAddress
    }
}

function Get-PerformanceSnapshot {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance Win32_OperatingSystem
    $memoryTotal  = [double]$os.TotalVisibleMemorySize
    $memoryFree   = [double]$os.FreePhysicalMemory
    $memoryUsedMb = [math]::Round(($memoryTotal - $memoryFree) / 1024, 2)
    $memoryFreeMb = [math]::Round($memoryFree / 1024, 2)

    $topCpu = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Name, CPU, PM, Id
    $topMem = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 -Property Name, @{n='WorkingSetMB';e={[math]::Round($_.WorkingSet64/1MB,2)}}, Id

    $diskPerf = Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus, MediaType, Size

    Write-JsonLog -Type 'PerformanceSnapshot' -Data @{
        MemoryMB = @{ Used = $memoryUsedMb; Free = $memoryFreeMb; Total = [math]::Round($memoryTotal/1024,2) }
        TopCpu   = $topCpu
        TopMem   = $topMem
        Disks    = $diskPerf
    }
}

function Repair-PerformanceCounter {
    [CmdletBinding()]
    param()
    Set-LiveProgressState -StepPercent 10 -Status 'Restaurando contadores (System32)'
    $sys32  = Join-Path $env:WINDIR 'System32'
    $syswow = Join-Path $env:WINDIR 'SysWOW64'

    if (Test-Path (Join-Path $sys32 'lodctr.exe')) {
        Invoke-ExternalCommand -Name 'lodctr_System32' -FilePath (Join-Path $sys32 'lodctr.exe') -ArgumentList '/R' -TreatNonZeroAsError
    }

    Set-LiveProgressState -StepPercent 45 -Status 'Restaurando contadores (SysWOW64)'
    if (Test-Path (Join-Path $syswow 'lodctr.exe')) {
        Invoke-ExternalCommand -Name 'lodctr_SysWOW64' -FilePath (Join-Path $syswow 'lodctr.exe') -ArgumentList '/R' -TreatNonZeroAsError
    }

    Set-LiveProgressState -StepPercent 80 -Status 'Sincronizando rendimiento WMI'
    Invoke-ExternalCommand -Name 'winmgmt_resyncperf' -FilePath 'winmgmt.exe' -ArgumentList '/resyncperf' -TreatNonZeroAsError
    Set-LiveProgressState -StepPercent 100 -Status 'Contadores de rendimiento reparados'
}

function Invoke-DefenderMaintenance {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if ($script:SkipDefenderRequested) {
        Write-JsonLog -Type 'Defender' -Data @{ Action = 'Skipped'; Reason = 'SkipDefender' }
        return
    }

    Set-LiveProgressState -StepPercent 5 -Status 'Comprobando disponibilidad de Defender'
    $cmdUpdate       = Get-Command -Name Update-MpSignature -ErrorAction SilentlyContinue
    $cmdScan         = Get-Command -Name Start-MpScan        -ErrorAction SilentlyContinue
    $cmdGetThreat    = Get-Command -Name Get-MpThreat        -ErrorAction SilentlyContinue
    $cmdRemoveThreat = Get-Command -Name Remove-MpThreat     -ErrorAction SilentlyContinue

    if (-not $cmdScan) {
        Write-JsonLog -Type 'Defender' -Data @{ Available = $false; Note = 'Defender no está disponible en esta sesión.' }
        return
    }

    if ($cmdUpdate -and $PSCmdlet.ShouldProcess('Defender', 'Actualizar firmas')) {
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-JsonLog -Type 'Defender' -Data @{ Action = 'UpdateSignatures' }
        Set-LiveProgressState -StepPercent 20 -Status 'Firmas actualizadas'
    }

    if ($PSCmdlet.ShouldProcess('Defender', 'FullScan')) {
        $scanJob = Start-MpScan -ScanType FullScan -AsJob -ErrorAction SilentlyContinue
        Write-JsonLog -Type 'Defender' -Data @{ Action = 'FullScanStarted'; JobId = $scanJob.Id }
        Set-LiveProgressState -StepPercent 35 -Status 'Escaneo completo en progreso'

        while ($scanJob.State -eq 'Running') {
            Write-Progress -Activity $script:ProgressActivity -Status 'Defender Full Scan' -PercentComplete -1 -Id 3
            Start-Sleep -Seconds 5
            $scanJob = Get-Job -Id $scanJob.Id -ErrorAction SilentlyContinue
        }

        if ($scanJob -and $scanJob.State -ne 'Completed') {
            Write-JsonLog -Type 'Defender' -Data @{ Action = 'FullScan'; Result = $scanJob.State }
        }
        else {
            Write-JsonLog -Type 'Defender' -Data @{ Action = 'FullScanCompleted' }
        }

        Receive-Job -Id $scanJob.Id -Keep -ErrorAction SilentlyContinue | Out-Null
        Write-Progress -Activity $script:ProgressActivity -Status 'Defender Full Scan' -Completed -Id 3
        Set-LiveProgressState -StepPercent 85 -Status 'Escaneo completo finalizado'
    }

    if ($cmdGetThreat) {
        $threats = Get-MpThreat -ErrorAction SilentlyContinue
        if ($threats) {
            Write-JsonLog -Type 'DefenderThreats' -Data @{ Threats = $threats }
            if ($cmdRemoveThreat -and $PSCmdlet.ShouldProcess('Defender', 'Remove Threats')) {
                Remove-MpThreat -ErrorAction SilentlyContinue
                Write-JsonLog -Type 'Defender' -Data @{ Action = 'RemoveMpThreat'; Result = 'Invoked' }
            }
            Set-LiveProgressState -StepPercent 100 -Status 'Amenazas gestionadas'
        }
        else {
            Set-LiveProgressState -StepPercent 100 -Status 'Escaneo sin amenazas detectadas'
        }
    }
}

function Repair-SystemFile {
    [CmdletBinding()]
    param()
    Set-LiveProgressState -StepPercent 5 -Status 'SFC en ejecución'
    Invoke-ExternalCommand -Name 'SFC' -FilePath 'sfc.exe' -ArgumentList '/scannow' -TreatNonZeroAsError

    Set-LiveProgressState -StepPercent 45 -Status 'DISM ScanHealth'
    Invoke-ExternalCommand -Name 'DISM_ScanHealth' -FilePath 'dism.exe' -ArgumentList '/Online','/Cleanup-Image','/ScanHealth' -TreatNonZeroAsError

    Set-LiveProgressState -StepPercent 85 -Status 'DISM RestoreHealth'
    Invoke-ExternalCommand -Name 'DISM_RestoreHealth' -FilePath 'dism.exe' -ArgumentList '/Online','/Cleanup-Image','/RestoreHealth' -TreatNonZeroAsError
}

function Optimize-ComponentStore {
    [CmdletBinding()]
    param()
    Set-LiveProgressState -StepPercent 10 -Status 'Cleanup del almacén de componentes'
    Invoke-ExternalCommand -Name 'DISM_ComponentCleanup' -FilePath 'dism.exe' -ArgumentList '/Online','/Cleanup-Image','/StartComponentCleanup' -TreatNonZeroAsError
}

function Reset-WinHttpProxy {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    Invoke-ExternalCommand -Name 'netsh_winhttp_reset_proxy' -FilePath 'netsh.exe' -ArgumentList 'winhttp','reset','proxy' -TreatNonZeroAsError
}

function Repair-WindowsUpdate {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $progressId = 6
    Write-Progress -Activity $script:ProgressActivity -Status 'Preparando reparación Windows Update' -PercentComplete 0 -Id $progressId
    Set-LiveProgressState -StepPercent 5 -Status 'Deteniendo servicios de Windows Update'

    $sd    = Join-Path $env:WINDIR 'SoftwareDistribution'
    $sdBak = "$sd.bak"
    $cr2   = Join-Path $env:WINDIR 'System32\catroot2'
    $cr2Bak= "$cr2.bak"

    $services = 'wuauserv','bits','cryptsvc'
    foreach ($svc in $services) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($svc, 'Stop service')) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }
    }

    Set-LiveProgressState -StepPercent 25 -Status 'Respaldando carpetas de distribución'

    if (Test-Path $sd -and -not (Test-Path $sdBak) -and $PSCmdlet.ShouldProcess($sd, 'Renombrar SoftwareDistribution')) {
        Rename-Item -Path $sd -NewName $sdBak -ErrorAction SilentlyContinue
        Write-JsonLog -Type 'WindowsUpdate' -Data @{ Action='Rename'; Path=$sd; NewPath=$sdBak }
    }

    if (Test-Path $cr2 -and -not (Test-Path $cr2Bak) -and $PSCmdlet.ShouldProcess($cr2, 'Renombrar catroot2')) {
        Rename-Item -Path $cr2 -NewName $cr2Bak -ErrorAction SilentlyContinue
        Write-JsonLog -Type 'WindowsUpdate' -Data @{ Action='Rename'; Path=$cr2; NewPath=$cr2Bak }
    }

    Set-LiveProgressState -StepPercent 60 -Status 'Reiniciando servicios de Windows Update'

    foreach ($svc in 'cryptsvc','bits','wuauserv') {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Running' -and $PSCmdlet.ShouldProcess($svc, 'Start service')) {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
    }

    Write-Progress -Activity $script:ProgressActivity -Status 'Reparación Windows Update completada' -Completed -Id $progressId
    Set-LiveProgressState -StepPercent 100 -Status 'Windows Update reparado'
}

function Repair-WindowsSearchIndex {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $searchService = Get-Service -Name 'WSearch' -ErrorAction SilentlyContinue
    if (-not $searchService) {
        Write-JsonLog -Type 'SearchIndex' -Data @{ Action = 'Skip'; Reason = 'Servicio WSearch no encontrado' }
        return
    }

    $progressId = 7
    $dataPath   = Join-Path $env:ProgramData 'Microsoft\Search\Data'
    $appPath    = Join-Path $dataPath 'Applications\Windows'
    $edbPath    = Join-Path $appPath 'Windows.edb'
    $edbBackup  = "$edbPath.$($script:Timestamp).bak"

    Write-Progress -Activity $script:ProgressActivity -Status 'Preparando reparación del indexador' -PercentComplete 0 -Id $progressId
    Set-LiveProgressState -StepPercent 5 -Status 'Deteniendo servicio de búsqueda'

    if ($searchService.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess('WSearch', 'Detener servicio de indexación')) {
        Stop-Service -Name $searchService.Name -Force -ErrorAction SilentlyContinue
    }

    Set-LiveProgressState -StepPercent 30 -Status 'Respaldando base de datos del índice'
    if (Test-Path $edbPath -and $PSCmdlet.ShouldProcess($edbPath, 'Respaldar base de datos de índice dañada')) {
        try {
            Move-Item -Path $edbPath -Destination $edbBackup -Force -ErrorAction Stop
            Write-JsonLog -Type 'SearchIndex' -Data @{ Action = 'BackupEdb'; Source = $edbPath; Backup = $edbBackup }
        }
        catch {
            Write-JsonLog -Type 'SearchIndexError' -Data @{ Action = 'BackupEdb'; Error = $_.Exception.Message }
        }
    }

    if (Test-Path $appPath -and $PSCmdlet.ShouldProcess($appPath, 'Limpiar archivos temporales del índice')) {
        Get-ChildItem -Path $appPath -Filter '*.log' -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    Set-LiveProgressState -StepPercent 65 -Status 'Reconstruyendo catálogo de búsqueda'
    if ($PSCmdlet.ShouldProcess('WSearch', 'Iniciar reconstrucción de índice')) {
        Start-Service -Name $searchService.Name -ErrorAction SilentlyContinue
        Invoke-ExternalCommand -Name 'Search_RebuildCatalog' -FilePath 'rundll32.exe' -ArgumentList 'searchindexer.dll,GenerateCatalog'
    }

    Write-Progress -Activity $script:ProgressActivity -Status 'Reparación del indexador completada' -Completed -Id $progressId
    Set-LiveProgressState -StepPercent 100 -Status 'Indexador reparado'
}

function Invoke-NetworkCleanup {
    Invoke-ExternalCommand -Name 'ipconfig_flushdns' -FilePath 'ipconfig.exe' -ArgumentList '/flushdns' -TreatNonZeroAsError
    Invoke-ExternalCommand -Name 'arp_flush'         -FilePath 'arp.exe'      -ArgumentList '-d','*' -TreatNonZeroAsError
}

function Invoke-TempCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $paths = @(
        'C:\Windows\Temp',
        $env:TEMP,
        (Join-Path $env:LOCALAPPDATA 'Temp'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\INetCache'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Temporary Internet Files'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default\Cache'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default\Cache')
    ) | Where-Object { $_ }

    $progressId = 4
    $total = $paths.Count
    $index = 0

    foreach ($p in $paths) {
        $index++
        $percent = [math]::Floor(($index / [double]$total) * 100)
        Write-Progress -Activity $script:ProgressActivity -Status "Limpieza temporal: $p" -PercentComplete $percent -Id $progressId
        Set-LiveProgressState -StepPercent $percent -Status "Limpieza de temporales ($index/$total)"

        if (Test-Path $p) {
            Write-JsonLog -Type 'TempCleanupPath' -Data @{ Path = $p }
            Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue |
                ForEach-Object {
                    if ($PSCmdlet.ShouldProcess($_.FullName, 'Eliminar temporal')) {
                        Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    }
                }
        }
    }

    Write-Progress -Activity $script:ProgressActivity -Status 'Limpieza temporal completada' -Completed -Id $progressId
    Set-LiveProgressState -StepPercent 100 -Status 'Limpieza de temporales completada'
}

function Invoke-DuplicateScan {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $userRoot    = $env:USERPROFILE
    $dataFolders = 'Desktop','Documents','Downloads','Pictures','Videos','Music','OneDrive'
    $scanRoots   = @()

    foreach ($df in $dataFolders) {
        $path = Join-Path $userRoot $df
        if (Test-Path $path) { $scanRoots += $path }
    }

    if (-not $scanRoots) {
        Write-JsonLog -Type 'Duplicates' -Data @{ Note = 'No se encontraron carpetas de datos.' }
        return
    }

    $sizeCounts = @{}
    $processed = 0
    $progressId = 5
    $sizeStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Get-ChildItem -Path $scanRoots -File -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $processed++
            if ($processed % 200 -eq 0) {
                $rate = if ($sizeStopwatch.Elapsed.TotalSeconds -gt 0) { [math]::Round($processed / $sizeStopwatch.Elapsed.TotalSeconds, 1) } else { 0 }
                Write-Progress -Activity $script:ProgressActivity -Status "Escaneo duplicados: $processed archivos" -PercentComplete -1 -Id $progressId
                Set-LiveProgressState -StepPercent ([math]::Min(20, [math]::Floor($processed / 200))) -Status "Escaneo tamaño ($processed archivos)" -Throughput "~$rate archivos/s"
            }

            $length = $_.Length
            if ($sizeCounts.ContainsKey($length)) {
                $sizeCounts[$length]++
            }
            else {
                $sizeCounts[$length] = 1
            }
        }

    $candidateSizes = $sizeCounts.GetEnumerator() | Where-Object { $_.Value -gt 1 } | ForEach-Object { $_.Key }
    if (-not $candidateSizes) {
        Write-JsonLog -Type 'Duplicates' -Data @{ Note = 'Sin candidatos por tamaño.' }
        Write-Progress -Activity $script:ProgressActivity -Status 'Escaneo duplicados completado' -Completed -Id $progressId
        Set-LiveProgressState -StepPercent 100 -Status 'Sin duplicados por tamaño'
        return
    }

    Set-LiveProgressState -StepPercent 25 -Status "$($candidateSizes.Count) tamaños con posibles duplicados"

    $hashErrors = 0
    $hashGroups = @{}
    $algorithm  = 'MD5'
    $stopHash   = $false
    $hashStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $hashed = 0

    Get-ChildItem -Path $scanRoots -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $candidateSizes -contains $_.Length } |
        ForEach-Object {
            $hashed++
            if ($stopHash) { return }
            try {
                $hash = Get-FileHash -Path $_.FullName -Algorithm $algorithm -ErrorAction Stop
                $key = $hash.Hash
                if (-not $hashGroups.ContainsKey($key)) {
                    $hashGroups[$key] = New-Object System.Collections.Generic.List[pscustomobject]
                }
                $hashGroups[$key].Add([pscustomobject]@{ FullName=$_.FullName; Length=$_.Length; Hash=$key; LastWriteTime=$_.LastWriteTime; Algorithm=$algorithm })
            }
            catch {
                $hashErrors++
                Write-JsonLog -Type 'DuplicateHashError' -Data @{ File = $_.FullName; Error = $_.Exception.Message }
                if ($hashErrors -ge $script:MaxHashErrorLimit) {
                    Write-Warning "Se alcanzó el límite de errores de hash ($script:MaxHashErrorLimit)."
                    $stopHash = $true
                }
            }

            if ($hashed % 100 -eq 0) {
                $rate = if ($hashStopwatch.Elapsed.TotalSeconds -gt 0) { [math]::Round($hashed / $hashStopwatch.Elapsed.TotalSeconds, 1) } else { 0 }
                $stepPercent = 25 + [math]::Min(50, [math]::Floor($hashed / 200))
                Set-LiveProgressState -StepPercent $stepPercent -Status "Hashing duplicados ($hashed archivos)" -Throughput "~$rate hashes/s"
            }
        }

    $dupGroups = $hashGroups.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    if (-not $dupGroups) {
        Write-JsonLog -Type 'Duplicates' -Data @{ Note = "Sin duplicados por hash ($algorithm)." }
        Write-Progress -Activity $script:ProgressActivity -Status 'Escaneo duplicados completado' -Completed -Id $progressId
        Set-LiveProgressState -StepPercent 100 -Status 'Sin duplicados por hash'
        return
    }

    Set-LiveProgressState -StepPercent 80 -Status "Cuarentena de duplicados ($($dupGroups.Count) grupos)"
    $quarantineRoot = Join-Path $userRoot '_Duplicates_Quarantine'
    $quarantineDir  = Join-Path $quarantineRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
    if (-not (Test-Path $quarantineDir)) {
        $null = New-Item -Path $quarantineDir -ItemType Directory -Force
    }

    foreach ($group in $dupGroups) {
        $ordered = $group.Value | Sort-Object LastWriteTime
        $keep    = $ordered[0]
        $dups    = $ordered | Select-Object -Skip 1

        foreach ($dup in $dups) {
            $relative   = $dup.FullName.Substring($userRoot.Length).TrimStart('\\')
            $targetPath = Join-Path $quarantineDir $relative
            $targetDir  = Split-Path $targetPath -Parent
            if (-not (Test-Path $targetDir)) {
                $null = New-Item -Path $targetDir -ItemType Directory -Force
            }

            if ($PSCmdlet.ShouldProcess($dup.FullName, 'Mover archivo duplicado a cuarentena')) {
                try {
                    Move-Item -Path $dup.FullName -Destination $targetPath -Force -ErrorAction Stop
                    Write-JsonLog -Type 'MoveDuplicateFile' -Data @{
                        OriginalPath = $dup.FullName
                        NewPath      = $targetPath
                        Hash         = $dup.Hash
                        Algorithm    = $dup.Algorithm
                        Length       = $dup.Length
                        KeepFile     = $keep.FullName
                    }
                }
                catch {
                    Write-JsonLog -Type 'MoveDuplicateFileError' -Data @{ OriginalPath = $dup.FullName; TargetPath = $targetPath; Error = $_.Exception.Message }
                }
            }
        }
    }

    Write-Progress -Activity $script:ProgressActivity -Status 'Escaneo duplicados completado' -Completed -Id $progressId
    Set-LiveProgressState -StepPercent 100 -Status 'Cuarentena de duplicados finalizada'
}

function Restore-CodexCli {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Set-LiveProgressState -StepPercent 10 -Status 'Verificando npm'
    $npmCommand = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npmCommand) {
        Write-JsonLog -Type 'CodexCli' -Data @{ Action = 'Skip'; Reason = 'npm no encontrado en PATH' }
        return
    }

    $npmPath = $npmCommand.Source
    $uninstallArgs = 'uninstall','-g','codex','--silent'
    $installArgs   = 'install','-g','codex@latest','--silent'

    Set-LiveProgressState -StepPercent 30 -Status 'Eliminando codex global previo'
    if ($PSCmdlet.ShouldProcess('codex', 'Eliminar paquete global')) {
        Invoke-ExternalCommand -Name 'npm_uninstall_codex' -FilePath $npmPath -ArgumentList $uninstallArgs
    }

    Set-LiveProgressState -StepPercent 60 -Status 'Instalando codex@latest'
    if ($PSCmdlet.ShouldProcess('codex', 'Instalar versión más reciente')) {
        Invoke-ExternalCommand -Name 'npm_install_codex_latest' -FilePath $npmPath -ArgumentList $installArgs -TreatNonZeroAsError
    }

    $verifyArgs = 'list','-g','codex','--json','--depth','0'
    $tempFile   = [System.IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath $npmPath -ArgumentList $verifyArgs -RedirectStandardOutput $tempFile -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0 -and (Test-Path $tempFile)) {
            $json = Get-Content -Path $tempFile -Raw -ErrorAction SilentlyContinue
            Write-JsonLog -Type 'CodexCli' -Data @{ Action = 'Verify'; ExitCode = $process.ExitCode; Output = $json }
            Set-LiveProgressState -StepPercent 100 -Status 'Codex CLI habilitado'
        }
        else {
            Write-JsonLog -Type 'CodexCli' -Data @{ Action = 'Verify'; ExitCode = $process.ExitCode; Note = 'La verificación no devolvió datos.' }
            Set-LiveProgressState -StepPercent 90 -Status 'Verificación Codex CLI sin datos'
        }
    }
    catch {
        Write-JsonLog -Type 'CodexCliError' -Data @{ Action = 'Verify'; Error = $_.Exception.Message }
        Set-LiveProgressState -StepPercent 90 -Status "Error al verificar Codex CLI: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue }
    }
}

function Find-StaleProgram {
    [CmdletBinding()]
    param()
    $uninstallKeys = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $entries = foreach ($key in $uninstallKeys) {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallLocation, UninstallString
    }

    if (-not $entries) { return }

    $stale = foreach ($e in $entries) {
        if ($e.InstallLocation -and -not (Test-Path $e.InstallLocation)) { $e }
    }

    if ($stale) {
        Write-JsonLog -Type 'StalePrograms' -Data @{ Count = $stale.Count; Items = $stale }
    }
}

Initialize-Logging

Write-JsonLog -Type 'SessionStart' -Data @{
    ComputerName = $env:COMPUTERNAME
    UserName     = $env:USERNAME
    OSVersion    = [System.Environment]::OSVersion.VersionString
    PSVersion    = $PSVersionTable.PSVersion.ToString()
    LogDirectory = $script:LogDirectory
    Timestamp    = $script:Timestamp
}

$availableSteps = [ordered]@{
    Diagnostics             = { Get-SystemDiagnostic }
    PerformanceSnapshot     = { Get-PerformanceSnapshot }
    RepairPerformanceCounters = { Repair-PerformanceCounter }
    DefenderScan            = { Invoke-DefenderMaintenance }
    SystemFileRepair        = { Repair-SystemFile }
    ComponentStoreCleanup   = { Optimize-ComponentStore }
    ResetWinHTTP            = { Reset-WinHttpProxy }
    RepairWindowsUpdate     = { Repair-WindowsUpdate }
    RepairSearchIndex       = { Repair-WindowsSearchIndex }
    NetworkCleanup          = { Invoke-NetworkCleanup }
    TempCleanup             = { Invoke-TempCleanup }
    DuplicateFilesUserProfile = { Invoke-DuplicateScan }
    RestoreCodexCli         = { Restore-CodexCli }
    DetectStalePrograms     = { Find-StaleProgram }
}

$stepsToRun = $availableSteps.Keys
if ($Step) {
    $stepsToRun = $availableSteps.Keys | Where-Object { $Step -contains $_ }
}
if ($SkipStep) {
    $stepsToRun = $stepsToRun | Where-Object { $SkipStep -notcontains $_ }
}

$stepsToRun = $stepsToRun | Where-Object { $availableSteps.Contains($_) }

$stepCount = $stepsToRun.Count
if ($stepCount -eq 0) {
    throw 'No hay pasos seleccionados para ejecutar.'
}

$index = 0
foreach ($stepName in $stepsToRun) {
    $index++
    $action = $availableSteps[$stepName]
    Invoke-MaintenanceStep -Name $stepName -Action $action -Index $index -Total $stepCount
}

Write-JsonLog -Type 'SessionEnd' -Data @{ Completed = $true; LogRoot = $script:LogDirectory }

if (-not $NoTranscript) {
    try { Stop-Transcript | Out-Null }
    catch { Write-Warning "No se pudo cerrar el Transcript: $($_.Exception.Message)" }
}

Write-Progress -Activity $script:ProgressActivity -Completed -Id 1
if (-not $Quiet) {
    Write-Information "Mantenimiento maestro completado. Revisa los logs en: $($script:LogDirectory)" -InformationAction Continue
}
