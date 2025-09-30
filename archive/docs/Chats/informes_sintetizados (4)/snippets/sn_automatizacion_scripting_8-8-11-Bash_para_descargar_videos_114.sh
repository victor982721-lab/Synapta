bash <<'EOF'
OUTDIR="/sdcard/DCIM/Camera"
mkdir -p "$OUTDIR"

echo "[1] Captura de pantalla"
echo "[2] Grabar pantalla (Ctrl+C para parar)"
read -p "Elige opción: " opt

case $opt in
  1)
    FILE="$OUTDIR/captura_$(date +%Y%m%d_%H%M%S).png"
    /system/bin/screencap -p "$FILE"
    echo "Captura guardada en: $FILE"
    ;;
  2)
    FILE="$OUTDIR/video_$(date +%Y%m%d_%H%M%S).mp4"
    echo "Grabando... pulsa Ctrl+C para detener"
    /system/bin/screenrecord "$FILE"
    echo "Video guardado en: $FILE"
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
EOF