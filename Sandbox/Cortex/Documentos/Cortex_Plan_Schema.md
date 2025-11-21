# Cortex Automation Plan Schema

> Versión 2025-11-20. Mantén este documento sincronizado con los cambios de `Cortex.Automation`. Peso actual ≈ 7.4 KB (apto para copiado en ChatGPT Web).

## 1. Propósito

Los planes definen ejecuciones **no interactivas** de Cortex. Cada plan es un archivo JSON o YAML que describe el `runId`, las opciones globales y una secuencia de `jobs`. Cortex valida el archivo antes de ejecutar y genera un log estructurado (`logs/<RunId>.json`) con el resultado de cada job.

## 2. Estructura raíz

```json
{
  "runId": "cortex-2025-11-20-seed",
  "description": "Sembrar Sandbox y sincronizar ramas Codex",
  "logPath": "C:/Logs/Cortex",
  "defaults": {
    "branch": "main",
    "remoteName": "origin",
    "qualityGate": true,
    "projectType": "DotNet-CLI",
    "continueOnError": false
  },
  "jobs": [ ... ]
}
```

| Campo          | Tipo      | Requerido | Descripción                                                                                  |
|----------------|-----------|-----------|----------------------------------------------------------------------------------------------|
| `runId`        | string    | Sí        | Identificador único del plan (sin espacios).                                                 |
| `description`  | string    | No        | Comentario corto visible en la bitácora/log.                                                 |
| `logPath`      | string    | No        | Carpeta donde se escribe el log JSON. Defecto: `<repo>/logs`.                                |
| `defaults`     | objeto    | No        | Valores heredados por cada job (branch, remote, tipo de proyecto, etc.).                     |
| `jobs`         | array     | Sí        | Lista ordenada de trabajos. Se detiene al primer error salvo que `continueOnError=true`.     |

## 3. Definición de `jobs`

Cada job requiere al menos `name`, `operation`, `repoPath` y `parameters`. Además puede incluir `dependsOn`, `continueOnError`, `retry`, `timeoutSeconds` y `planPath` (para subplanes).

```json
{
  "name": "ScaffoldDemo",
  "operation": "Scaffold",
  "repoPath": "C:/Users/Victor/Neurologic",
  "parameters": {
    "ProjectName": "DemoCLI",
    "ProjectType": "PS-CLI",
    "Output": "C:/Users/Victor/Neurologic/Sandbox"
  },
  "dependsOn": [],
  "continueOnError": false,
  "retry": 0,
  "timeoutSeconds": 1800
}
```

### Campos de job

| Campo               | Tipo      | Requerido | Notas                                                                                                                                |
|---------------------|-----------|-----------|--------------------------------------------------------------------------------------------------------------------------------------|
| `name`              | string    | Sí        | Único por plan. Usado en logs y en `dependsOn`.                                                                                      |
| `operation`         | string    | Sí        | Una de las operaciones listadas en la tabla de la sección 4.                                                                         |
| `repoPath`          | string    | Sí        | Ruta absoluta del repositorio sobre el que se opera.                                                                                 |
| `parameters`        | objeto    | Sí        | Parámetros específicos según la operación.                                                                                           |
| `dependsOn`         | string[]  | No        | Jobs que deben terminar en `Success` antes de ejecutar este. Evita ciclos.                                                           |
| `continueOnError`   | bool      | No        | Si `true`, el plan continúa aunque este job falle (igual registra error). Por defecto hereda de `defaults` (o `false`).               |
| `retry`             | int       | No        | Reintentos (máx 3) cuando el job falla por error transitorio.                                                                        |
| `timeoutSeconds`    | int       | No        | Máx duración del job. 0 = sin límite.                                                                                                |
| `planPath`          | string    | Solo `operation = "Plan"` | Ruta a un plan secundario que se ejecuta en su propio contexto; `repoPath` puede omitirse en ese caso.                        |

## 4. Operaciones disponibles

