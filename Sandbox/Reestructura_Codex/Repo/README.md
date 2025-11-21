# Neurologic – Estructura propuesta

Este árbol replica la estructura recomendada en el informe **Reestructuración Integral del Repositorio**, organizada para mantener módulos reutilizables en `Core/`, proyectos experimentales en `Sandbox/` y utilidades comunes en `Scripts/`. Todos los artefactos siguen las normas culturales y técnicas globales, con preferencia por C# y PowerShell y proyectos .NET multi-target (net8/net7/net6).

## Carpetas principales
- `Core/`: librerías canónicas reutilizables (módulos FileSystem, Indexing y Search), cada una con `src/` y `tests/` multi-framework.
- `Sandbox/`: proyectos en desarrollo; cada proyecto tiene documentación (`docs/`), inventarios (`csv/`), código en `src/`, pruebas en `tests/` y su artefacto principal (`*.csproj` o `*.ps1`).
- `Scripts/`: herramientas globales de soporte que no pertenecen a un proyecto específico.

## Documentación obligatoria (raíz)
- `Politica_Cultural_y_Calidad.md`: principios culturales y estándar técnico mínimo.
- `AGENTS.md`: prioridades de reglas para agentes y desarrolladores.
- `Preferencias_del_Usuario.md`: expectativas de comunicación y entrega.
- `Repo_Estructura_ASCII.md`: mapa ASCII actualizado del repositorio propuesto.

Consulta los README y AGENTS de cada subcarpeta para instrucciones específicas.
