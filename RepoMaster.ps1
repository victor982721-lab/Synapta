# =========================================================================================================================================================================================
# === RepoMaster - Script de administración de repositorios Synapta / Neurologic ===
# =========================================================================================================================================================================================
<#
.SYNOPSIS   
Herramienta interactiva para administrar repositorios del ecosistema Synapta/Neurologic desde una sola consola.

.DESCRIPTION
RepoMaster automatiza tareas frecuentes sobre repositorios Git alojados bajo una ruta base (por defecto, Documents\GitHub):
- Alta de subproyectos en Sandbox con estructura estándar (docs, csv, Scripts, src, tests).
- Generación de archivos base (AGENTS.md, README.md, .csproj, mapas ASCII, JSON de jerarquía, CSV, procedimientos).
- Sincronización de cambios locales hacia origin (pull + commit + push).
- Fusión de ramas Codex_YYYY-MM-DD generadas por agentes en la rama principal indicada.
- Análisis estático con PSScriptAnalyzer sobre proyectos creados.
- Descarga de artifacts publicados por GitHub Actions (vía GitHub CLI).
- Operaciones en lote sobre todos los repositorios Git detectados bajo la ruta base.
- Función “Doctor” para validar la estructura mínima esperada de cada proyecto.

El script está pensado como monolito interactivo: muestra menús, pregunta confirmaciones y guía al usuario en cada paso.
También admite un modo no interactivo básico mediante -InitialRepo y -AutoOption.

.PARAMETER BasePath
Ruta base donde se buscarán repositorios Git y se mostrará el menú de selección.
Por defecto: "$env:USERPROFILE\Documents\GitHub".

.PARAMETER DefaultBranch
Nombre de la rama principal sobre la que operan las funciones de sincronización y fusión (por ejemplo, main o master).
Puede ser sobreescrita por -InitialBranch.

.PARAMETER InitialRepo
Ruta a un repositorio concreto para ejecutar directamente una opción automática, sin pasar por el menú de selección.
Se usa en combinación con -AutoOption.

.PARAMETER AutoOption
Código de opción a ejecutar en modo automático sobre -InitialRepo.
Valores actuales:
  '1' = Crear estructura Sandbox en el repo inicial.
  '2' = Sincronizar cambios locales → origin/DefaultBranch.
  '3' = Fusionar Codex_YYYY-MM-DD → DefaultBranch.
  '4' = Descargar artifacts de GitHub Actions.
Otros valores se consideran no soportados y disparan una advertencia.

.PARAMETER InitialBranch
Permite sobreescribir la rama por defecto (-DefaultBranch) al inicio de la ejecución.
Si se indica, todas las operaciones que usan la rama principal trabajarán sobre este valor.

.NOTES
Autor:    ChatGPT (generado para el usuario).
Contexto: Ecosistema Synapta / Neurologic – administración de repos locales y flujos con Codex / GitHub.
Fecha:    19 de noviembre de 2025.

REQUISITOS:
- Git instalado y accesible en PATH (para Ensure-GitAvailable / Ensure-GitRepo / operaciones de sync).
- .NET SDK (para dotnet build / dotnet test en operaciones en lote).
- PSScriptAnalyzer instalado si se desea usar Invoke-PSSAAnalysis:
    Install-Module -Name PSScriptAnalyzer
- GitHub CLI (gh) configurado con autenticación válida para descargar artifacts:
    https://cli.github.com/  +  gh auth login

.LINK
(Interno) Documentación de estándares de proyecto Neurologic / Synapta, si aplica.

.EXAMPLE
# Uso interactivo normal sobre la ruta base por defecto
.\RepoMaster.ps1

.EXAMPLE
# Ejecutar directamente la creación de estructura Sandbox sobre un repo concreto
.\RepoMaster.ps1 -InitialRepo 'C:\Code\MyRepo' -AutoOption '1'

.EXAMPLE
# Trabajar sobre una rama principal distinta a main (por ejemplo, develop)
.\RepoMaster.ps1 -DefaultBranch 'develop'

#>
    
# =========================================================================================================================================================================================
# === Parámetros y configuración ===
# =========================================================================================================================================================================================

[CmdletBinding()]
param(
    [string]$BasePath = (Join-Path $env:USERPROFILE 'Documents\GitHub'),
    [string]$DefaultBranch = 'main',
    [string]$InitialRepo,
    [ValidateSet('1','2','3','4','5','6')]
    [string]$AutoOption,
    [string]$InitialBranch
)

# =========================================================================================================================================================================================
# === Si se especifica una rama inicial, se sobrepone al valor por defecto ===
# =========================================================================================================================================================================================

if ($InitialBranch) {
    $DefaultBranch = $InitialBranch
}

