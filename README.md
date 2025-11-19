<<<<<<< HEAD
# Neurologic

Repositorio personal para el ecosistema **Neurologic / Synapta**:
automatización, motores internos, indexadores y proyectos de escritorio
(WPF/.NET), orientados a uso propio.

Este README no está pensado como documentación pública, sino como índice
operativo para los documentos de reglas internas.

---

## Documentos normativos

- **Política cultural y de calidad – Ecosistema Neurologic**  
  Estándar global de cultura, calidad y criterios mínimos de aceptación.
  Aplica a personas y agentes (humanos y IA).

- **AGENTS – Neurologic (General para Codex)**  
  Reglas específicas para el agente **Codex** al trabajar en este
  repositorio (multi-framework .NET, organización de módulos, reutilización
  de motores, etc.).

- **AGENTS específicos de proyecto**  
  Cada subproyecto puede definir sus propias reglas adicionales:
  - `Neurologic/Ws_Insights/AGENTS.md`
  - (futuros proyectos irán añadiendo sus propios `AGENTS.md`)

Los AGENTS específicos solo pueden **endurecer** el estándar cultural y
técnico global, nunca rebajarlo.

---

## Tipos de agentes y alcance

En este repositorio se usan varios “agentes” sobre el mismo código:

- **Codex en CLI (GPT-5 Codex)**  
  - Agente de generación automática de código y proyectos.  
  - Debe obedecer:
    - Política cultural y de calidad – Ecosistema Neurologic.
    - AGENTS – Neurologic (General para Codex).
    - AGENTS específicos del subproyecto donde trabaje.

- **Codex / asistentes de código en la web**  
  - Mismo rol que Codex en CLI, pero ejecutado desde la plataforma web.  
  - Mismas reglas que el punto anterior.

- **ChatGPT (web o CLI)**  
  - Agente conversacional y de apoyo técnico (análisis, explicación,
    diseño, refactors guiados, etc.).  
  - Debe respetar la **Política cultural y de calidad**, pero no está obligado
    a seguir al pie de la letra las reglas operativas pensadas
    específicamente para Codex (por ejemplo, multi-target automático al
    crear proyectos, reglas de creación de archivos en lote, etc.).  
  - Cuando ChatGPT actúe como “Codex” (generando código A→Z), se
    recomienda alinearse voluntariamente con los AGENTS de Codex para
    mantener coherencia.

---

## Prioridad de reglas

Cuando haya dudas sobre qué seguir, el orden es:

1. **Política cultural y de calidad – Ecosistema Neurologic.**
2. **AGENTS específicos del proyecto** (si existen).
3. **AGENTS – Neurologic (General para Codex)** para trabajos de generación
   de código automatizada.
4. Criterio puntual en esta sesión (instrucciones ad hoc que no violen los
   puntos anteriores).

---
=======
# Ws_Insights

Motor de búsqueda de archivos con interfaz WPF optimizada para análisis masivo en Windows. La solución combina un *front-end* rico en controles (filtrado por extensiones, métricas en vivo, exportación CSV/Markdown) con un paquete modular `Search.Engine` pensado para indexación eficiente, cachés y pipelines de búsqueda paralelos.

> **Estado actual:** la UI está funcional y todos los módulos del motor tienen contratos definidos, pero varias clases (`SearchPipeline`, `IndexManager`, `FileEnumerator`, etc.) contienen implementaciones “stub”. El README sirve como guía para instrumentar y optimizar cada capa.

## Arquitectura rápida

