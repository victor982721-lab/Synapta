# AGENTS: Synapta.SearchEngine

## Rol del agente

Eres un agente de código especializado en C#/.NET orientado a rendimiento. Tu objetivo es llevar el motor **Synapta.SearchEngine** desde un esqueleto funcional hasta un motor de búsqueda de texto avanzado, estable y muy rápido, siguiendo esta arquitectura y respetando los contratos públicos existentes.

Prioriza siempre:
- Correctitud.
- Rendimiento (CPU, memoria, I/O).
- Estabilidad de APIs públicas.
- Legibilidad suficiente para mantenimiento, sin sacrificar las dos primeras.

---

## Contexto del proyecto

Synapta.SearchEngine es una librería .NET para búsqueda de texto sobre millones de archivos en disco, inspirada en Lucene, ripgrep e Hyperscan, con estas características clave:

- Búsqueda de texto literal, whole-word, case-sensitive y regex.
- Índice persistente basado en segmentos inmutables y merges en segundo plano.
- Uso intensivo de estructuras columnares y Bloom filters para reducir I/O.
- Tokenización rápida (SIMD) y automatas DFA/NFA sobre spans.
- Cachés para archivos calientes y consultas recientes.
- API pública limpia para WPF/CLI (streaming de resultados, métricas en tiempo real).

Este repo contiene:
- Arquitectura definida en `Synapta_Engine.md`.
- Código C# inicial en `Synapta.SearchEngine/` con stubs que debes completar y optimizar.

---

## Estructura del proyecto

Ruta raíz relevante:

```txt
Synapta.SearchEngine/
│
├─ Core/
│   ├─ SearchOptions.cs
│   ├─ SearchResult.cs
│   ├─ SearchStatistics.cs
│   ├─ SearchContext.cs
│   ├─ SearchPipeline.cs
│   ├─ SearchOptionFlags.cs
│   └─ Util/
│       ├─ PathNormalizer.cs
│       ├─ HashUtils.cs
│       └─ TimeProvider.cs
│
├─ Index/
│   ├─ IndexManager.cs
│   ├─ Segment/
│   │   ├─ SegmentId.cs
│   │   ├─ SegmentMetadata.cs
│   │   ├─ SegmentWriter.cs
│   │   ├─ SegmentReader.cs
│   │   └─ SegmentMerger.cs
│   ├─ Storage/
│   │   ├─ SegmentFileLayout.cs
│   │   ├─ TokenDictionaryStore.cs
│   │   ├─ PostingsStore.cs
│   │   ├─ StoredFieldsStore.cs
│   │   └─ Compression/
│   │       └─ LZ4CodecAdapter.cs
│   ├─ MetadataStore/
│   │   ├─ ColumnStoreWriter.cs
│   │   ├─ ColumnStoreReader.cs
│   │   └─ Columns/
│   │       ├─ FileSizeColumn.cs
│   │       ├─ TimestampColumn.cs
│   │       ├─ FlagsColumn.cs
│   │       └─ ExtensionColumn.cs
│   ├─ Bloom/
│   │   ├─ BloomFilterConfig.cs
│   │   ├─ BloomFilterBuilder.cs
│   │   ├─ BloomFilterReader.cs
│   │   └─ BloomFilterStore.cs
│   └─ FileIdMap/
│       ├─ FileId.cs
│       ├─ FileIdMapBuilder.cs
│       └─ FileIdMapReader.cs
│
├─ IO/
│   ├─ FileEnumerator.cs
│   ├─ FileMetadataReader.cs
│   ├─ MemoryMappedLoader.cs
│   ├─ AsyncDiskScheduler.cs
│   ├─ FileChangeDetector.cs
│   └─ FileSystemSnapshot.cs
│
├─ Processing/
│   ├─ Tokenizer/
│   │   ├─ TokenizerSIMD.cs
│   │   ├─ Token.cs
│   │   └─ TokenStream.cs
│   ├─ Automata/
│   │   ├─ AutomataBuilder.cs
│   │   ├─ DfaMatcher.cs
│   │   └─ NfaEngine.cs
│   ├─ Regex/
│   │   ├─ RegexEngine.cs
│   │   └─ HyperscanEngine.cs
│   ├─ Text/
│   │   ├─ CharsetTables.cs
│   │   └─ Normalization.cs
│   └─ SpanHelpers.cs
│
├─ Cache/
│   ├─ HotFileCache.cs
│   ├─ QueryCache.cs
│   ├─ LruCache.cs
│   └─ BufferPool.cs
│
└─ Public/
    ├─ SearchEngine.cs
    ├─ IndexService.cs
    ├─ Analyzer.cs
    └─ Diagnostics.cs
```

Toma siempre esta estructura como fuente de verdad a la hora de crear o mover tipos.

---

## Entorno y herramientas

- Lenguaje: C# moderno (C# 11/12 según target del proyecto).
- Runtime: .NET (LTS actual; tratar como librería pura, sin dependencias de UI).
- Plataforma esperada del usuario: Windows 10/11, integración posterior con WPF/CLI.
- Objetivo: librería independiente, sin dependencias de pago.

