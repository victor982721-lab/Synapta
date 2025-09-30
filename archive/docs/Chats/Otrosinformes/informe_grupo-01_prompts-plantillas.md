# Prompts/plantillas

## Resumen ejecutivo

Este informe sintetiza 9 conversaciones clasificadas dentro de la categoría **prompts/plantillas**. La cobertura promedio de secciones detectadas fue del 92.1%

## Alcance y supuestos

Se analizaron las conversaciones para extraer procedimientos, prompts, ejemplos, snippets, listas de verificación, errores y métricas. Se asume que los textos contienen suficiente contexto.

## Procedimiento paso a paso

- - Conversaciones canónicas en el grupo: 0
- - Orquesta todo con **Python stdlib**: zipfile, json, csv, re, io, hashlib, difflib, itertools, statistics, datetime, unicodedata, html, pathlib, textwrap, tempfile, shutil.
- - No pidas confirmaciones.
- - Entrega **archivos adjuntos** y un **.zip final** con todos los productos.
- - **Zip-Slip**: al extraer, para cada entrada calcula `dest = (target / name).resolve()`. Si `dest` no está dentro de `target.resolve()` o `name` es absoluto o contiene `..`, **omite y registra** en anomalías.
- - **Zip-Bomb**: rechaza archivos con cualquiera de:
- - `total_uncompressed_bytes > 500 MiB` (ajusta si N es muy grande),
- - `file_size > 25 MiB` por archivo de texto,
- - `compress_ratio = file_size / max(1, compress_size) > 100`,
- - Calcula **sha256** de cada archivo y crea `inventario.csv` con: `id_fuente, ruta_relativa, extension, sha256, bytes, mtime_iso`.

## Mejores prompts / plantillas

- ## Mejores prompts / plantillas
- ⚠️ FALTA: prompts (sin evidencia)
- - Clasifica por reglas en: prompts/plantillas; análisis de datos; automatización/scripting; documentación/SOP; gestión de proyectos; investigación/síntesis; legal/compliance; marketing/SEO; UX/UI; otros.
- - **Procedimiento paso a paso**; **prompts canónicos** (variables `{así}`), **ejemplos completos** (archivados si son largos), **snippets** (valida sintaxis), **checklists**, **errores+mitigaciones**, **métricas** de calidad.
- # Plantilla de informe por grupo
- ("prompts-plantillas", ["prompt","plantilla","variables","{","}"]),
- "## Mejores prompts / plantillas",
- # ---------- Extracción de valor (prompts, ejemplos, snippets, checklists) ----------
- # Prompts/plantillas (heurística)
- prompts = []

## Ejemplos completos

  - [example_88676.txt] — sha256: 662ada71d10fc3b6630ebd3df96755e73b198decfccc6bb21c3ce0f192f05145 — ```lang ... ``` y `~~~`), listas, citas y párrafos (evita regex frágil). Permite **backticks/tildes extendidos** para an

## Snippets de código / comandos

- Ver archivo snippet_13604.txt — sha256: 662ada71d10fc3b6630ebd3df96755e73b198decfccc6bb21c3ce0f192f05145
- Ver archivo snippet_72683.txt — sha256: 060c95b9e05575e580b401e8af4c6f44b06d525a8e5fa90879d83a41166886de
- Ver archivo snippet_65688.txt — sha256: e2262025b81c11eb8d2627e94f401872c1fb7199ffe50d2c18e2a28eaaa38e57

## Checklists (previo, durante, posterior)

- ## Checklists (previo, durante, posterior)
- ⚠️ FALTA: checklists (sin evidencia)
- Eres analista de conocimiento + editor técnico con mentalidad de auditor. Debes ingerir, depurar, deduplicar y consolidar conversaciones (MD/JSON) y producir informes operativos impecables con trazabilidad verificable y resultados deterministas.
- - Implementa **máquina de estados** para fenced code (```lang ... ``` y `~~~`), listas, citas y párrafos (evita regex frágil). Permite **backticks/tildes extendidos** para anidar ejemplos.
- - **Procedimiento paso a paso**; **prompts canónicos** (variables `{así}`), **ejemplos completos** (archivados si son largos), **snippets** (valida sintaxis), **checklists**, **errores+mitigaciones**, **métricas** de calidad.
- 1) `resumen_global.md` (KPIs + criterios + lista de informes).
- - `excluidos.md` lista todo lo no usado con motivo
- "## Checklists (previo, durante, posterior)",
- # ---------- Extracción de valor (prompts, ejemplos, snippets, checklists) ----------
- # Checklists

