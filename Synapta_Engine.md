# Motor de búsqueda Synapta

> Diseño arquitectónico de alto nivel para un motor de búsqueda de texto en archivos, inspirado en Lucene, ripgrep, Hyperscan, ClickHouse y motores modernos de logs, pero enfocado a un entorno local/desktop .NET.

---

## 1. Objetivos

- Búsqueda de texto ultra rápida sobre millones de archivos en disco.
- Soporte a texto literal, whole-word, case-sensitive, regex avanzada.
- Indexador persistente con segmentos inmutables y merges en segundo plano.
- Bajo consumo de CPU/RAM para consultas repetidas (cachés, Bloom filters).
- Integración directa con UI WPF (streaming de resultados, métricas en tiempo real).
- Uso exclusivo de tecnologías gratuitas y open source.

---

## 2. Árbol ASCII de la arquitectura

```txt
Synapta.SearchEngine/
│
├─ Core/
│   ├─ SearchOptions.cs
│   ├─ SearchResult.cs
│   ├─ SearchStatistics.cs
│   ├─ SearchContext.cs
│   ├─ SearchPipeline.cs
│   ├─ Flags/
│   │   └─ SearchOptionFlags.cs
│   └─ Util/
│       ├─ PathNormalizer.cs
│       ├─ HashUtils.cs      (xxHash3 / MD5 si hace falta)
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
│   │   ├─ RegexEngine.cs          (wrapper general)
│   │   └─ HyperscanEngine.cs      (opcional, P/Invoke)
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

---

## 3. Core

### 3.1 `SearchOptions`

- Estructura compacta, basada en struct/record struct.
- Usa flags bitmask (`SearchOptionFlags`) en lugar de múltiples bools.
- Propiedades clave:
  - `RootPath` (ruta base normalizada).
  - `Query` (patrón original del usuario).
  - `Extensions` (array de extensiones normalizadas, sin punto).
  - Flags: `CaseSensitive`, `UseRegex`, `WholeWord`, `IncludeSubfolders`, `IncludeHidden`, `IncludeSystem`.
  - Límites: `MaxDegreeOfParallelism`, `MaxFileSizeBytes`, `MinFileSizeBytes`.
  - `PauseToken` para soporte de pausa/reanudación.

### 3.2 `SearchResult`

- Representa una coincidencia individual o un "hit" agrupado.
- Campos sugeridos:
  - `string Path`
  - `int LineNumber`
  - `int Column`
  - `string Snippet`
  - `double Score` (opcional, para ranking futuro).
  - `SearchMatchKind` (Literal, Regex, WholeWord, Prefix, etc.).
  - `SegmentId` + `DocId` para enlazar con el índice.

### 3.3 `SearchStatistics`

- Métricas para UI y diagnósticos:
  - `FilesScanned`, `FilesSkippedByBloom`, `FilesFromCache`.
  - `BytesReadFromDisk`, `BytesReadFromCache`.
  - `MatchesFound`, `SegmentsVisited`.
  - Tiempos: `IndexLookupTime`, `DiskTime`, `ProcessingTime`, `TotalTime`.

### 3.4 `SearchContext`

- Objeto de contexto de una búsqueda:
  - Referencia a `SearchOptions`.
  - Referencia al `IndexManager`.
  - Referencia a caches (HotFile, QueryCache).
  - Cancelación (`CancellationToken`).
  - Estadísticas acumuladas.

### 3.5 `SearchPipeline`

- Orquesta el flujo de una búsqueda:
  - Fase 1: búsqueda en índice + Bloom filters.
  - Fase 2: lectura de contenido (disk / cache).
  - Fase 3: ejecución de DFA/regex sobre spans.
  - Fase 4: ensamblado de `SearchResult`.
- Diseñado para ejecución asíncrona (`IAsyncEnumerable<SearchResult>` para streaming).

---

## 4. Index (segmentos, columnares, Bloom)

### 4.1 `IndexManager`

- Es la fachada principal del índice persistente.
- Responsabilidades:
  - Saber qué segmentos existen y su estado.
  - Coordinar escrituras de nuevos segmentos.
  - Ejecutar merges de segmentos en background.
  - Resolver rutas → `FileId` (vía `FileIdMap`).
  - Exponer operaciones de alto nivel:
    - `BuildFullIndex(rootPath)`: indexación completa.
    - `UpdateIndex(changes)`: indexación incremental.
    - `SearchTokens(tokens, filters)`: búsqueda basada en índice.

### 4.2 Segmentos

Cada segmento es auto-contenido e inmutable:

- `SegmentMetadata`:
  - `SegmentId`, versión, timestamp.
  - Rango de documentos (DocId mínimo/máximo).
  - Estadísticas agregadas (nº docs, nº tokens, tamaño medio, etc.).

- Archivos por segmento (layout lógico):
  - `segment-info.bin` → metadatos básicos, cabecera.
  - `tokens.bin` → diccionario de términos (token → ordinal).
  - `postings.bin` → listas de postings (tokenOrdinal → [DocId, freq, posiciones]).
  - `paths.bin` → mapeo `DocId → pathId` / `path string` comprimido.
  - `stored.bin` → campos almacenados opcionales (por ejemplo, fragmentos de texto pre-cacheados).
  - `meta.bin` → columnares (tamaños, fechas, flags, extensión).
  - `bloom.bin` → Bloom filter por documento y/o por token.

### 4.3 `SegmentWriter`

- Toma como entrada:
  - Archivos + contenido tokenizado.
  - Metadatos de archivo.
- Construye:
  - Diccionario de tokens (ordenado, deduplicado).
  - Postings list compresos (delta encoding + LZ4).
  - Column store de metadatos.
  - Bloom filters (por archivo o por token).
- Produce un conjunto de archivos de segmento **inmutables**.

### 4.4 `SegmentReader`

- Lee un segmento dado y responde consultas de tokens:
  - `GetPostings(token)` → enumeración eficiente de DocIds/posiciones.
  - `FilterByMetadata(criteria)` → usa column store antes de tocar postings.
  - `MaybeContainsToken(docId, token)` → consulta rápida vía Bloom.
- Optimizado para acceso solo lectura, thread-safe.

### 4.5 `SegmentMerger`

- Merge incremental de segmentos:
  - Compone varios segmentos pequeños en uno grande.
  - Recalcula diccionario global y postings.
  - Reescribe Bloom filters y metadatos.
- Se ejecuta en background controlando IO y CPU.

### 4.6 `MetadataStore` / Column store

- Cada columna se guarda de forma contigua en `meta.bin`:
  - Ejemplo de columnas:
    - Tamaño (long[] / varint).
    - Timestamps (long[] ticks / unix time).
    - Flags por archivo (bitmask).
    - Extensión (id a partir de diccionario de extensiones).
- Ventaja:
  - Filtros "previos" rápidos: se escanean miles de entradas en RAM sin tocar texto.

### 4.7 Bloom filters

- Configurables por segmento y por tipo de campo.
- Casos de uso:
  - Bloom global por token: decidir qué segmentos visitar.
  - Bloom por documento: decidir qué archivo merece lectura completa.
- Compromiso ajustable entre almacenamiento y falsos positivos.

### 4.8 `FileIdMap`

- Encapsula el problema de identificar archivos independientemente de la ruta completa:
  - Clave basada en (FileId físico de NTFS, tamaño, timestamp).
  - Útil para detección de archivos renombrados / movidos.

---

## 5. IO (enumeración, MMAP, scheduler)

### 5.1 `FileEnumerator`

- Recorre el árbol de directorios desde `RootPath`.
- Aplica filtros iniciales:
  - Extensiones permitidas.
  - Tamaño mínimo/máximo.
  - IncludeHidden / IncludeSystem.
- Expone un stream (IAsyncEnumerable) de `FileMetadata`.

### 5.2 `FileMetadataReader`

- Extrae metadatos del sistema de archivos:
  - Tamaño, fechas de creación/último acceso/escritura.
  - Flags de sólo lectura, oculto, sistema, etc.

### 5.3 `MemoryMappedLoader`

- Abre archivos con Memory Mapped Files.
- Devuelve vistas en forma de `ReadOnlyMemory<byte>` / `ReadOnlySpan<byte>`.
- Minimiza copias y delega al SO el paging.

### 5.4 `AsyncDiskScheduler`

- Controla cuántas lecturas concurrentes están activas.
- Conoce:
  - Límite de ancho de banda IO estimado.
  - Nivel de carga de CPU actual.
- Algoritmo:
  - Si IO-bound → limita threads de lectura, mantiene CPU ocupada.
  - Si CPU-bound → reduce trabajo de análisis paralelo, prioriza caché.

### 5.5 `FileChangeDetector`

- Usa snapshots y metadatos (y opcionalmente `FileSystemWatcher`).
- Detecta:
  - Nuevos archivos.
  - Archivos modificados (cambio de tamaño/timestamp).
  - Archivos eliminados.
- Genera un conjunto de cambios para `IndexManager.UpdateIndex`.

---

## 6. Processing (tokenizador SIMD, automatas, regex)

### 6.1 `TokenizerSIMD`

- Tokeniza texto usando instrucciones SIMD:
  - Procesa bloques de 32/64 bytes por iteración.
  - Usa tablas (`CharsetTables`) para clasificar caracteres (letra, dígito, delimitador, espacio, etc.).
  - Optional: normalización a mayúsculas/minúsculas en bloque.
- Devuelve una secuencia de `Token` (posición, longitud, hash opcional).

### 6.2 `Automata` (DFA/NFA)

- `AutomataBuilder`:
  - Convierte consultas literales / patrones simples en automatas deterministas.
- `DfaMatcher`:
  - Ejecuta el DFA sobre un `ReadOnlySpan<char>` o `ReadOnlySpan<byte>` con decodificación UTF-8 integrada.
- `NfaEngine` (opcional, para patrones algo más complejos):
  - Menos eficiente que DFA, pero más flexible.

### 6.3 `RegexEngine` / `HyperscanEngine`

- `RegexEngine`:
  - Adaptador para usar:
    - `System.Text.RegularExpressions.Regex` por defecto.
    - `HyperscanEngine` cuando esté disponible.
- `HyperscanEngine` (opcional, C API via P/Invoke):
  - Optimizado para conjuntos grandes de patrones y streaming.

### 6.4 `Text` utils

- `CharsetTables`:
  - Tablas de 256 entradas para clasificar bytes: letra, digit, whitespace, delimiter, etc.
- `Normalization`:
  - Funciones para normalizar acentos, mayúsculas/minúsculas, etc., según configuración.

### 6.5 `SpanHelpers`

- Utilidades genéricas sobre `Span` y `ReadOnlySpan`:
  - Búsqueda de subcadenas optimizada.
  - División por delimitadores sin asignaciones.
  - Copia segmentada hacia buffers externos cuando sea necesario.

---

## 7. Cache (archivos calientes, consultas, buffers)

### 7.1 `HotFileCache`

- Cachea contenido y/o tokens para los archivos más usados.
- Política típica: LRU por tamaño total en bytes (p.ej. 256–1024 MB).
- Entrada típica de cache:
  - `FileId`.
  - Último hash de contenido (xxHash3).
  - Snapshot de tokens o bloques de texto más consultados.

### 7.2 `QueryCache`

- Caché de resultados para consultas recientes.
- Clave: `SearchOptions` "normalizadas" (query, flags, rutas relevantes).
- Valor: lista comprimida de `SearchResult` o de `DocId` + posiciones.

### 7.3 `LruCache`

- Implementación genérica de LRU (diccionario + lista doblemente enlazada).
- Usada por HotFileCache y QueryCache.

### 7.4 `BufferPool`

- Basado en `ArrayPool<byte>` / `ArrayPool<char>`.
- Reutiliza buffers para minimizar asignaciones.

---

## 8. API pública (`Public/`)

### 8.1 `IndexService`

- Construcción y mantenimiento de índices:
  - `Task BuildFullAsync(string rootPath, IndexBuildOptions options)`.
  - `Task UpdateAsync(FileChangeSet changes)`.
  - `Task RebuildSegmentAsync(SegmentId id)`.
  - `Task CompactAsync()` (lanza merges controlados).

### 8.2 `SearchEngine`

- Punto principal para el consumidor (UI WPF, CLI, etc.).
- API sugerida:
  - `Task<SearchSession> StartSearchAsync(SearchOptions options, CancellationToken ct)`.
  - `IAsyncEnumerable<SearchResult> StreamResultsAsync(SearchSession session, CancellationToken ct)`.
  - `Task<SearchStatistics> GetStatisticsAsync(SearchSession session)`.

### 8.3 `Analyzer`

- Utilidades avanzadas:
  - Análisis de cobertura de índices.
  - Reportes de archivos no indexados.
  - Sugerencias de optimización (tamaño de Bloom, políticas de merge, etc.).

### 8.4 `Diagnostics`

- Exposición de métricas internas para logging y UI avanzada:
  - Uso de cachés.
  - Número de segmentos.
  - Tiempos medios/percentiles de búsqueda.
  - Límites configurados de IO/CPU.

---

## 9. Flujos principales

### 9.1 Indexación completa (cold build)

1. `IndexService.BuildFullAsync(rootPath)` crea un snapshot inicial del FS.
2. `FileEnumerator` recorre rutas y genera `FileMetadata`.
3. `FileMetadataReader` completa los metadatos.
4. `MemoryMappedLoader` carga contenido en bloques.
5. `TokenizerSIMD` tokeniza contenido.
6. `SegmentWriter` construye los primeros segmentos.
7. `IndexManager` registra segmentos y los expone para búsqueda.

### 9.2 Indexación incremental

1. `FileChangeDetector` produce un `FileChangeSet` (nuevos, modificados, eliminados).
2. `IndexService.UpdateAsync(changes)` crea segmentos delta.
3. `IndexManager` marca segmentos como obsoletos cuando corresponda.
4. `SegmentMerger` se encarga de merges cuando la fragmentación lo justifica.

### 9.3 Búsqueda

1. UI construye `SearchOptions`.
2. `SearchEngine.StartSearchAsync(options)` crea un `SearchContext`.
3. `SearchPipeline`:
   - Consulta `QueryCache`; si hit → streaming inmediato.
   - Pregunta al índice (`IndexManager.SearchTokens`) qué segmentos contienen los tokens.
   - Aplica Bloom filters y filtros de metadatos para reducir candidatos.
   - Para los archivos candidatos:
     - Usa `HotFileCache` si el archivo está caliente.
     - Si no, pasa por `AsyncDiskScheduler` + `MemoryMappedLoader`.
   - Ejecuta `TokenizerSIMD` + DFA/regex sobre los spans.
   - Construye y devuelve `SearchResult` en streaming.
4. La UI consume `IAsyncEnumerable<SearchResult>` y va pintando.

---

## 10. Extensiones opcionales (nivel máximo)

- **Regex avanzada con Hyperscan**:
  - `HyperscanEngine` como backend para regex masivas.
  - Compilación de conjuntos de patrones frecuentes.

- **Indexación distribuida (LAN)**:
  - Compartir segmentos entre nodos via HTTP/gRPC.
  - Cada nodo mantiene su propio índice local y puede federar queries.

- **Ranking semántico (futuro)**:
  - Capa de ranking sobre `SearchResult` usando modelos ML ligeros.

- **Dashboards de rendimiento**:
  - `Diagnostics` expuesto vía HTTP o named pipes para monitorizar desde otra UI.

---

## 11. Resumen

- La arquitectura propuesta combina:
  - Índice invertido segmentado, inmutable, con merges.
  - Column-store de metadatos para filtros rápidos.
  - Bloom filters para reducir I/O.
  - IO memory-mapped para minimizar copias.
  - Tokenización SIMD y automatas DFA para velocidad extrema.
  - Caches específicas para archivos calientes y consultas frecuentes.
  - API limpia para que la UI consuma resultados en streaming.
- Todo apoyado en componentes open source y gratuitos (LZ4, Hyperscan opcional, .NET intrinsics), sin depender de servicios de pago.