# =========================================================================================================================================================================================
# === Utilidades de salida por consola ===
# =========================================================================================================================================================================================

function Write-Info([string]$Message) {
    Write-Host "[neurologic] $Message" -ForegroundColor Cyan
}

function Write-WarnMsg([string]$Message) {
    Write-Host "[neurologic][WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrMsg([string]$Message) {
    Write-Host "[neurologic][ERROR] $Message" -ForegroundColor Red
}

# =========================================================================================================================================================================================
# === Función para cargar plantillas de disco ===
# =========================================================================================================================================================================================

function Get-TemplateContent {
    param(
        [string]$RepoPath,
        [string]$TemplateName
    )
    $path = Join-Path (Join-Path $RepoPath 'Templates') $TemplateName
    if (Test-Path $path) {
        return Get-Content -Raw -LiteralPath $path
    }
    return $null
}

# =========================================================================================================================================================================================
# === Función para expandir plantillas usando placeholders {{KEY}} ===
# =========================================================================================================================================================================================

function Expand-Template {
    param(
        [string]$Content,
        [hashtable]$Placeholders
    )
    $pattern = '\{\{([A-Z0-9_]+)\}\}'
    $scriptBlock = {
        param($m)
        $key = $m.Groups[1].Value
        if ($Placeholders.ContainsKey($key)) {
            $Placeholders[$key]
        } else {
            $m.Value
        }
    }
    return [regex]::Replace($Content, $pattern, $scriptBlock.GetNewClosure())
}

# =========================================================================================================================================================================================
# === Función para crear nuevos archivos basados en plantillas ===
# =========================================================================================================================================================================================

function New-FileFromTemplate {
    param(
        [string]$Destination,
        [string]$TemplateContent,
        [hashtable]$Placeholders,
        [string]$FallbackContent
    )
    if (Test-Path $Destination) { return }
    $content = if ($TemplateContent) {
        Expand-Template -Content $TemplateContent -Placeholders $Placeholders
    } else {
        Expand-Template -Content $FallbackContent -Placeholders $Placeholders
    }
    Set-Content -LiteralPath $Destination -Encoding UTF8 -Value $content
}

# =========================================================================================================================================================================================
# === Funciones de validación para Git ===
# =========================================================================================================================================================================================

function Ensure-GitAvailable {
    try {
        Get-Command git -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-ErrMsg "No se encontró 'git' en PATH."
        return $false
    }
}

function Ensure-GitRepo {
    param([string]$RepoPath)
    if (-not (Ensure-GitAvailable)) { return $false }
    if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
        Write-ErrMsg "La ruta '$RepoPath' no contiene un repositorio git."
        return $false
    }
    return $true
}

function Show-Changes {
    param([string[]]$Lines)
    if (-not $Lines -or $Lines.Count -eq 0 -or ([string]::IsNullOrWhiteSpace(($Lines -join '')))) {
        Write-Info "No hay cambios locales."
        return
    }
    Write-Info "Cambios locales:"
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
        $status = $line.Substring(0,2)
        $path   = $line.Substring(3).Trim()
        switch -Regex ($status) {
            '^\?\?' { Write-Host ("  + (untracked) {0}" -f $path) -ForegroundColor Green }
            '^A'    { Write-Host ("  + (added)     {0}" -f $path) -ForegroundColor Green }
            '^.A'   { Write-Host ("  + (added)     {0}" -f $path) -ForegroundColor Green }
            '^D'    { Write-Host ("  - (deleted)   {0}" -f $path) -ForegroundColor Red }
            '^.D'   { Write-Host ("  - (deleted)   {0}" -f $path) -ForegroundColor Red }
            '^M'    { Write-Host ("  ~ (modified)  {0}" -f $path) -ForegroundColor Yellow }
            '^.M'   { Write-Host ("  ~ (modified)  {0}" -f $path) -ForegroundColor Yellow }
            '^R'    { Write-Host ("  > (renamed)   {0}" -f $path) -ForegroundColor Magenta }
            default { Write-Host ("    (other)     {0} [{1}]" -f $path, $status.Trim()) -ForegroundColor DarkGray }
        }
    }
}

# =========================================================================================================================================================================================
# === Función para ejecutar análisis estático con PSScriptAnalyzer ===
# =========================================================================================================================================================================================

function Invoke-PSSAAnalysis {
    param([string]$Path)
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-WarnMsg "PSScriptAnalyzer no está instalado. Instálalo con 'Install-Module -Name PSScriptAnalyzer'."
        return
    }
    try {
        Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Warning,Error -Fix | Out-Null
        Write-Info "Análisis PSSA completado."
    } catch {
        Write-ErrMsg "El análisis PSSA falló: $($_.Exception.Message)"
    }
}