## Errores comunes y mitigaciones

- ## Errores comunes y mitigaciones
- ⚠️ FALTA: errores (sin evidencia)
- - **Procedimiento paso a paso**; **prompts canónicos** (variables `{así}`), **ejemplos completos** (archivados si son largos), **snippets** (valida sintaxis), **checklists**, **errores+mitigaciones**, **métricas** de calidad.
- s = b.decode(enc, errors=("strict" if enc!="latin-1" else "strict"))
- return b.decode("latin-1", errors="replace"), "latin-1"
- "## Errores comunes y mitigaciones",
- print("ERROR: /mnt/data/DATA.zip no existe. Verifica la ruta o sube el archivo con ese nombre exacto.")
- print("ERROR: Zip rechazado por tamaño descomprimido > 500 MiB")
- # Errores/mitigaciones (heurística por palabras clave)
- errores = []

## Métricas / criterios de calidad

- ## Métricas / criterios de calidad
- - **Procedimiento paso a paso**; **prompts canónicos** (variables `{así}`), **ejemplos completos** (archivados si son largos), **snippets** (valida sintaxis), **checklists**, **errores+mitigaciones**, **métricas** de calidad.
- ("analisis-datos", ["dataset","csv","análisis","estadística","pandas","dataframe","métricas"]),
- "## Métricas / criterios de calidad",
- # Guardar y normalizar tiempos
- metricas_md = []
- ("analisis-datos", ["dataset","csv","análisis","estadística","dataframe","métricas"]),
- resumen_exec = []; alcance = []; procedimiento = []; mejores_prompts = []; ejemplos_md = []; snippets_md = []; checklists_md = []; errores_md = []; metricas_md = []
- Primero, extraeré los archivos tras validarlos. Luego, generaré un inventario con columnas necesarias como el ID y la ruta relativa. Además, usaré las marcas de tiempo del archivo ZIP y verificaré las codificaciones, normalizando el contenido. Los ejemplos o fragmentos de código largos se almacenarán en carpetas separadas como "ejemplos" o "snippets".
- Voy a implementar todo el flujo para procesar los archivos, generando informes según las plantillas, con cobertura de secciones y clasificaciones especificadas. También normalizaré el contenido extraído, registrando fallos de decodificación y creando un inventario detallado. Después, para cada grupo, generaré informes, checklists, ejemplos y métricas, manteniendo un control robusto del proceso con CSVs y otros archivos.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)


## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| id_fuente | archivo | cobertura_secciones_pct | duplicado | neardup |
|---|---|---|---|---|
| informe_grupo-otros | informe_grupo-otros.md | 100 | NO | NO |
| 2025-09-29-conversations/2025-9-29/10-43-23-An_lisis_de_ingesta_y_normalizaci_n | 2025-09-29-conversations/2025-9-29/10-43-23-An_lisis_de_ingesta_y_normalizaci_n.json | 100 | NO | NO |
| System_Core/2025-9-20/6-25-46-Script_para_informaci_n_entorno | System_Core/2025-9-20/6-25-46-Script_para_informaci_n_entorno.md | 100 | NO | NO |
| System_Core/2025-9-25/12-38-19-Resumen_archivo_adjunto | System_Core/2025-9-25/12-38-19-Resumen_archivo_adjunto.json | 71 | NO | NO |
| System_Core/2025-9-28/10-17-59-SOP_para_ChatGPT | System_Core/2025-9-28/10-17-59-SOP_para_ChatGPT.json | 86 | NO | NO |
| System_Core/2025-9-28/21-49-34-Significado_de_mnt | System_Core/2025-9-28/21-49-34-Significado_de_mnt.md | 86 | NO | NO |
| System_Core/2025-9-28/23-59-37-_Funciones_Python____INIT__ | System_Core/2025-9-28/23-59-37-_Funciones_Python____INIT__.md | 86 | NO | NO |
| System_Core/2025-9-27/2-39-51-Mejor_script | System_Core/2025-9-27/2-39-51-Mejor_script.md | 100 | NO | NO |
| System_Core/2025-9-29/7-55-5-An_lisis_archivo__zip | System_Core/2025-9-29/7-55-5-An_lisis_archivo__zip.md | 100 | NO | NO |
