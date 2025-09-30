```powershell
$Global:_HasSimulatedPaths = ($Global:_SimulatedPaths.Count -gt 0)
if ($Global:_HasSimulatedPaths) {
  Write-Log -Level DryRun -Message ("Se simularon {0} rutas." -f $Global:_SimulatedPaths.Count)
}
```