# =========================================================================================================================================================================================
# === Función para verificar la estructura del proyecto (Doctor) ===
# =========================================================================================================================================================================================

function Invoke-Doctor {
    param([string]$ProjectPath)
    $expected = @(
        'AGENTS.md',
        'README.md',
        'docs',
        'csv',
        'Scripts',
        'src',
        'tests'
    )
    foreach ($item in $expected) {
        $full = Join-Path $ProjectPath $item
        if (-not (Test-Path $full)) {
            Write-WarnMsg "Falta elemento obligatorio: $full"
        }
    }
    $dirName = Split-Path $ProjectPath -Leaf
    $csproj = Join-Path $ProjectPath "$dirName.csproj"
    if (-not (Test-Path $csproj)) {
        Write-WarnMsg "No existe el archivo de proyecto: $csproj"
    }
    $extra = @(
        'docs\Procedimiento_de_solicitud_de_artefactos.md',
        'docs\bitacora.md'
    )
    foreach ($file in $extra) {
        $fullExtra = Join-Path $ProjectPath $file
        if (-not (Test-Path $fullExtra)) {
            Write-WarnMsg "Recomendación: Crear $fullExtra"
        }
    }
    Write-Info "Revisión de estructura finalizada."
}

# =========================================================================================================================================================================================
# === Funciones para operaciones sobre múltiples repositorios ===
# =========================================================================================================================================================================================

function Invoke-MultiRepoMenu {
    param(
        [string]$RootPath,
        [string]$Branch
    )
    $repos = Get-ChildItem -Path $RootPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName '.git') }
    if (-not $repos) {
        Write-WarnMsg "No se encontraron repositorios bajo $RootPath."
        return
    }
    Write-Host ""
    Write-Host "=== Operaciones en lote ===" -ForegroundColor Cyan
    Write-Host "1. Crear estructura Sandbox en todos"
    Write-Host "2. Analizar con PSSA todos los repos"
    Write-Host "3. Ejecutar build y tests .NET en todos"
    Write-Host "4. Sincronizar cambios locales → origin/$Branch en todos"
    Write-Host "5. Doctor: revisar estructura de todos"
    Write-Host "6. Cancelar"
    $choice = Read-Host "Selecciona una opción para la operación en lote"
    switch ($choice) {
        '1' {
            foreach ($repo in $repos) {
                Invoke-StructureCreator -RepoPath $repo.FullName
            }
        }
        '2' {
            foreach ($repo in $repos) {
                Invoke-PSSAAnalysis -Path $repo.FullName
            }
        }
        '3' {
            foreach ($repo in $repos) {
                $csprojFiles = Get-ChildItem -Path $repo.FullName -Recurse -Filter '*.csproj' -ErrorAction SilentlyContinue
                foreach ($proj in $csprojFiles) {
                    try {
                        Write-Info "Compilando $($proj.FullName)..."
                        dotnet build $proj.FullName -c Release | Out-Null
                        Write-Info "Build completado para $($proj.Name)."
                        Write-Info "Ejecutando pruebas para $($proj.Name)..."
                        dotnet test $proj.DirectoryName | Out-Null
                        Write-Info "Pruebas completadas para $($proj.Name)."
                    } catch {
                        Write-ErrMsg "Falló build o test en $($proj.FullName): $($_.Exception.Message)"
                    }
                }
            }
        }
        '4' {
            foreach ($repo in $repos) {
                Invoke-SyncUp -RepoPath $repo.FullName -Branch $Branch
            }
        }
        '5' {
            foreach ($repo in $repos) {
                Invoke-Doctor -ProjectPath (Join-Path $repo.FullName 'Sandbox')
            }
        }
        default {
            Write-WarnMsg "Operación cancelada o inválida."
        }
    }
}

# =========================================================================================================================================================================================
# === Función principal para crear la estructura de proyecto ===
# =========================================================================================================================================================================================

