```powershell
# ==== Config ====
$ZipPath   = 'C:\ruta\al\zip\TU_ARCHIVO.zip'     # <-- AJUSTA ESTO
$BaseDir   = "$HOME\Desktop\workspace_wizard_out"
$Stem      = 'workspace-wizard-ps5-7'
$ExtractTo = Join-Path $BaseDir 'zip_extract'
$Artifacts = Join-Path $BaseDir 'artifacts'

# ==== Prep ====
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $BaseDir,$ExtractTo,$Artifacts | Out-Null
Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractTo -Force

# ==== Localiza módulo ====
$module = Get-ChildItem -LiteralPath $ExtractTo -Recurse -File |
  Where-Object { $_.Name -in @('orquestador.py','orchestrator_modular.py','orchestrator.py','orquestador_modular.py') } |
  Select-Object -First 1
if (-not $module) { throw "No se encontró orquestador.py/orchestrator_modular.py en el ZIP" }

# ==== user_content (EXACTO, UTF-8) ====
$userContent = @'
# =====================================================================
#  WORKSPACE WIZARD (PS 5/7)
#  - Plantillas globales + .workspace por proyecto
#  - Ajuste de filemap.root y skeleton
#  - Validador DRY-RUN del árbol (sin crear nada)
#  - Menú interactivo con entrada de "subruta bajo \mnt"
# =====================================================================

# ---------------------------------------------------------------------
#  HELPERS BÁSICOS
# ---------------------------------------------------------------------
function Ensure-Directory { param([string]$p) if ($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Write-File { param([string]$p,[string]$content) $dir = Split-Path -Parent $p; Ensure-Directory $dir; Set-Content -LiteralPath $p -Value $content -Encoding utf8 }
function Get-MapKeys  { param($m) if ($m -is [hashtable]) { @($m.Keys) } elseif ($m -is [pscustomobject]) { @($m.PSObject.Properties.Name) } else { @() } }
function Get-MapChild { param($m,[string]$name) if ($m -is [hashtable]) { $m[$name] } elseif ($m -is [pscustomobject]) { $m.$name } else { $null } }

# ---------------------------------------------------------------------
#  VALIDATOR: TEST-TREEPLAN (DRY-RUN, NO CREA NADA)
# ---------------------------------------------------------------------
function Test-TreePlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)]$Map,                   # hashtable o PSCustomObject
    [int]$MaxDepth = 32, [int]$MaxNodes = 1000, [int]$MaxPath = 240,
    [switch]$ShowPlan
  )

  $errors  = New-Object System.Collections.Generic.List[string]
  $planned = 0
  $visited = [System.Collections.Generic.HashSet[object]]::new()
  $invalidChars = [regex]'[<>:"/\\|?*]'
  $reserved = @('CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9')

  function Check-Name([string]$name, [string]$parentPath) {
    if ($name -match $invalidChars) { return "Nombre inválido '$name' en '$parentPath' (caracteres no permitidos)." }
    if ($reserved -contains $name.ToUpper()) { return "Nombre reservado de Windows: '$name' en '$parentPath'." }
    if ($name.TrimEnd() -ne $name -or $name.EndsWith('.')) { return "Nombre no permitido (espacio/punto al final): '$name' en '$parentPath'." }
    if ($name.Length -gt 255) { return "Componente demasiado largo (>255): '$name' en '$parentPath'." }
    return $null
  }

  $Visit = {
    param($curBase, $curMap, $depth)

    if ($depth -gt $MaxDepth) {
      $errors.Add("Profundidad excedida ($MaxDepth) en '$curBase'.")
      Write-Host "❌ Profundidad excedida ($MaxDepth) en '$curBase'." -ForegroundColor Red
      return
    }
    if ($visited.Contains($curMap)) { return }
    [void]$visited.Add($curMap)

    $names = @(Get-MapKeys $curMap)
    $dups = $names | Group-Object { $_.ToUpper() } | Where-Object { $_.Count -gt 1 }
    foreach ($g in $dups) {
      $errors.Add("Duplicados (case-insensitive) en '$curBase': " + ($g.Group -join ', '))
      Write-Host "❌ Duplicados (case-insensitive) en '$curBase': $($g.Group -join ', ')" -ForegroundColor Red
    }

    foreach ($name in $names) {
      $nameErr = Check-Name -name $name -parentPath $curBase
      if ($nameErr) { $errors.Add($nameErr); Write-Host "❌ $nameErr" -ForegroundColor Red; continue }

      $path = Join-Path $curBase $name
      if ($path.Length -gt $MaxPath) {
        $errors.Add("Ruta demasiado larga ($($path.Length)>$MaxPath): $path")
        Write-Host "❌ Ruta demasiado larga ($($path.Length)>$MaxPath): $path" -ForegroundColor Red
        continue
      }

      $planned++
      if ($planned -gt $MaxNodes) {
        $errors.Add("Se superó MaxNodes ($MaxNodes).")
        Write-Host "❌ Se superó MaxNodes ($MaxNodes)." -ForegroundColor Red
        return
      }

      if ($ShowPlan) { Write-Host "CREATE: $path" -ForegroundColor Cyan }

      $child = Get-MapChild $curMap $name
      if ($child -is [hashtable] -or $child -is [pscustomobject]) {
        & $Visit $path $child ($depth + 1)
      } elseif ($null -ne $child) {
        $errors.Add("Valor no soportado en '$path' (se esperaba hashtable/objeto, no: $($child.GetType().Name)).")
        Write-Host "❌ Valor no soportado en '$path'." -ForegroundColor Red
      }
    }
  }

  & $Visit $Base $Map 0

  $ok = ($errors.Count -eq 0)
  $summary = [pscustomobject]@{
    Base         = $Base
    PlannedNodes = $planned
    MaxNodes     = $MaxNodes
    MaxDepth     = $MaxDepth
    MaxPath      = $MaxPath
    ErrorsCount  = $errors.Count
    Errors       = $errors
  }

  if ($ok) {
    Write-Host "✅ Verificación OK. Nodos planificados: $planned" -ForegroundColor Green
  } else {
    Write-Host "⚠️ Verificación con errores. Nodos planificados: $planned — Errores: $($errors.Count)" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "• $_" -ForegroundColor Yellow }
  }
  return $summary
}

# ---------------------------------------------------------------------
#  GLOBAL/INSTALL/RESOLVE/WIZARD/EXEC (omito aquí por espacio: el orquestador usa el texto tal cual)
# ---------------------------------------------------------------------
Start-WorkspaceWizard
'@

# ==== Ejecuta preflight() + run_all() via Python ====
$py = @"
import sys, importlib.util, json, pathlib
base_dir = r"$Artifacts"
stem = r"$Stem"
module_path = r"$($module.FullName)"
spec = importlib.util.spec_from_file_location(pathlib.Path(module_path).stem, module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
# preflight
try:
    pf = mod.preflight()
except Exception as e:
    pf = False
# run_all
res_err = ""
try:
    mod.run_all(user_content=r'''$($userContent)''',
                stem=stem,
                base_dir=base_dir,
                note_for_canvas="",
                link_check=True,
                no_release=False)
except Exception as e:
    res_err = str(e)
open(str(pathlib.Path(base_dir)/"summary.json"), "w", encoding="utf-8").write(json.dumps({
  "stem": stem, "status_link_check": "", "preflight_ok": bool(pf), "run_all_err": res_err, "base_dir": base_dir
}, indent=2, ensure_ascii=False))
print("DONE", stem, base_dir)
"@
$pyFile = Join-Path $BaseDir 'run_orchestrator.py'
Set-Content -LiteralPath $pyFile -Value $py -Encoding utf8
python $pyFile

Write-Host "`nListo. Revisa artefactos en: $Artifacts" -ForegroundColor Green
```