| Operación   | Descripción                                                                                              | Parámetros requeridos                                                                                                                                        |
|-------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Scaffold`  | Genera estructura Sandbox/Core con plantillas completas.                                                 | `ProjectName`, `ProjectType (PS-CLI|DotNet-CLI|DotNet-UI)`, `Output`, opcional `TemplatesOverride`.                                                          |
| `Analyze`   | Ejecuta Parser AST, PSSA y `dotnet build/test` (quality gate).                                           | `Paths` (array de rutas), `QualityGate` (bool).                                                                                                              |
| `Build`     | Construye proyectos .NET usando `dotnet build` / `dotnet publish`.                                       | `SolutionOrProjectPath`, `Configuration` (`Debug`/`Release`), opcional `PublishProfile`.                                                                     |
| `SyncUp`    | Commit + pull + push hacia origin (cmdlet `Invoke-SyncUp`).                                              | `Branch`, `RemoteName`, `CommitMessage`, opcional `IncludeUntracked` (bool).                                                                                |
| `SyncDown`  | Fusiona la rama Codex_Y-m-d (±1 día) en la rama principal, con confirmación automática.                  | `Branch`, `RemoteName`, opcional `AutoConfirm` (bool).                                                                                                       |
| `Artifacts` | Descarga y extrae artifacts de GitHub Actions.                                                           | `RunIdOrTag`, `ArtifactName`, `Destination`, opcional `ExtractionMode` (`Replace`/`Merge`).                                                                  |
| `Plan`      | Ejecuta un subplan (otra estructura JSON/YAML).                                                          | `planPath`, opcional `inheritDefaults` (bool).                                                                                                               |
| `Doctor`    | Verifica la estructura mínima (`Invoke-Doctor`).                                                         | `ProjectPaths` (array) o `RepoPath` + `SearchPattern`.                                                                                                       |
| `Custom`    | Lanza un script PowerShell del repositorio (para tareas específicas).                                    | `ScriptPath`, `Arguments` (array), `WorkingDirectory`.                                                                                                       |

> Añade nuevas operaciones actualizando esta tabla y la lógica en `Cortex.Automation`. Toda operación debe retornar `Success`, `Failed` o `Skipped`.

## 5. Parámetros detallados

### 5.1 Scaffold
- `ProjectName`: string, sin espacios.
- `ProjectType`: `PS-CLI`, `DotNet-CLI` o `DotNet-UI`.
- `Output`: ruta donde se creará la carpeta (`Sandbox/Nombre`).
- `TemplatesOverride`: opcional, indica carpeta personalizada de plantillas.
- `SeedDocuments`: bool opcional (default `true`) para poblar AGENTS/README/solicitud con placeholders inteligentes.

### 5.2 Analyze
- `Paths`: array de rutas (archivos o carpetas).
- `QualityGate`: bool. Si `true`, cualquier error detiene el plan.
- `SkipPSSA`: bool opcional.
- `DotNetConfigurations`: array (`["Debug","Release"]` por defecto).

### 5.3 SyncUp / SyncDown
- `Branch`: se puede omitir si existe `defaults.branch`.
- `RemoteName`: idem (`origin` por defecto).
- `CommitMessage`: solo para `SyncUp`.
- `AutoConfirm`: si `true`, no pide confirmación interactiva.

### 5.4 Artifacts
- `RunIdOrTag`: ID numérico del workflow o etiqueta (por ejemplo `latest-success`).
- `ArtifactName`: coincide con el nombre publicado en GitHub Actions.
- `Destination`: ruta de extracción.
- `ExtractionMode`: `Replace` (default) o `Merge`.

### 5.5 Plan
- `planPath`: ruta absoluta o relativa (respecto al archivo actual).
- `inheritDefaults`: si `true`, los `defaults` del plan padre se combinan con los del subplan (aplica solo a campos no definidos).

### 5.6 Custom
- `ScriptPath`: archivo `.ps1` relativo al repositorio.
- `Arguments`: arreglo de strings (pasados tal cual).
- `WorkingDirectory`: opcional; si se omite usa `repoPath`.

## 6. Validaciones

1. `runId` debe ser único por día; se recomienda `cortex-YYYYMMDD-Nombre`.
2. `jobs[].name` único dentro del plan; `dependsOn` solo puede referenciar nombres existentes.
3. No se permite un ciclo en `dependsOn`. Cortex hará un topological sort.
4. Cada `operation` requiere los parámetros establecidos en la sección 5; faltantes generan error.
5. `ProjectType` admite únicamente `PS-CLI`, `DotNet-CLI`, `DotNet-UI`.
6. Las rutas deben existir salvo que el propio job las cree (`Scaffold`, `Artifacts` con `Replace`).
7. Tamaño máximo recomendado del plan: 200 KB. Cada archivo debe ser UTF-8 sin BOM.
8. `retry` máximo 3. `timeoutSeconds` máximo 7200.
9. Los subplanes (`Plan`) se validan recursivamente; si un subplan falla se marca como `Failed` y su job padre también.

## 7. Ejemplo completo (JSON)

```json
{
  "runId": "cortex-2025-11-20-main",
  "description": "Crear sandbox y subir cambios",
  "defaults": {
    "branch": "main",
    "remoteName": "origin",
    "qualityGate": true,
    "continueOnError": false
  },
  "jobs": [
    {
      "name": "ScaffoldCortexDemo",
      "operation": "Scaffold",
      "repoPath": "C:/Users/Victor/Neurologic",
      "parameters": {
        "ProjectName": "DemoCLI",
        "ProjectType": "DotNet-CLI",
        "Output": "C:/Users/Victor/Neurologic/Sandbox"
      }
    },
    {
      "name": "AnalyzeDemo",
      "operation": "Analyze",
      "repoPath": "C:/Users/Victor/Neurologic/Sandbox/DemoCLI",
      "parameters": {
        "Paths": [
          "C:/Users/Victor/Neurologic/Sandbox/DemoCLI/src",
          "C:/Users/Victor/Neurologic/Sandbox/DemoCLI/Scripts"
        ],
        "QualityGate": true
      },
      "dependsOn": ["ScaffoldCortexDemo"]
    },
    {
      "name": "SyncUpDemo",
      "operation": "SyncUp",
      "repoPath": "C:/Users/Victor/Neurologic/Sandbox/DemoCLI",
      "parameters": {
        "Branch": "main",
        "RemoteName": "origin",
        "CommitMessage": "feat: seed DemoCLI desde plan automation"
      },
      "dependsOn": ["AnalyzeDemo"]
    }
  ]
}
```

## 8. Ejemplo YAML con subplan

```yaml
runId: cortex-handoff-02
logPath: C:/Logs/Cortex
defaults:
  branch: develop
  remoteName: origin
  projectType: PS-CLI
