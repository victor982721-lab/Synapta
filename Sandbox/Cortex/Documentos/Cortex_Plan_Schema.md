# Cortex Automation Plan Schema

> Versión 2025-11-20. Sincronizado con `src/Cortex.Automation.ps1` (AutoOption 7).

## 1. Propósito

Describe planes **no interactivos** para Cortex. Cada plan JSON/YAML define `runId`, parámetros globales y una lista de `jobs`. El ejecutor valida dependencias simples (`dependsOn`), ejecuta las operaciones soportadas y escribe log JSON (`logs/<RunId>.json`) con `RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `DurationMs`, `Details`, `Errors`.

## 2. Raíz del documento

```json
{
  "runId": "cortex-2025-11-20",
  "logPath": "C:/Logs/Cortex",
  "defaults": {
    "branch": "main",
    "remoteName": "origin",
    "projectType": "PS-CLI",
    "qualityGate": true
  },
  "jobs": [ ... ]
}
```

- `runId` (string, opcional): si no existe se genera `cortex-<timestamp>`.
- `logPath` (string, opcional): carpeta para el log consolidado. Default: `<repo>/logs`.
- `defaults` (objeto, opcional): valores heredados por los jobs.
- `jobs` (array, requerido): lista ordenada.

## 3. Jobs

```json
{
  "name": "ScaffoldDemo",
  "operation": "Scaffold",
  "repoPath": "C:/Repos/Neurologic",
  "parameters": {
    "ProjectName": "Demo",
    "ProjectType": "DotNet-CLI",
    "Output": "C:/Repos/Neurologic/Sandbox"
  },
  "dependsOn": [],
  "continueOnError": false
}
```

Campos por job:

| Campo         | Tipo     | Req | Descripción |
|---------------|----------|-----|-------------|
| `name`        | string   | Sí  | Identificador único del job. |
| `operation`   | string   | Sí  | Una de las operaciones de la sección 4. |
| `repoPath`    | string   | No  | Ruta base; si falta usa `pwd`. |
| `parameters`  | objeto   | Sí  | Parámetros específicos de la operación. |
| `dependsOn`   | string[] | No  | Jobs previos que deben terminar en Success. |
| `continueOnError` | bool | No  | Si `true`, continúa aunque falle (se registra Failed). |

## 4. Operaciones soportadas

| Operación  | Descripción | Parámetros requeridos |
|------------|-------------|-----------------------|
| `Scaffold` | Genera estructura Sandbox/Core con plantillas embebidas. | `ProjectName`, `ProjectType (PS-CLI|DotNet-CLI|DotNet-UI)`, `Output` |
| `Analyze`  | Parser AST, PSSA (si existe) y `dotnet build`. | `QualityGate` opcional (bool) |
| `SyncUp`   | `git add/commit/pull/push` al remoto. | `Branch`, `RemoteName`, `CommitMessage`, `IncludeUntracked` opcional |
| `SyncDown` | `git fetch` + `merge` de rama Codex (auto genera nombre si falta). | `Branch`, `RemoteName`, `CodexBranch` opcional |
| `Artifacts`| Descarga y extracción de artefactos (`gh` o HTTP+Zip). | `Destination`, (`RunIdOrTag` + `ArtifactName` + `Repository`) **o** `DownloadUrl` |
| `Export`   | Empaquetado con ps2exe (si está instalado). | `Output`, `Runtime` opcional |

## 5. Buenas prácticas

1. Versiona los planes en `Documentos/Planes/` y registra resultados en la bitácora.
2. Prefiere rutas absolutas; si usas relativas, asume el `repoPath` como base.
3. Valida el plan con `pwsh ./Entregable/Cortex.ps1 -AutoOption 7 -PlanPath <archivo> -LogPath <logs>` antes de integrarlo.
4. Mantén los nombres de job cortos y sin espacios para facilitar `dependsOn`.
5. Evita operaciones no soportadas en esta versión; amplía el schema solo cuando el script implemente la nueva operación.
