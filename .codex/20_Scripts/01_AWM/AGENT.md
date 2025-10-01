# RUTA LOCAL DEL REPO (ajústala si usaste otra)
$RepoPath    = "$HOME\src\bashforge"
$BranchName  = "feat/agent-md-replacement"
$Relative    = ".codex/20_Scripts/01_AWM/AGENT.md"
$Target      = Join-Path $RepoPath $Relative

# 1) Cambiar/crear rama
git -C $RepoPath checkout -B $BranchName

# 2) Backup del archivo actual (si existe)
if (Test-Path -LiteralPath $Target) {
  $bak = "$Target.$(Get-Date -Format 'yyMMddHHmm').bak"
  Copy-Item -LiteralPath $Target -Destination $bak -Force
  Write-Host "✔ Backup: $bak"
}

# 3) Escribir DESDE EL PORTAPAPELES (sin expandir variables)
$clip = Get-Clipboard -Raw
if ([string]::IsNullOrWhiteSpace($clip)) { throw "El portapapeles está vacío. Copia el contenido y reintenta." }
Set-Content -LiteralPath $Target -Value $clip -Encoding UTF8

# 4) Commit + push
git -C $RepoPath add -- "$Relative"
git -C $RepoPath commit -m "chore: replace AGENT.md with Codex-aware, WPF+CLI, QA bootstrap version"
git -C $RepoPath push -u origin $BranchName

# 5) (Opcional) Abrir PR con gh si lo tienes
if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh pr create --repo "victor982721-lab/bashforge" --title "Replace AGENT.md with Codex-aware version" --body "Automated replacement with backup."
} else {
  Write-Host "↗ Abre el PR: https://github.com/victor982721-lab/bashforge/compare/$BranchName?expand=1"
}

