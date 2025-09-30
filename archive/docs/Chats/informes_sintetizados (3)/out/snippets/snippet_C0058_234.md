```
<base_dir>/ysd/<case_id>/
  _ysd_in/                # originales .ysd (solo lectura)
  _ysd_out/
    segments/             # *.bin carved
    decoded/              # salidas decomp/crypto
    extract/              # objetos por TOC
    logs/                 # *.jsonl + stderr/stdout capturado
    charts/               # entropy.png (si hay librería)
  _reports/
    REPORT_ysd_v1.md
    ysd-spec_v1.md
  _release/
    ysd-release-YYYYMMDDThhmmssZ.zip
  work/                   # temporales (limpiables)
  manifest.json
  SHA256SUMS.txt
```