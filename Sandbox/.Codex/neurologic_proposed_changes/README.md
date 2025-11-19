# Neurologic – guía de trabajo consolidada

Este documento describe la finalidad del repositorio **Neurologic** y reúne las reglas que deben seguir todas las personas y agentes al colaborar en él. Está construido a partir de la política cultural, el AGENTS general y las preferencias del usuario.

## Objetivo del repositorio

El ecosistema Neurologic sirve como base para construir y compartir herramientas de análisis de archivos, indexación de sistemas de ficheros y utilidades CLI/GUI para Windows. El repositorio se divide en dos grandes áreas:

* **Core** – Librerías **multi‑target** (`net8.0`, `net7.0`, `net6.0`) que implementan motores reutilizables, como acceso al NTFS USN Journal, lectura recursiva de directorios, indexadores, mecanismos de búsqueda, etc.
* **Sandbox** – Subproyectos experimentales o aplicaciones de ejemplo (por ejemplo `Ws_Insights`, `RunTimeAnalyzerCLI`, `HybridCliShell`). Cada subcarpeta de `Sandbox` debe contener su propio `AGENTS.md`, `README.md`, carpetas `docs/` y `csv/` y scripts de ejemplo.

Las normas globales se establecen en la **Política cultural y de calidad** y el **AGENTS general**. Las reglas de un proyecto específico sólo pueden fortalecer estas normas, nunca rebajarlas. Las preferencias del usuario definen el estilo de interacción (idioma español MX, respuesta corta, scripts completos). Para detalles, consulta los archivos `Politica_Cultural_y_Calidad.md`, `AGENTS.md` y `Preferencias_del_Usuario.md` en el nivel raíz.

## Estado actual del repositorio

* `Core/` – Carpeta vacía que se llenará con librerías canon. Esta versión incluye plantillas (`FileSystem`, `Indexing`, `Search`) con proyectos `.csproj` multi‑target para que se añadan clases y pruebas más adelante.
* `Sandbox/` – Contiene subproyectos:
  * `Ws_Insights` – Biblioteca y CLI para crear índices de archivos; incluye documentación extensa en `docs/` y tablas en `csv/`.
  * `RunTimeAnalyzerCLI` – Ejemplo generado con especificación completa; utiliza la plantilla definida en esta guía.
  * `HybridCliShell` – Resultado de una petición sin especificación; carece de estructura normalizada y servirá como contraste.
* `.Codex/` – Herramientas auxiliares y módulos de terceros (PSScriptAnalyzer y Pester) que pueden instalarse localmente para evitar descargas externas. Ver `.Codex/README.md`.
* `Scripts/` – Utilidades de mantenimiento y validación (por ejemplo `Validate-Structure.ps1` y `Detect-MergeConflicts.ps1`).

## Uso de scripts

* **Validate-Structure.ps1** – Recorrido que comprueba que cada subcarpeta de `Sandbox` contiene los archivos obligatorios: `AGENTS.md`, `README.md`, `docs/`, `csv/`. Informa con advertencias cualquier falta.
* **Detect-MergeConflicts.ps1** – Busca marcadores de conflictos (`<<<<<<<`, `=======`, `>>>>>>>`) en los archivos versionados para evitar que se fusionen ramas con conflictos sin resolver.

Ejecuta estos scripts desde PowerShell 7.5.4 o superior:

```powershell
# Validar estructura de proyectos en Sandbox
pwsh -NoLogo -NoProfile -File .\Scripts\Validate-Structure.ps1 -RepoRoot "C:\Ruta\a\Neurologic"

# Detectar conflictos de merge
pwsh -NoLogo -NoProfile -File .\Scripts\Detect-MergeConflicts.ps1
```

## Cómo añadir un nuevo subproyecto

1. Crea una carpeta bajo `Sandbox/NombreDelProyecto`. Usa nombres descriptivos y evita espacios.
2. Copia las plantillas de `Templates/README_subproject.md` y `Templates/AGENTS_subproject.md` como `README.md` y `AGENTS.md` en la carpeta del nuevo proyecto y complétalas.
3. Crea un directorio `docs/` con:
   * `spec.md` – La especificación técnica formal basada en la plantilla de SOP (ver `docs/SOP_SPECS_updated.md`).
   * `filemap_ascii.txt` – Mapa ASCII de archivos y carpetas generado después de crear el código.
   * `table_hierarchy.json` – JSON con la jerarquía de módulos y componentes.
   * `plan.md` – Resumen del flujo de trabajo sugerido para agentes.
4. Crea un directorio `csv/` con tablas descriptivas de módulos (una fila por clase / componente).
5. Asegúrate de que el proyecto cumple la política de multi‑targeting (`net8.0;net7.0;net6.0`) y, si es una aplicación Windows/WPF, incluya `UseWPF=true`.
6. Ejecuta `Validate-Structure.ps1` para comprobar que no falta nada.

Esta guía pretende garantizar que todas las contribuciones sean coherentes, reproducibles y alineadas con las normas globales del ecosistema Neurologic.
