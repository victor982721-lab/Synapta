# Core – Librerías reutilizables

La carpeta **Core** aloja las librerías canon reutilizables de Neurologic. Su objetivo es centralizar la lógica común (lectura de ficheros, indexación, búsqueda, etc.) para evitar duplicar código en cada proyecto. Esta carpeta está actualmente vacía y se incluye aquí un esqueleto inicial para arrancar su desarrollo.

## Módulos previstos

El inventario descrito en `Repo_Estructura_ASCII.md` identifica tres módulos principales que deberán implementarse:

1. **FileSystem** – Acceso de bajo nivel al sistema de ficheros NTFS, lectura de USN Journal, notificaciones de cambios y utilidades de recorrido recursivo con filtros avanzados.
2. **Indexing** – Infraestructura para crear y actualizar índices de archivos, almacenar metadatos (hashes, tamaños, fechas) y exponer API para consultar y comparar versiones.
3. **Search** – Motores de búsqueda textual y de coincidencia (por nombre, ruta, contenido), construidos sobre los índices existentes.

Cada módulo tendrá su propia subcarpeta, proyecto `.csproj` multi‑target y un proyecto de pruebas. Por ahora se ofrecen plantillas vacías para permitir que cada componente crezca gradualmente.

## Cómo empezar a contribuir

1. **Crea la estructura** – Cada módulo debe tener su carpeta bajo `Core/` con la estructura recomendada en `Core/AGENTS.md`.
2. **Define la API** – Antes de escribir la implementación, diseña la API pública (clases, métodos, eventos) y consúltala con el equipo para asegurar que cubrirá los casos de uso.
3. **Implementa con pruebas** – Añade la lógica en `src/` y crea pruebas en `tests/`. Utiliza Pester para scripts de PowerShell o xUnit para C#.
4. **Documenta** – Mantén actualizado este README y el `README.md` de cada módulo con instrucciones de uso y ejemplos.
5. **Cumple las políticas** – Sigue los principios de reutilización, determinismo y respeto al trabajo previo tal como se recoge en la Política cultural y el AGENTS general【240671532981222†L10-L28】【209859175334907†L96-L117】.

Esta carpeta aún no contiene código, pero la planificación de su estructura permite a los contribuyentes alinear sus aportaciones con las normas globales y sentar las bases de un ecosistema ordenado y mantenible.
