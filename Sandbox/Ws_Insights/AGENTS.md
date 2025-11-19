# AGENTS – Ws_Insights (Codex)

Este archivo define las reglas para el agente **Codex** al trabajar sobre el proyecto `Neurologic/Ws_Insights`.

---

## 1. Contexto del proyecto

- Proyecto WPF principal: `Neurologic/Ws_Insights/`
- Archivo de proyecto: `Ws_Insights.csproj`
- Archivos de referencia obligatorios:
  - `Ws_Insights/README.md`
  - `Ws_Insights/AGENTS.md`
  - `Ws_Insights/docs/filemap_ascii.txt`
  - `Ws_Insights/docs/table_hierarchy.json`
  - `Ws_Insights/csv/*.csv`

Codex debe asumir que el árbol de archivos y su inventario se describen de forma canónica en `docs/filemap_ascii.txt` y en los CSV mapeados por `docs/table_hierarchy.json`.

---

## 2. Estructura, namespaces y CSV

1. **Regla de namespace**
   - Cada carpeta bajo `Neurologic/Ws_Insights` define un namespace:
     - `Ws_Insights` (raíz)
     - `Ws_Insights.Search`, `Ws_Insights.Search.Core`, `Ws_Insights.Search.Index.*`, etc.
     - `Ws_Insights.Search.Engine.*`
     - `Ws_Insights.Utilities`, `Ws_Insights.Models`, `Ws_Insights.File_Extensions`, `Ws_Insights.Reporting`, etc.
   - El namespace de un archivo debe corresponder exactamente a la ruta declarada en `docs/filemap_ascii.txt`.

2. **No inventar estructura**
   - Codex **no debe crear nuevas carpetas ni mover archivos** salvo instrucción explícita.
   - Para nuevos archivos, usar siempre un directorio ya existente que coincida con la responsabilidad deseada.

3. **CSV como inventario**
   - Cada ruta lógica (`ws_insights/search/index/storage`, `ws_insights/search/processing/regex`, etc.) tiene un CSV asociado en `Ws_Insights/csv/`.
   - Cuando se cree o elimine un archivo:
     - Registrar/actualizar su entrada en el CSV correspondiente.
     - Mantener consistente la descripción y el estado con el estilo de las filas existentes.
   - No crear nuevos CSV salvo instrucción explícita.

---

## 3. Arquitectura del indexador (Ws_Insights.Search*)

El indexador de `Ws_Insights` ya está organizado en capas. Codex debe **extenderlo** y **reutilizarlo**, no crear un indexador paralelo.

### 3.1 Capas de alto nivel

- `Ws_Insights.Search`
  - Punto de entrada de alto nivel (UI / aplicación).
  - Archivos clave:
    - `SearchEngine.cs`
    - `SearchOptions.cs`
    - `SearchProgress.cs`
  - Cualquier integración con la UI o flujos de búsqueda públicos debe pasar por esta capa.

- `Ws_Insights.Search.Core`
  - Tipos de dominio y pipeline:
    - `SearchContext`, `SearchResult`, `SearchStatistics`.
    - `SearchPipeline` (coordinación de pasos).
    - `SearchMatchKind`, `SearchOptionFlags` (flags).
    - Utilidades (`HashUtils`, `PathNormalizer`, `TimeProvider`).
  - Nuevos pasos del pipeline o nuevos tipos de resultado se implementan aquí.

### 3.2 Capa de IO y caché

- `Ws_Insights.Search.IO`
  - Acceso al sistema de archivos:
    - `FileChangeDetector`
    - `FileMetadataReader`
    - `FileSystemSnapshot`
  - Nueva lógica de detección de cambios, snapshots o lectura de metadatos debe agregarse aquí, no en código ad-hoc.

- `Ws_Insights.Search.Cache`
  - `BufferPool.cs`
  - Cualquier nueva política de reutilización de buffers o cachés de uso general para el indexador debe integrarse aquí.

### 3.3 Procesamiento de texto y patrones

- `Ws_Insights.Search.Processing`
  - Código de alto rendimiento para manipular spans y datos en memoria:
    - `SpanHelpers.cs`

- `Ws_Insights.Search.Processing.Automata`
  - Compilación y ejecución de autómatas:
    - `AutomataBuilder`, `NfaEngine`, `DfaMatcher`
  - Nuevos algoritmos de matching basados en autómatas se implementan aquí.

- `Ws_Insights.Search.Processing.Regex`
  - Motores de regex:
    - `HyperscanEngine`
    - `RegexEngine`
  - Para nuevas extensiones de filtrado por expresiones regulares, se deben reutilizar estas clases.

- `Ws_Insights.Search.Processing.Text`
  - Normalización y tablas de caracteres:
    - `CharsetTables`
    - `Normalization`
  - Cualquier cambio a reglas de normalización o tablas de caracteres se realiza aquí.

- `Ws_Insights.Search.Processing.Tokenizer`
  - Tokenización:
    - `Token`, `TokenizerSIMD`, `TokenStream`
  - Nuevas reglas de tokenización o pipelines de tokens deben construirse sobre estas clases.

### 3.4 Indexador persistente (disco)

El indexador en disco se implementa en `Ws_Insights.Search.Index.*`. Esta es la **fuente de verdad** para el índice persistente.

