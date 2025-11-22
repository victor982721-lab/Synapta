# Filelist CLI

`Filelist` es una herramienta ligera que consume la base `indexador.db` generada por `Indexador.Core` y ofrece reportes orientados a auditorías, duplicados y estadísticas de tamaño.

## Flujo básico

1. Arranca el índice (por ejemplo con `Indexador.Tool --watch` o a través del scheduler) para que `indexador.db` esté actualizado.  
2. Ejecuta `dotnet run --project Filelist -- --root C:\Datos --list --duplicates` para leer la base y mostrar los archivos actuales.  
3. Puedes aplicar filtros con `--extension`, `--min-size` y `--max-size`; la tabla resultante sólo muestra los registros filtrados.

## Opciones disponibles

- `--list`: imprime cada archivo con ruta relativa, tamaño/hora y hash.  
- `--top <n>`: muestra los n archivos más grandes.  
- `--duplicates`: agrupa los archivos por hash y muestra los duplicados.  
- `--map`: imprime un mapa de carpetas con cantidad de archivos, tamaño total y duplicados.  
- `--extension <ext>`: filtra por extensión (ej. `.dll`).  
- `--min-size/--max-size`: filtra por tamaño mínimo/máximo en bytes.  
- `--no-summary`: suprime la cabecera resumen; por defecto se imprime.  
- `--verbose`: muestra métricas de carga.  
- `--db`: si no se indica, se usa `indexador.db` dentro del root configurado.

`Filelist` no recalcula hashes ni vuelve a indexar, así que es muy eficiente para consultas repetidas; depende del índice central y puede combinar con `IndexWatcher` o scripts personalizados.
