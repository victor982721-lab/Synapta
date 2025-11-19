# Procedimiento para elaborar especificaciones técnicas (SOP) – Versión ampliada

Este documento actualiza la guía `SOP_SPECS.md` incorporando recomendaciones surgidas de la auditoría del repositorio. Su propósito es ayudar a redactar solicitudes de trabajo a agentes IA (como Codex) que generen proyectos coherentes con la arquitectura de Neurologic. Sigue un lenguaje normativo y evita mencionar capacidades del modelo.

## 1. Alcance

La especificación define las tareas que el agente debe realizar, el contexto en el que operará y las restricciones tecnológicas. Es aplicable a proyectos de nueva creación o extensiones de proyectos existentes bajo `Sandbox/`.

## 2. Secciones de la especificación

1. **[AGENTE_DESTINO]** – Identifica el agente al que va dirigida la petición: `Codex CLI`, `Codex Web` o `ChatGPT`.
2. **[MODO]** – Indica si la solicitud es de **generación de proyecto** (creará estructura y código) o **extensión/refactorización** (modificará un proyecto existente).
3. **[CONTEXTO]** – Describe el estado actual del proyecto, enlaces a documentación relevante, módulos de `Core` que deben reutilizarse y cualquier observación. Debe incluir rutas (relativas al repo) y destacar si el proyecto ya existe o se va a crear.
4. **[OBJETIVO_TECNICO]** – Enumera claramente los resultados esperados (por ejemplo, crear un CLI que indexe archivos NTFS y exponga un comando `scan`). Evita ambigüedades.
5. **[ALCANCE_FUNCIONAL]** – Lista las funcionalidades que se deben implementar y las que se excluyen. Usa lenguaje imperativo: “Debe realizar…”, “No debe …”.
6. **[INTERFAZ]** – Define la interfaz de usuario o API: comandos, argumentos, parámetros, menús, etc. Para CLI, incluye ejemplos de uso y descripción de flags.
7. **[ESTRUCTURA_ARCHIVOS]** – *NUEVA* – Define la estructura esperada del proyecto siguiendo la convención del ecosistema. Debe incluir subcarpetas:
   - `AGENTS.md` y `README.md` en la raíz del proyecto.
   - Carpeta `docs/` con `spec.md` (la propia especificación), `filemap_ascii.txt` (mapa ASCII generado tras crear el código), `table_hierarchy.json` (jerarquía de módulos), `plan.md` (flujo de tareas del agente) y cualquier documentación adicional.
   - Carpeta `csv/` con tablas que describan módulos, clases y componentes (una fila por entidad).
   - Carpeta `src/` con el código fuente y `tests/` con las pruebas.
8. **[DEPENDENCIAS_CORE]** – *NUEVA* – Lista los módulos de `Core` o librerías existentes que deben reutilizarse. Por ejemplo, “Reutilizar funciones de recorrido de NTFS en `Core.FileSystem`”. Si es una funcionalidad nueva, explicar por qué no existe en `Core`.
9. **[RESTRICCIONES_TECNOLOGICAS]** – Detalla lenguajes permitidos, frameworks de destino (multi‑target net8/net7/net6), uso de WPF o WinForms, módulos prohibidos, etc.
10. **[CRITERIOS_ACEPTACION]** – Define qué condiciones deben cumplirse para dar por finalizado el trabajo: compilación exitosa, tests que pasen, conformidad con la política de calidad, generación de artefactos en `docs/` y `csv/` y revisión del `Validate-Structure.ps1` sin advertencias.
11. **[PLAN_AGENTE]** – *NUEVA* – Resumen del flujo de trabajo sugerido. Por ejemplo: “Leer AGENTS del proyecto, localizar módulos en `Core`, generar plan breve de pasos, implementar código, actualizar documentación, ejecutar `Validate-Structure.ps1`”. Este plan puede basarse en el flujo de `/Plan` descrito en el AGENTS general【877231274733731†L12-L69】.

## 3. Normas de redacción

* Utiliza un tono **imperativo** y claro: “Debe generar…”, “No utilizará…”, “Se creará…”.
* No menciones que se trata de un modelo de IA; enfócate en la tarea y el contexto técnico.
* No utilices condicionales (“podría”, “si se puede”) ni lenguaje especulativo.
* Referencia las normas globales cuando proceda: menciona que debe respetar la política de reutilización y el multi‑targeting de proyectos.

## 4. Ejemplo de estructura

```
[AGENTE_DESTINO]
Codex CLI

[MODO]
generacion

[CONTEXTO]
Se creará un nuevo proyecto en Sandbox llamado FileHasher. No existe actualmente. Debe reutilizar Core.FileSystem para listar archivos.

[OBJETIVO_TECNICO]
Generar una herramienta CLI que calcule hashes MD5 y xxHash3 de archivos y los guarde en un CSV.

[ALCANCE_FUNCIONAL]
Debe:
  - Permitir especificar la ruta de origen con -Path.
  - Calcular hashes para todos los archivos en subcarpetas.
  - Exportar a CSV los campos: Ruta, HashMD5, HashXxHash3.
No debe:
  - Procesar archivos mayores a 2 GB.

[INTERFAZ]
Comando: filehasher
Argumentos:
  -Path <string>  Ruta de origen (obligatorio)
Ejemplo: filehasher -Path "C:\Datos\Proyectos"

[ESTRUCTURA_ARCHIVOS]
Se creará la carpeta Sandbox/FileHasher con:
  AGENTS.md, README.md, docs/, csv/, src/, tests/.
  docs/ contendrá spec.md, filemap_ascii.txt, table_hierarchy.json y plan.md.
  csv/ contendrá filehasher_root.csv.

[DEPENDENCIAS_CORE]
Debe reutilizar Core.FileSystem para enumerar archivos y calcular hashes.

[RESTRICCIONES_TECNOLOGICAS]
Uso de PowerShell 7.5.x y .NET 8.0. No utilizar WSL ni Python.

[CRITERIOS_ACEPTACION]
Compila sin errores, genera CSV con hashes, pasa pruebas incluidas y cumple Validate-Structure.ps1.

[PLAN_AGENTE]
1. Leer AGENTS general y de Neurologic.
2. Crear estructura de carpetas y archivos según ESTRUCTURA_ARCHIVOS.
3. Generar código en src/ reutilizando Core.FileSystem para la enumeración y cálculo de hashes.
4. Generar tablas CSV y docs.
5. Validar con el script Validate-Structure.ps1 y entregar artefactos.
```

Este formato actualizado permite a los agentes generar proyectos coherentes, con estructura y documentación uniformes. Al incluir secciones nuevas, se garantiza que se reutilicen los módulos existentes y que cada proyecto nuevo aporte de forma ordenada al ecosistema Neurologic.