- `MainWindow.xaml(+.cs)` – Panel maestro: define bindings para filtros (regex, palabra completa, límites de tamaño, subcarpetas, extensiones) y controla el ciclo *Start → Pause/Resume → Stop* enviando `SearchOptions` al motor. Expone `Progress<SearchProgress>` para alimentar métricas en vivo y tiene exportadores CSV/Markdown.
- `File_Extensions` – Administrador de categorías de extensiones (checkbox tri-state) que produce listas normalizadas para el motor.
- `Models` – POCOs (`FileMatch`, `ExtensionOption`, etc.) usados tanto por la UI como por la capa de búsqueda.
- `Search.Engine`
  - `Core` – Tipos base: `SearchOptions`, `SearchContext`, `SearchPipeline`, `SearchResult`, helpers de normalización y flags compactos (`SearchOptionFlags`). Aquí se orquesta la lógica de alto rendimiento (lectura, tokenización, ranking) y se exponen `PauseToken`s para cooperación con la UI.
  - `Cache` – Implementaciones básicas de `LruCache`, `HotFileCache`, `QueryCache` y utilidades de buffer pooling (`ArrayPool<T>`).
  - `IO` – Lectura de disco (`FileEnumerator`, `MemoryMappedLoader`, `AsyncDiskScheduler`, `FileChangeDetector`).
  - `Index` – Infraestructura para un índice persistente segmentado (Bloom filters, metadata column stores, `IndexManager`).
  - `Processing` – Pipelines de análisis de texto (tokenizer SIMD, normalización, motores regex/Hyperscan).
  - `Public` – Fachadas de alto nivel (`SearchEngine`, `IndexService`, `Diagnostics`, `Analyzer`).
- `Reporting` – Exportadores a CSV (y Markdown en `MainWindow`).
- `Themes` – Diccionarios claros/oscuro con soporte para conmutación en caliente.
- `Utilities` – Infraestructura de `PauseToken` cooperativo para *throttling* sin cancelar el trabajo.

## Requisitos

- Windows 11/10 de 64 bits (el `RuntimeIdentifier` es `win-x64`).
- .NET 8 SDK (LTS) con workloads de escritorio (`Microsoft.NET.Sdk.WindowsDesktop`).
- VS 2022 17.8+ o `dotnet` CLI 8.0 para compilar WPF/AOT.
- El subdirectorio `Search.Engine` contiene prototipos que dependen de APIs de .NET 9; por ahora el proyecto net8 los omite del build (se mantienen como referencia técnica).

## Primeros pasos

```pwsh
cd Ws_Insights
dotnet restore
dotnet build -c Release
```

- El proyecto ya incluye `PublishSingleFile`, `SelfContained`, `PublishTrimmed` y `PublishAot`. Si tu SDK no soporta AOT, puedes desactivar temporalmente `<PublishAot>true</PublishAot>` o usar `dotnet publish /p:PublishAot=false`.
- Todos los artefactos de compilación (`bin/`, `obj/`, `.vs/`) están ignorados en `Ws_Insights/.gitignore`.

### Ejecutar en modo depuración (mayor iteración)

```pwsh
dotnet run --project Ws_Insights.csproj
```

> Cuando se ejecute por primera vez, selecciona la carpeta raíz, ajusta las extensiones y presiona **Iniciar búsqueda**. Mientras el motor esté incompleto, la UI solo mostrará logs, pero puedes validar bindings, exportaciones y flujo de pausa/reanudar.

### Publicar binario optimizado

```pwsh
dotnet publish Ws_Insights.csproj `
  -c Release `
  -r win-x64 `
  /p:PublishSingleFile=true `
  /p:PublishTrimmed=true `
  /p:PublishAot=true `
  /p:SelfContained=true `
  -o publish
