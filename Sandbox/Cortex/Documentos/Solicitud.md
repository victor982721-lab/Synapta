[AGENTE_DESTINO]
Codex Web

[TIPO_SOLICITUD]
artefacto_reutilizable

[ANTECEDENTES]
RepoMaster.ps1 ha crecido como script monolítico que combina UI, lógica de negocio, plantillas y operaciones Git/CI. El informe técnico (`docs/Informe.md`) documenta más de 50 hallazgos: ausencia de StrictMode, dependencia de `Read-Host`, opciones automáticas incompletas (5 y 6), falta de logging/resúmenes, manejo deficiente de merges Codex y descarga manual de artefactos. Se requiere un rediseño manteniendo un solo `.ps1`, pero con capas internas claras para soportar PowerShell 5.1+ y pwsh 7+, Windows 7+, proyectos PowerShell y .NET multi-target (net6/net7/net8) y la futura compilación del script a ejecutable. El proyecto Cortex parte del código actual (copiado en `docs/Cortex.ps1`) y de la estructura Sandbox generada por RepoMaster.

[OBJETIVO_TECNICO]
Entregar un script `Cortex.ps1` autosuficiente que:
1. Genere estructuras Sandbox/Core completas con toda la documentación y CSV rellenados a partir de plantillas embebidas.
2. Ofrezca operaciones Git avanzadas (sync up/down, merges Codex, validación de estado limpio, remote configurable) con manejo automático de conflictos.
3. Ejecute análisis integrados (PSSA, Parser AST, dotnet build/test) y reporte resultados resumidos con opción de “quality gate”.
4. Descargue y extraiga artefactos desde GitHub Releases/Actions usando `gh` si existe o HTTP + `System.IO.Compression.ZipFile` si no.
5. Exponga menús y prompts maestro (`PromptForChoice`, `Confirm-Action`, `Write-Progress`) y ofrezca un modo no interactivo basado en parámetros/archivos para CI/CD.
6. Centralice constantes/configuración, logs y resúmenes multi-repo, y documente cómo compilar el script a EXE (ps2exe/dotnet publish).

[ARTEFACTOS_REUTILIZABLES]
1. `Cortex.Core.Scaffolding` – Motor para crear estructuras, docs y plantillas (PowerShell + .NET). (Nuevo)
2. `Cortex.Core.GitOps` – API para git status/add/commit/pull/push/merge Codex con control de remotos y conflictos. (Refactor de lógica existente)
3. `Cortex.Core.Analysis` – Integración con Parser AST, PSSA, dotnet build/test y quality gates. (Nuevo)
4. `Cortex.Core.Artifacts` – Cliente de descargas `gh`/HTTP y extracción ZIP .NET. (Nuevo)
5. `Cortex.CLI` – Capa de interacción con menús y prompts; usa únicamente funciones Core. (Nuevo)
6. `Cortex.Automation` – Entrada por parámetros/JSON para pipelines, incluye scheduler de jobs/lotes. (Nuevo)
7. `Cortex.Exporter` – Procedimiento para empaquetar el script en EXE (ps2exe + publicación dotnet). (Nuevo)

[ALCANCE_FUNCIONAL]
Incluye:
- Refactorización completa de `RepoMaster` a `Cortex` con separación Core/UI y StrictMode.
- Compatibilidad PS 5.1+ / pwsh 7+, Windows 7+.
- Generación de proyectos PowerShell y .NET multi-target (CLI o UI) seleccionables por menú o parámetros.
- Plantillas embebidas para AGENTS, README, Procedimiento, Informe, Solicitud, CSV, tabla de jerarquía y bitácora.
- Sincronización Git y descarga de artefactos automática.
- Logging/resúmenes y salida estructurada para CI.
Excluye:
- Migrar a módulos externos (.psm1) o dividir en varios archivos.
- Soporte para Linux/Mac en esta fase (debe detectar y advertir si se ejecuta fuera de Windows).
- Reescritura de proyectos existentes distintos a RepoMaster; el foco es el script maestro.

[INTERFAZ]
*CLI interactiva*:
- Menú principal con `PromptForChoice` y atajos numéricos.
- Confirmaciones críticas con `Confirm-Action` (Sí/No) y mensajes de color (verde éxito, amarillo warning, rojo error).
- `Write-Progress` para operaciones largas (descargas, builds, multi-repo).
*Modo no interactivo / automation*:
- Parámetros globales: `-AutoOption`, `-RepoPath`, `-ProjectName`, `-ProjectType (PowerShell|DotNetCli|DotNetUi)`, `-Branch`, `-RemoteName`, `-TemplateOverride`, `-PlanPath`, `-QualityGate`, `-LogPath`, `-ConfigFile`.
- Capacidad de leer un archivo JSON/YAML con jobs (ej. `cortex plan run --file plan.json`). El esquema se documenta en `docs/Cortex_Plan_Schema.md` y debe mantenerse sincronizado con la implementación.
*Exportador*:
- Comando `Invoke-CortexExporter -Output C:\Tools\Cortex.exe -Runtime win-x64` que encapsula el script con ps2exe o publica un host .NET que lo ejecute embebido.

