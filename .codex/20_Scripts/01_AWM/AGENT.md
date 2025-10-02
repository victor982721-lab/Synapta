# === config ===
$RepoPath   = "$HOME\src\bashforge"          # o: (git rev-parse --show-toplevel).Trim()
$BranchName = "feat/agent-md-replacement"
$Relative   = ".codex/20_Scripts/01_AWM/AGENT.md"
$Target     = Join-Path $RepoPath $Relative

# === branch ===
git -C $RepoPath checkout -B $BranchName

# === backup (por si acaso) ===
if (Test-Path $Target) {
  $bak = "$Target.$(Get-Date -Format 'yyMMddHHmm').bak"
  Copy-Item -LiteralPath $Target -Destination $bak -Force
  Write-Host "✔ Backup: $bak"
}

# === escribir desde portapapeles (evita el error de $out) ===
$clip = Get-Clipboard -Raw
if ([string]::IsNullOrWhiteSpace($clip)) { throw "Portapapeles vacío. Copia el contenido y reintenta." }
Set-Content -LiteralPath $Target -Value $clip -Encoding UTF8

# === commit + push ===
git -C $RepoPath add -- "$Relative"
git -C $RepoPath commit -m "chore: replace AGENT.md with Codex-aware, WPF+CLI, QA bootstrap version"
git -C $RepoPath push -u origin $BranchName

# === verificación rápida ===
git -C $RepoPath status
git -C $RepoPath log --oneline -n 1