function Invoke-StructureCreator {
    param([string]$RepoPath)
    $sandboxRoot = Join-Path $RepoPath 'Sandbox'
    if (-not (Test-Path $sandboxRoot)) {
        New-Item -ItemType Directory -Path $sandboxRoot -Force | Out-Null
    }
    Write-Host ""
    Write-Host "=== Crear estructura Sandbox ===" -ForegroundColor Cyan
    Write-Host "Repositorio: $RepoPath" -ForegroundColor Green
    $rawName = Read-Host "Nombre del proyecto"
    if ([string]::IsNullOrWhiteSpace($rawName)) {
        Write-ErrMsg "Nombre inválido."
        return
    }
    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $projectName = -join ($rawName.Trim().ToCharArray() | ForEach-Object { if ($invalid -notcontains $_) { $_ } })
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        Write-ErrMsg "El nombre solo contiene caracteres inválidos."
        return
    }
    $projectRoot = Join-Path $sandboxRoot $projectName
    if (Test-Path $projectRoot) {
        $reuse = Read-Host "La carpeta ya existe. ¿Continuar y reutilizarla? (S/N, ENTER=S)"
        if ([string]::IsNullOrWhiteSpace($reuse)) { $reuse = 'S' }
        if ($reuse.Trim().ToUpperInvariant() -ne 'S') {
            Write-WarnMsg "Operación cancelada."
            return
        }
    }
    $folders = @(
        $projectRoot,
        (Join-Path $projectRoot 'docs'),
        (Join-Path $projectRoot 'csv'),
        (Join-Path $projectRoot 'Scripts'),
        (Join-Path $projectRoot 'src'),
        (Join-Path $projectRoot 'tests')
    )
    foreach ($dir in $folders) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # =========================================================================================================================================================================================
    # Definición de variables a sustituir sin incluir llaves en las claves
    # =========================================================================================================================================================================================
    
    $placeholders = @{
        'PROJECT_NAME'        = $projectName
        'PRIMARY_LANGUAGES'   = 'C# (.NET); PowerShell'
        'TARGET_FRAMEWORKS'   = 'net8.0;net7.0;net6.0'
        'PROJECT_DESCRIPTION' = 'Proyecto del ecosistema Neurologic que produce artefactos reutilizables y herramientas.'
        'KEY_ARTEFACTS'       = 'Pendiente de definir'
        'CORE_DEPENDENCIES'   = 'Core.FileSystem; Core.Indexing; Core.Logging'
        'OUT_OF_SCOPE'        = 'Detallar exclusiones'
        'BUILD_STEPS'         = 'dotnet build .\{{PROJECT_NAME}}.csproj -c Release'
        'RUN_STEPS'           = '.\bin\Release\net8.0\{{PROJECT_NAME}}.exe'
        'TEST_STEPS'          = 'dotnet test'
        'AGENT_DESTINATION'   = 'Codex Web'
        'REQUEST_TYPE'        = 'artefacto_reutilizable'
    }
    
    # =========================================================================================================================================================================================
    # Carga las plantillas y crea los archivos AGENTS.md y README.md del subproyecto
    # =========================================================================================================================================================================================
    
    $agentsTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'AGENTS_subproject.md'
    $agentsFallback = @"
# AGENTS – {{PROJECT_NAME}}

Completa esta plantilla siguiendo el Procedimiento_de_solicitud_de_artefactos.
"@
    $agentsPath = Join-Path $projectRoot 'AGENTS.md'
    New-FileFromTemplate -Destination $agentsPath -TemplateContent $agentsTemplate -Placeholders $placeholders -FallbackContent $agentsFallback
    $readmeTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'README_subproject.md'
    $readmeFallback = @"
# {{PROJECT_NAME}}

