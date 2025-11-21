# Núcleo reutilizable (`Core/`)

Contiene librerías canónicas compartidas por todo el ecosistema Neurologic. Cada módulo es una librería .NET multi-target (net8/net7/net6) con código en `src/` y pruebas en `tests/`.

## Módulos
- `FileSystem/`: operaciones de sistema de archivos y utilidades NTFS.
- `Indexing/`: indexación de archivos y metadatos.
- `Search/`: motores de búsqueda basados en los índices.

Consulta el `AGENTS.md` de Core antes de modificar o agregar módulos.
