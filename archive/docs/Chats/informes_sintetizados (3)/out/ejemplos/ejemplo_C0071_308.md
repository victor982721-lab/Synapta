```json
{
  "metadata": {
    "script_name": "PS-Env-Audit-CLEAN.ps1",
    "size_bytes": 12750,
    "sha256": "1b9e2d7d0e8f2b0d9b8f0e2d3c0b6bf9e56a656abfe7b433160d9165a9e7fcc0",
    "detected_encoding": "utf-8",
    "target_os": "Windows 10 Pro 10.0.19045",
    "target_ps_version": "7.5.3",
    "analyzed_at_utc": "2025-09-20T12:00:00Z"
  },
  "findings": [
    {
      "id": "R02-EmptyCatch-1",
      "rule": "R02-EmptyCatch",
      "category": "Robustez",
      "severity": "Low",
      "confidence": 0.8,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 38,
      "column": null,
      "snippet": "037:     $o=[ordered]@{ FrameworkDescription=$null; RuntimeIdentifier=$null; Version=$null; ClrVersionLegacy=$null }\n038:     try { $o.FrameworkDescription=[Runtime.InteropServices.RuntimeInformation]::FrameworkDescription } catch {}\n039:     try { $o.RuntimeIdentifier=[Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier } catch {}",
      "rationale": "Bloque catch vacío oculta errores. Reduce trazabilidad. Aceptable si es telemetría no crítica.",
      "fix_template": "En catch, registrar el error o establecer valor por defecto explícito. Ej: catch { $err=$_.Exception.Message; $o.Prop=$null }",
      "fix_patch_hint": "Sustituir {} por { Write-Verbose $_; $null } o manejo específico."
    },
    {
      "id": "R02-EmptyCatch-2",
      "rule": "R02-EmptyCatch",
      "category": "Robustez",
      "severity": "Low",
      "confidence": 0.8,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 39,
      "column": null,
      "snippet": "038:     try { $o.FrameworkDescription=[Runtime.InteropServices.RuntimeInformation]::FrameworkDescription } catch {}\n039:     try { $o.RuntimeIdentifier=[Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier } catch {}\n040:     try { if ($PSVersionTable.ContainsKey('CLRVersion') -and $PSVersionTable.CLRVersion) { $o.ClrVersionLegacy=$PSVersionTable.CLRVersion.ToString() } } catch {}",
      "rationale": "Bloque catch vacío oculta errores. Reduce trazabilidad. Aceptable si es telemetría no crítica.",
      "fix_template": "En catch, registrar el error o establecer valor por defecto explícito. Ej: catch { $err=$_.Exception.Message; $o.Prop=$null }",
      "fix_patch_hint": "Sustituir {} por { Write-Verbose $_; $null } o manejo específico."
    },
    {
      "id": "R02-EmptyCatch-3",
      "rule": "R02-EmptyCatch",
      "category": "Robustez",
      "severity": "Low",
      "confidence": 0.8,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 40,
      "column": null,
      "snippet": "039:     try { $o.RuntimeIdentifier=[Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier } catch {}\n040:     try { if ($PSVersionTable.ContainsKey('CLRVersion') -and $PSVersionTable.CLRVersion) { $o.ClrVersionLegacy=$PSVersionTable.CLRVersion.ToString() } } catch {}\n041:     try { $o.Version=[Environment]::Version.ToString() } catch {}",
      "rationale": "Bloque catch vacío oculta errores. Reduce trazabilidad. Aceptable si es telemetría no crítica.",
      "fix_template": "En catch, registrar el error o establecer valor por defecto explícito. Ej: catch { $err=$_.Exception.Message; $o.Prop=$null }",
      "fix_patch_hint": "Sustituir {} por { Write-Verbose $_; $null } o manejo específico."
    },
    {
      "id": "R01-ErrorActionMissing-4",
      "rule": "R01-ErrorActionMissing",
      "category": "Robustez",
      "severity": "Medium",
      "confidence": 0.6,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 154,
      "column": null,
      "snippet": "154: Set-Content -LiteralPath $ReportPath -Value $json -Encoding UTF8",
      "rationale": "Set-Content sin -ErrorAction. En errores no detiene el flujo. Recomendado -ErrorAction Stop + try/catch.",
      "fix_template": "Set-Content ... -ErrorAction Stop",
      "fix_patch_hint": "Envolver en try/catch si es parte del flujo crítico de salida."
    },
    {
      "id": "R01-ErrorActionMissing-5",
      "rule": "R01-ErrorActionMissing",
      "category": "Robustez",
      "severity": "Medium",
      "confidence": 0.6,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 200,
      "column": null,
      "snippet": "200: Set-Content -LiteralPath $ReportPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8",
      "rationale": "Set-Content sin -ErrorAction. En errores no detiene el flujo. Recomendado -ErrorAction Stop + try/catch.",
      "fix_template": "Set-Content ... -ErrorAction Stop",
      "fix_patch_hint": "Envolver en try/catch si es parte del flujo crítico de salida."
    },
    {
      "id": "R01-ErrorActionMissing-6",
      "rule": "R01-ErrorActionMissing",
      "category": "Robustez",
      "severity": "Medium",
      "confidence": 0.6,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 262,
      "column": null,
      "snippet": "262: Set-Content -LiteralPath $ReportPath -Value $text -Encoding UTF8",
      "rationale": "Set-Content sin -ErrorAction. En errores no detiene el flujo. Recomendado -ErrorAction Stop + try/catch.",
      "fix_template": "Set-Content ... -ErrorAction Stop",
      "fix_patch_hint": "Envolver en try/catch si es parte del flujo crítico de salida."
    },
    {
      "id": "R01-ErrorActionMissing-7",
      "rule": "R01-ErrorActionMissing",
      "category": "Robustez",
      "severity": "Low",
      "confidence": 0.5,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 265,
      "column": null,
      "snippet": "265: if ($OpenAfter) { Start-Process -FilePath $ReportPath }",
      "rationale": "Start-Process sin -ErrorAction. En errores no detiene el flujo. Recomendado -ErrorAction Stop + try/catch.",
      "fix_template": "Start-Process ... -ErrorAction Stop",
      "fix_patch_hint": "Envolver en try/catch si falla abrir el archivo."
    },
    {
      "id": "Q01-StrictModeMissing-8",
      "rule": "Q01-StrictModeMissing",
      "category": "Calidad",
      "severity": "Low",
      "confidence": 0.7,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 7,
      "column": null,
      "snippet": "005: #>\n006: \n007: [CmdletBinding()]\n008: param(\n009:     [string]$StartDirectory = \"$([Environment]::GetFolderPath('Desktop'))\",\n010:     [ValidateSet('markdown','json','txt')][string]$ReportFormat,\n011:     [string]$ReportPath = \"$([Environment]::GetFolderPath('Desktop'))\\PS_Env_Report.md\"",
      "rationale": "No se establece Set-StrictMode ni $ErrorActionPreference. Mejora detección temprana de errores.",
      "fix_template": "Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop' en alcance local.",
      "fix_patch_hint": "Añadir al inicio del script con comentario que justifique."
    },
    {
      "id": "R03-ParamValidation-9",
      "rule": "R03-ParamValidation",
      "category": "Robustez",
      "severity": "Low",
      "confidence": 0.6,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 8,
      "column": null,
      "snippet": "008: param(\n009:     [string]$StartDirectory = \"$([Environment]::GetFolderPath('Desktop'))\",\n010:     [ValidateSet('markdown','json','txt')][string]$ReportFormat,\n011:     [string]$ReportPath = \"$([Environment]::GetFolderPath('Desktop'))\\PS_Env_Report.md\",\n012:     [switch]$IncludeModuleInventory,\n013:     [switch]$IncludeEnvVars,\n014:     [switch]$IncludePaths,\n015:     [switch]$IncludeHardware,\n016:     [switch]$OpenAfter",
      "rationale": "Parámetros sin validaciones amplias. $ReportPath podría validar existencia del directorio y extensión coherente con ReportFormat.",
      "fix_template": "[ValidateScript({ Test-Path (Split-Path -Path $_ -Parent) } )]",
      "fix_patch_hint": "Agregar ValidateScript y reglas de coherencia."
    },
    {
      "id": "P01-LocalInfoExposure-10",
      "rule": "P01-LocalInfoExposure",
      "category": "Privacidad",
      "severity": "Low",
      "confidence": 0.9,
      "file": "PS-Env-Audit-CLEAN.ps1",
      "line": 80,
      "column": null,
      "snippet": "080: UserName=[Environment]::UserName\n081: MachineName=[Environment]::MachineName\n162: $lines += ('PowerShell: {0} {1}  Host: {2} {3}' -f $hostInfo.PSEdition,$hostInfo.PSVersion,$hostInfo.HostName,$hostInfo.HostVersion)\n209: $md.Add(('- PowerShell: {0} {1} - Host: {2} {3}' -f $hostInfo.PSEdition,$hostInfo.PSVersion,$hostInfo.HostName,$hostInfo.HostVersion)) | Out-Null",
      "rationale": "El reporte incluye UserName y MachineName. En tu entorno fijo es aceptable. Si compartes el archivo, podría filtrar datos.",
      "fix_template": "Ofuscar o permitir salida 'redacted' bajo conmutador.",
      "fix_patch_hint": "Añadir switch -Redact y reemplazar valores sensibles al construir el reporte."
    }
  ],
  "summary": {
    "counts_por_categoria": {
      "Robustez": 7,
      "Calidad": 1,
      "Privacidad": 1
    },
    "severidad": {
      "Low": 8,
      "Medium": 3
    },
    "score": 75.9,
    "top_risks": [
      "R01-ErrorActionMissing-6",
      "R01-ErrorActionMissing-5",
      "R01-ErrorActionMissing-4",
      "R01-ErrorActionMissing-2",
      "R01-ErrorActionMissing-1"
    ],
    "quick_wins": [
      "Añadir Set-StrictMode -Version Latest y $ErrorActionPreference = 'Stop' al inicio",
      "Agregar -ErrorAction Stop a Set-Content y envolver en try/catch",
      "Reemplazar catch {} por catch { registrar error }",
      "Opcional: switch -Redact para ofuscar UserName y MachineName si compartes el reporte"
    ]
  },
  "privacy": {
    "redacted": true,
    "redaction_map": [
      "{REDACTED:PATH}",
      "{REDACTED:IP}",
      "{REDACTED:USER}",
      "{REDACTED:MACHINE}"
    ]
  }
}
```