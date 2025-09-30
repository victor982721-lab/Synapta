```bash
#!/usr/bin/env bash
set -euo pipefail
STEM="${1:-workspace-wizard-ps5-7}"
DIR="${2:-/mnt/data}"
cd "$DIR"
echo "# Recomputando SHA256 para $STEM*"
for f in "$STEM.ps1" "$STEM.txt" "$STEM.md" "$STEM.json" "$STEM.csv" "$STEM.html" "$STEM"_chart.png "$STEM"_explanation.md "REPORT.md" "manifest.json"; do
  if [ -f "$f" ]; then
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$f"; else shasum -a 256 "$f"; fi
  fi
done
echo "# Conteo de artefactos"
ls -1 "$STEM"* 2>/dev/null | wc -l
```