[ESTRUCTURA_ARCHIVOS]
```
Cortex/
├── AGENTS.md
├── README.md
├── Cortex.csproj (para pruebas/helpers .NET)
├── docs/
│   ├── Procedimiento_de_solicitud_de_artefactos.md
│   ├── Informe.md
│   ├── solicitud_de_artefactos.md
│   ├── filemap_ascii.txt
│   ├── table_hierarchy.json
│   ├── bitacora.md
│   └── Cortex.ps1 (versión actual)
├── csv/
│   ├── modules.csv
│   └── artefacts.csv
├── Scripts/
├── src/
└── tests/
```
`docs/filemap_ascii.txt` y `docs/table_hierarchy.json` deben actualizarse para reflejar los nuevos artefactos generados durante el desarrollo.

[DEPENDENCIAS_CORE]
- `git`, `dotnet` (6/7/8 SDK), `gh` CLI (opcional), `ps2exe` (PowerShell module) o tooling equivalente para exportar.
- Parser AST (`System.Management.Automation.Language.Parser`), `PSScriptAnalyzer` (instalar/detectar).
- `System.IO.Compression.ZipFile`, `System.Net.Http.HttpClient`.
- Políticas y plantillas globales de Neurologic (AGENTS general, Procedimiento, Informe).
- `docs/Cortex_Plan_Schema.md` para planes Automation y `logs/` como ruta por defecto de bitácoras JSON.

[CRITERIOS_ACEPTACION]
1. `Cortex.ps1` pasa Parser AST + PSSA (sin errores); incorpora `Set-StrictMode` y `$ErrorActionPreference='Stop'`.
2. Cada operación crítica cuenta con modo interactivo (menú) y no interactivo (parámetros/plan file); `-AutoOption 1..6` funciona y devuelve códigos de salida coherentes.
3. Scaffolding genera AGENTS/README/Procedimiento/Informe/Solicitud/CSV/Tabla/Bitácora prellenados a partir de plantillas embebidas, con placeholders reemplazados.
4. `Invoke-CortexProject -Type DotNetCli` crea un `.csproj` multi-target (net6/net7/net8) y proyectos PS 5+/pwsh 7+ comparten módulos sin duplicación.
5. Git operations validan estado limpio, abortan merges con conflictos y muestran resumen final (tabla por repo).
6. Descarga de artefactos funciona tanto con `gh` como con fallback HTTP + ZipFile.
7. Logging/resúmenes disponibles (JSON y texto) para cada operación y para multi-repo siguiendo el esquema (`RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `DurationMs`, `Details`, `Errors`).
8. Documentación actualizada (`Get-Help`, README, AGENTS, bitácora), plan Automation conforme al esquema y comando documentado para compilar a EXE.
9. Casos de prueba Pester/xUnit definidos (Iteración 2) y ejecutados (Iteración 3) con evidencia en la bitácora para PowerShell 5.1 y 7+.

[PLAN_AGENTE]
1. Leer AGENTS general, AGENTS de Cortex, Procedimiento e Informe.
2. Auditar `docs/Cortex.ps1` (RepoMaster actual) e identificar funciones a descomponer (scaffolding, Git, análisis, descargas, multi-repo).
3. Diseñar arquitectura en capas (Core, Services, CLI, Automation, Exporter) y definir contratos (parámetros, objetos de resultado).
4. Implementar funciones Core (sin `Read-Host`), luego las capas UI/Automation usando los contratos.
5. Integrar plantillas embebidas y validaciones (StrictMode, PSSA, Parser, prerequisitos).
6. Añadir menús `PromptForChoice`, Confirm-Action, Write-Progress y resúmenes multi-repo.
7. Incluir módulo de descargas/zip y exportador a EXE.
8. Documentar todo (README, AGENTS, ayuda interna), actualizar CSV, filemap, tabla de jerarquía y bitácora.
9. Probar en PowerShell 5.1 y 7+, ejecutar dotnet build/test generados, adjuntar logs.
10. Entregar `Cortex.ps1`, instrucciones de compilación y registro de pruebas en la bitácora.
