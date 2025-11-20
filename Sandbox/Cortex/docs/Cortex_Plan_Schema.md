# Cortex Plan Schema

Este documento define el formato de los planes de automatización que consume `Cortex.Automation`. El archivo puede ser JSON o YAML y describe una lista de trabajos a ejecutar en modo no interactivo.

## Estructura general

```json
{
  "runId": "2025-11-19-cortex-seed",
  "logPath": "C:/Logs/Cortex",
  "jobs": [
    {
      "name": "SeedSandbox",
      "repoPath": "C:/Users/.../Neurologic",
      "operation": "Scaffold",
      "parameters": {
        "ProjectName": "DemoProject",
        "ProjectType": "DotNet-CLI",
        "Output": "C:/Users/.../Neurologic/Sandbox"
      }
    },
    {
      "name": "SyncUp",
      "repoPath": "C:/Users/.../Neurologic",
      "operation": "SyncUp",
      "parameters": {
        "Branch": "main",
        "RemoteName": "origin",
        "CommitMessage": "feat: seed demo"
      }
    }
  ]
}
```

## Campos obligatorios

- `runId` (string): identificador único de la ejecución.
- `jobs` (array): cada elemento define una operación.
- `jobs[].name`: etiqueta descriptiva.
- `jobs[].repoPath`: ruta absoluta del repo objetivo.
- `jobs[].operation`: uno de `Scaffold`, `Analyze`, `Build`, `SyncUp`, `SyncDown`, `Artifacts`, `Plan` (para planes anidados) u operaciones futuras.
- `jobs[].parameters`: objeto con los parámetros específicos de la operación.

## Campos opcionales

- `logPath`: carpeta donde se escribirán los logs (por defecto `logs/`).
- `jobs[].continueOnError` (bool, default false): si es `true`, la ejecución continúa aunque la operación falle (registrando el error).
- `jobs[].planPath`: cuando `operation = "Plan"`, ruta a otro archivo de plan.

## Validaciones

1. `jobs` no puede estar vacío.
2. `operation` debe mapearse a una función Core existente.
3. `ProjectType` admite solo `PS-CLI`, `DotNet-CLI`, `DotNet-UI`.
4. `parameters` debe contener los campos necesarios para cada operación:
   - `Scaffold`: `ProjectName`, `ProjectType`, `Output`.
   - `Analyze`: `Paths`, `QualityGate` (bool).
   - `SyncUp`/`SyncDown`: `Branch`, `RemoteName`, `CommitMessage` (solo SyncUp) y banderas de confirmación.
   - `Artifacts`: `RunId`, `ArtifactName`, `Destination`.
5. Las rutas deben existir salvo que la operación sea `Scaffold` (que crea carpetas).

## Ejemplo YAML

```yaml
runId: cortex-mr-01
jobs:
  - name: scaffold-demo
    repoPath: C:/Dev/Neurologic
    operation: Scaffold
    parameters:
      ProjectName: DemoCLI
      ProjectType: PS-CLI
      Output: C:/Dev/Neurologic/Sandbox
  - name: syncup-demo
    repoPath: C:/Dev/Neurologic/Sandbox/DemoCLI
    operation: SyncUp
    parameters:
      Branch: main
      RemoteName: origin
      CommitMessage: "chore: seed demo"
```

Mantén este esquema actualizado cuando se añadan nuevas operaciones o parámetros para que los planes Automation sigan siendo autodescriptivos.