- `Ws_Insights.Search.Index.Bloom`
  - Filtros Bloom:
    - `BloomFilterBuilder`, `BloomFilterConfig`, `BloomFilterReader`, `BloomFilterStore`
  - Nuevas estrategias de prefiltrado deben implementarse aquí.

- `Ws_Insights.Search.Index.FileIdMap`
  - Mapeo lógico entre archivos e IDs:
    - `FileId`, `FileIdMapBuilder`, `FileIdMapReader`
  - Cualquier cambio a la forma de asignar IDs de archivo se agrega aquí.

- `Ws_Insights.Search.Index.MetadataStore`
  - Almacenamiento de metadatos en columnas:
    - `ColumnStoreReader`, `ColumnStoreWriter`
  - Columnas:
    - `ExtensionColumn`, `FileSizeColumn`, `FlagsColumn`, `TimestampColumn`
  - Nuevos campos de metadatos requieren:
    - Nueva columna en `Columns/`.
    - Ajustes en el writer/reader correspondientes.

- `Ws_Insights.Search.Index.Storage`
  - Estructuras de almacenamiento de índice:
    - `PostingsStore`
    - `StoredFieldsStore`
    - `TokenDictionaryStore`
  - Compresión:
    - `Compression/LZ4CodecAdapter.cs`  
  - Nuevos formatos de postings, campos almacenados o diccionarios deben añadirse aquí, utilizando `LZ4CodecAdapter` como mecanismo de compresión estándar.

- `Ws_Insights.Search.Index.Segment`
  - Segmentos de índice:
    - `SegmentMetadata`
    - `SegmentReader`
    - `SegmentWriter`
  - `SegmentFileLayout.cs` define el layout físico de archivos de segmento.
  - Cualquier cambio en la organización física del índice debe pasar por `SegmentFileLayout` y las clases de segmento, no por rutas construidas manualmente.

- `Ws_Insights.Search.Public`
  - API pública del indexador:
    - `Analyzer`
    - `IndexService`
  - Nuevas operaciones de indexación/consulta visibles para el resto del sistema deben exponerse a través de `IndexService` y, de ser necesario, tipos adicionales de Analyzer.

### 3.5 Motor interno (Search.Engine)

- `Ws_Insights.Search.Engine.*` representa el motor interno sin UI:
  - `Cache`: `HotFileCache`, `LruCache`, `QueryCache`
  - `Core`: `SearchPipeline` interno
  - `Index`: `IndexManager`
  - `IO`: `AsyncDiskScheduler`, `FileEnumerator`, `MemoryMappedLoader`
  - `Processing.Regex`: `RegexEngine` interno
  - `Public`: `Diagnostics`, `SearchEngine`
- Cuando se extienda el comportamiento de bajo nivel (scheduler, IO de alto rendimiento, cachés internas, diagnóstico), hacerlo aquí en lugar de introducir motores paralelos dentro de `Ws_Insights.Search`.

---

## 4. Multi-framework obligatorio (.NET)

Todos los proyectos C# gestionados por Codex en este árbol deben:

1. Usar **multi-targeting** con los frameworks:

```xml
<TargetFrameworks>
  net8.0-windows;
  net7.0-windows;
  net6.0-windows
</TargetFrameworks>
```

2. Tener `UseWPF` habilitado cuando el proyecto incluya UI WPF:

```xml
<UseWPF>
  true
</UseWPF>
```
3. No degradar proyectos existentes a un solo TargetFramework.
4. Al crear nuevos proyectos relacionados con Ws_Insights, replicar este esquema de multi-framework.

---

## 5. Reglas técnicas transversales

1. Lenguajes y tecnologías:

   * Código principal de Ws_Insights: **C# (.NET)**.
   * Scripts auxiliares (bajo `Scripts/`): **PowerShell 7+** o **Bash** cuando aplique.

2. Restricciones:

   * No usar **Windows PowerShell 5.1**.
   * No introducir dependencias en **WSL / Linux / WSL2** salvo instrucción explícita.

3. Diseño:

   * Respetar el patrón **MVVM** en la UI WPF.
   * Usar únicamente los temas existentes (`ThemeDark.xaml`, `ThemeLight.xaml`) como base para estilos.

4. Calidad:

   * Cualquier cambio en componentes críticos del indexador (Bloom, FileIdMap, MetadataStore, Storage, Segment, IndexService, SearchPipeline) debe acompañarse de pruebas unitarias en el lugar adecuado del árbol de código.

---

## 6. Resumen operativo mínimo para Codex

1. Usar el árbol de `docs/filemap_ascii.txt` y los CSV como **fuente de verdad** de estructura e inventario.
2. Mantener la regla **namespace = ruta de carpeta**.
3. No crear ni mover carpetas salvo instrucción explícita.
4. Extender el indexador usando las capas existentes en `Ws_Insights.Search.*` y `Ws_Insights.Search.Engine.*`; no crear indexadores paralelos.
5. Registrar cualquier archivo nuevo en el CSV correspondiente.
6. Mantener siempre `net8.0-windows;net7.0-windows;net6.0-windows` en proyectos C# relacionados.
7. Aplicar MVVM, reutilizar módulos existentes y acompañar cambios críticos con pruebas unitarias.
