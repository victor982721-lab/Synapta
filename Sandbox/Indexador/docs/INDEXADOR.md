# Índice del Indexador

## Propósito
`Indexador.Core` es el motor reusable que mantiene el catálogo central de archivos (`indexador.db`). `Indexador.Tool` invoca ese motor desde una interfaz CLI que sirve de base para otros proyectos (Dedupe, Filelist, etc.).  
El índice registra: rutas absolutas, tamaños, hashes (por defecto CRC32), fechas y metadatos adicionales (`Tags`, `Notes`, `Source`). Todos los consumidores pueden confiar en este catálogo en vez de reescaneos completos.

## Componentes clave

| Nombre | Responsabilidad |
| --- | --- |
| `IndexManager` | Coordina la lógica de indexado: crea contexto (base+hash provider), recorre archivos, decide si hay que recalcular hash y actualiza `IndexDatabase`. |
| `IndexDatabase` | Crea el archivo SQLite con la tabla `Files`, ejecuta upsert/borrados y expone `GetRecords` para consumir los registros. |
| `HashProviderFactory` | Fabrica proveedores de hash. Actualmente soporta `CRC32` (rápido) y `SHA256` (estricta). |
| `IndexRecord`, `IndexSummary`, `IndexUpdateOptions` | DTOs que describen la metadata del archivo, resumen de operaciones y opciones de configuración respectiva. |

## Flujo de indexación

1. Se invoca `IndexManager.IndexDirectory` con opciones (`RootPath`, `DatabasePath`, `HashAlgorithm`, etc.).  
2. Se genera un contexto con la base de datos abierta y el proveedor de hash seleccionado.  
3. Se recorren todos los archivos; si no hay cambios (hash/tamaño/tiempo) se omiten; de lo contrario se rehash y se upserta el registro.  
4. Si `CleanMissing` está activo, se eliminan rutas que ya no existen.  
5. `MaxParallelism` (por defecto `Environment.ProcessorCount`) controla cuántos archivos se rehashan simultáneamente cuando hay muchos cambios; así el indexador escala a decenas de miles de archivos al tiempo que mantiene SQLite en un hilo único para las escrituras.
5. `UpdateEntries` permite refrescar únicamente los archivos que cambian (ideal para watchers).

## Uso básico del CLI

```
dotnet run --project Indexador.Tool -- --root C:\Datos --filelist --duplicates
```

- `--root`: path raíz del índice.  
- `--db`: archivo SQLite (por defecto `indexador.db` dentro del root).  
- `--force`: recalcula hashes aún cuando los metadatos no cambiaron.  
- `--hash`: indica `CRC32` o `SHA256`.  
- `--source`: etiqueta que se almacena en cada registro.  
- `--duplicates`, `--filelist`, `--filemap`: reportes que se basan exclusivamente en el índice generado.  

## Reutilización para proyectos hermanos

1. Agrega `Indexador.Core` como dependencia.  
2. Usa `IndexManager.GetRecords`, `BuildFileMap` o `FindDuplicates` para leer el catálogo sin recalcular.  
3. Si necesitas actualizar rutas específicas, invoca `IndexManager.UpdateEntries` con la lista de archivos afectados; esto mantiene el índice sincronizado sin reescaneos.

Con esta base puedes construir herramientas CLI/GUI que lean del mismo índice compartido y respondan con rapidez a consultas de duplicados, estadísticas o auditorías.