Describe el propósito del proyecto y sus artefactos reutilizables.
"@
    $readmePath = Join-Path $projectRoot 'README.md'
    New-FileFromTemplate -Destination $readmePath -TemplateContent $readmeTemplate -Placeholders $placeholders -FallbackContent $readmeFallback
    
    # =========================================================================================================================================================================================
    # Genera un proyecto .NET básico si no existe el archivo .csproj
    # =========================================================================================================================================================================================
    
    $csprojPath = Join-Path $projectRoot "$projectName.csproj"
    if (-not (Test-Path $csprojPath)) {
@"
<Project Sdk=""Microsoft.NET.Sdk"">
  <PropertyGroup>
    <TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <AssemblyName>$projectName</AssemblyName>
  </PropertyGroup>
</Project>
"@ | Set-Content -LiteralPath $csprojPath -Encoding UTF8
    }
    
    # =========================================================================================================================================================================================
    # Crea mapa ASCII de estructura de carpetas si no existe
    # =========================================================================================================================================================================================
    
    $asciiPath = Join-Path $projectRoot 'docs\filemap_ascii.txt'
    if (-not (Test-Path $asciiPath)) {
@"
$projectName/
├── AGENTS.md
├── README.md
├── $projectName.csproj
├── docs/
│   ├── solicitud_de_artefactos.md
│   ├── filemap_ascii.txt
│   ├── table_hierarchy.json
│   ├── Procedimiento_de_solicitud_de_artefactos.md
│   └── bitacora.md
├── csv/
│   ├── modules.csv
│   └── artefacts.csv
├── Scripts/
├── src/
└── tests/
"@ | Set-Content -LiteralPath $asciiPath -Encoding UTF8
    }
    
    # =========================================================================================================================================================================================
    # Crea archivo JSON de jerarquía si no existe
    # =========================================================================================================================================================================================
    
    $hierarchyPath = Join-Path $projectRoot 'docs\table_hierarchy.json'
    if (-not (Test-Path $hierarchyPath)) {
@"
{
  "name": "$projectName",
  "children": [
    { "name": "docs" },
    { "name": "csv" },
    { "name": "Scripts" },
    { "name": "src" },
    { "name": "tests" }
  ]
}
"@ | Set-Content -LiteralPath $hierarchyPath -Encoding UTF8
    }
    
    # =========================================================================================================================================================================================
    # Crea Procedimiento_de_solicitud_de_artefactos si no existe
    # =========================================================================================================================================================================================
    
    $procedurePath = Join-Path $projectRoot 'docs\Procedimiento_de_solicitud_de_artefactos.md'
    if (-not (Test-Path $procedurePath)) {
@"
# Procedimiento_de_solicitud_de_artefactos - $projectName

> Entrega este documento a ChatGPT antes de elaborar la solicitud para Codex Web y eliminalo en cuanto la solicitud quede consistente y lista para enviarse.

## Primera iteracion - Investigacion sobre $projectName
1. Genera un informe de investigacion libre que describa el dominio del proyecto, tecnologias abiertas comparables, patrones arquitectonicos compatibles con .NET y cualquier dependencia critica (datos, APIs, frameworks).
2. Identifica que componentes podrian convertirse en artefactos reutilizables para otros proyectos y como se relacionan con modulos existentes en Core o Sandbox.
3. Evalua riesgos tecnicos y oportunidades de integracion (seguridad, rendimiento, escalabilidad, automatizacion de pruebas).
4. Resume hallazgos en secciones numeradas con referencias explicitas a los archivos de `docs/` y `csv/` que se deberan completar en las iteraciones posteriores.
5. Entrega conclusiones accionables que preparen a la siguiente iteracion para construir el plan y la solicitud.

## Segunda iteracion - Elaboracion de plan y solicitud
1. Con la investigacion aprobada, rellena `docs/solicitud_de_artefactos.md` con todos los apartados obligatorios (agente destino, tipo de solicitud, antecedentes, objetivo tecnico, alcance, interfaz, estructura de archivos, dependencias y criterios de aceptacion).
2. Actualiza `AGENTS.md` y `README.md` con el proposito, dependencias, artefactos objetivo e instrucciones operativas alineadas a la investigacion; elimina los placeholders antes de compartirlos fuera del equipo.
3. Propone un plan operativo para el agente que incluya lectura de AGENTS, generacion de artefactos reutilizables y validaciones necesarias antes de producir codigo.
4. Actualiza `docs/table_hierarchy.json` para reflejar la relacion entre artefactos reutilizables y productos finales, indicando que partes pertenecen a Core y cuales a Sandbox.
5. Documenta cualquier insumo pendiente (credenciales, datos, decisiones de negocio) y valida que la solicitud sea suficiente para que Codex trabaje de forma autonoma.
6. Indica explicitamente que este procedimiento debe eliminarse cuando la solicitud y su soporte esten completos y aprobados.

## Tercera iteracion - CSV y verificaciones estructurales
1. Completa `csv/modules.csv` y `csv/artefacts.csv` con la nomenclatura final, responsables y estado de cada componente, alineandolos con la estructura declarada en `docs/table_hierarchy.json`.
2. Verifica la congruencia entre los CSV, el JSON y la solicitud; cualquier discrepancia debe corregirse antes de cerrar la iteracion.
3. Actualiza `docs/filemap_ascii.txt` para reflejar la estructura final del proyecto, incluyendo nuevos directorios o scripts.
4. Registra en `docs/bitacora.md` los acuerdos, riesgos y proximos pasos derivados de esta iteracion.
5. Confirma que los archivos `docs/solicitud_de_artefactos.md`, `csv/*.csv`, `docs/table_hierarchy.json` y `docs/filemap_ascii.txt` cuentan la misma historia; despues elimina este procedimiento antes de enviar el paquete a Codex.

### Entregables por iteracion
- Iteracion 1: Informe de investigacion + lista preliminar de artefactos y dependencias.
- Iteracion 2: Solicitud completa + jerarquia actualizada + plan operativo.
- Iteracion 3: CSV consolidados + mapa ASCII actualizado + bitacora con acuerdos finales.
"@ | Set-Content -LiteralPath $procedurePath -Encoding UTF8
    }
    
    # =========================================================================================================================================================================================
    # Crea bitacora.md si no existe para registrar hallazgos
    # =========================================================================================================================================================================================
    
    $bitacoraPath = Join-Path $projectRoot 'docs\bitacora.md'
    if (-not (Test-Path $bitacoraPath)) {
"# Bitácora`n`nRegistra decisiones, supuestos y hallazgos relevantes para este proyecto." |
        Set-Content -LiteralPath $bitacoraPath -Encoding UTF8
    }
    
    # =========================================================================================================================================================================================
    # Carga plantilla de solicitud de artefactos y crea el archivo
    # =========================================================================================================================================================================================
    
    $solicitudTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'solicitud_de_artefactos.md'
    $solicitudFallback = Get-TemplateContent -RepoPath (Split-Path $PSCommandPath -Parent) -TemplateName 'solicitud_de_artefactos.md'
    if (-not $solicitudFallback) {
        $solicitudFallback = @"
[AGENTE_DESTINO]
{{AGENT_DESTINATION}}

[TIPO_SOLICITUD]
{{REQUEST_TYPE}}
"@
    }
    $solicitudPath = Join-Path $projectRoot 'docs\solicitud_de_artefactos.md'
    New-FileFromTemplate -Destination $solicitudPath -TemplateContent $solicitudTemplate -Placeholders $placeholders -FallbackContent $solicitudFallback
    
    # =========================================================================================================================================================================================
    # Crea archivos CSV si no existen
    # =========================================================================================================================================================================================
    
    $csvModules = Join-Path $projectRoot 'csv\modules.csv'
    if (-not (Test-Path $csvModules)) {
        "Componente,Descripcion,Estado,Responsable" | Set-Content -LiteralPath $csvModules -Encoding UTF8
    }
    $csvArtefacts = Join-Path $projectRoot 'csv\artefacts.csv'
    if (-not (Test-Path $csvArtefacts)) {
        "Artefacto,Ubicacion,Proyecto_Origen,Proyecto_Destino,Estado" | Set-Content -LiteralPath $csvArtefacts -Encoding UTF8
    }
    Write-Host ""
    Write-Info "Estructura estándar creada/actualizada en $projectRoot"
    Write-Info "Completa las plantillas antes de solicitar trabajo a Codex."
    
    # =========================================================================================================================================================================================
    # Ejecuta análisis estático PSSA sobre el nuevo proyecto
    # =========================================================================================================================================================================================
    
    Invoke-PSSAAnalysis -Path $projectRoot
    
    # =========================================================================================================================================================================================
    # Ejecuta revisión de estructura para avisar de faltantes
    # =========================================================================================================================================================================================
    
    Invoke-Doctor -ProjectPath $projectRoot
}

