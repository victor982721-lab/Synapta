# AGENTS – Prueba2

Este documento complementa el AGENTS general de Neurologic y la Política cultural y de calidad. Define las reglas específicas para **Prueba2**. Sustituye los placeholders y elimina las notas una vez completado.

## 1. Entorno

* **Sistema operativo objetivo:** Windows 10 (mínimo).
* **Shell principal:** PowerShell 7.5.x (`pwsh`).
* **Lenguajes permitidos:** C# (.NET); PowerShell.
* **Target frameworks (si aplica):** net8.0;net7.0;net6.0. Mantén multi-target `net8.0;net7.0;net6.0` salvo justificación documentada.

## 2. Propósito del proyecto

Describe brevemente la finalidad de Prueba2 dentro del ecosistema Neurologic, indicando si genera artefactos reutilizables, una aplicación final o ambos.

## 3. Artefactos reutilizables requeridos

1. Lista explícita de módulos de Core o scripts compartidos que este proyecto debe reutilizar o producir. Ejemplo:
   * `Core.FileSystem` – Enumeradores NTFS (obligatorio).
   * `Prueba2.Scripts.Validate` – Nueva utilidad solicitada en `csv/artefacts.csv`.
2. Todo artefacto nuevo debe registrarse en `csv/artefacts.csv` y documentarse siguiendo `Procedimiento_de_solicitud_de_artefactos.md`.

## 4. Principios específicos

1. **Reutilización antes que reinvención** – Extiende los módulos Core antes de escribir lógica duplicada.
2. **Determinismo** – Misma entrada → misma salida. Documenta cualquier comportamiento no determinista.
3. **Separación de capas** – Mantén lógica de negocio desacoplada de UI/CLI. Usa namespaces que sigan la ruta de carpetas.
4. **Documentación viva** – Actualiza `docs/solicitud_de_artefactos.md`, `filemap_ascii.txt`, `table_hierarchy.json` y `plan.md` en cada iteración.
5. **Pruebas mínimas** – Incluye pruebas en `tests/` (xUnit/NUnit para C#, Pester para PowerShell) que cubran rutas críticas.

## 5. Entradas y salidas estructuradas

Describe el formato de entradas/salidas (JSON, CSV, NDJSON) y cómo deben consumirse desde otros proyectos.

## 6. Excepciones autorizadas

Lista cualquier excepción puntual al AGENTS general (por ejemplo, uso de un único framework) con su justificación y alcance temporal. Sin aprobación explícita, no se permiten excepciones.

## 7. Checklist antes de solicitar trabajo

1. Plantillas completadas (`AGENTS.md`, `README.md`, `docs/solicitud_de_artefactos.md`).
2. CSV actualizados (`modules.csv`, `artefacts.csv`).
3. Scripts obligatorios listados en `Scripts/`.
4. Ejecución reciente de `Scripts/Validate-Structure.ps1` sin errores.

