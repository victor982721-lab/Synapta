# AGENTS – Cortex

Este AGENTS extiende el lineamiento general de Neurologic para definir cómo se debe diseñar y construir **Cortex**, el sucesor modular de `RepoMaster.ps1`. Lee primero `docs/Procedimiento_de_solicitud_de_artefactos.md`, `docs/Informe.md`, `docs/Cortex_Plan_Schema.md` y este documento antes de solicitar trabajo a cualquier agente.

## 1. Objetivo del proyecto

Construir un **script maestro unificado (Cortex.ps1)** capaz de:
- Automatizar la generación de solicitudes y estructuras estándar (AGENTS, README, docs, CSV, tabla de jerarquía, bitácora) para nuevos proyectos del ecosistema.
- Crear scaffolds completos tanto para **proyectos PowerShell** (módulos y scripts compatibles PS 5.1+ / pwsh 7+) como para **proyectos .NET multi-target (net6/net7/net8)** que puedan exponerse como CLI o UI según se elija.
- Ejecutarse en modo **interactivo** (prompts maestros, menús con `PromptForChoice`) y **no interactivo** (parámetros, archivos de configuración) para permitir automatizaciones CI/CD.
- Encapsular toda la funcionalidad en un único `.ps1`, pero con arquitectura en capas (Core, Services, CLI, Automation) que facilite pruebas, refactors y la futura compilación a ejecutable (ps2exe o empaquetado con `dotnet publish`).

## 2. Alcance y entregables mínimos

1. **Capas lógicas**:
   - `Cortex.Core.*`: operaciones puras (Git, scaffolding, validaciones, plantillas).
   - `Cortex.Services.*`: orquestadores especializados (RequestBuilder, ProjectFactory, ArtifactSync).
   - `Cortex.CLI`: menús interactivos, prompts y confirmaciones.
   - `Cortex.Automation`: interfaz por parámetros/JSON para pipelines.
2. **Funciones clave** (detalladas en docs/solicitud_de_artefactos.md):
   - Generar estructuras Sandbox/Core alineadas a RepoMaster actual, pero con plantillas enriquecidas (AGENTS, README, Procedimiento, Informe, Solicitud, CSV).
   - Sincronizar repos locales/remotos (pull, merge Codex, push) con detección y manejo de conflictos.
   - Ejecutar análisis (PSSA, Parser AST, dotnet build/test).
   - Descargar/extraer artefactos desde GitHub Releases o CI, usando `gh` si está disponible o `System.Net.Http` + `System.IO.Compression.ZipFile`.
   - Generar resúmenes y logs por operación y por lote multi-repo.
3. **Compatibilidad**:
   - Entorno de trabajo y validación: Windows 10/11 con PowerShell 7.x.
   - Compatibilidad mínima de ejecución: Windows 7+ y Windows PowerShell 5.1 (Cortex debe detectar la versión y ajustar rutas/encoding/comandos en consecuencia).
   - .NET SDK 6, 7 y 8 para los proyectos generados (multi-target obligatorio).
4. **Salida final**:
   - Script `.ps1` listo para ejecutarse tal cual.
   - Documentación integrada (`Get-Help`), plantillas embebidas y mecanismo para compilar a EXE (indicaciones/documentación + comando automatizado).

## 3. Requisitos técnicos obligatorios

1. **Strict Mode & errores**: `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`, manejo explícito de excepciones y códigos de salida (0 éxito, códigos >0 para fallos).
2. **Separación UI/Core**: ninguna función Core debe usar `Read-Host`. Toda entrada se recibe por parámetros. Las funciones UI llaman a las Core y traducen la interacción.
3. **Prompt maestro**: menús basados en `$Host.UI.PromptForChoice`, confirmaciones centralizadas (Confirm-Action) y colores/progreso (`Write-Progress`) para operaciones largas.
4. **Soporte no interactivo**: cada acción expone parámetros (e.g. `New-CortexProject -Type PowerShell -Name Foo -Output C:\Repos`). `-AutoOption` debe cubrir todas las operaciones (1–6+) y aceptar switches como `-RunId`, `-ArtifactName`, `-RemoteName`.
5. **Plantillas embebidas**: almacenar en el propio script el contenido necesario (AGENTS, README, Procedimiento, Informe, Solicitud, CSV headers, etc.) y permitir override mediante carpeta `Templates/`.
6. **Validaciones integradas**:
   - Verificar prerequisitos (git, dotnet, gh, ps2exe si aplica).
   - Revisar estado limpio del repo antes de push/merge.
   - Abort/rollback en caso de conflicto (`git merge --abort`) y mensajes claros.
   - Ejecutar Parser AST / PSSA y mostrar resumen (warnings, errores) con opción `-QualityGate`.