# =========================================================================================================================================================================================
# === Función para sincronizar cambios locales al remoto ===
# =========================================================================================================================================================================================

function Invoke-SyncUp {
    param([string]$RepoPath, [string]$Branch)
    if (-not (Ensure-GitRepo -RepoPath $RepoPath)) { return }
    Push-Location $RepoPath
    try {
        $rawStatus = (& git status --porcelain)
        if ([string]::IsNullOrWhiteSpace($rawStatus)) {
            Write-Info "No hay cambios locales que subir."
            return
        }
        $lines = $rawStatus -split "`n"
        Show-Changes -Lines $lines
        $confirm = Read-Host "¿Subir estos cambios a origin/$Branch? (S/N, ENTER=S)"
        if ([string]::IsNullOrWhiteSpace($confirm)) { $confirm = 'S' }
        if ($confirm.Trim().ToUpperInvariant() -ne 'S') {
            Write-WarnMsg "Operación cancelada."
            return
        }
        & git add -A
        $defaultMsg = "chore: sync local -> origin/$Branch ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        $msg = Read-Host "Mensaje de commit (ENTER = $defaultMsg)"
        if ([string]::IsNullOrWhiteSpace($msg)) { $msg = $defaultMsg }
        & git commit -m $msg
        try { & git pull origin $Branch } catch { Write-ErrMsg "git pull origin $Branch falló."; return }
        & git push origin $Branch
        Write-Info "Cambios enviados a origin/$Branch."
    } finally {
        Pop-Location
    }
}

# =========================================================================================================================================================================================
# === Función para fusionar la rama Codex_* en la rama principal ===
# =========================================================================================================================================================================================