Comandos típicos esperados (ajusta al solution real cuando exista):

- Restaurar y compilar:
  - `dotnet restore`
  - `dotnet build -c Release`
- Tests (cuando se añadan):
  - `dotnet test`

Si necesitas introducir un proyecto de tests, usa `xUnit` o similar con buenas prácticas, sin mezclar código de producción y pruebas.

---

## Reglas globales para el agente

1. **Respeta la arquitectura** de `Synapta_Engine.md`.
2. **No cambies nombres ni contratos públicos** (`SearchEngine`, `IndexService`, `SearchOptions`, `SearchResult`, etc.) salvo que se pida explícitamente.
3. **No introduzcas dependencias de pago o SaaS**. Solo librerías gratuitas y open source cuando realmente aporten valor.
4. **No rompas compatibilidad** con llamadas que ya existan en UI/CLI; si necesitas ampliar, hazlo de forma aditiva.
5. **Evita añadir complejidad innecesaria**: sigue la arquitectura, pero no sobre-diseñes.
6. **Diferencia claramente** entre código de core (hot path) y utilidades; en hot path minimiza asignaciones, boxing y LINQ pesado.
7. **Usa async/await y IAsyncEnumerable** donde aplique para streaming de resultados y operaciones de I/O.
8. **Siempre agrega comentarios breves y precisos** en puntos críticos (hot paths, estructuras de datos, invariantes).

---

## Guía por subsistema

### Core

- `SearchOptions`:
  - Implementar como struct/record struct compacto con bitmask `SearchOptionFlags`.
  - Debe normalizar rutas y extensiones en el constructor/fábricas.
  - Exponer helpers para saber si una flag está activa sin múltiples bools.

- `SearchResult`:
  - Incluir ruta, línea, columna, snippet y `SearchMatchKind`.
  - Preparar campos `SegmentId` + `DocId` para enlazar con el índice (aunque inicialmente se usen poco).

- `SearchStatistics`:
  - Acumular métricas de archivos, bytes, matches y tiempos (por fases).
  - Mantener actualizada durante toda la ejecución de `SearchPipeline`.

- `SearchContext`:
  - Encapsular opciones, índice, cachés, `CancellationToken`, `SearchStatistics`.
  - No exponer detalles internos de cachés/índice a la UI.

- `SearchPipeline`:
  - Orquestar el flujo de búsqueda en fases: índice → Bloom/columnas → IO/cache → matching → resultados.
  - Exponer `IAsyncEnumerable<SearchResult>` para streaming.
  - Respetar siempre cancelación y límites de paralelismo.

### Index/

- `IndexManager`:
  - Gestionar lista de segmentos, sus estados y versiones.
  - Exponer operaciones de alto nivel:
    - `BuildFullIndex(rootPath)`.
    - `UpdateIndex(FileChangeSet)`.
    - `SearchTokens(...)` que devuelva segmentos y docs candidatos.

- Segmentos (`SegmentId`, `SegmentMetadata`, `SegmentWriter`, `SegmentReader`, `SegmentMerger`):
  - Considerar cada segmento inmutable.
  - `SegmentWriter`: construir diccionario de tokens, postings, columnares y Bloom.
  - `SegmentReader`: exponer APIs eficientes `GetPostings`, `FilterByMetadata`, `MaybeContainsToken`.
  - `SegmentMerger`: combinar segmentos pequeños, reescribir todo de forma coherente.

- `Storage/`:
  - `SegmentFileLayout`: definir nombres y organización de archivos físicos (`segment-info.bin`, `tokens.bin`, `postings.bin`, `paths.bin`, `stored.bin`, `meta.bin`, `bloom.bin`).
  - `TokenDictionaryStore`, `PostingsStore`, `StoredFieldsStore`: aislar lógica de lectura/escritura binaria.
  - `Compression/LZ4CodecAdapter`: adaptar compresión LZ4 (o stub inicial) para postings/columnas.

- `MetadataStore/`:
  - `ColumnStoreWriter`/`Reader`: manejar columnas contiguas en `meta.bin`.
  - Columnas concretas: tamaños, timestamps, flags, extensión.
  - Pensar en filtros que reduzcan I/O antes de tocar texto (pre-filters rápidos en RAM).

- `Bloom/`:
  - Configurar Bloom filters por token y/o por documento.
  - Proveer APIs rápidas para decidir si merece la pena leer un segmento o archivo.

- `FileIdMap/`:
  - Representar identificadores estables de archivos para detectar renombrados/movidos.

### IO/

- `FileEnumerator`:
  - Recorrer el árbol de directorios según `SearchOptions` (extensiones, tamaños, flags).
  - Exponer un flujo asíncrono de `FileMetadata`.

- `FileMetadataReader`:
  - Extraer tamaño, timestamps y atributos (hidden/system, etc.).

- `MemoryMappedLoader`:
  - Usar Memory Mapped Files en implementaciones avanzadas.
  - Exponer `ReadOnlyMemory<byte>` / `ReadOnlySpan<byte>`.

