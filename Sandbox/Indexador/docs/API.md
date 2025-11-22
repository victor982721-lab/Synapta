# API del Indexador

El proyecto `Indexador.Api` es una API REST mínima que expone el catálogo compartido (`indexador.db`) para consultas externas sin necesidad de reindexar.

## Endpoints disponibles

- `GET /records`: devuelve cada archivo indexado (ruta relativa, tamaño, fecha y hash). Parámetros opcionales:
  - `root`: ruta raíz donde vive el índice (por defecto `Environment.SpecialFolder.UserProfile`).
  - `db`: ruta personalizada de `indexador.db`.
  - `extension`: filtra por extensión (ej. `.dll`).
  - `minSize` / `maxSize`: filtran por tamaño en bytes.
  - `limit`: límite de resultados.

- `GET /duplicates`: agrupa los archivos por hash (opcionalmente filtrados) y devuelve listas de duplicados por hash.
- `GET /map`: devuelve la estructura de carpetas (archivo, tamaño total, duplicados) según el índice actualizado.
- `GET /summary`: muestra resumen básico (total de archivos, tamaño total, grupos de duplicados/ficheros duplicados).

Los endpoints solo leen de `indexador.db` (no realizan hashes ni escaneos). Puedes protegerlos detrás de un reverse proxy o añadir middleware de autenticación si lo necesitas.
