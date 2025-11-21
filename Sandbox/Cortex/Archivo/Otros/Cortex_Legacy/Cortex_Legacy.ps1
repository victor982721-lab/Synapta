    # =========================================================================================================================================================================================
    # === RepoMaster - Script de administración de repositorios Synapta / Neurologic ===
    # =========================================================================================================================================================================================

    # {{Aquí va el contenido del Introducción_Cortex.ps1 ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}}}
        
    # =========================================================================================================================================================================================
    # === Parámetros y configuración ===
    # =========================================================================================================================================================================================

    [CmdletBinding()]
    param(
        [string]$BasePath = (Join-Path $env:USERPROFILE 'Documents\GitHub'),
        [string]$DefaultBranch = 'main',
        [string]$InitialRepo,
        [ValidateSet('1','2','3','4','5','6','7','8')]
        [string]$AutoOption,
        [string]$InitialBranch
    )

    # ===============================
    <#
    .SYNOPSIS   
    - Variables que contienen las versiones optimizadas de AGENTS.md, Politica_cultural_y_de_calidad.md, Preferencias_del_Usuario.md, README.md y el AGENTS de Core.
    - Ensure-RepoDocs usa estas cadenas para crear o reponer esos archivos; si actualizas los documentos, actualiza también estas variables.
    #>
    # ===============================

    $GlobalNeurologicAgentsContent = 

    #@'

    #{{Aquí va el contenido del AGENTS.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

    #'@

    # ================================

    $GlobalPolicyContent = 

    #@'

    #{{Aquí va el contenido del Politica_CC.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

    #'@

    # ================================

    $GlobalUserPrefsContent = 

    #@'

    #{{Aquí va el contenido de Preferencias_Usuario.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

    #'@

    # ================================

    $GlobalRepoReadmeContent = 

    #@'

    #{{Aquí va el contenido del Repo_README.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

    #'@

    # ================================

    $CoreAgentsContent = 

    #@'

    #{{Aquí va el contenido del Core_AGENTS.md ubicado en "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox\Cortex\docs\Templates"}}

    #'@

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
    # === Funciones para crear y mantener documentos globales y estructura del repositorio ===
    # =========================================================================================================================================================================================

    # Crea los documentos normativos globales en el repositorio si aún no existen.  También asegura la presencia de la carpeta Core con su AGENTS.
    function Ensure-RepoDocs {
        param([string]$RepoPath)
        # Ruta raíz del repositorio
        $rootDocs = @{
            'AGENTS.md'                           = $GlobalNeurologicAgentsContent
            'Politica_cultural_y_de_calidad.md'    = $GlobalPolicyContent
            'Preferencias_del_Usuario.md'           = $GlobalUserPrefsContent
            'README.md'                            = $GlobalRepoReadmeContent
        }
        foreach ($kvp in $rootDocs.GetEnumerator()) {
            $dest = Join-Path $RepoPath $kvp.Key
            if (-not (Test-Path $dest)) {
                # Crea el archivo con el contenido correspondiente
                $kvp.Value | Set-Content -LiteralPath $dest -Encoding UTF8
            }
        }
        # Asegura que exista la carpeta Core y su AGENTS
        $coreDir = Join-Path $RepoPath 'Core'
        if (-not (Test-Path $coreDir)) {
            New-Item -ItemType Directory -Path $coreDir -Force | Out-Null
        }
        $coreAgentsPath = Join-Path $coreDir 'AGENTS.md'
        if (-not (Test-Path $coreAgentsPath)) {
            $CoreAgentsContent | Set-Content -LiteralPath $coreAgentsPath -Encoding UTF8
        }
        # Crea README de Core si no existe (explica los módulos)
        $coreReadmePath = Join-Path $coreDir 'README.md'
        if (-not (Test-Path $coreReadmePath)) {
            @"# Core

    La carpeta **Core** contiene módulos reutilizables oficiales del ecosistema.  Cada subcarpeta representa un módulo independiente con su propia solución (`.csproj`) y pruebas.  Consulta el `AGENTS.md` de Core para conocer las reglas específicas de desarrollo."@ |
                Set-Content -LiteralPath $coreReadmePath -Encoding UTF8
        }
        # Asegura existencia de carpeta Sandbox
        $sandboxDir = Join-Path $RepoPath 'Sandbox'
        if (-not (Test-Path $sandboxDir)) {
            New-Item -ItemType Directory -Path $sandboxDir -Force | Out-Null
        }
    }

    # Genera el archivo Repo_Estructura_ASCII.md con un mapa actualizado de carpetas y archivos principales del repositorio.  Listará los proyectos en Sandbox que existan.
    function Update-RepoFileMap {
        param([string]$RepoPath)
        $sandboxDir = Join-Path $RepoPath 'Sandbox'
        if (-not (Test-Path $sandboxDir)) {
            $projects = @()
        } else {
            $projects = Get-ChildItem -Path $sandboxDir -Directory | Where-Object { $_.Name -ne '.Codex' }
        }
        $lines = @()
        $lines += 'Neurologic/'
        $lines += '├── AGENTS.md'
        $lines += '├── Politica_cultural_y_de_calidad.md'
        $lines += '├── Preferencias_del_Usuario.md'
        $lines += '├── Repo_Estructura_ASCII.md'
        $lines += '├── README.md'
        $lines += '├── Core/'
        $lines += '│   ├── AGENTS.md'
        $lines += '│   ├── README.md'
        $lines += '│   └── …'
        $lines += '└── Sandbox/'
        if ($projects.Count -gt 0) {
            for ($i = 0; $i -lt $projects.Count; $i++) {
                $proj = $projects[$i]
                $prefix = '    '
                $indicator = if ($i -eq $projects.Count - 1) { '└──' } else { '├──' }
                $lines += "$prefix$indicator $($proj.Name)/"
                # Archivos principales dentro del proyecto
                $lines += "$prefix    ├── AGENTS.md"
                $lines += "$prefix    ├── README.md"
                $lines += "$prefix    ├── $($proj.Name).csproj"
                $lines += "$prefix    ├── docs/"
                $lines += "$prefix    │   ├── Procedimiento_Codex_$($proj.Name).md"
                $lines += "$prefix    │   ├── solicitud_de_artefactos.md"
                $lines += "$prefix    │   ├── filemap_ascii.txt"
                $lines += "$prefix    │   ├── table_hierarchy.json"
                $lines += "$prefix    │   ├── plan.md"
                $lines += "$prefix    │   └── bitacora.md"
                $lines += "$prefix    ├── csv/"
                $lines += "$prefix    │   ├── modules.csv"
                $lines += "$prefix    │   └── artefacts.csv"
                $lines += "$prefix    ├── Scripts/"
                $lines += "$prefix    ├── src/"
                $lines += "$prefix    └── tests/"
            }
        }
        $content = ($lines -join "`n") + "`n"
        $asciiPath = Join-Path $RepoPath 'Repo_Estructura_ASCII.md'
        Set-Content -LiteralPath $asciiPath -Encoding UTF8 -Value $content
    }

    # =========================================================================================================================================================================================
    # === Función para inicializar la estructura base del repositorio ===
    # =========================================================================================================================================================================================

    function Invoke-RepoInitializer {
        param([string]$RepoPath)
        # Crea los documentos globales y carpetas base (Core, Sandbox) si no existen
        Ensure-RepoDocs -RepoPath $RepoPath
        # Actualiza el mapa ASCII del repositorio para reflejar la estructura sin proyectos
        Update-RepoFileMap -RepoPath $RepoPath
        Write-Info "Estructura base del repositorio creada en $RepoPath"
        Write-Info "Se han generado los documentos globales y el sandbox vacío."
    }

    # =========================================================================================================================================================================================
    # === Función para crear una copia de seguridad de un proyecto en Sandbox ===
    # =========================================================================================================================================================================================

    function Invoke-ProjectBackup {
        param([string]$RepoPath)
        $sandboxDir = Join-Path $RepoPath 'Sandbox'
        if (-not (Test-Path $sandboxDir)) {
            Write-WarnMsg "El repositorio no tiene carpeta Sandbox."
            return
        }
        $projects = Get-ChildItem -Path $sandboxDir -Directory | Where-Object { $_.Name -ne '.Codex' }
        if (-not $projects -or $projects.Count -eq 0) {
            Write-WarnMsg "No hay proyectos en Sandbox para respaldar."
            return
        }
        Write-Host "Proyectos disponibles para respaldo:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $projects.Count; $i++) {
            Write-Host ("{0}. {1}" -f ($i + 1), $projects[$i].Name)
        }
        $sel = Read-Host "Selecciona el número del proyecto a respaldar"
        if (-not ($sel -match '^[0-9]+$')) {
            Write-WarnMsg "Selección inválida."
            return
        }
        $index = [int]$sel - 1
        if ($index -lt 0 -or $index -ge $projects.Count) {
            Write-WarnMsg "Selección fuera de rango."
            return
        }
        $proj = $projects[$index]
        # Ruta de origen para comprimir
        $sourcePath = $proj.FullName
        # Directorio destino en Documents del usuario
        $destDir = Join-Path $env:USERPROFILE 'Documents'
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $zipName = "{0}_{1}.7z" -f $proj.Name, $timestamp
        $zipPath = Join-Path $destDir $zipName
        # Verifica que 7z esté disponible
        try {
            $null = Get-Command 7z -ErrorAction Stop
        } catch {
            Write-WarnMsg "No se encontró 7z.exe en PATH. Instala 7‑Zip para usar esta función."
            return
        }
        Write-Info "Comprimiendo $($proj.Name) a $zipPath ..."
        try {
            # Comprime el proyecto completo con la mejor compresión (-mx=9)
            & 7z a -t7z -mx=9 $zipPath $sourcePath | Out-Null
            Write-Info "Respaldo completado: $zipPath"
        } catch {
            Write-ErrMsg "La compresión falló: $($_.Exception.Message)"
        }
    }

    # =========================================================================================================================================================================================
    # === Función para eliminar un proyecto en Sandbox ===
    # =========================================================================================================================================================================================

    function Invoke-ProjectDeletion {
        param([string]$RepoPath)
        $sandboxDir = Join-Path $RepoPath 'Sandbox'
        if (-not (Test-Path $sandboxDir)) {
            Write-WarnMsg "El repositorio no tiene carpeta Sandbox."
            return
        }
        $projects = Get-ChildItem -Path $sandboxDir -Directory | Where-Object { $_.Name -ne '.Codex' }
        if (-not $projects -or $projects.Count -eq 0) {
            Write-WarnMsg "No hay proyectos en Sandbox para eliminar."
            return
        }
        Write-Host "Proyectos disponibles para eliminar:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $projects.Count; $i++) {
            Write-Host ("{0}. {1}" -f ($i + 1), $projects[$i].Name)
        }
        $sel = Read-Host "Selecciona el número del proyecto a eliminar"
        if (-not ($sel -match '^[0-9]+$')) {
            Write-WarnMsg "Selección inválida."
            return
        }
        $index = [int]$sel - 1
        if ($index -lt 0 -or $index -ge $projects.Count) {
            Write-WarnMsg "Selección fuera de rango."
            return
        }
        $proj = $projects[$index]
        $confirm = Read-Host "¿Seguro que deseas eliminar $($proj.Name)? Esta acción no se puede deshacer. (S/N)"
        if ($confirm.Trim().ToUpperInvariant() -ne 'S') {
            Write-WarnMsg "Eliminación cancelada."
            return
        }
        try {
            Remove-Item -LiteralPath $proj.FullName -Recurse -Force
            Write-Info "Proyecto $($proj.Name) eliminado."
            # Actualiza el mapa ASCII para reflejar la eliminación
            Update-RepoFileMap -RepoPath $RepoPath
        } catch {
            Write-ErrMsg "No se pudo eliminar el proyecto: $($_.Exception.Message)"
        }
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

        # Asegura que la raíz del repositorio tenga los documentos globales y la estructura base
        Ensure-RepoDocs -RepoPath $RepoPath
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

        # Solicita el tipo de proyecto (.NET o PowerShell).  Un proyecto .NET generará
        # un archivo .csproj y un archivo C# principal en la raíz.  Un proyecto
        # PowerShell no generará archivos .cs ni .csproj y en su lugar creará un
        # script principal .ps1 y una plantilla de pruebas Pester en `tests/`.
        $ptype = ''
        while ($ptype -ne '1' -and $ptype -ne '2') {
            $ptype = Read-Host "Tipo de proyecto (1 = .NET, 2 = PowerShell)"
            if ([string]::IsNullOrWhiteSpace($ptype)) { $ptype = '1' }
        }
        $isDotNet = $ptype -eq '1'
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
        
        # Construye la tabla de placeholders para expandir las plantillas.  Algunas
        # claves se ajustan según el tipo de proyecto (C# o PowerShell).
        $primaryLang = if ($isDotNet) { 'C# (.NET)' } else { 'PowerShell' }
        # Construye el diccionario de placeholders, ajustando comandos de build, ejecución y test según el tipo de proyecto
        $placeholders = @{
            'PROJECT_NAME'        = $projectName
            'PRIMARY_LANGUAGES'   = $primaryLang
            'TARGET_FRAMEWORKS'   = 'net8.0;net7.0;net6.0'
            'PROJECT_DESCRIPTION' = 'Proyecto del ecosistema Neurologic que produce artefactos reutilizables y herramientas.'
            'KEY_ARTEFACTS'       = 'Pendiente de definir'
            'CORE_DEPENDENCIES'   = 'Core.FileSystem; Core.Indexing; Core.Logging'
            'OUT_OF_SCOPE'        = 'Detallar exclusiones'
            'AGENT_DESTINATION'   = 'Codex Web'
            'REQUEST_TYPE'        = 'artefacto_reutilizable'
        }
        if ($isDotNet) {
            $placeholders['BUILD_STEPS'] = 'dotnet build {{PROJECT_NAME}}.csproj -c Release'
            $placeholders['RUN_STEPS']   = '.\bin\Release\net8.0\{{PROJECT_NAME}}.exe'
            $placeholders['TEST_STEPS']  = 'dotnet test'
        } else {
            $placeholders['BUILD_STEPS'] = 'N/A (PowerShell)'
            $placeholders['RUN_STEPS']   = 'pwsh .\main.ps1'
            $placeholders['TEST_STEPS']  = 'Invoke-Pester -Script .\tests\main.Tests.ps1'
        }
        
        # =========================================================================================================================================================================================
        # Carga las plantillas y crea los archivos AGENTS.md y README.md del subproyecto
        # =========================================================================================================================================================================================
        
        $agentsTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'AGENTS_subproject.md'
        # Contenido por defecto para AGENTS de subproyecto: incluye reglas específicas y marcas "a completar"
        $agentsFallback = @"
    # AGENTS – {{PROJECT_NAME}}

    Este documento complementa el **AGENTS general** de Neurologic y la **Política cultural y de calidad**.  Define las reglas específicas para el proyecto **{{PROJECT_NAME}}**, que vive bajo `Sandbox/{{PROJECT_NAME}}`.  Al comenzar el proyecto, ChatGPT debe rellenar los apartados marcados como “a completar” y eliminar estas instrucciones una vez completados.

    ## 1. Entorno

    * **Sistema operativo principal:** Windows 10 (compatibilidad desde Windows 7 hasta Windows 11).
    * **Shell principal:** PowerShell 7.5.x (`pwsh`) (compatibilidad con PowerShell 5 en adelante).
    * **Lenguajes permitidos:** C# (.NET) para módulos, PowerShell para scripts; Python o Bash solo cuando esté justificado.
    * **Target frameworks:** {{TARGET_FRAMEWORKS}}.  Desarrollar para .NET 8 manteniendo compatibilidad con .NET 7 y .NET 6.  Mantener multi‑targeting salvo justificación documentada.
    * **Compatibilidad con Linux:** no se requiere compatibilidad con Linux en esta fase; los flujos WSL/WSL2 siguen prohibidos salvo instrucción.

    ## 2. Propósito del proyecto

    *Este apartado debe ser completado por ChatGPT en la iteración de investigación.*  Describe de forma breve la finalidad de **{{PROJECT_NAME}}** dentro del ecosistema Neurologic: qué problema resuelve, qué produce (artefactos reutilizables, herramientas o ambos) y para quién.

    ## 3. Artefactos reutilizables requeridos

    Lista de módulos o scripts que **{{PROJECT_NAME}}** debe reutilizar o producir.  Para cada artefacto, indica un identificador, nombre, formato (JSON/CSV/NDJSON/otro) y una breve descripción.  Todos los artefactos nuevos deben registrarse en `csv/artefacts.csv` y documentarse en `docs/solicitud_de_artefactos.md`.

    ## 4. Principios específicos

    1. **Reutilización antes que reinvención** – Extiende los módulos Core antes de escribir lógica duplicada.
    2. **Determinismo** – Misma entrada → misma salida.  Documenta cualquier comportamiento no determinista.
    3. **Separación de capas** – Mantén la lógica de negocio desacoplada de la UI/CLI.  Usa namespaces que sigan la ruta de carpetas.
    4. **Documentación viva** – Actualiza `docs/solicitud_de_artefactos.md`, `docs/filemap_ascii.txt`, `docs/table_hierarchy.json`, `docs/plan.md` y `docs/bitacora.md` en cada iteración.
    5. **Pruebas mínimas** – Incluye pruebas en `tests/` (xUnit/NUnit para C#, Pester para PowerShell) que cubran rutas críticas.

    ## 5. Entradas y salidas estructuradas

    *Define los formatos de entrada y salida de los artefactos que produce {{PROJECT_NAME}}.*  Indica si son JSON, CSV, NDJSON u otro, y cómo deben consumirse desde otros proyectos.  Este apartado debe rellenarse según la investigación realizada en la primera iteración.

    ## 6. Excepciones autorizadas

    Enumera cualquier excepción puntual al AGENTS general (por ejemplo, uso de un único framework) con su justificación y alcance temporal.  Sin aprobación explícita, no se permiten excepciones.

    ## 7. Checklist antes de solicitar trabajo

    1. Plantillas completadas (`AGENTS.md`, `README.md`, `docs/solicitud_de_artefactos.md`).
    2. CSV actualizados (`csv/modules.csv`, `csv/artefacts.csv`).
    3. Scripts obligatorios listados en `Scripts/` y listados en la solicitud.
    4. Ejecución reciente de `Scripts/Validate-Structure.ps1` sin errores.
    5. Documentos `docs/filemap_ascii.txt`, `docs/table_hierarchy.json`, `docs/plan.md` y `docs/bitacora.md` actualizados y coherentes.
    "@
        $agentsPath = Join-Path $projectRoot 'AGENTS.md'
        New-FileFromTemplate -Destination $agentsPath -TemplateContent $agentsTemplate -Placeholders $placeholders -FallbackContent $agentsFallback
        $readmeTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'README_subproject.md'
        # Contenido por defecto para el README de subproyecto: guía de uso y referencias
        $readmeFallback = @"
    # {{PROJECT_NAME}}

    Proyecto del ecosistema **Neurologic** que producirá artefactos reutilizables y herramientas.  Este documento sirve como ficha descriptiva del proyecto y guía de uso.  Los apartados marcados como “a completar” deben ser rellenados por ChatGPT en la fase de planificación.

    ## Características principales

    * **Artefactos reutilizables:** *a completar*.  Indica qué artefactos (módulos, scripts, exportadores) generará {{PROJECT_NAME}} y para qué servirán.
    * **Dependencias Core:** *a completar*.  Lista los módulos de `Core` que se requieren (por ejemplo `Core.FileSystem`, `Core.Indexing`, `Core.Logging`).
    * **Alcance excluido:** *a completar*.  Describe explícitamente qué no hará este proyecto.

    ## Cómo usar este proyecto

    1. **Compilación/instalación:** `dotnet build {{PROJECT_NAME}}.csproj -c Release`.
    2. **Ejecución:** `./bin/Release/net8.0/{{PROJECT_NAME}}.exe` (o el framework correspondiente).
    3. **Pruebas:** `dotnet test` para ejecutar los proyectos de prueba.
    4. La documentación completa se encuentra en `docs/` y las tablas normativas en `csv/`.

    ## Estructura obligatoria

    ```
    {{PROJECT_NAME}}/
    ├── AGENTS.md
    ├── README.md
    ├── {{PROJECT_NAME}}.csproj (para proyectos .NET) o main.ps1 (para proyectos PowerShell)
    ├── docs/
    │   ├── Procedimiento_Codex_{{PROJECT_NAME}}.md
    │   ├── solicitud_de_artefactos.md
    │   ├── filemap_ascii.txt
    │   ├── table_hierarchy.json
    │   ├── plan.md
    │   └── bitacora.md
    ├── csv/
    │   ├── modules.csv
    │   └── artefacts.csv
    ├── Scripts/
    ├── src/
    └── tests/
    ```

    ## Referencias

    * **Política cultural y de calidad – Ecosistema Neurologic.**
    * **AGENTS general y `AGENTS.md` de este proyecto.**
    * **`docs/Procedimiento_Codex_{{PROJECT_NAME}}.md`** – procedimiento paso a paso para que ChatGPT investigue, prepare la solicitud y consolide los inventarios.
    "@
        $readmePath = Join-Path $projectRoot 'README.md'
        New-FileFromTemplate -Destination $readmePath -TemplateContent $readmeTemplate -Placeholders $placeholders -FallbackContent $readmeFallback
        
        # =========================================================================================================================================================================================
        # Genera archivos específicos según el tipo de proyecto
        # =========================================================================================================================================================================================

        if ($isDotNet) {
            # Proyecto .NET: genera .csproj y un archivo principal C# en la raíz
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
            # Crea un archivo C# principal vacío (Program.cs) en la raíz si no existe
            $csMainPath = Join-Path $projectRoot "$projectName.cs"
            if (-not (Test-Path $csMainPath)) {
    @"
    // Archivo principal generado automáticamente para el proyecto $projectName.
    namespace $projectName;

    internal class Program
    {
        static void Main()
        {
            // Punto de entrada del programa
        }
    }
    "@ | Set-Content -LiteralPath $csMainPath -Encoding UTF8
            }
        }
        else {
            # Proyecto PowerShell: no generar .csproj ni archivos C#.  Crear script principal .ps1 y plantilla Pester.
            $psMainPath = Join-Path $projectRoot 'main.ps1'
            if (-not (Test-Path $psMainPath)) {
    @"
    <#
        Script principal para el proyecto $projectName.
        Agregue aquí la lógica de su herramienta o módulo de PowerShell.
    #>
    "@ | Set-Content -LiteralPath $psMainPath -Encoding UTF8
            }
            # Crea una plantilla de pruebas Pester en la carpeta tests
            $pesterTestPath = Join-Path $projectRoot 'tests\main.Tests.ps1'
            if (-not (Test-Path $pesterTestPath)) {
    @"
    <#
        Plantilla de pruebas Pester para el proyecto $projectName.
        Las pruebas deben cubrir las funciones y scripts definidos en el proyecto.
    #>
    Describe '$projectName' {
        It 'Debe ejecutar sin errores' {
            # Invoca al script principal y verifica que no arroje excepción
            . "$((Resolve-Path -LiteralPath $psMainPath).Path)" | Should -Not -Throw
        }
    }
    "@ | Set-Content -LiteralPath $pesterTestPath -Encoding UTF8
            }
        }
        
        # =========================================================================================================================================================================================
        # Crea mapa ASCII de estructura de carpetas si no existe
        # =========================================================================================================================================================================================

        $asciiPath = Join-Path $projectRoot 'docs\filemap_ascii.txt'
        if (-not (Test-Path $asciiPath)) {
            # Diferenciar representación según el tipo de proyecto.  Para proyectos .NET se incluye el .csproj
            # y el archivo .cs principal; para proyectos PowerShell se incluye main.ps1 y la prueba Pester.
            if ($isDotNet) {
                $asciiContent = @"
    $projectName/
    ├── AGENTS.md
    ├── README.md
    ├── $projectName.csproj
    ├── $projectName.cs
    ├── docs/
    │   ├── Procedimiento_Codex_$projectName.md
    │   ├── solicitud_de_artefactos.md
    │   ├── filemap_ascii.txt
    │   ├── table_hierarchy.json
    │   ├── plan.md
    │   └── bitacora.md
    ├── csv/
    │   ├── modules.csv
    │   └── artefacts.csv
    ├── Scripts/
    ├── src/
    └── tests/
    "@
            } else {
                $asciiContent = @"
    $projectName/
    ├── AGENTS.md
    ├── README.md
    ├── main.ps1
    ├── docs/
    │   ├── Procedimiento_Codex_$projectName.md
    │   ├── solicitud_de_artefactos.md
    │   ├── filemap_ascii.txt
    │   ├── table_hierarchy.json
    │   ├── plan.md
    │   └── bitacora.md
    ├── csv/
    │   ├── modules.csv
    │   └── artefacts.csv
    ├── Scripts/
    ├── src/
    └── tests/
        └── main.Tests.ps1
    "@
            }
            Set-Content -LiteralPath $asciiPath -Encoding UTF8 -Value $asciiContent
        }
        
        # =========================================================================================================================================================================================
        # Crea archivo JSON de jerarquía si no existe
        # =========================================================================================================================================================================================
        
        $hierarchyPath = Join-Path $projectRoot 'docs\table_hierarchy.json'
        if (-not (Test-Path $hierarchyPath)) {
            $hierContent = @"
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
    "@
            Set-Content -LiteralPath $hierarchyPath -Encoding UTF8 -Value $hierContent
        }
        
        # =========================================================================================================================================================================================
        # Crea Procedimiento_de_solicitud_de_artefactos si no existe
        # =========================================================================================================================================================================================
        
        $procedurePath = Join-Path $projectRoot ("docs\Procedimiento_Codex_" + $projectName + ".md")
        if (-not (Test-Path $procedurePath)) {
            $procContent = @"
    # Procedimiento Codex – $projectName

    > Este documento guía a una sesión de ChatGPT para investigar el dominio de **$projectName**, preparar la solicitud de artefactos y consolidar los inventarios y jerarquías del proyecto.  No forma parte del paquete final: debe eliminarse del repositorio cuando la solicitud y sus soportes estén completos.

    ## 0. Propósito y alcance

    $projectName es un proyecto de **artefactos reutilizables y herramientas** dentro de `Neurologic/Sandbox`.  La responsabilidad de ChatGPT es:

    1. **Investigar** el dominio del proyecto, las tecnologías comparables y los patrones arquitectónicos adecuados para .NET.
    2. **Redactar la solicitud de artefactos** siguiendo la plantilla en `docs/solicitud_de_artefactos.md` y actualizar `AGENTS.md`, `README.md` y otras jerarquías.
    3. **Consolidar los inventarios** en los CSV y la jerarquía JSON y verificar que todos los documentos cuentan la misma historia.

    ## 1. Orden de lectura del contexto

    Antes de empezar, lee los siguientes documentos en este orden:

    1. `Preferencias_del_Usuario.md` (en la raíz del repositorio) – preferencias de tono, idioma y entorno.
    2. `Politica_cultural_y_de_calidad.md` – principios culturales y estándar técnico mínimo.
    3. `AGENTS.md` en la raíz – reglas globales para Codex.
    4. `Core/AGENTS.md` si planeas reutilizar o crear módulos en Core.
    5. `Sandbox/$projectName/AGENTS.md` y `Sandbox/$projectName/README.md` – reglas específicas y descripción del proyecto.
    6. `Sandbox/$projectName/docs/filemap_ascii.txt` y `docs/table_hierarchy.json` – mapa ASCII y jerarquía inicial del proyecto.
    7. Cabeceras de `csv/modules.csv` y `csv/artefacts.csv` para conocer los campos normativos.

    ## 2. Iteración 1 – Investigación

    Objetivo: entender el dominio de $projectName y definir los artefactos preliminares.

    1. Investiga el problema que $projectName pretende resolver, tecnologías abiertas comparables, patrones arquitectónicos compatibles con .NET y cualquier dependencia crítica (datos, APIs, frameworks).
    2. Identifica qué componentes podrían convertirse en artefactos reutilizables para otros proyectos y cómo se relacionan con módulos existentes en `Core` o en otros proyectos de `Sandbox`.
    3. Evalúa riesgos técnicos y oportunidades de integración (seguridad, rendimiento, escalabilidad, automatización de pruebas).
    4. Resume tus hallazgos en un informe con secciones numeradas.  En cada sección, indica qué archivos de `docs/` y `csv/` necesitarán actualizarse en las siguientes iteraciones.
    5. Concluye con una lista preliminar de artefactos reutilizables y dependencias, con su justificación.

    **Entregable:** un archivo de informe (`docs/informe_investigacion.md` u otro nombre descriptivo) dentro de la carpeta `docs/`.

    ## 3. Iteración 2 – Solicitud y plan

    Objetivo: convertir la investigación en una solicitud estructurada y reglas concretas para el proyecto.

    1. Rellena `docs/solicitud_de_artefactos.md` usando la plantilla.  Sustituye cada sección por contenido concreto; elimina cualquier texto de ayuda.
    2. Actualiza `Sandbox/$projectName/AGENTS.md` con:
       - Propósito real de $projectName.
       - Lista de artefactos reutilizables a producir y reutilizar.
       - Formatos de entrada y salida.
       - Excepciones autorizadas (si existen).
    3. Actualiza `Sandbox/$projectName/README.md` con:
       - Descripción clara del proyecto.
       - Artefactos reutilizables y dependencias Core.
       - Alcance excluido.
       - Comandos de compilación, ejecución y pruebas con los nombres definitivos.
    4. Actualiza `docs/table_hierarchy.json` para reflejar la relación entre artefactos reutilizables y productos finales.  Indica qué partes pertenecen a Core y cuáles a Sandbox.
    5. Define un plan de trabajo para Codex en `[PLAN_AGENTE]` de `solicitud_de_artefactos.md`.  Incluye pasos concretos (leer AGENTS, extender Core, generar código, ejecutar `Scripts/Validate-Structure.ps1`, correr pruebas, actualizar CSV y docs).
    6. Documenta insumos pendientes (credenciales, datos, decisiones de negocio) y registra supuestos y decisiones en `docs/bitacora.md`.

    7. **Si el proyecto es PowerShell**, prepara las pruebas **Pester** correspondientes en la carpeta `tests/` y especifica en el plan de trabajo que Codex debe ejecutarlas como parte de los criterios de aceptación.  Las pruebas Pester deben cubrir las funcionalidades definidas en la solicitud.

    ## 4. Iteración 3 – CSV y verificación estructural

    Objetivo: consolidar los inventarios normativos y validar que todos los documentos son coherentes.

    1. Llena `csv/modules.csv` y `csv/artefacts.csv` con la nomenclatura final, responsables y estado de cada componente, alineándolos con `docs/table_hierarchy.json` y `docs/solicitud_de_artefactos.md`.
    2. Verifica la congruencia entre los CSV, la jerarquía JSON, la solicitud y los archivos `AGENTS.md` y `README.md`.  Cualquier discrepancia debe corregirse antes de cerrar la iteración.
    3. Actualiza `docs/filemap_ascii.txt` para reflejar la estructura final del proyecto, incluyendo cualquier directorio o script nuevo.
    4. Registra en `docs/bitacora.md` los acuerdos, riesgos y próximos pasos derivados de esta iteración.
    5. Ejecuta `Scripts/Validate-Structure.ps1` (si existe) y asegúrate de que no se produzcan errores.

    ## 5. Checklist final y eliminación de este procedimiento

    Antes de enviar la carpeta a Codex, verifica:

    1. ¿El archivo `docs/solicitud_de_artefactos.md` está completo y sin textos de ayuda?
    2. ¿`AGENTS.md` y `README.md` reflejan el propósito y las reglas finales del proyecto?
    3. ¿`docs/table_hierarchy.json`, `csv/modules.csv`, `csv/artefacts.csv` y `docs/filemap_ascii.txt` cuentan la misma historia?
    4. ¿`docs/plan.md` (si existe) y `docs/bitacora.md` están actualizados con el plan operativo y las decisiones tomadas?
    5. ¿Has ejecutado las pruebas (`dotnet test`) y `Scripts/Validate-Structure.ps1` con éxito?

    Si todas las respuestas son afirmativas, **elimina este documento** de la carpeta `docs/` y empaqueta el proyecto (sin el procedimiento) para su entrega a Codex.
    "@
            Set-Content -LiteralPath $procedurePath -Encoding UTF8 -Value $procContent
        }
        
        # =========================================================================================================================================================================================
        # Crea plan.md y bitacora.md si no existen
        # =========================================================================================================================================================================================

        $planPath = Join-Path $projectRoot 'docs\plan.md'
        if (-not (Test-Path $planPath)) {
    @"
    # Plan operativo

    Este documento sirve para planificar las iteraciones y entregas del proyecto.  Después de la investigación y la elaboración de la solicitud, ChatGPT debe proponer un plan de trabajo para Codex en este archivo, dividiendo el desarrollo en fases o iteraciones.  Cada fase debe incluir objetivos, artefactos a desarrollar, riesgos identificados y criterios de éxito.

    Ejemplo de estructura:

    1. **Iteración 1 – Artefacto A**
       - Objetivo: …
       - Tareas: …
       - Riesgos: …
       - Criterios de éxito: …

    2. **Iteración 2 – Artefacto B**
       - …

    El plan debe alinearse con la solicitud de artefactos y con los principios definidos en los AGENTS y la política.
    "@ | Set-Content -LiteralPath $planPath -Encoding UTF8
        }
        $bitacoraPath = Join-Path $projectRoot 'docs\bitacora.md'
        if (-not (Test-Path $bitacoraPath)) {
    @"
    # Bitácora

    Utiliza este archivo para registrar decisiones, supuestos y hallazgos relevantes durante el ciclo de vida de $projectName.  Cada entrada debe incluir una fecha, un breve resumen, los archivos afectados y referencias a documentos o iteraciones.  La bitácora ayuda a mantener un historial transparente y a justificar cambios en artefactos y estructuras.
    "@ | Set-Content -LiteralPath $bitacoraPath -Encoding UTF8
        }
        
        # =========================================================================================================================================================================================
        # Carga plantilla de solicitud de artefactos y crea el archivo
        # =========================================================================================================================================================================================
        
        $solicitudTemplate = Get-TemplateContent -RepoPath $RepoPath -TemplateName 'solicitud_de_artefactos.md'
        $solicitudFallback = Get-TemplateContent -RepoPath (Split-Path $PSCommandPath -Parent) -TemplateName 'solicitud_de_artefactos.md'
        if (-not $solicitudFallback) {
            # Plantilla completa para la solicitud de artefactos con secciones que deben ser rellenadas por ChatGPT
            $solicitudFallback = @"
    [AGENTE_DESTINO]
    {{AGENT_DESTINATION}}

    [TIPO_SOLICITUD]
    {{REQUEST_TYPE}}

    [ANTECEDENTES]
    Describe el contexto actual, rutas relevantes y estado del proyecto.

    [OBJETIVO_TECNICO]
    Lista imperativa de resultados esperados.

    [ARTEFACTOS_REUTILIZABLES]
    - Artefacto 1 → Uso planificado.
    - Artefacto 2 → Uso planificado.

    [ALCANCE_FUNCIONAL]
    Debe:
    - …
    No debe:
    - …

    [INTERFAZ]
    Detalla comandos, parámetros o endpoints necesarios.

    [ESTRUCTURA_ARCHIVOS]
    Incluye el árbol mínimo (AGENTS, README, docs, csv, src, tests) y cualquier archivo adicional requerido.

    [DEPENDENCIAS_CORE]
    Indica qué módulos de Core deben reutilizarse o crearse.

    [CRITERIOS_ACEPTACION]
    Define condiciones verificables (compilación, pruebas, Validate‑Structure, actualización de CSV, etc.).

    [PLAN_AGENTE]
    Secuencia sugerida para el agente (leer AGENTS, extender Core, generar código, documentar, validar).
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

        # Actualiza el mapa ASCII del repositorio para reflejar este nuevo proyecto
        Update-RepoFileMap -RepoPath $RepoPath
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
            '2' { Invoke-RepoInitializer -RepoPath $RepoPath }
            '3' { Invoke-SyncUp -RepoPath $RepoPath -Branch $Branch }
            '4' { Invoke-SyncDown -RepoPath $RepoPath -Branch $Branch }
            '5' { Invoke-ArtifactDownload -RepoPath $RepoPath }
            '6' { Invoke-ProjectBackup -RepoPath $RepoPath }
            '7' { Invoke-ProjectDeletion -RepoPath $RepoPath }
            # La opción '8' se maneja en el menú interactivo (Atrás).  En modo automático, no tiene sentido y se considera no soportada.
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
            Write-Host "2. Crear estructura base del repositorio (documentos globales + sandbox vacío)"
            Write-Host "3. Sincronizar cambios locales → origin/$Branch"
            Write-Host "4. Fusionar rama Codex_YYYY-MM-DD → $Branch"
            Write-Host "5. Descargar artifacts de GitHub Actions"
            Write-Host "6. Crear copia de seguridad de un proyecto"
            Write-Host "7. Eliminar un proyecto del Sandbox"
            Write-Host "8. Atrás (seleccionar otro repo)"
            $opt = Read-Host "Elige una opción"
            if ($opt -eq '8') { break }
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