- `AsyncDiskScheduler`:
  - Coordinar la cantidad de lecturas concurrentes.
  - Tener en cuenta estado CPU vs I/O (aunque al inicio sea heurístico/simple).

- `FileChangeDetector` + `FileSystemSnapshot`:
  - Detectar nuevos, modificados y eliminados.
  - Generar `FileChangeSet` para `IndexManager.UpdateIndex`.

### Processing/

- Tokenizer:
  - `TokenizerSIMD`: usar tablas (`CharsetTables`) y operaciones vectorizadas cuando se implemente a fondo.
  - Devolver `TokenStream` con posición/longitud (y hashes cuando sea necesario).

- Automata:
  - `AutomataBuilder`: construir DFA para patrones simples (literal, whole-word, etc.).
  - `DfaMatcher`: ejecutar el DFA sobre spans UTF-8/UTF-16.
  - `NfaEngine`: motor secundario para patrones más complejos.

- Regex:
  - `RegexEngine`: envolver `System.Text.RegularExpressions.Regex`.
  - `HyperscanEngine`: dejar preparado P/Invoke opcional para uso futuro.

- Text:
  - `CharsetTables`: lookup tables de clasificación de caracteres.
  - `Normalization`: normalización de acentos, case, etc., según flags de búsqueda.

- `SpanHelpers`:
  - Utilidades sobre `Span`/`ReadOnlySpan` que eviten asignaciones (búsquedas, splits, copias segmentadas).

### Cache/

- `LruCache`: implementación genérica de LRU.
- `HotFileCache`: cachear contenido/tokens de archivos más usados.
- `QueryCache`: cachear resultados de consultas recientes basadas en `SearchOptions` normalizadas.
- `BufferPool`: reutilizar buffers (ArrayPool) para reducir GC.

### Public/

- `SearchEngine`:
  - Punto de entrada para UI/CLI.
  - Debe ofrecer:
    - `StartSearchAsync(SearchOptions, CancellationToken)` → `SearchSession`.
    - `StreamResultsAsync(SearchSession, CancellationToken)` → `IAsyncEnumerable<SearchResult>`.
    - `GetStatisticsAsync(SearchSession)` → `SearchStatistics`.

- `IndexService`:
  - `BuildFullAsync`, `UpdateAsync`, `RebuildSegmentAsync`, `CompactAsync`.

- `Analyzer`:
  - Análisis de cobertura, archivos no indexados, recomendaciones de configuración.

- `Diagnostics`:
  - Exponer métricas internas para logging/dashboards.

---

## Reglas de rendimiento

Cuando trabajes en rutas calientes:

- Evita al máximo:
  - Asignaciones innecesarias (especialmente dentro de loops).
  - LINQ pesado en hot paths.
  - Boxing y conversiones repetitivas.
- Prefiere:
  - `Span`/`ReadOnlySpan`, `Memory<T>`.
  - Buffers reutilizables vía `BufferPool`.
  - Estructuras compactas (`struct`, `record struct`) donde tenga sentido.
- Respeta `MaxDegreeOfParallelism` y límites de I/O.
- Usa token de cancelación siempre que haya operaciones largas.

---

## Reglas de seguridad y sistema de archivos

- Nunca asumas rutas absolutas fuera de las que provea el usuario (ej.: no recorrer `C:\` completo sin filtro).
- Respeta flags `IncludeHidden` y `IncludeSystem`.
- Maneja excepciones de I/O de forma controlada (archivo bloqueado, permisos insuficientes, etc.).
- No escribas archivos fuera de directorios de índice definidos por el usuario.

---

## Flujo de trabajo sugerido para tareas del agente

Cuando el usuario pida cambios o nuevas funcionalidades:

1. **Leer primero** `Synapta_Engine.md` para entender cómo encaja la petición en la arquitectura.
2. **Localizar** los archivos relevantes dentro de `Synapta.SearchEngine/`.
3. **Proponer un plan breve** (en la respuesta) antes de tocar código si el cambio es grande.
4. **Aplicar cambios A→Z**:
   - Mostrar siempre archivos completos modificados, no solo fragments.
   - Mantener nombres de tipos y namespaces coherentes con la estructura.
5. **Actualizar comentarios** y documentación in-code cuando cambien responsabilidades.
6. **Sugerir tests** o añadirlos cuando el contexto lo permita.

---

## Límites y no-objetivos

- No implementar ni modificar UI WPF aquí; este repo es el motor de búsqueda.
- No introducir dependencia fuerte a frameworks específicos de logging o DI; usar abstracciones simples.
- No añadir código muerto o experimental sin etiquetarlo claramente o sin petición explícita.

---

## Objetivo final

Lograr que Synapta.SearchEngine sea:

- Estable, bien organizado y fácil de integrar en WPF/CLI.
- Capaz de escalar a millones de archivos con tiempos de respuesta bajos.
- Extensible para futuras mejoras (Hyperscan, indexación distribuida, ranking semántico) sin romper la base.

Todos tus cambios deben empujar el motor hacia este objetivo respetando las reglas anteriores.

