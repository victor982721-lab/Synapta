# Scripts

Este directorio concentra herramientas auxiliares para preparar el entorno de desarrollo de los proyectos Synapta.

## `setup-synapta-env.sh`

Script idempotente que instala **.NET SDK**, **PowerShell** y **PSScriptAnalyzer** dentro del directorio del usuario, respetando los
principios descritos en `AGENTS.md` (parámetros claros, salidas estructuradas y telemetría básica).

### Uso rápido

```bash
./setup-synapta-env.sh \
  --channel 8.0 \
  --pwsh-version 7.5.4 \
  --home "$HOME" \
  --summary setup.json
```

### Flags disponibles

| Flag | Descripción |
| --- | --- |
| `-c, --channel` | Canal del instalador de .NET (`8.0`, `9.0`, etc.). |
| `-p, --pwsh-version` | Versión de PowerShell a descargar (por defecto `7.5.4`). |
| `-H, --home` | Carpeta base donde se guardarán las herramientas. |
| `-o, --summary` | Archivo donde persistir el resumen JSON del proceso. |
| `--skip-pssa` | Omite la instalación de PSScriptAnalyzer. |
| `--no-color` | Desactiva la salida coloreada (útil para logs CI). |
| `-h, --help` | Muestra la ayuda integrada. |

El script siempre imprime un resumen JSON (también puede escribirse en archivo con `--summary`), de modo que otras automatizaciones
puedan consumir el estado final de cada componente.

### Librerías reutilizables (`Scripts/lib`)

Para fomentar la modularidad, los scripts Bash comparten utilidades comunes dentro del subdirectorio `lib/`:

| Archivo | Rol |
| --- | --- |
| `lib/logging.sh` | Inicializa colores ANSI y expone `synapta::log::{banner,section,info,...}`. |
| `lib/utils.sh` | Helpers agnósticos (`require_cmd`, `ensure_dir`, `emit_summary`). |
| `lib/installers/dotnet.sh` | Funciones `synapta::dotnet::ensure/install` para descargar el SDK por canal. |
| `lib/installers/pwsh.sh` | Rutinas para instalar o validar PowerShell portables. |
| `lib/installers/pssa.sh` | Installer best-effort de **PSScriptAnalyzer** (PowerShell). |

Otros scripts pueden `source` estos módulos para reutilizar logging, validaciones y rutinas de instalación sin duplicar código.
