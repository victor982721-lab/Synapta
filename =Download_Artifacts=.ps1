<#! 
    Sync-CodexMain.ps1

    Dos modos pensados para trabajar siempre sobre la rama 'main'
    de un repo sandbox, sincronizando con GitHub para usar Codex Web.

    Modo 1: Subir cambios locales a GitHub (sync up)
      - Muestra un resumen de cambios locales (git status --porcelain).
      - Pregunta confirmación.
      - Hace git add -A, git commit, git pull origin main, git push origin main.

    Modo 2: Traer cambios de la rama Codex_{date} y fusionarlos en main (sync down + merge)
      - Soporta nombres de rama:  Codex_yyyy-MM-dd  o  codex_yyyy-MM-dd.
      - Verifica que el árbol de trabajo esté limpio (sin cambios locales).
      - Calcula nombre de rama Codex_YYYY-MM-DD para HOY.
      - git fetch origin
      - Verifica que exista origin/Codex_YYYY-MM-DD u origin/codex_YYYY-MM-DD.
      - Muestra diff entre origin/main y origin/Codex_YYYY-MM-DD (sin pager).
      - Pregunta confirmación.
      - Hace:
          * git checkout main (o la rama configurada)
          * git pull origin main
          * git merge --no-ff origin/Codex_YYYY-MM-DD
          * git push origin main
          * git push origin --delete Codex_YYYY-MM-DD   (borrar rama remota)
          * git branch -D Codex_YYYY-MM-DD             (borrar rama local si existe)
        Si hay conflictos en el merge, los muestra y NO borra la rama.

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
Write-Host "  2) Traer cambios desde rama Codex_{date} (merge en main y borrar rama)"
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
        # Modo 2: traer cambios desde rama Codex_{date} y fusionar en main

        # Asegurarse de que no haya cambios locales
        $rawStatus = (& git status --porcelain)
        if (-not [string]::IsNullOrWhiteSpace($rawStatus)) {
            Write-WarnMsg "Hay cambios locales sin commitear. No se continuará para evitar mezclar con la rama Codex."
            Write-Host "Revisa primero con:" -ForegroundColor Yellow
            Write-Host "  git status"
            Write-Host "  git diff"
            return
        }

        # Fecha de hoy
        $today = Get-Date -Format 'yyyy-MM-dd'
        $candidateBranches = @(
            ("Codex_{0}" -f $today),
            ("codex_{0}" -f $today)
        )

        Write-Info ("Buscando rama Codex para hoy ({0})..." -f $today)
        Write-Info "Haciendo git fetch origin..."
        & git fetch origin | Out-Null

        $codexBranch = $null

        foreach ($name in $candidateBranches) {
            $remoteMatch = (& git branch -r --list ("origin/{0}" -f $name))
            if (-not [string]::IsNullOrWhiteSpace($remoteMatch)) {
                $codexBranch = $name
                break
            }
        }

        if (-not $codexBranch) {
            Write-ErrMsg "No se encontró ninguna rama remota Codex para la fecha de hoy ($today)."
            Write-Host "Ramas remotas que parecen ser de Codex:" -ForegroundColor Yellow
            & git branch -r --list "origin/Codex_*" "origin/codex_*"
            return
        }

        Write-Info ("Se usará la rama remota origin/{0}" -f $codexBranch)

        # Mostrar diff entre origin/main y origin/Codex_{date}
        Write-Host ""
        Write-Info ("Diff entre origin/{0} y origin/{1} (sin pager):" -f $Branch, $codexBranch)
        & git --no-pager diff ("origin/{0}" -f $Branch) ("origin/{0}" -f $codexBranch)
        Write-Host ""

        $confirm = Read-Host ("Escribe 'S' y pulsa ENTER para fusionar origin/{0} en {1}, o cualquier otra cosa para cancelar" -f $codexBranch, $Branch)
        if ($confirm.Trim().ToUpperInvariant() -ne "S") {
            Write-Info "Operación cancelada por el usuario."
            return
        }

        # Asegurarse de estar en la rama main/Branch
        Write-Info ("Cambiando a rama {0}..." -f $Branch)
        & git checkout $Branch

        Write-Info ("Actualizando {0} desde origin/{0}..." -f $Branch)
        try {
            & git pull origin $Branch
        } catch {
            Write-ErrMsg "git pull origin $Branch falló. Revisa el estado del repo."
            return
        }

        Write-Info ("Haciendo merge --no-ff de origin/{0} en {1}..." -f $codexBranch, $Branch)
        try {
            & git merge --no-ff ("origin/{0}" -f $codexBranch)
        } catch {
            Write-ErrMsg "El merge produjo conflictos. Revisa 'git status' y 'git diff'. La rama Codex NO se borró."
            return
        }

        # Verificar si quedaron conflictos
        $postStatus = (& git status --porcelain --untracked-files=no)
        if ($postStatus -match '^\s*UU') {
            Write-ErrMsg "Hay archivos en conflicto (estado 'UU'). Resuélvelos manualmente antes de hacer push."
            Write-Host "Usa, por ejemplo:" -ForegroundColor Yellow
            Write-Host "  git status"
            Write-Host "  git diff"
            Write-Host "  git add <archivos_resueltos>"
            Write-Host "  git commit"
            Write-Host ""
            Write-WarnMsg ("La rama origin/{0} NO se borró por seguridad." -f $codexBranch)
            return
        }

        Write-Info ("Merge completado. Haciendo push de {0} a origin..." -f $Branch)
        & git push origin $Branch

        # Borrar rama remota Codex_{date}
        Write-Info ("Borrando rama remota origin/{0}..." -f $codexBranch)
        try {
            & git push origin --delete $codexBranch
        } catch {
            Write-WarnMsg ("No se pudo borrar la rama remota {0}. Revisa permisos o hazlo a mano en GitHub." -f $codexBranch)
        }

        # Borrar rama local Codex_{date} si existe
        $localBranchMatch = (& git branch --list $codexBranch)
        if (-not [string]::IsNullOrWhiteSpace($localBranchMatch)) {
            Write-Info ("Borrando rama local {0}..." -f $codexBranch)
            try {
                & git branch -D $codexBranch
            } catch {
                Write-WarnMsg ("No se pudo borrar la rama local {0}. Revisa manualmente." -f $codexBranch)
            }
        }

        Write-Info ("Listo. Los cambios de {0} quedaron fusionados en {1} y la rama Codex se limpió (en lo posible)." -f $codexBranch, $Branch)
    }
    default {
        Write-WarnMsg "Opción inválida. Nada que hacer."
        return
    }
}
