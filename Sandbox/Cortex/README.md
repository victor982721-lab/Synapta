# Cortex

Cortex es la evolución modular de `RepoMaster.ps1`: un script maestro único, capaz de generar estructuras completas de proyectos Neurologic, automatizar sincronizaciones Git, ejecutar análisis de calidad y emitir solicitudes listas para Codex Web. Debe operar tanto en modo interactivo (prompts guiados) como en modo no interactivo (parámetros/archivos de configuración) y soportar la creación de proyectos PowerShell y .NET multi-target (net6/net7/net8, Windows 7+).

## Entorno y compatibilidad

- Desarrollo y pruebas principales: Windows 10/11 con PowerShell 7.x.
- Compatibilidad mínima: Windows 7/8.1 con Windows PowerShell 5.1 (Cortex detectará la versión y aplicará ajustes).
- Proyectos generados: multi-target net8/net7/net6 (CLI por defecto, UI solo cuando se documente un requisito específico).

## Objetivos principales

1. **Scaffolding inteligente**: crear Sandbox/Core con toda la documentación (AGENTS, README, Procedimiento, Informe, Solicitud, CSV, tabla de jerarquía, bitácora) sin depender de archivos externos.
2. **Operaciones Git avanzadas**: sync up/down, merges Codex diarios, validación de estado limpio, abort en conflictos y soporte para remotos configurables.
3. **Análisis y calidad**: ejecución integrada de PSSA, Parser AST, dotnet build/test, resúmenes por proyecto y “quality gate” opcional.
4. **Descarga y empaquetado de artefactos**: cliente para `gh`/HTTP, extracción ZIP vía .NET y comando para compilar el propio script en EXE (ps2exe o dotnet publish).
5. **Experiencia CLI/Automation**: menús basados en `PromptForChoice`, barras de progreso, logging y resúmenes multi-repo; API por parámetros para pipelines CI/CD.

## Arquitectura esperada

- `Cortex.Core.Scaffolding`: motor de plantillas y estructura.
- `Cortex.Core.GitOps`: API de sincronización y merges.
- `Cortex.Core.Analysis`: análisis y validaciones (PSSA, Parser, dotnet).
- `Cortex.Core.Artifacts`: descargas y extracción.
- `Cortex.CLI`: interfaz interactiva.
- `Cortex.Automation`: modo headless (parámetros/JSON).
- `Cortex.Exporter`: empaquetado del script a ejecutable.
- `Cortex.Services.*`: orquestadores que coordinan varios componentes Core (RequestBuilder, ProjectFactory, ArtifactSync).

Los componentes deben residir en el mismo `.ps1`, pero claramente separados (regiones o módulos internos) para permitir pruebas y reuso.

## AutoOption y modos de ejecución

| AutoOption | Operación                                                               |
|------------|---------------------------------------------------------------------------|
| 1          | Crear estructura Sandbox/Core con plantillas completadas                 |
| 2          | Ejecutar PSSA/Parser AST/dotnet build-test (quality gate)                |
| 3          | Build/tests multi-repo                                                    |
| 4          | Sync Up (git add/commit/push, validando estado limpio)                    |
| 5          | Sync Down (fetch + merge Codex con manejo de conflictos)                  |
| 6          | Descarga/extracción de artefactos                                         |
| 7          | Ejecutar plan Automation desde archivo JSON/YAML (`cortex plan run ...`) |

- **Modo interactivo**: menús `PromptForChoice`, confirmaciones `Confirm-Action`, `Write-Progress`.
- **Modo no interactivo**: parámetros (`-ProjectType PS-CLI|DotNet-CLI|DotNet-UI`, `-PlanPath`, `-LogPath`, `-RunId`, etc.) o archivo de plan (`docs/Cortex_Plan_Schema.md` describe la estructura).

## Logging y planes Automation

- Esquema de log JSON obligatorio: `RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `DurationMs`, `Details`, `Errors`.
- Ruta por defecto `logs/` (creada automáticamente). Cada ejecución genera `logs/<RunId>.json` + resumen en texto.
- Los planes Automation (JSON/YAML) deben seguir `docs/Cortex_Plan_Schema.md`, que incluye ejemplo y reglas de validación.

## Cortex.csproj

El archivo `Cortex.csproj` sirve como proyecto auxiliar para:

1. Reutilizar helpers .NET (ZipFile, HttpClient, Parser, etc.) desde pruebas o pipelines.
2. Ser base del Exporter (ps2exe / host .NET) cuando se genere el ejecutable final.
3. Ejecutar pruebas unitarias/integración (xUnit, BenchmarkDotNet) que respalden las funciones Core.

Debe mantenerse multi-target (`net8.0;net7.0;net6.0`) y alinearse con los comandos documentados en la solicitud.

## Estado actual

- `docs/Informe.md`: análisis detallado de mejoras para RepoMaster/Cortex.
- `docs/solicitud_de_artefactos.md`: solicitud en elaboración para Codex Web.
- `AGENTS.md`: reglas específicas del proyecto.
- `docs/Cortex_Plan_Schema.md`: estructura del plan JSON/YAML para Automation.
- `csv/modules.csv` y `csv/artefacts.csv`: inventario a completar conforme se definan artefactos.
- `docs/bitacora.md`: registrar acuerdos/decisiones de cada iteración.
- `docs/Procedimiento_de_solicitud_de_artefactos.md`: guía de iteraciones para generar solicitudes.

## Próximos pasos

1. Completar la solicitud con alcance, dependencias y criterios de aceptación (Iteración 2).
2. Definir los artefactos en CSV (Iteración 3) y validar consistencia con tabla de jerarquía / filemap.
3. Enviar la solicitud a Codex Web para que entregue el nuevo `Cortex.ps1`.
4. Diseñar casos de prueba (Iteración 2), implementarlos/validarlos (Iteración 3) y ejecutarlos en PowerShell 5.1 y 7+.
5. Documentar resultados en la bitácora y compilar a EXE si aplica.