function Invoke-SyncDown {
    param([string]$RepoPath, [string]$Branch)
    if (-not (Ensure-GitRepo -RepoPath $RepoPath)) { return }
    Push-Location $RepoPath
    try {
        $rawStatus = (& git status --porcelain)
        if (-not [string]::IsNullOrWhiteSpace($rawStatus)) {
            Write-WarnMsg "Hay cambios locales sin comprometer. Cancela o deja el repo limpio."
            return
        }
        $today = Get-Date -Format 'yyyy-MM-dd'
        $candidates = @("Codex_$today","codex_$today")
        & git fetch origin | Out-Null
        $codexBranch = $null
        foreach ($name in $candidates) {
            $remoteMatch = (& git branch -r --list ("origin/{0}" -f $name))
            if (-not [string]::IsNullOrWhiteSpace($remoteMatch)) {
                $codexBranch = $name
                break
            }
        }
        if (-not $codexBranch) {
            Write-ErrMsg "No se encontró rama Codex para $today."
            & git branch -r --list "origin/Codex_*" "origin/codex_*"
            return
        }
        Write-Info ("Usando origin/{0}" -f $codexBranch)
        & git --no-pager diff ("origin/$Branch") ("origin/$codexBranch")
        $confirm = Read-Host "Escribe 'S' para fusionar origin/$codexBranch en $Branch"
        if ($confirm.Trim().ToUpperInvariant() -ne 'S') {
            Write-WarnMsg "Operación cancelada."
            return
        }
        & git checkout $Branch
        try { & git pull origin $Branch } catch { Write-ErrMsg "git pull origin $Branch falló."; return }
        try { & git merge --no-ff ("origin/$codexBranch") } catch { Write-ErrMsg "El merge produjo conflictos."; return }
        $postStatus = (& git status --porcelain --untracked-files=no)
        if ($postStatus -match '^\s*UU') {
            Write-ErrMsg "Hay archivos en conflicto (UU). Resuélvelos manualmente."
            return
        }
        & git push origin $Branch
        Write-Info "Merge completado. Limpiando ramas Codex..."
        try { & git push origin --delete $codexBranch } catch { Write-WarnMsg "No se pudo borrar origin/$codexBranch." }
        $localMatch = (& git branch --list $codexBranch)
        if (-not [string]::IsNullOrWhiteSpace($localMatch)) {
            try { & git branch -D $codexBranch } catch { Write-WarnMsg "No se pudo borrar la rama local $codexBranch." }
        }
    } finally {
        Pop-Location
    }
}

# =========================================================================================================================================================================================
# === Función para obtener el slug de un repositorio en GitHub ===
# =========================================================================================================================================================================================

function Get-RepoSlug {
    param([string]$RepoPath)
    if (-not (Ensure-GitRepo -RepoPath $RepoPath)) { return $null }
    Push-Location $RepoPath
    try {
        $remote = (& git remote get-url origin).Trim()
    } catch {
        Write-ErrMsg "No se pudo obtener la URL de origin."
        return $null
    } finally {
        Pop-Location
    }
    if ($remote -match 'github\.com[:/]([^/]+/[^/]+?)(\.git)?$') {
        return $Matches[1]
    }
    Write-ErrMsg "No se pudo inferir owner/repo desde: $remote"
    return $null
}

# =========================================================================================================================================================================================
# === Función para asegurar la disponibilidad de GitHub CLI ===
# =========================================================================================================================================================================================

function Ensure-GitHubCli {
    try {
        Get-Command gh -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-ErrMsg "Se requiere GitHub CLI (gh). Instálalo y ejecuta 'gh auth login'."
        return $false
    }
}

# =========================================================================================================================================================================================
# === Función para descargar artifacts de GitHub Actions ===
# =========================================================================================================================================================================================

function Invoke-ArtifactDownload {
    param([string]$RepoPath)
    if (-not (Ensure-GitHubCli)) { return }
    $slug = Get-RepoSlug -RepoPath $RepoPath
    if (-not $slug) { return }
    Write-Info ("Consultando workflows recientes de {0}..." -f $slug)
    try {
        $json = gh api "repos/$slug/actions/runs" -f per_page=5
    } catch {
        Write-ErrMsg "No se pudieron listar los workflows: $($_.Exception.Message)"
        return
    }
    $runs = ($json | ConvertFrom-Json).workflow_runs
    if (-not $runs) {
        Write-WarnMsg "No hay workflows recientes."
        return
    }
    $index = 0
    foreach ($run in $runs) {
        Write-Host ("[{0}] {1} | ID {2} | {3} | {4}" -f $index, $run.name, $run.id, $run.head_branch, $run.status)
        $index++
    }
    $choice = Read-Host "Selecciona índice o escribe un ID de run (ENTER = 0)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '0' }
    if ($choice -match '^\d+$' -and [int]$choice -lt $runs.Count) {
        $runId = $runs[[int]$choice].id
    } else {
        $runId = $choice
    }
    $artifactName = Read-Host "Nombre exacto del artifact (ENTER = todos)"
    $defaultDir = Join-Path $RepoPath ("artifacts\run_{0}" -f $runId)
    $targetDir = Read-Host "Ruta destino (ENTER = $defaultDir)"
    if ([string]::IsNullOrWhiteSpace($targetDir)) { $targetDir = $defaultDir }
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Write-Info ("Descargando artifacts a {0}..." -f $targetDir)
    $args = @('run','download',$runId,'--repo',$slug,'--dir',$targetDir)
    if (-not [string]::IsNullOrWhiteSpace($artifactName)) {
        $args += @('--name',$artifactName)
    }
    try {
        & gh @args
        Write-Info "Descarga completada."
    } catch {
        Write-ErrMsg "Fallo al descargar artifacts: $($_.Exception.Message)"
    }
}

