```bash
# Escanear dos rutas y crear CSV con hash
python filemap_sha256.py --roots "/ruta/A" "/ruta/B" --csv filemap_sha256.csv

# O bien, partir de tu FileList.csv (con columna 'path'):
python filemap_sha256.py --input-csv FileList.csv --path-column path --csv filemap_sha256.csv
```