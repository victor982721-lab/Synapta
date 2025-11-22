# Watcher en vivo

## Objetivo
El watcher nutre el índice en tiempo real reaccionando a eventos del sistema de archivos. Así evitas ejecuciones completas y actualizas solo lo realmente modificado.

## Cómo funciona

1. `Indexador.Tool --watch` construye un `IndexWatcher` con un `FileSystemWatcher` que escucha `Created`, `Changed`, `Deleted` y `Renamed`.  
2. Cada evento normaliza la ruta (`PathTools.NormalizePath`) y se añade a un conjunto sin duplicados.  
3. Un `Timer` interno aplica un **debounce** configurable (`--debounce <ms>`), agrupando todos los eventos que ocurren en un lapso corto (por defecto 1500 ms).  
4. Cuando el temporizador dispara, el watcher llama a `IndexManager.UpdateEntries` con el lote y descarta las rutas que ya no existen.  
5. El watcher escribe un resumen y vuelve a esperar nuevos eventos; presionar `Ctrl+C` detiene el ciclo y procesa los pendientes antes de salir.

## Ejemplo de invocación

```
dotnet run --project Indexador.Tool -- --root C:\Datos --watch --debounce 1000
```

- `--watch`: habilita el modo vivo.  
- `--debounce`: milisegundos de espera antes de ejecutar la actualización del lote (mínimo 200 ms).  
- `--root` y `--db`: funcionan igual que en el modo CLI normal; el watcher depende del índice existente para decidir qué necesita nuevo hash.  

## Buenas prácticas

- Mantén el watcher en un servicio (PowerShell, Windows Service o Scheduled Task) para que arranque automáticamente.  
- Balancea `--debounce`: valores más bajos detectan cambios más rápido, pero pueden generar más ejecuciones; ajusta según la frecuencia de trabajo.  
- Usa `--force` si sospechas que el índice está corrupto pero quieres evitar eliminar registros manualmente.  
- Si monitoreas múltiples roots, corre instancias separadas del watcher con sus respectivas bases (por ejemplo `C:\Datos` y `C:\Proyectos`).  

Documenta la ruta del archivo `indexador.db` para que el resto de los proyectos sepan dónde leer el catálogo actualizado por el watcher.