jobs:
  - name: scaffold-ps-cli
    operation: Scaffold
    repoPath: C:/Neurologic
    parameters:
      ProjectName: DemoPS
      ProjectType: PS-CLI
      Output: C:/Neurologic/Sandbox

  - name: subplan-operaciones
    operation: Plan
    repoPath: C:/Neurologic
    parameters:
      planPath: C:/Neurologic/Sandbox/Cortex/Documentos/Subplanes/operaciones.yml
      inheritDefaults: true
    dependsOn:
      - scaffold-ps-cli
```

## 9. Buenas prácticas

1. Versiona los planes en `Neurologic/Sandbox/Cortex/Documentos/Planes/`.
2. Prefiere rutas absolutas para evitar ambigüedades.
3. Define `runId` con prefijo del proyecto y fecha (ej. `cortex-2025-11-20-ws_insights`).
4. Usa `Plan` para agrupar jobs repetitivos (por ejemplo, ejecutar el mismo flujo en varios repos).
5. Documenta cada plan en la bitácora (`docs/bitacora.md`) indicando RunId y resultado.
6. No mezcles entornos sin declararlo (ej. no uses Sandbox y Core en el mismo job sin advertencia).
7. Antes de publicar un plan nuevo, valida con `Cortex.Automation -ValidatePlan <archivo>` (modo dry-run).

Con este esquema endurecido, cualquier agente o pipeline puede reproducir flujos complejos sin intervención manual y con logs consistentes. Asegúrate de mantenerlo actualizado cada vez que Cortex incorpore nuevas operaciones o parámetros.
