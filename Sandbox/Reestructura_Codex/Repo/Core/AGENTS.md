# AGENTS – Core

- Respeta `namespace = ruta de carpeta` (por ejemplo, `Neurologic.Core.FileSystem`).
- Proyectos de librería deben multi-target: `<TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>`.
- Mantén la lógica sin dependencias de UI; expón APIs reutilizables.
- Incluye pruebas automatizadas en `tests/` y ejecútalas con `dotnet test` antes de integrar cambios.
- Documenta nuevas API en el README del módulo.
