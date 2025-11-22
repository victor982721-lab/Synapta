# Documentación de `Analyze-Scripts`

## Visión general
`Analyze-Scripts.ps1` es un analizador concurrente de scripts PowerShell y Python que recorre recursivamente el árbol indicado y produce un reporte tabular y opcional en CSV/JSON. El flujo mantiene memoria contenida gracias a `ForEach-Object -Parallel` (ThrottleLimit 6) y genera resúmenes que incluyen conteos de funciones, comandos relevantes, intentos de corrección con PSScriptAnalyzer y la extracción de especificaciones detalladas por función.

## Características clave
- **Búsqueda dirigida**: sólo procesa `*.ps1`, `*.psm1` y `*.py`, saltando cualquier ruta que incluya `packages`.
- **Paralelismo y streaming**: cada archivo se analiza en un runspace aparte; el resultado se va escribiendo a consola y se acumula en una variable intermedia sin cargar todos los archivos en memoria.
- **Corrección automática**: si el parser de PowerShell falla, se intenta aplicar `Invoke-ScriptAnalyzer -Fix` y `Invoke-Formatter` antes de reintentar parsearlo; ese reintento sólo se ejecuta una vez por archivo.
- **Soporte Python**: invoca un helper Python ligero para generar el mismo resumen (funciones, comandos interesantes, errores de parseo) y se integra con `py`/`python` disponibles en el sistema.
- **Especificaciones de funciones**: consume `FunctionSpecHelper.psm1` para transformar cada `FunctionDefinitionAst` en una especificación rica (nombre, parámetros, comandos, bloques `try/catch`, `return`, AST limpio) y la expone como parte del objeto final (`FunctionSpecCount`, `FunctionSpecSummary`, `FunctionSpecs`).

## Uso
```powershell
.\Analyze-Scripts.ps1 -RootPath ..\Sandbox\Cortex -OutputPath Cortex-report.json
```

### Parámetros
- `-RootPath`: carpeta raíz con los scripts a analizar (por defecto, el directorio padre del script).
- `-OutputPath`: entrega el reporte final en CSV o JSON (`.json` produce JSON nativo, cualquier otra extensión cae en CSV).

El reporte de consola incluye `Script`, `FunctionCount`, `FunctionSpecCount`, `FunctionSpecSummary`, `Functions`, `Interesting`, `Commands` y `ParseErrors`. La salida JSON contiene además el array `FunctionSpecs` con la información generada por `FunctionSpecHelper.psm1`.

### Requisitos
- PowerShell 7+ (para `ForEach-Object -Parallel` e interoperabilidad moderna).
- `py` o `python` con Python 3 en PATH para analizar scripts `.py`.
- (Opcional) PSScriptAnalyzer con `Invoke-Formatter` si quieres que el fix automático sea efectivo; el script es tolerante cuando el módulo no está instalado.

## Integraciones futuras y ampliaciones
1. **Indexación persistente**: extender la exportación JSON para guardar un archivo `.spec.json` por script (como hacía `=Analizador_Funciones=`) y construir índices de funciones reutilizables con versiones del AST.
2. **Asistente CLI**: crear un wrapper PowerShell o CMD para lanzar el analizador desde catálogos existentes (`Sandbox`, `Core`) y disparar actualizaciones automáticas de specs.
3. **Reporte interactivo**: habilitar un paso que convierta `FunctionSpecs` en tablas Markdown o en un dashboard estático para revisiones de código.
4. **Evaluación automática de migraciones**: combinar el análisis de funciones con heurísticas que sugieran si un script se puede convertir a C# o PowerShell, basándose en la complejidad del AST y la cantidad de funciones.

## Consideraciones de mantenimiento
- `FunctionSpecHelper.psm1` debe mantenerse sincronizado con futuras versiones del AST y la política de documentación, porque `Remove-EmptyNodes` y `Extract-ASTTree` definen el esquema básico.
- Si se ejecuta en entornos con módulos restringidos, ajustar el bloque de importación (`Import-Module $using:helperModulePath`) para usar rutas completas o perfiles cargados.
- Las mejoras en `Try-FixPowerShellParse` pueden incluir filtros selectivos (por ejemplo, sólo corregir scripts bajo ciertos directorios) para evitar cambios de estilo indeseados en masa.
