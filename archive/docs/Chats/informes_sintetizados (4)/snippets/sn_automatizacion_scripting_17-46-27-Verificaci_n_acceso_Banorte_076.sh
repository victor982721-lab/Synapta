cat <<'EOF' > check_boot_state.sh
#!/data/data/com.termux/files/usr/bin/bash
# Script para checar integridad del bootloader / AVB en Samsung desde Termux
# Muestra si el sistema está en green, orange o red

echo "[*] Consultando propiedades del sistema..."
boot_state=$(getprop ro.boot.verifiedbootstate)
flash_state=$(getprop ro.boot.flash.locked)
warranty=$(getprop ro.boot.warranty_bit)

echo "----------------------------------"
echo " Verified Boot State : $boot_state"
echo " Flash Lock State    : $flash_state"
echo " Knox Warranty Bit   : $warranty"
echo "----------------------------------"

case "$boot_state" in
  green)
    echo "✅ Estado GREEN: Bootloader bloqueado y sistema íntegro."
    ;;
  orange)
    echo "⚠️ Estado ORANGE: Bootloader desbloqueado."
    ;;
  red)
    echo "❌ Estado RED: Integridad rota, sistema modificado."
    ;;
  *)
    echo "❓ Estado desconocido: $boot_state"
    ;;
esac
EOF

chmod +x check_boot_state.sh
./check_boot_state.sh