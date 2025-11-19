# Indexing

**Estado:** Plantilla inicial – Sin implementación aún.

El módulo **Indexing** proporcionará la infraestructura para crear, actualizar y consultar índices de archivos dentro del ecosistema Neurologic. Un índice es una estructura persistente que almacena metadatos (por ejemplo, nombre, ruta, tamaño, fechas y hashes) para permitir búsquedas rápidas y comparaciones de versiones.

## Funcionalidad esperada

* Crear índices iniciales a partir de un recorrido por el sistema de archivos usando `Core.FileSystem`.
* Actualizar un índice cuando cambien los archivos (creación, modificación, borrado) detectando sólo las diferencias.
* Consultar índices por diferentes criterios: ruta, extensión, tamaño, hash, etc.
* Exponer un API para que otros proyectos puedan almacenar sus propios datos adicionales en las entradas del índice (por ejemplo, etiquetas o notas).

## Diseño

* Debe apoyarse en `Core.FileSystem` para obtener la información base de los archivos.
* Guardará los datos en formatos estructurados (CSV, JSON o base de datos ligera) según la política de salidas estructuradas【240671532981222†L36-L50】.
* Debe ser agnóstico de la interfaz de usuario: ni el CLI ni la GUI deben influir en la lógica de indexado.
* Incluirá pruebas que cubran la creación y actualización incremental de índices.

## Próximos pasos

1. Definir el formato del índice y las clases principales (por ejemplo, `FileEntry`, `IndexStore`).
2. Implementar creación inicial de índice y carga desde disco.
3. Integrar con `Core.Search` para soportar consultas.
4. Documentar ejemplos de uso en este README y añadir pruebas.
