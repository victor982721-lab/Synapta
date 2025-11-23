# ProcessMonitor PowerShell Module

This folder mirrors the `ProcessMonitor` module that lives in your user `PowerShell\Modules` path so you can version the helper inside the **Neurologic** repo.

## `Show-TopMemoryProcesses`

- **Purpose**: sorts the top consumers of memory and enriches the table with metadata useful for troubleshooting.
- **Key columns**
  - `Memory (MB)` / `Memory (%)`: working set consumption and its share of system RAM.
  - `Memory Delta (MB)`: difference compared to the previous run, so you can spot spikes or drops between invocations.
  - `CPU (s)` / `CPU (%)`: accumulated CPU time and an estimated percent of total CPU (distributed across logical cores using the process uptime).
  - `IsNative`: boolean flag set when the executable or a known native process name lives under `%SystemRoot%`, `%WINDIR%`, `System32`, `SysWOW64`, or the common Microsoft program folders (`%ProgramFiles%\Microsoft*`, `%ProgramFiles(x86)%\Microsoft*`, `%ProgramFiles%\Windows Defender`, etc.). That list also includes names such as `MsMpEng`/`Memory Compression` so Defender and memory management services stay flagged even when their path cannot be retrieved.
  - `Threads`, `Handles`, `StartTime`, `Path`: provide process context for identifying misbehaving apps.

## Snapshot tracking

- The module writes the last snapshot to `%LOCALAPPDATA%\ProcessMonitor\lastSnapshot.json`. `Memory Delta (MB)` is always computed against the previous run; if the file is missing or corrupted the helper recovers silently and starts tracking again.

## Display hints

- The default table draws a slim 8-column grid with cyan headers, gray separators, and green-tinted rows for native binaries; the footer explains that natives fade into the background while long paths are truncated. Memory/CPU columns turn yellow/red as percentages pass the `-MemoryWarnPercent`/`-MemoryAlertPercent` and `-CpuWarnPercent`/`-CpuAlertPercent` thresholds, and dark cyan highlights big drops in `Memory Delta`.
- Use `-Detalle` to switch to the multi-line breakdown you already saw if you need every field expanded, or add `-ReturnObjects` to capture the raw data for scripts.
  You can also pass `-MinMemoryMB`/`-MinCpuPercent` to skip the entries below a threshold or `-HideNative` to omit Windows-built services entirely before printing.
- Each row is assigned a `Category` (Security, Browser, Shell, System, Office, VM, Media, Database, Other) based on process names/paths so you can scan by workload type.
- The memory and CPU columns turn yellow/red when the reported ratios exceed the thresholds you pass (`-MemoryWarnPercent`/`-MemoryAlertPercent` and `-CpuWarnPercent`/`-CpuAlertPercent`), letting you spot spiky workloads at a glance.

## Usage notes

1. Import the module from the repo (or your user module path):
   ```powershell
   Import-Module 'C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Tools\ProcessMonitor\ProcessMonitor.psm1'
   ```
2. Run the public function:
   ```powershell
   Show-TopMemoryProcesses -Top 30
   ```
   * Add `-Detalle` to skip the tabular view and print a per-process breakdown (the output uses the same green/gray styling you saw before).
   * Add `-ReturnObjects` if you want to capture the filtered list as objects for downstream scripting or exports.
   * Filter the table earlier with `-MinMemoryMB <value>` / `-MinCpuPercent <value>` or drop Windows-built rows using `-HideNative`.
   * Tune the coloring thresholds with `-MemoryWarnPercent`, `-MemoryAlertPercent`, `-CpuWarnPercent`, and `-CpuAlertPercent`.
3. Pipe the output to `Export-Csv` or `Out-File` if you need reporting or persistence.

The module also exposes `Get-SafeProcessPropertyValue` for internal use but only exports `Show-TopMemoryProcesses`. Keep this copy with your other tooling so you can document, extend, and version the helper inside `Tools`.
