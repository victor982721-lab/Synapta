# Cortex

Cortex ahora se entrega como un orquestador en `Entregable/Cortex.ps1` que carga capas modulares ubicadas en `src/`. El objetivo sigue siendo ofrecer un único `.ps1` ejecutable, con separación clara de responsabilidades y compatibilidad Windows PowerShell 5.1+ / pwsh 7+ en Windows 7/10/11.

## Arquitectura rápida

<<<<<<< HEAD
- `Entregable/Cortex.ps1`: punto de entrada con `Set-StrictMode`, parámetros para modo no interactivo (`-AutoOption 1..7`) y menú `PromptForChoice` cuando no se especifica `-AutoOption`.
=======
- `Entregable/Cortex.ps1`: punto de entrada con `Set-StrictMode`, parámetros para modo no interactivo (`-AutoOption 1..7`), switch `-Interactive` y menú `PromptForChoice`.
>>>>>>> origin/codex_2025-11-21
- `src/Cortex.Common.ps1`: helpers compartidos (validación de plataforma, invocación de comandos, logging y plantillas embebidas).
- `src/Cortex.Core.Scaffolding.ps1`: genera estructuras Sandbox/Core con plantillas embebidas, csproj multi-target (`net8/net7/net6`) y scripts base.
- `src/Cortex.Core.GitOps.ps1`: operaciones `SyncUp`/`SyncDown`, validando rutas y soportando remotos configurables.
- `src/Cortex.Core.Analysis.ps1`: Parser AST, PSSA (si está instalado) y `dotnet build`; admite `-QualityGate`.
- `src/Cortex.Core.Artifacts.ps1`: descarga de artefactos vía `gh run download` o fallback HTTP+ZipFile.
- `src/Cortex.Automation.ps1`: ejecutor de planes JSON/YAML alineado con `Documentos/Cortex_Plan_Schema.md`.
<<<<<<< HEAD
- `src/Cortex.CLI.ps1`: menú interactivo basado en `PromptForChoice` que orquesta las capas Core.
- `src/Cortex.Exporter.ps1`: envoltorio para ps2exe y orientación de empaquetado.
=======
- `src/Cortex.CLI.ps1`: menú interactivo basado en `PromptForChoice` que orquesta las capas Core, incluyendo exportador con `-Runtime` configurable.
- `src/Cortex.Exporter.ps1`: envoltorio para ps2exe y orientación de empaquetado.
- `Scripts/Cortex.Wizard.ps1`: envoltorio dedicado al modo interactivo que reusa el orquestador con los mismos parámetros clave.
>>>>>>> origin/codex_2025-11-21

## Uso rápido

```powershell
# Ayuda
pwsh ./Entregable/Cortex.ps1 -ShowHelp

# AutoOption 1: scaffolding
pwsh ./Entregable/Cortex.ps1 -AutoOption 1 -RepoPath C:\Repos -ProjectName Demo -ProjectType DotNet-CLI

# AutoOption 4: SyncUp
pwsh ./Entregable/Cortex.ps1 -AutoOption 4 -RepoPath C:\Repos\Demo -Branch main -RemoteName origin -CommitMessage "feat: sync"

<<<<<<< HEAD
# AutoOption 7: plan JSON/YAML
pwsh ./Entregable/Cortex.ps1 -AutoOption 7 -PlanPath C:\Repos\plan.json -LogPath C:\Repos\logs
```

El modo interactivo se ejecuta llamando `pwsh ./Entregable/Cortex.ps1` sin parámetros; el menú permite elegir las mismas operaciones.
=======
# AutoOption 6: artefactos
pwsh ./Entregable/Cortex.ps1 -AutoOption 6 -ArtifactName build.zip -RunIdOrTag 123456 -ArtifactRepository org/repo -ArtifactDestination C:\Repos\Demo\artifacts

# AutoOption 7: plan JSON/YAML
pwsh ./Entregable/Cortex.ps1 -AutoOption 7 -PlanPath C:\Repos\plan.json -LogPath C:\Repos\logs

# Wizard interactivo explícito
pwsh ./Entregable/Cortex.ps1 -Interactive -RepoPath C:\Repos\Demo
# o bien
pwsh ./Scripts/Cortex.Wizard.ps1 -RepoPath C:\Repos\Demo
```

El modo interactivo se ejecuta llamando `pwsh ./Entregable/Cortex.ps1` sin parámetros o usando el wrapper `Scripts/Cortex.Wizard.ps1`; el menú permite elegir las mismas operaciones.
>>>>>>> origin/codex_2025-11-21

## Compatibilidad y dependencias

- Requiere Windows (valida antes de ejecutar). Compatible con Windows PowerShell 5.1 y pwsh 7+.
- Dependencias externas usadas cuando están disponibles: `git`, `dotnet`, `gh`, `ps2exe`, `PSScriptAnalyzer`.
- Proyectos .NET generados mantienen multi-target (`net8.0;net7.0;net6.0`).

## Logging

Todas las operaciones pueden escribir en `logs/<RunId>.json` con el esquema: `RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `DurationMs`, `Details`, `Errors`.
