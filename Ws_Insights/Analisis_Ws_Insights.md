| 🟥 Por hacer                              | 🟧 En progreso      | 🟩 Hecho |
|-------------------------------------------|----------------------|----------|
| Integrar MFT/USN Journal                  |                      |          |
| Fallback Directory.EnumerateFiles         |                      |          |
| Resolver FileID → metadata                |                      |          |
| Listener incremental (USN)                |                      |          |
| Fallback FileSystemWatcher                |                      |          |
| IFilter (COM)                             |                      |          |
| PDFPig fallback                           |                      |          |
| OpenXML SDK fallback                      |                      |          |
| NPOI fallback                             |                      |          |
| Pipeline automático de parsers            |                      |          |
| Integrar Tesseract OCR                    |                      |          |
| Reglas condicionadas OCR                  |                      |          |
| Hash xxHash3                              |                      |          |
| Detección de duplicados                   |                      |          |
| Segmentos NDJSON                          |                      |          |
| Bloom Filters                             |                      |          |
| Posting Lists (término → docs)            |                      |          |
| Frecuencias TF                            |                      |          |
| Merge de segmentos                        |                      |          |
| Búsqueda por nombre (Everything-like)     |                      |          |
| Búsqueda por contenido                    |                      |          |
| Filtros avanzados                         |                      |          |
| Regex avanzada / Hyperscan opcional       |                      |          |
| Validación de cabeceras (PDF/JPG/PNG)     |                      |          |
| Marcado de archivos corruptos             |                      |          |
| Conteo palabras frecuentes                |                      |          |
| Stopwords                                 |                      |          |
| Hash por línea y por párrafo              |                      |          |
| Mover archivos / deduplicación            |                      |          |
| Papelera temporal                         |                      |          |
| Etiquetado manual                         |                      |          |
| Snippet automático                        |                      |          |
| Notas temporales / sesión                 |                      |          |
| Panel duplicados (UI)                     |                      |          |
| Panel corruptos (UI)                      |                      |          |
| Panel palabras frecuentes (UI)            |                      |          |
| Vista Everything-like (UI)                |                      |          |
| Vista de snippets / preview (UI)          |                      |          |



