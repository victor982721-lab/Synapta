bash <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
OUTDIR="/sdcard"
mkdir -p "$OUTDIR"

echo "[1] Captura de pantalla"
echo "[2] Grabar pantalla (detener con Ctrl+C)"
read -p "Elige opción: " opt

case $opt in
  1)
    FILE="$OUTDIR/captura_$(date +%Y%m%d_%H%M%S).png"
    screencap -p "$FILE"
    echo "Captura guardada en: $FILE"
    ;;
  2)
    FILE="$OUTDIR/video_$(date +%Y%m%d_%H%M%S).mp4"
    echo "Grabando... Ctrl+C para detener"
    screenrecord "$FILE"
    echo "Video guardado en: $FILE"
    ;;
  *)
    echo "Opción inválida"
    ;;
esac
EOF