# =========================================================================================================================================================================================
# === Función para seleccionar un repositorio existente o ruta manual ===
# =========================================================================================================================================================================================

function Select-Repository {
    param([string]$RootPath)
    if (-not (Test-Path $RootPath)) {
        Write-WarnMsg "La ruta base '$RootPath' no existe. Se creará."
        New-Item -ItemType Directory -Path $RootPath -Force | Out-Null
    }
    while ($true) {
        $repos = Get-ChildItem -Path $RootPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName '.git') } |
            Sort-Object Name
        Write-Host ""
        Write-Host "=== Selección de repositorio ===" -ForegroundColor Cyan
        if ($repos.Count -eq 0) {
            Write-WarnMsg "No se encontraron repos en $RootPath."
        } else {
            for ($i = 0; $i -lt $repos.Count; $i++) {
                Write-Host ("{0}. {1}" -f ($i + 1), $repos[$i].Name)
            }
        }
        Write-Host "M. Especificar ruta manual"
        Write-Host "Q. Salir"
        Write-Host "B. Operaciones en lote"
        $choice = Read-Host "Selecciona una opción"
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }
        switch ($choice.Trim().ToUpperInvariant()) {
            'Q' { return $null }
            'M' {
                $manual = Read-Host "Ruta completa al repo"
                if ([string]::IsNullOrWhiteSpace($manual)) { continue }
                if (Test-Path $manual) {
                    return (Resolve-Path $manual).Path
                }
                Write-WarnMsg "Ruta no encontrada."
            }
            'B' {
                Invoke-MultiRepoMenu -RootPath $RootPath -Branch $DefaultBranch
            }
            default {
                if ($choice -match '^\d+$') {
                    $index = [int]$choice - 1
                    if ($index -ge 0 -and $index -lt $repos.Count) {
                        return $repos[$index].FullName
                    }
                }
                Write-WarnMsg "Selección inválida."
            }
        }
    }
}

# =========================================================================================================================================================================================
# === Función para ejecutar una opción del menú principal ===
# =========================================================================================================================================================================================

function Execute-Option {
    param(
        [string]$Option,
        [string]$RepoPath,
        [string]$Branch
    )
    switch ($Option) {
        '1' { Invoke-StructureCreator -RepoPath $RepoPath }
        '2' { Invoke-SyncUp -RepoPath $RepoPath -Branch $Branch }
        '3' { Invoke-SyncDown -RepoPath $RepoPath -Branch $Branch }
        '4' { Invoke-ArtifactDownload -RepoPath $RepoPath }
        default { Write-WarnMsg "Opción no reconocida." }
    }
}

# =========================================================================================================================================================================================
# === Menú de operaciones para un repositorio ===
# =========================================================================================================================================================================================

function Show-OperationsMenu {
    param([string]$RepoPath, [string]$Branch)
    while ($true) {
        Write-Host ""
        Write-Host "=== Operaciones sobre $RepoPath ===" -ForegroundColor Cyan
        Write-Host "1. Crear estructura Sandbox (plantillas + docs + CSV)"
        Write-Host "2. Sincronizar cambios locales → origin/$Branch"
        Write-Host "3. Fusionar rama Codex_YYYY-MM-DD → $Branch"
        Write-Host "4. Descargar artifacts de GitHub Actions"
        Write-Host "5. Atrás (seleccionar otro repo)"
        $opt = Read-Host "Elige una opción"
        if ($opt -eq '5') { break }
        Execute-Option -Option $opt -RepoPath $RepoPath -Branch $Branch
    }
}

# =========================================================================================================================================================================================
# === Lógica principal de la aplicación ===
# =========================================================================================================================================================================================

if ($InitialRepo -and $AutoOption) {
    if (-not (Test-Path $InitialRepo)) {
        Write-ErrMsg "La ruta indicada en -InitialRepo no existe."
        return
    }
    $resolved = (Resolve-Path $InitialRepo).Path
    Execute-Option -Option $AutoOption -RepoPath $resolved -Branch $DefaultBranch
    return
}

Write-Host ""
Write-Host "=== Neurologic Repo Admin ===" -ForegroundColor Cyan
Write-Host "BasePath: $BasePath"
Write-Host "Branch por defecto: $DefaultBranch"

while ($true) {
    $repoPath = Select-Repository -RootPath $BasePath
    if (-not $repoPath) {
        Write-Info "Fin de la sesión."
        break
    }
    Show-OperationsMenu -RepoPath $repoPath -Branch $DefaultBranch
}
