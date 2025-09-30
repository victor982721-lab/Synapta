```bash
bash <<'EOF'
OUT="/sdcard/captura_$(date +%Y%m%d_%H%M%S).png"
screencap -p "$OUT"
echo "Guardado en: $OUT"
EOF
```