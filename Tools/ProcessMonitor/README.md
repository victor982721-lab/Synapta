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

- Native processes appear dimmed (`Gray`) when you run `Show-TopMemoryProcesses`, so any bright line is worth investigating; the table still prints the `IsNative` flag alongside.

## Usage notes

1. Import the module from the repo (or your user module path):
   ```powershell
   Import-Module 'C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Tools\ProcessMonitor\ProcessMonitor.psm1'
   ```
2. Run the public function:
   ```powershell
   Show-TopMemoryProcesses -Top 30
   ```
   Add `-ReturnObjects` if you want to capture the filtered list as objects for downstream scripting or exports.
3. Pipe the output to `Export-Csv` or `Out-File` if you need reporting or persistence.

The module also exposes `Get-SafeProcessPropertyValue` for internal use but only exports `Show-TopMemoryProcesses`. Keep this copy with your other tooling so you can document, extend, and version the helper inside `Tools`.
