#!/usr/bin/env bash
set -euo pipefail

echo "=== Setup: PowerShell + PSSA + Pester + .NET 6/7/8 ==="

PWSH_VERSION=7.5.4
PWSH_DIR="/root/.powershell/$PWSH_VERSION"

DOTNET_DIR="/root/.dotnet"
DOTNET_CHANNELS=("6.0" "7.0" "8.0")

mkdir -p "$PWSH_DIR" "$DOTNET_DIR"

# ============================================================
# Dependencias mínimas
# ============================================================
apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libicu-dev \
    libssl-dev \
    zlib1g

# ============================================================
# PowerShell
# ============================================================
curl -L \
  "https://github.com/PowerShell/PowerShell/releases/download/v$PWSH_VERSION/powershell-$PWSH_VERSION-linux-x64.tar.gz" \
  -o /tmp/powershell.tar.gz

tar -xzf /tmp/powershell.tar.gz -C "$PWSH_DIR"
chmod -R +x "$PWSH_DIR"
rm /tmp/powershell.tar.gz

echo "export PATH=\"$PWSH_DIR:\$PATH\"" | tee /etc/profile.d/pwsh.sh
chmod +x /etc/profile.d/pwsh.sh

echo 'export PSModulePath="/root/.local/share/powershell/Modules:/usr/local/share/powershell/Modules:/usr/share/powershell/Modules:/root/.powershell/Modules"' \
  | tee /etc/profile.d/psmodules.sh
chmod +x /etc/profile.d/psmodules.sh

# ============================================================
# .NET 6/7/8 SDKs
# ============================================================
curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh

for channel in "${DOTNET_CHANNELS[@]}"; do
  /tmp/dotnet-install.sh --channel "$channel" --install-dir "$DOTNET_DIR" --no-path
done

echo "export DOTNET_ROOT=\"$DOTNET_DIR\"" | tee /etc/profile.d/dotnet.sh
echo 'export PATH="$DOTNET_ROOT:$PATH"' >> /etc/profile.d/dotnet.sh
chmod +x /etc/profile.d/dotnet.sh

# También disponibles en este shell de setup:
export DOTNET_ROOT="$DOTNET_DIR"
export PATH="$DOTNET_ROOT:$PATH"

# ============================================================
# Módulos de análisis
# ============================================================
"$PWSH_DIR/pwsh" -NoLogo -NoProfile -Command "Install-Module PSScriptAnalyzer -Force -Scope AllUsers"
"$PWSH_DIR/pwsh" -NoLogo -NoProfile -Command "Install-Module Pester -Force -Scope AllUsers"

echo "=== Setup listo. Pwsh, PSSA, Pester y .NET 6/7/8 instalados ==="