7. **Registro/bitácora**: salida estructurada por operación y capacidad de emitir log a archivo (JSON/CSV) para pipelines siguiendo el esquema descrito en la sección 6 (ruta por defecto `logs/` configurable via parámetros).

## 4. Artefactos que se deben generar o actualizar

Registrar cada uno en `csv/artefacts.csv` y `csv/modules.csv`:
1. `Cortex.Core.Scaffolding` – Motor para generar estructuras y plantillas.
2. `Cortex.Core.GitOps` – API para sync up/down, merges Codex, manejo de remotos configurables.
3. `Cortex.Core.Analysis` – Integración con PSSA, Parser AST, dotnet build/test, ejecución resumida.
4. `Cortex.Core.Artifacts` – Cliente para descargas `gh`/HTTP, extracción ZIP vía .NET.
5. `Cortex.Services.*` – Orquestadores de alto nivel (RequestBuilder, ProjectFactory, ArtifactSync) que combinan múltiples componentes Core.
5. `Cortex.CLI` – Interfaz interactiva con menús guiados, prompts y resúmenes.
6. `Cortex.Automation` – Entrada por parámetros, JSON o archivos de configuración (planJobs) para pipelines.
7. `Cortex.Exporter` – Paso opcional que empaqueta/compila el script en EXE (`ps2exe` o `dotnet publish` con hosting).

## 5. Flujo operativo esperado

1. **Iteración 1 – Investigación**: revisar Informe y recopilar dependencias existentes (RepoMaster, plantillas, templates). Documentar en README + AGENTS.
2. **Iteración 2 – Diseño / Solicitud**: definir arquitectura modular, interfaces core/UI, escenarios interactivo/no interactivo, compatibilidad multi-framework; actualizar `docs/solicitud_de_artefactos.md`, `AGENTS.md`, `README.md`.
3. **Iteración 3 – Materialización**: una vez Codex Web entregue Cortex.ps1 modular, actualizar CSV, filemap, tabla de jerarquía, bitácora y compilar si se requiere.

## 6. Convenciones adicionales

- Encoding UTF-8 sin BOM.
- Comentarios XML style para funciones (ayuda `Get-Help`).
- Tests mínimos en `tests/` (Pester/xUnit) para las funciones Core clave; Iteración 2 debe definir los casos y Iteración 3 verificar su implementación.
- Logs y resúmenes deben usarse también en `Invoke-MultiRepo` siguiendo el esquema:
  - `RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `DurationMs`, `Details`, `Errors`.
  - Carpeta por defecto `logs/` (creada si no existe) con archivos JSON (`logs/<RunId>.json`) y resumen en texto.
- Documentar comandos finales para compilar a EXE (PS2EXE y dotnet-global tool si aplica).
- Tabla de auto opciones obligatoria:

| AutoOption | Operación                                                         |
|------------|-------------------------------------------------------------------|
| 1          | Crear estructura Sandbox/Core con plantillas llenadas             |
| 2          | Ejecutar PSSA/Parser/dotnet build-test                            |
| 3          | Build/tests multi-repo                                            |
| 4          | Sync Up (git add/commit/push)                                     |
| 5          | Sync Down (fetch/merge Codex, manejar conflictos)                 |
| 6          | Descarga y extracción de artefactos                               |
| 7          | Ejecutar plan Automation desde archivo JSON/YAML                  |

- Tipos de proyecto soportados (`-ProjectType`): `PS-CLI`, `DotNet-CLI`, `DotNet-UI`. La opción por defecto es CLI; UI solo se usa si la solicitud documenta requisitos específicos.
- `Cortex.csproj` se utiliza como proyecto auxiliar para helpers .NET, pruebas y como base para el Exporter; debe mantenerse multi-target (net8/net7/net6).
- `Cortex_Plan_Schema.md` define la estructura JSON/YAML de los planes Automation y debe mantenerse sincronizado con la implementación.
- Documentos efímeros (p. ej. Procedimiento) no deben enviarse a Codex; si se retiran, almacenar su última versión en `docs/Archive/` o registrar el resumen en la bitácora.

## 7. Checklist antes de solicitar trabajo

1. Procedimiento completado hasta la iteración correspondiente.
2. `docs/solicitud_de_artefactos.md` lleno con antecedentes, objetivo, alcance, criterios de aceptación.
3. `AGENTS.md` y `README.md` sin placeholders.
4. `csv/modules.csv` y `csv/artefacts.csv` enumeran todos los artefactos mencionados en la solicitud.
5. `docs/table_hierarchy.json`, `docs/filemap_ascii.txt` y `docs/bitacora.md` reflejan la estructura y las decisiones actuales.
6. `Cortex.ps1` actual (RepoMaster clon) listo como referencia para refactor/modularización.

Cumple con este AGENTS al coordinar la solicitud para Codex Web; cualquier desviación debe quedar documentada en la bitácora y en la solicitud.
