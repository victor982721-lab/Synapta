Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-CortexWindowsPlatform {
<<<<<<< HEAD
=======
    [CmdletBinding()]
    param()

>>>>>>> origin/codex_2025-11-21
    if ($IsWindows -eq $false -and [Environment]::OSVersion.Platform -ne 'Win32NT') {
        throw 'Cortex solo está soportado en Windows (PowerShell 5.1+ / pwsh 7+).'
    }
}

function Get-CortexRoot {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)]
        [string]$ScriptRoot
    )
    return (Split-Path -Parent $ScriptRoot)
}

function Invoke-CortexCommand {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $startDir = Get-Location
    if ($WorkingDirectory) {
        Set-Location -Path $WorkingDirectory
    }

    try {
        & $FilePath @Arguments
        $exitCode = if ($LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        if ($exitCode -ne 0) {
            throw "El comando '$FilePath' falló con código $exitCode."
        }
    }
    finally {
        if ($WorkingDirectory) {
            Set-Location -Path $startDir
        }
    }
}

function Test-CortexCommand {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)][string]$Name
    )
    return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function New-CortexLogEntry {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][int]$DurationMs,
        [string]$Details,
        [string]$Errors,
        [string]$LogPath
    )

    $entry = [ordered]@{
        RunId      = $RunId
        Timestamp  = (Get-Date).ToString('s')
        Repo       = $Repo
        Operation  = $Operation
        Status     = $Status
        DurationMs = $DurationMs
        Details    = $Details
        Errors     = $Errors
    }

    if (-not $LogPath) {
        return [pscustomobject]$entry
    }

    if (-not (Test-Path -Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory | Out-Null
    }

    $filePath = Join-Path $LogPath "$RunId.json"
    $existing = @()
    if (Test-Path -Path $filePath) {
        $existing = Get-Content -Path $filePath | ConvertFrom-Json
    }

    $allEntries = @($existing) + ([pscustomobject]$entry)
    $allEntries | ConvertTo-Json -Depth 4 | Out-File -FilePath $filePath -Encoding utf8
    return [pscustomobject]$entry
}

$CortexTemplates = @{
    'AGENTS.md' = @'
# AGENTS – {{PROJECT_NAME}}

Este proyecto fue generado por Cortex. Mantén compatibilidad con PowerShell 5.1+ / pwsh 7+ y prioriza CLI.
'@
    'README.md' = @'
# {{PROJECT_NAME}}

Proyecto generado con Cortex. Tipo: {{PROJECT_TYPE}}. Incluye estructuras Sandbox/Core, plantillas y compatibilidad net8/net7/net6.
'@
    'Procedimiento.md' = @'
# Procedimiento de trabajo – {{PROJECT_NAME}}

1. Ejecuta el menú de Cortex o usa parámetros -AutoOption.
2. Mantén el repo limpio antes de sincronizar (SyncUp/SyncDown).
3. Registra hallazgos en Bitacora.md.
'@
    'Informe.md' = @'
# Informe inicial – {{PROJECT_NAME}}

Registra aquí los hallazgos técnicos y decisiones.
'@
    'Solicitud.md' = @'
# Solicitud de artefacto – {{PROJECT_NAME}}

Describe el objetivo técnico, alcance y criterios de aceptación.
'@
    'Artefactos.csv' = "Artefacto,Ubicacion,Proyecto_Origen,Proyecto_Destino,Estado"
    'Modulos.csv'    = "Componente,Descripcion,Estado,Responsable"
    'Bitacora.md'    = "# Bitácora – {{PROJECT_NAME}}`n- {{DATE}}: Registro inicial creado."
    'Cortex_Plan_Schema.md' = "Consulta el schema principal en Sandbox/Cortex/Documentos/Cortex_Plan_Schema.md"
    'table_hierarchy.json' = "{}"
    'table_hierarchy_template.json' = "{}"
}

function Expand-CortexTemplate {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ProjectType
    )

    $result = $Content.Replace('{{PROJECT_NAME}}', $ProjectName)
    $result = $result.Replace('{{PROJECT_TYPE}}', $ProjectType)
    $result = $result.Replace('{{DATE}}', (Get-Date).ToString('yyyy-MM-dd'))
    return $result
}

function Write-CortexFileIfMissing {
<<<<<<< HEAD
=======
    [CmdletBinding()]
>>>>>>> origin/codex_2025-11-21
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    if (-not (Test-Path -Path $Path)) {
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path -Path $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
        $Content | Out-File -FilePath $Path -Encoding utf8
    }
}