| Archivo                     | Namespace                                      | Rol / Qué se supone que haga                                                                                       | Estado actual                                               |
|-----------------------------|------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|
| Analyzer.cs                 | Ws_Insights.Search.Public                      | Análisis avanzado del índice: cobertura, sugerencias de optimización                                               | Stub (devuelve diccionario vacío)                           |
| AsyncDiskScheduler.cs       | Ws_Insights.Search.IO                          | Scheduler para limitar / consolidar lecturas concurrentes de disco (SemaphoreSlim)                                 | Implementado (IO asíncrono real)                            |
| AutomataBuilder.cs          | Ws_Insights.Search.Processing.Automata         | Constructor de autómatas DFA desde patrones literales                                                              | Stub (solo envuelve DfaMatcher con substring)               |
| BloomFilterBuilder.cs       | Ws_Insights.Search.Index.Bloom                 | Construir Bloom filters a partir de tokens usando BloomFilterConfig                                                | Stub (BuildForTokens crea BloomFilterStore vacío)           |
| BloomFilterConfig.cs        | Ws_Insights.Search.Index.Bloom                 | Configuración de Bloom filters (nº hashes, nº bits, tamaño)                                                        | Implementado (config mínima)                                |
| BloomFilterReader.cs        | Ws_Insights.Search.Index.Bloom                 | Leer Bloom filters desde disco y consultar pertenencia                                                             | Stub (MaybeContains siempre false)                          |
| BloomFilterStore.cs         | Ws_Insights.Search.Index.Bloom                 | Representación en memoria de un Bloom filter (bitset + funciones hash)                                             | Stub (Add vacío, MaybeContains siempre false)               |
| BufferPool.cs               | Ws_Insights.Search.Cache                       | Pool de buffers reutilizables para byte[] y char[], delegando en ArrayPool                                         | Implementado (wrapper simple)                               |
| CharsetTables.cs            | Ws_Insights.Search.Processing.Text             | Tablas precalculadas de tipos de carácter (letra, dígito, espacio, delimitador, etc.)                              | Stub (arrays vacíos, todo false)                            |
| ColumnStoreReader.cs        | Ws_Insights.Search.Index.MetadataStore         | Lectura de columnas de metadatos (tamaños, fechas, flags, etc.) desde almacenamiento columnar                      | Stub (ReadColumn devuelve lista vacía)                      |
| ColumnStoreWriter.cs        | Ws_Insights.Search.Index.MetadataStore         | Escritura de columnas de metadatos homogéneos a almacenamiento columnar                                            | Stub (WriteColumn no hace nada)                             |
| Diagnostics.cs              | Ws_Insights.Search.Public                      | Métricas internas del motor: cachés, segmentos, timings                                                            | Stub (diccionario vacío)                                    |
| DfaMatcher.cs               | Ws_Insights.Search.Processing.Automata         | Ejecutar “DFA” sobre texto y devolver índices de coincidencias                                                     | Implementación simple (IndexOf substring, no DFA real)      |
| ExtensionColumn.cs          | Ws_Insights.Search.Index.MetadataStore.Columns | Columna doc → id de extensión (índice a diccionario de extensiones únicas)                                         | Stub (Values = lista vacía)                                 |
| FileChangeDetector.cs       | Ws_Insights.Search.IO                          | Detectar cambios entre snapshots: archivos Added / Modified / Removed                                              | Implementado (diff por timestamps y tamaño)                 |
| FileEnumerator.cs           | Ws_Insights.Search.IO                          | Enumerador de archivos de alto rendimiento con filtros (extensiones, tamaños, atributos)                           | Implementado (FileSystemEnumerable + filtros)               |
| FileId.cs                   | Ws_Insights.Search.Index.FileIdMap             | Identificador estable de archivo independiente de la ruta (FileId basado en Guid)                                  | Implementado (ID sintético; no usa FileId NTFS real)        |
| FileIdMapBuilder.cs         | Ws_Insights.Search.Index.FileIdMap             | Construir mapa path → FileId                                                                                       | Stub funcional (asigna Guid nuevos por path)                |
| FileIdMapReader.cs          | Ws_Insights.Search.Index.FileIdMap             | Leer mapa path → FileId desde estado persistido                                                                    | Stub funcional (diccionario en memoria)                     |
| FileMetadataReader.cs       | Ws_Insights.Search.IO                          | Leer metadatos de archivo (tamaño, fechas, atributos) en un tipo FileMetadata                                      | Implementado                                                |
| FileSizeColumn.cs           | Ws_Insights.Search.Index.MetadataStore.Columns | Columna de tamaños de archivo por documento                                                                        | Stub (Values = lista vacía)                                 |
| FileSystemSnapshot.cs       | Ws_Insights.Search.IO                          | Snapshot del sistema de archivos: path → FileMetadata                                                              | Implementado (contenedor simple)                            |
| FlagsColumn.cs              | Ws_Insights.Search.Index.MetadataStore.Columns | Columna de flags/bitmask por documento (atributos, etc.)                                                           | Stub (Values = lista vacía)                                 |
| HashUtils.cs                | Ws_Insights.Search.Core.Util                   | Helper para cálculo de hash rápido (placeholder de xxHash3, usa MD5 truncado a 64 bits)                            | Stub funcional (hash real pendiente)                        |
| HotFileCache.cs             | Ws_Insights.Search.Cache                       | Caché de archivos “calientes” en memoria, key = path, value = byte[] (usa MemoryMappedLoader / LruCache)           | Implementado                                                |
| HyperscanEngine.cs          | Ws_Insights.Search.Processing.Regex            | Wrapper para motor Hyperscan vía P/Invoke                                                                          | Stub (IsAvailable = false, sin matching)                    |
| IndexManager.cs             | Ws_Insights.Search.Index                       | Fachada para gestionar el índice persistente: segmentos, escritura, merges, búsquedas                              | Stub (Build/Update/Search sin lógica real)                  |
| IndexService.cs             | Ws_Insights.Search.Public                      | Servicio de indexado: build, update, rebuild selectivo y compactar índice                                          | Parcial (Build/Update activos; Rebuild/Compact TODO)        |
| LruCache.cs                 | Ws_Insights.Search.Cache                       | Caché LRU simple (Dictionary + LinkedList), no thread-safe                                                         | Implementado (placeholder pero usable)                      |
| LZ4CodecAdapter.cs          | Ws_Insights.Search.Index.Storage.Compression   | Adaptador a códec LZ4 externo para compresión de bloques del índice                                                | Stub (Compress/Decompress = passthrough)                    |
| MemoryMappedLoader.cs       | Ws_Insights.Search.IO                          | Abstracción para carga “memory mapped” de archivos                                                                 | Stub funcional (usa File.ReadAllBytes; pendiente MMF)       |
| NfaEngine.cs                | Ws_Insights.Search.Processing.Automata         | Motor NFA para patrones más complejos                                                                              | Stub (Match siempre false)                                  |
| Normalization.cs            | Ws_Insights.Search.Processing.Text             | Normalización de texto: quitar acentos y normalizar mayúsculas/minúsculas                                          | Implementado (remueve acentos, opcional lower-case)         |
| PathNormalizer.cs           | Ws_Insights.Search.Core.Util                   | Normalizar rutas: trim, expandir variables, resolver path absoluto, limpiar separadores finales                    | Implementado                                                |
| PostingsStore.cs            | Ws_Insights.Search.Index.Storage               | Acceso a postings lists por tokenOrdinal dentro de un segmento                                                     | Stub (GetPostings → yield break)                            |
| QueryCache.cs               | Ws_Insights.Search.Cache                       | Caché de resultados de queries: normaliza SearchOptions y guarda List<SearchResult> en LruCache                    | Implementado (lógica sencilla por opciones)                 |
| RegexEngine.cs              | Ws_Insights.Search.Processing.Regex            | Motor regex unificado: Regex .NET (y futuro fallback Hyperscan)                                                    | Funcional (usa Regex compilado; sin Hyperscan aún)          |
| SearchContext.cs            | Ws_Insights.Search.Core                        | Contexto de una búsqueda: opciones, IndexManager, cachés, estadísticas y CancellationToken                         | Implementado (POCO de contexto)                             |
| SearchEngine.cs             | Ws_Insights.Search.Public                      | Fachada pública del motor: crear búsqueda, streamear resultados, obtener estadísticas                              | Operativo (depende de SearchPipeline)                       |
| SearchMatchKind.cs          | Ws_Insights.Search.Core                        | Enum del tipo de match: Literal, Regex, WholeWord, Prefix                                                          | Implementado                                                |
| SearchOptionFlags.cs        | Ws_Insights.Search.Core.Flags                  | Flags combinables para comportamiento de búsqueda (CaseSensitive, UseRegex, WholeWord, etc.)                       | Implementado                                                |
| SearchOptions.cs            | Ws_Insights.Search.Core                        | Record struct con todos los parámetros de búsqueda (ruta, query, extensiones, flags, tamaños, paralelismo, etc.)   | Implementado                                                |
| SearchPipeline.cs           | Ws_Insights.Search.Core                        | Pipeline de búsqueda: enumera archivos, lee contenido, hace matching y emite SearchResult                          | Implementado como placeholder no indexado (regex/literal)   |
| SearchResult.cs             | Ws_Insights.Search.Core                        | Representa un hit: ruta, línea, columna, snippet, score, tipo de match, SegmentId/DocId                            | Implementado (POCO de resultado)                            |
| SearchStatistics.cs         | Ws_Insights.Search.Core                        | Métricas de ejecución de una búsqueda (archivos, bytes, tiempos, etc.)                                             | Implementado (POCO de estadísticas)                         |
| SegmentFileLayout.cs        | Ws_Insights.Search.Index.Storage               | Define nombres de archivos que componen un segmento en disco (info, tokens, postings, paths, stored, meta, bloom)  | Implementado (constantes y helpers de layout)               |
| SegmentMetadata.cs          | Ws_Insights.Search.Index.Segment               | Metadata descriptiva de un segmento: Id, nº docs, tokens, tamaños, rango de docIds, timestamp                      | Implementado (POCO)                                         |
| SegmentReader.cs            | Ws_Insights.Search.Index.Segment               | Lector de un segmento inmutable: obtener postings, metadata, Bloom, etc. para búsquedas                            | Stub (GetPostings → yield break)                            |
| SegmentWriter.cs            | Ws_Insights.Search.Index.Segment               | Escritor de segmentos inmutables: tokenizar docs, crear postings, columnas, Bloom, etc.                            | Stub (WriteAsync solo crea SegmentId)                       |
| SpanHelpers.cs              | Ws_Insights.Search.Processing                  | Helpers para operar con Span/ReadOnlySpan (búsqueda de subspan sin allocs)                                         | Stub funcional (convierte a string + IndexOf)               |
| StoredFieldsStore.cs        | Ws_Insights.Search.Index.Storage               | Acceso a stored fields (snippets/metadata caros) por docId                                                         | Stub (devuelve diccionario vacío)                           |
| TimeProvider.cs             | Ws_Insights.Search.Core.Util                   | Abstracción de tiempo (ITimeProvider) + proveedor global reemplazable para tests                                   | Implementado (test-friendly)                                |
| Token.cs                    | Ws_Insights.Search.Processing.Tokenizer        | Representa un token: posición y longitud dentro del texto                                                          | Implementado (record struct simple)                         |
| TokenDictionaryStore.cs     | Ws_Insights.Search.Index.Storage               | Diccionario de tokens por segmento: mapear string ↔ ordinal y gestionar persistencia                               | Stub (GetOrdinal = -1, GetToken = string.Empty)             |
| TokenizerSIMD.cs            | Ws_Insights.Search.Processing.Tokenizer        | Tokenizador “rápido” basado en SIMD para texto                                                                     | Stub funcional (Split por espacios; sin SIMD real)          |
| TokenStream.cs              | Ws_Insights.Search.Processing.Tokenizer        | Wrapper enumerable para una colección de Token                                                                     | Implementado (envuelve IEnumerable<Token>)                  |
| TimestampColumn.cs          | Ws_Insights.Search.Index.MetadataStore.Columns | Columna de timestamps (creación/modificación) por documento                                                        | Stub (Values = lista vacía)                                 |
| App.xaml                    | Ws_Insights                                    | Definición de la aplicación WPF y recursos globales (dictionaries de temas, estilos, etc.)                         | Implementado                                                |
| App.xaml.cs                 | Ws_Insights                                    | Code-behind de `App`: clase `Application` principal                                                                | Implementado (mínimo)                                       |
| AssemblyInfo.cs             | Global                                         | Atributos de ensamblado WPF (`ThemeInfo` para localización de diccionarios de recursos)                            | Implementado                                                |
| Csv.Exporter.cs             | Ws_Insights.Reporting                          | Exportador de resultados (`IEnumerable<FileMatch>`) a CSV (encabezados, escape de comas/comillas)                  | Implementado                                                |
| ExtensionCategoryDefinition.cs | Ws_Insights.Models                          | Record que define una categoría de extensiones (nombre, descripción, lista de extensiones)                         | Implementado                                                |
| ExtensionManagerWindow.cs   | Ws_Insights.File_Extensions                    | Lógica de ventana WPF para gestionar categorías/opciones de extensiones (tri-state, Select All)                    | Implementado                                                |
| ExtensionManagerWindow.xaml | Ws_Insights.File_Extensions                    | XAML de la ventana de gestión de extensiones (bindings a `Categories`, botones, etc.)                              | Implementado                                                |
| ExtensionOption.cs          | Ws_Insights.Models                             | Modelo de extensión individual con `IsChecked` (INotifyPropertyChanged para binding WPF)                           | Implementado                                                |
| FileMatch.cs                | Ws_Insights.Models                             | Record de resultado de archivo: nombre, extensión, ruta, tamaño, snippet, tamaño en KB                             | Implementado                                                |
| MainWindow.xaml             | Ws_Insights                                    | Vista principal WPF: layout de buscador, resultados, log, barra lateral, botones, etc.                             | Implementado                                                |
| MainWindow.xaml.cs          | Ws_Insights                                    | Lógica de la ventana principal: lanza búsquedas, maneja comandos UI, ordena resultados, log, etc.                  | Implementado                                                |
| PauseToken.cs               | Ws_Insights.Utilities                          | Implementa `PauseTokenSource`/`PauseToken` para pausa/reanudación cooperativa de tareas async                      | Implementado                                                |
| SearchEngine.cs             | Ws_Insights.Search                             | Motor de búsqueda de alto nivel para la UI: orquesta enumeración, matching y reporting async                       | Implementado                                                |
| SearchOptions.cs            | Ws_Insights.Search                             | Opciones de búsqueda expuestas a la UI (ruta, query, extensiones, flags, tamaños, pausa, etc.)                     | Implementado                                                |
| SearchProgress.cs           | Ws_Insights.Search                             | Snapshot de progreso de búsqueda (archivos escaneados, matches, errores, velocidad, archivo actual)                | Implementado                                                |
| ThemeDark.xaml              | —                                              | Diccionario de recursos XAML: colores/brushes para tema oscuro de la app                                           | Implementado                                                |
| ThemeLight.xaml             | —                                              | Diccionario de recursos XAML: colores/brushes para tema claro de la app                                            | Implementado                                                |
| Ws_Insights.csproj          | —                                              | Archivo de proyecto .NET 8 WPF (target, publish single file, runtime win-x64, opciones de build)                   | Implementado                                                |
