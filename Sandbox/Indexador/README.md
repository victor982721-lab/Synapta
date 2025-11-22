# Indexador Neurologic

## Visión general
`Indexador` es el artefacto central encargado de mantener una base de datos SQLite (`indexador.db`) que almacena metadatos y hashes de archivos a partir de una ruta raíz definida. El motor se expone como:

| Componente | Rol | Reutilización |
 |------------|-----|----------------|
 | `Indexador.Core` | Lógica compartida: registros, base de datos, hash providers, watcher y actualizaciones incrementales. | Consumible por CLI y futuros proyectos (Dedupe, Filelist, etc.). |
 | `Indexador.Tool` | CLI que expone operaciones (indexar, filelist/filemap/duplicados y watcher en vivo) y sirve de shell ejecutable. | Interfaz recomendada para todo el ecosistema Neurologic. |

## Flujo del indexador

1. `IndexManager.IndexDirectory` recorre la carpeta raíz (`--root` o directorio actual) y calcula hashes rápidos (por defecto `CRC32`, puede cambiarse con `--hash`).  
2. Cada archivo se compara contra la base (`IndexDatabase`). Si el archivo ya existe y no cambió (mismo hash, tamaño y `LastWriteUtc`), se omite.  
3. Las entradas nuevas o modificadas se guardan en `Files` con `FullPath`, tamaños, timestamps, hash, etiquetas y el algoritmo utilizado.  
4. La tabla `Files` se limpia de rutas eliminadas si se ejecuta con `--no-clean` desactivado.  
5. `IndexManager.UpdateEntries` permite recalcular sólo un lote de rutas afectadas, ideal para el watcher o procesos externos; la opción `MaxParallelism` controla cuántos hashes se calculan en paralelo para mantener la CPU ocupada en catálogos grandes.

### Hash providers

El motor puede intercambiar implementaciones:  
- `CRC32` (por defecto) para velocidad y menor carga.  
- `SHA256` para validaciones estrictas.  
La fábrica `HashProviderFactory` se encarga de instanciar la implementación solicitada; basta usar `--hash SHA256` para cambiar.

## Uso de `Indexador.Tool`

### Comando principal

```bash
dotnet run --project Indexador.Tool -- --root C:\Datos --db C:\Datos\indexador.db --filelist --filemap --duplicates
```

- `--root`: ruta raíz donde se indexan los archivos (por defecto, el directorio actual).  
- `--db`: ubicación del archivo SQLite; si no se especifica se crea `indexador.db` dentro del root.  
- `--force`: recalcula hashes aunque los archivos no hayan cambiado.  
- `--no-clean`: conserva los registros huérfanos sin eliminarlos.  
- `--filelist`: lista el contenido indexado con tamaño y fecha.  
- `--filemap`: muestra un resumen por directorio (cantidad, tamaño total y duplicados).  
- `--duplicates`: agrupa archivos por hash para detectar duplicados.  
- `--hash`: define el algoritmo de hash (`CRC32` o `SHA256`).  
- `--source`: etiqueta para identificar qué componente generó la entrada.  
- `--watch`: activa un watcher batcheado para actualizar el índice ante cambios (ver sección siguiente).  
- `--debounce`: define el tiempo en milisegundos para agrupar eventos (por defecto 1500 ms).

## Flujo del watcher (`IndexWatcher`)

1. `Indexador.Tool --watch` arranca un `FileSystemWatcher` dentro de `IndexWatcher`, que mira archivos creados, modificados, eliminados y renombrados dentro del root y subdirectorios.  
2. Cada evento normaliza la ruta y se añade a un set de pendientes (evitando duplicados y directorios).  
3. Con un `Timer` internal se aplica un debounce (default 1.5 s) para agrupar los cambios en lotes.  
4. Cuando el temporizador dispara, `IndexWatcher` llama a `IndexManager.UpdateEntries`, que recalcula solo los archivos en el lote y elimina ranuras inexistentes (si ya se borraron).  
5. Al completar, el watcher publica un resumen y vuelve a esperar eventos; `Ctrl+C` detiene el ciclo y vacía pendientes.

