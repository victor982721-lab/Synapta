DOTNET_DIR="/root/.dotnet"

if [ ! -x "$DOTNET_DIR/dotnet" ]; then
  echo "[maintenance] ERROR: dotnet no encontrado."
  exit 1
fi

"$DOTNET_DIR/dotnet" --info >/dev/null
echo "[maintenance] dotnet OK."