```

El resultado es un ejecutable único (`Ws_Insights.exe`) listo para distribución interna. Esta configuración:

- Vincula el runtime (no requiere .NET instalado).
- Recorta ensamblados no usados con `TrimMode=partial`.
- Genera código nativo (AOT) para reducir *startup* y mejorar latencias de UI.
- Mantiene compatibilidad con WPF limitando el trimming agresivo.

## Guía de optimización sugerida

1. **Enumeración & IO**
   - Sustituir `FileEnumerator` por un scanner basado en `Directory.EnumerateFiles` y `FileSystemEnumerable<T>` con filtros por extensión, tamaño y atributos en el propio enumerador.
   - Implementar `AsyncDiskScheduler` con colas por prioridad (p. ej. `System.Threading.Channels`) para evitar sobresaturar IO cuando `MaxDegreeOfParallelism` sea alto.
   - Usar `MemoryMappedFile` real en `MemoryMappedLoader` y liberar vistas grandes via `SafeMemoryMappedViewHandles`.

2. **Indexado**
   - `IndexManager` debería mantener metadatos en `SegmentMetadata` y Bloom filters (`BloomFilterStore`) para minimizar lecturas frías. Mantén un *write-ahead log* simple para reconstrucción.
   - Aprovecha `FileIdMap` para mapear rutas → IDs enteros; esto permite bitsets compactos y mejor cache locality.

3. **Procesamiento**
   - `TokenizerSIMD`/`SpanHelpers` están preparados para utilizar `System.Runtime.Intrinsics`. Implementa detección de AVX2/AVX512 y fallback escalar.
   - `HyperscanEngine` sirve como *interop point*; hasta entonces, `RegexEngine` puede usar `RegexOptions.Compiled` con `RegexGenerator`.

4. **Caches**
   - Ajusta capacidad de `HotFileCache` usando datos reales (p. ej. 256 MB). Considera usar `Microsoft.Extensions.Caching.Memory` con `MemoryCacheEntryOptions.Priority`.
   - `QueryCache` debería invalidarse cuando `SearchOptionFlags` cambien o al detectar modificaciones en disco (`FileChangeDetector`).

5. **Telemetría & UI**
   - Conecta `Diagnostics.GetMetrics` al panel lateral para mostrar *cache hit ratio*, lecturas/seg, tamaño del índice, etc.
   - `PauseTokenSource` ya soporta throttling cooperativo; respeta `PauseToken.WaitIfPausedAsync` en cada fase intensiva (enumeración, lectura y matching) para evitar congelar la UI.

## Flujo funcional de la UI

1. **Selección de carpeta** y filtros (extensiones, sensibilidad, regex, límites de tamaño).
2. `OnStartSearch` construye `SearchOptions` y lanza `_engine.SearchAsync(...)` pasando:
   - `IProgress<SearchProgress>` con métricas: `FilesScanned`, `Matches`, `Errors`, `FilesPerSecond`, etc.
   - `Func<FileMatch, Task>` para insertar resultados en `ObservableCollection<FileMatch>` (UI thread vía `Dispatcher`).
3. Botones de **Pausar/Reanudar** y **Detener** controlan `PauseTokenSource` y `CancellationTokenSource`.
4. Exportación:
   - CSV (`Reporting/Csv.Exporter.cs`) – compatible con Excel; utiliza `UTF8Encoding(true)` y escaping RFC4180.
   - Markdown – generado al pausar para permitir audit logs y *sharing* rápido.

## Próximos pasos recomendados

1. Completar `SearchEngine.SearchAsync` + `SearchPipeline.ExecuteAsync` integrando enumerador, cachés e index manager.
2. Implementar `FileEnumerator` con filtros reales y soporte incremental (`FileChangeDetector`).
3. Conectar `IndexService` a una base en disco (JSON lineal, LiteDB o binario propio) para preservar segmentos entre ejecuciones.
4. Añadir pruebas unitarias/microbenchmarks (`BenchmarkDotNet`) para tokenizer, Bloom filters y caches.
5. Integrar CI (GitHub Actions) que ejecute `dotnet format`, `dotnet test`, `dotnet publish` y suba artefactos comprimidos.

Con esta guía puedes iterar en la plataforma web con Codex sabiendo qué piezas tocar para maximizar eficiencia, tiempos de respuesta y footprint del ejecutable.
>>>>>>> origin/codex_2025-11-19
