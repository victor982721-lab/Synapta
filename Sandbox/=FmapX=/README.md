# =FmapX=

Inventario de archivos en PowerShell que genera un árbol (MD/TXT) y JSONL con metadatos opcionales. El flujo se divide en un orquestador interactivo (`src/FileMapX.ps1`) y módulos reutilizables en `Scripts/`.

## Uso rápido
- Interactivo: `pwsh -NoLogo -File ./src/FileMapX.ps1` y sigue el asistente.
- No interactivo: `pwsh -NoLogo -File ./src/FileMapX.ps1 -RootPath 'C:\Data' -EmitJsonl -EmitTree -OutputDir 'C:\Salidas'` (otros parámetros siguen disponibles).

## Módulos
- `Scripts/FileMapX.Native.ps1`: carga de tipos Win32 y recorrido rápido para conteo previo.
- `Scripts/FileMapX.Functions.ps1`: utilidades de hashing MD5, clasificación, escritura JSONL y render de árbol.