Este enfoque evita escaneos completos y carga el índice solo cuando hay actividad real, manteniendo el consumo bajo.

## Extensión a otros proyectos

- Los proyectos futuros (`Dedupe`, `Filelist`, etc.) pueden usar `IndexManager` y `IndexDatabase` para leer/actualizar el mismo `indexador.db`.  
- Basta añadir una referencia a `Indexador.Core` y reutilizar `IndexManager.GetRecords`, `BuildFileMap` o `FindDuplicates`.  
- Para evitar recalcular hashes, los consumidores pueden pasar rutas modificadas al watcher (`IndexWatcher`) o usar `UpdateEntries` directamente con la lista de cambios detectados.

## Próximos pasos recomendados

1. Integrar `Indexador.Tool --watch` en un servicio (PowerShell/Windows Service) que se ejecute automáticamente. Para facilitarlo se incluye el script `scripts/Start-IndexadorWatcher.ps1` (registra su propio log `IndexadorWatcher.log`, configurable mediante `-LogPath`), que invoca el CLI con parámetros recomendados, reintenta tras fallos y expone parámetros (`--root`, `--db`, `--hash`, `--debounce`).  
2. Crear scripts que expongan `--duplicates`/`--filemap` como reportes periódicos.  
3. Opcionalmente, añadir una interfaz REST o web para consultar el índice desde otros equipos.

## Documentación complementaria

- `docs/INDEXADOR.md`: mapa del motor core y las DTOs clave.  
- `docs/WATCHER.md`: flujo del watcher, parámetros de debounce y ejemplos de invocación.  
- `docs/SERVICE.md`: guía para registrar `scripts/Start-IndexadorWatcher.ps1` en una tarea programada o servicio Windows.  
- `docs/FILELIST.md`: describe el uso del nuevo `Filelist` CLI que lee el índice, aplica filtros y genera reportes de duplicados, top y mapa.  
- `docs/API.md`: describe cómo exponer el índice mediante la nueva API `Indexador.Api`.  
- `scripts/Monitor-IndexadorLog.ps1`: monitor ligero del `IndexadorWatcher.log` que detecta errores recientes.  
- `scripts/Backup-IndexadorDb.ps1`: copia periodica de `indexador.db` a una carpeta de respaldo con timestamp.
- `scripts/IndexadorHealthCheck.ps1`: script simple para verificar que la API responde `/summary` después de un reboot o despliegue.
- `scripts/Register-IndexadorWatcherTask.ps1`: wrapper para registrar el watcher como tarea programada (opciones como `-RunAtStartup`, `-Force`, `-ReplaceExisting` y `-Hash` ya vienen configuradas).
- `scripts/Run-PostRebootChecks.ps1`: ejecuta el checklist completo (tarea, API, monitor de log y backup) tras un reinicio.
- `scripts/Register-PostRebootChecksTask.ps1`: registra una tarea que dispara el check automático al iniciar el sistema.
- `scripts/Register-IndexadorMonitoringTasks.ps1`: agenda tareas periódicas para el health check y el monitor de log.
- `scripts/IndexadorControlCenter.ps1`: panel interactivo para ver estado, iniciar watcher, ejecutar checks y re-registrar tareas sin memorizar comandos.
- `scripts/Create-ControlCenterShortcut.ps1`: crea un acceso directo en el escritorio para abrir el centro de control con un doble clic.
- `docs/STATUS.md`: explica cómo diferenciar procesos legítimos (`MsMpEng`) y qué comandos usar para chequear qué bloquea el índice.

Con esta documentación el flujo del indexador y su watcher queda registrado para futuros compañeros. Puedes enlazar este `README.md` desde cualquier proyecto que consuma el índice. Posteriormente puedo ayudarte a generar plantillas de documentación más específicas (por ejemplo `docs/Watcher.md`). ¿Quieres que avance con eso?   
- `docs/CHECKLIST.md`: pasos rápidos para validar watcher, API, log y backup tras un reinicio.
