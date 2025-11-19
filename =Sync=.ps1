<#!
    Sync-CodexMain.ps1

    Dos modos pensados para trabajar siempre sobre la rama 'main'
    de un repo sandbox, sincronizando con GitHub para usar Codex Web.

    Modo 1: Subir cambios locales a GitHub (sync up)
      - Muestra un resumen de cambios locales (git status --porcelain).
      - Pregunta confirmación.
      - Hace git add -A, git commit, git pull origin main, git push origin main.

    Modo 2: Traer cambios desde GitHub (sync down)
      - Verifica que NO haya cambios locales sin commitear.
      - Hace git pull origin main para traer los cambios (por ejemplo,
        los que vienen de una PR creada por Codex Web).

    Requisitos:
      - git en PATH
      - Estar dentro de un repo clonado de GitHub que use 'main'
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = (Get-Location),
    [string]$Branch   = "main"
)

function Write-Info([string]$Message) {
    Write-Host "[sync] $Message" -ForegroundColor Cyan
}

function Write-WarnMsg([string]$Message) {
    Write-Host "[sync][WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrMsg([string]$Message) {
    Write-Host "[sync][ERROR] $Message" -ForegroundColor Red
}

function Show-Changes {
    param(
        [string[]]$Lines
    )

    if (-not $Lines -or $Lines.Count -eq 0 -or
        ([string]::IsNullOrWhiteSpace(($Lines -join '')))) {
        Write-Info "No hay cambios locales."
        return
    }

    Write-Info "Cambios locales:"

    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.Length -lt 4) { continue }

        $status = $line.Substring(0,2)
        $path   = $line.Substring(3).Trim()

        switch -Regex ($status) {
            '^\?\?' {
                Write-Host ("  + (untracked) {0}" -f $path) -ForegroundColor Green
            }
            '^A' {
                Write-Host ("  + (added)     {0}" -f $path) -ForegroundColor Green
            }
            '^.A' {
                Write-Host ("  + (added)     {0}" -f $path) -ForegroundColor Green
            }
            '^D' {
                Write-Host ("  - (deleted)   {0}" -f $path) -ForegroundColor Red
            }
            '^.D' {
                Write-Host ("  - (deleted)   {0}" -f $path) -ForegroundColor Red
            }
            '^M' {
                Write-Host ("  ~ (modified)  {0}" -f $path) -ForegroundColor Yellow
            }
            '^.M' {
                Write-Host ("  ~ (modified)  {0}" -f $path) -ForegroundColor Yellow
            }
            '^R' {
                Write-Host ("  > (renamed)   {0}" -f $path) -ForegroundColor Magenta
            }
            default {
                Write-Host ("    (other)     {0} [{1}]" -f $path, $status.Trim()) -ForegroundColor DarkGray
            }
        }
    }
}

# --- Validar git ---
try {
    Get-Command git -ErrorAction Stop | Out-Null
} catch {
    Write-ErrMsg "No se encontró 'git' en PATH."
    return
}

# --- Validar repo ---
if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    Write-ErrMsg "El directorio '$RepoRoot' no parece un repositorio git (.git no encontrado)."
    return
}

Set-Location $RepoRoot

# --- Rama actual ---
$currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
Write-Info ("Rama actual: {0}" -f $currentBranch)

if ($currentBranch -ne $Branch) {
    Write-WarnMsg ("Estás en la rama '{0}', pero el script está configurado para trabajar con '{1}'." -f $currentBranch, $Branch)
    $ans = Read-Host "¿Continuar de todas formas? (S/N, ENTER = N)"
    if ($ans.Trim().ToUpperInvariant() -ne "S") {
        Write-Info "Cancelado por el usuario."
        return
    }
}

# --- Menú simple ---
Write-Host ""
Write-Host "Selecciona modo:" -ForegroundColor Cyan
Write-Host "  1) Subir cambios locales a GitHub (commit + pull + push)"
Write-Host "  2) Traer cambios desde GitHub (pull)"
Write-Host ""

$mode = Read-Host "Opción (1/2, ENTER = 1)"
if ([string]::IsNullOrWhiteSpace($mode)) { $mode = "1" }

switch ($mode.Trim()) {
    '1' {
        # Modo 1: subir cambios locales
        $rawStatus = (& git status --porcelain)
        if ([string]::IsNullOrWhiteSpace($rawStatus)) {
            Write-Info "No hay cambios locales que subir."
            return
        }

        $lines = $rawStatus -split "`n"
        Show-Changes -Lines $lines

        Write-Host ""
        $cont = Read-Host "¿Subir estos cambios a origin/$Branch? (S/N, ENTER = S)"
        if ([string]::IsNullOrWhiteSpace($cont)) { $cont = "S" }
        if ($cont.Trim().ToUpperInvariant() -ne "S") {
            Write-Info "Operación cancelada por el usuario."
            return
        }

        Write-Info "Haciendo stage de todos los cambios..."
        & git add -A

        $defaultMsg = "chore: sync local -> origin/$Branch ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        $msg = Read-Host "Mensaje de commit (ENTER para usar mensaje automático)"
        if ([string]::IsNullOrWhiteSpace($msg)) {
            $msg = $defaultMsg
        }

        Write-Info ("Creando commit: {0}" -f $msg)
        & git commit -m $msg

        Write-Info "Haciendo git pull origin $Branch (para integrar remoto antes de push)..."
        try {
            & git pull origin $Branch
        } catch {
            Write-ErrMsg "git pull origin $Branch falló. Revisa conflictos con 'git status' y 'git diff'."
            return
        }

        Write-Info "Haciendo git push origin $Branch..."
        & git push origin $Branch
        Write-Info "Listo. Cambios locales subidos a origin/$Branch."
    }
    '2' {
        # Modo 2: traer cambios desde GitHub
        $rawStatus = (& git status --porcelain)
        if (-not [string]::IsNullOrWhiteSpace($rawStatus)) {
            Write-WarnMsg "Hay cambios locales sin commitear. No se realizará pull para evitar mezclas raras."
            Write-Host "Revisa primero con:" -ForegroundColor Yellow
            Write-Host "  git status"
            Write-Host "  git diff"
            return
        }

        Write-Info "Trayendo cambios de origin/$Branch (git pull)..."
        try {
            & git pull origin $Branch
        } catch {
            Write-ErrMsg "git pull origin $Branch falló. Revisa el mensaje de error de git."
            return
        }

        Write-Info "Listo. origin/$Branch sincronizado en tu carpeta local."
    }
    default {
        Write-WarnMsg "Opción inválida. Nada que hacer."
        return
    }
}
