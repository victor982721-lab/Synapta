# Investigación y síntesis

## Resumen ejecutivo

Este informe sintetiza 5 conversación(es) consolidadas del tema **Investigación y síntesis**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1. **Parámetros base**
2. **Construcción del contenido**
3. **Escritura y verificación**
4. **“Return summary”**
1. **Salida de consola (importante)**
2. **Conteo de caracteres vs bytes**
3. **Rutas en verify.ps1**
4. **`Write-Host` en PowerShell**
5. **Compatibilidad del verificador Bash**
6. **Permisos en `verify.sh`**
7. **Manifest consistente**
8. **Imports no usados**
9. **Nombre de campos**
10. **Robustez mínima**
1. **Gates canónicos**
2. **Nombres**
3. **Consistencia CV**
4. **Críticos**
5. **Reproducibilidad en gates**
6. **TTI**
7. **Audit capabilities**
1. **Cerrar las brechas de umbrales** (gates y métricas) con los cambios propuestos.
2. **Definir `set_base_csv` y `metodo_de_scoring`** (esquema, tamaño, fuente de verdad).
3. **Instrumentar secret scan** (herramienta/regex + reporte en `/05_riesgos/seguridad.md`).
4. **Completar `audit_capabilities_table` con fuentes** y etiquetas **[Oficial]/[Comunidad]** antes de usarla.
5. **Probar reproducibilidad** con 3–5 corridas deterministas y registrar `cv`, `repro_pct`, `TTI`.
1) `path` que cumpla `^/mnt/data/.+\.ps1$`, o
2) ensamblado por `fragments` + `file_name` (`*.ps1`), donde cada fragmento tiene `seq` ≥1 y `content` no vacío. fileciteturn0file0
1) Rellenas `Ejemplo.json` con tus scripts y opciones.
2) Lo envías como **request**.
3) Recibes un JSON de **reporte** y lo validas contra `Reporte.json` si quieres verificación estricta.
1. Subes el archivo .ps1.
2. Generaré un JSON de solicitud que siga el formato de Postmortem_v5.json, con el perfil "local-fixed", reglas predeterminadas de Ejemplo.json y la ruta del script.
3. Realizaré verificaciones estáticas como el análisis de la estructura y las reglas. No obstante, para comenzar necesitamos que subas el script.
1) Línea 12. Efecto secundario al importar módulo: `Set-Location -Path $PSScriptRoot`. Recomendado quitarlo del `.psm1`. Regla usada: R11 *(suposición de mapeo)*. Severidad: Medium.
2) Línea 176. Uso de `PSBoundParameters['OutputDir']` sin declarar `$OutputDir` en `param`. Código inefectivo. Regla usada: R08 *(suposición de mapeo)*. Severidad: Low.
1) Confirmación técnica de los hallazgos
2) Mejoras al protocolo/schema de postmortem (respaldadas)
3) Cambios mínimos sugeridos
4) Extensiones concretas al schema
1) Seguridad y efectos laterales
2) Calidad del módulo
3) Supply-chain y portabilidad
4) Artefactos y CI
1) Edita `request_template_ext.json` y reemplaza `REPLACE_ME`.
2) Valida contra `Postmortem_v5_ext.json`.
3) Ejecuta tu motor. Valida la salida contra `Reporte_ext.json`.
1) Identidad y estilo
2) Entorno objetivo
3) Política de entrega
4) Reglas de scripting PowerShell
5) Postmortem con ChatGPT como motor
6) Semillas doctrinales
7) Persistencia y Python
8) Navegación y verificación
9) Operación y foco
10) Preferencias adicionales

## Mejores prompts / plantillas

- 🧪 Ejemplo de Prompt para ChatGPT
- Create extended schemas and a request template based on existing schemas in /mnt/data.
- ---- Create request template with defaults and new extensions ----

## Ejemplos completos

- [ej_investigacion_sintesis_6-22-21-Lee_y_analiza_script.md] — sha256: 39c0ec42ec8a997bb5cb382c99ada24bb147ee87e139189d28167496ea8b5b99 — resumen

  ### Entrada (user)

  Lee y analiza por completo lo siguiente:

  ~~~~~

- [ej_investigacion_sintesis_6-7-43-An_lisis_SOP_01.md] — sha256: caece300ce11cd9b30626c1cdb1d0ce84e61dbd1825dc963ef6ac1f5989c1910 — resumen

  ### Entrada (user)

  Lee por completo y analiza a detalle lo siguiente:

  ```

- [ej_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos.md] — sha256: 5ee0ef3b71e27ba63d51d7544b121ecdca7697987d6d8c47b3b0eb03fba5f32a — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_investigacion_sintesis_7-25-19-Entendimiento_de_documento_JSON.md] — sha256: 368c7893865e82bbcecdcb3c20962faf9ebd7c6401968dfec4ca8091ffe1b696 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_investigacion_sintesis_4-2-30-Redacci_n_concisa_y_estructurada.md] — sha256: b6ac52333704d886cfcba56b991f47b413109272f0da4bc4325940adb689f960 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Usuario **multiproyecto** con enfoque en automatización, documentación reproducible y resultados verificables. Prefiere entregas listas para uso (scripts, reportes, `.zip`), con trazabilidad y citas. Valora calidad por encima de velocidad; no requiere portabilidad *nix a menos que lo pida. Trabaja con proyectos que combinan **instrucciones del proyecto + archivos**; evita depender de memoria.\nOther Information: Preferencias: respuestas **claras, accionables, sin relleno**; español técnico; encabezado con resumen y lista de entregables; nombres de archivos **ASCII**; cuando haya bloques con ``` internos, envolver con fence de **5 tildes**. Evitar “mínimos aceptables”; prefiere correcciones **proactivas** si detectas fallas.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Actúa como **Asistente PRO**: entrega en **un solo turno** artefactos útiles y verificados. Sé **proactivo**: si el pedido implica A y B, entrega ambos sin pedir permiso.  \nEvita alucinaciones; cita **fuentes oficiales** de OpenAI para capacidades y usa **web.run** cuando la información pueda haber cambiado. Etiqueta foros/medios como **[Comunidad/Prensa]**.  \nResponde en **español técnico**, conciso, con **resumen ejecutivo**, pasos de validación y enlaces de descarga **ASCII**. Si generas múltiples archivos, empaquétalos en `.zip`.  \nNo prometas trabajo futuro ni pidas confirmaciones triviales; solo pregunta ante bloqueos reales. Si hay Python disponible, úsalo para verificar cálculos/estructuras antes de entregar.  \nSi la tarea es “haz lo que tengas que hacer”, **completa el flujo extremo a extremo** con tu mejor esfuerzo.```"}

  ### Salida (assistant)

## Snippets de código / comandos

- [sn_investigacion_sintesis_6-22-21-Lee_y_analiza_script_001.txt] — sha256: c7a05718b53810b5be7a6e85e094d2b110ff3774f126e159ff7ab175d15949fc — resumen



  # Generate a comprehensive markdown report (>30,000 characters) per user request.
  import os, hashlib, json, textwrap, datetime, random


- [sn_investigacion_sintesis_6-7-43-An_lisis_SOP_01_002.txt] — sha256: b89e04a88acc95d0d4e4ac1eceeb99c90fe3df04525a91ee3f006065a9603e77 — resumen


  {
    "sop_id": "SOP-01",
    "name": "ANASTASIS_REVENARI",
    "version": "1.1.0",

- [sn_investigacion_sintesis_6-7-43-An_lisis_SOP_01_003.txt] — sha256: 09cb560e8369a93dbb774b0bebd65f8e94eb18a9c7ffb9d0b7c17754ef17d93b — resumen

  input: gov_pct, repro_pct, cv, tti_seconds, criticos_abiertos

  score_consistencia = 100 - min(100, cv*100)
  final_score = 0.35*gov_pct + 0.35*repro_pct + 0.30*score_consistencia


- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_004.txt] — sha256: eb21e3b259af945130b980ab21f380ffdd02d5aabdfaaa435cf02fc464a8c15c — resumen

  Gmail → OpenAI (GPT-4o Mini) → Slack / Google Sheets

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_005.txt] — sha256: eb21e3b259af945130b980ab21f380ffdd02d5aabdfaaa435cf02fc464a8c15c — resumen

  Gmail → OpenAI (GPT-4o Mini) → Slack / Google Sheets

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_006.txt] — sha256: 54d14a71181cf4fe86ad043d8383d42ab5b0c3b2dfd2d2c681a73575407c1f29 — resumen

  Resumen del correo electrónico:

  De: {Nombre del remitente}
  Asunto: {Asunto del correo}
  Fecha: {Fecha de recepción}

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_007.json] — sha256: 84434bcbff113b08b5c1558168205d05d450d169a21375a8faeb25b5fa023c64 — resumen

  {
    "remitente": "Juan Pérez",
    "asunto": "Reunión de seguimiento",
    "fecha": "2025-09-15",
    "resumen": {

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_008.txt] — sha256: 93c88d60c9db99f1fb78fd7747456c7aa3c8f76c5bcb92f72850fbf79debed52 — resumen

  Resume los correos electrónicos no leídos de hoy, agrupándolos por remitente y destacando los más urgentes.

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_009.txt] — sha256: 3f85d6dd6c5bfdc0c0f7836e9c7d436947f7ad7751f8bc22a472a1e1d5c24e04 — resumen

  Analiza mi estilo de redacción en Gmail y sugiere mejoras para hacerlo más profesional.

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_010.txt] — sha256: 97d70c020667f0991fa9bc0c72286e7a96cacf32e5be7f29cb19b79e4bf3c498 — resumen

  Revisa mis correos electrónicos recientes con [cliente/empresa] para ayudarme a preparar nuestra próxima llamada.

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_011.txt] — sha256: 9369cdd12cb99b256394932a7892cf7c388dfe5c322c691b3c572d37019889b1 — resumen

  Encuentra los tres documentos más relevantes sobre [tema] en mi Google Drive.

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_012.txt] — sha256: 4051ad4b9d4348103e11c8559ac28b924fd272023e2acdef7b08462089380df7 — resumen

  Analiza mis hojas de cálculo en Dropbox y extrae información sobre áreas donde podemos ahorrar.

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_013.txt] — sha256: f37c1a9d67151af32c5157a8ff6d070a5eea8f54440515161bd87f5aa928c532 — resumen

  "Resume los correos electrónicos no leídos de hoy y destaca los que requieren acción urgente."

- [sn_investigacion_sintesis_20-31-17-Resumen_autom_tico_correos_014.txt] — sha256: f37c1a9d67151af32c5157a8ff6d070a5eea8f54440515161bd87f5aa928c532 — resumen

  "Resume los correos electrónicos no leídos de hoy y destaca los que requieren acción urgente."

- [sn_investigacion_sintesis_7-25-19-Entendimiento_de_documento_JSON_015.json] — sha256: 7064f950592d11be2baa541b094005738d6f927318929550eeb6309c29983f1d — resumen

  {
    "quality_gates": {
      "pssa": { "fail_on": ["Error","Warning"] },
      "complexity": { "max": 10 },
      "help_coverage": { "min_pct": 90 },

- [sn_investigacion_sintesis_7-25-19-Entendimiento_de_documento_JSON_016.json] — sha256: 10c70959c4c94c803f7a4157d347cf141ff7f9ecde45d4665a5a0ec83f4a2565 — resumen

  {
    "tools": {
      "psscriptanalyzer": { "version": "x.y.z", "rules_run": ["..."] }
    },
    "metrics": {

- [sn_investigacion_sintesis_7-25-19-Entendimiento_de_documento_JSON_017.txt] — sha256: 236dd04ab21f84a3b070114578b96e5c3e21af2afe2f0fef72d39d812ffbbdbc — resumen

  {
    "session": "postmortem-seeds-01-08",
    "scope": {
      "files": [
        "/mnt/data/seed01.psm1",

- [sn_investigacion_sintesis_7-25-19-Entendimiento_de_documento_JSON_018.md] — sha256: 82e22d87a8734aa2558cccad631b71d2d223a6fbb5515d2d027075ae7c27c950 — resumen

  # Memoria Persistente — Operación, Postmortem y Prácticas de Código

  ## Objetivo
  Estandarizar cómo produzco y evalúo código en PowerShell 7, maximizando seguridad, calidad, reproducibilidad y trazabilidad. Documento diseñado para carga directa a memoria persistente.


## Checklists (previo, durante, posterior)

- - `report_chars` en el “resumen” se puebla con `os.path.getsize(report_path)` (bytes). Si el informe tuviera caracteres no ASCII, **bytes ≠ caracteres**. Si necesitas precisión, mide con `len(content)` antes de escribir o vuelve a leer y decodificar.
- - **Estilo de salida y objetivo operativo** (un turno, outputs listos, verificación y empaquetado).
- - **Bien diseñado** para generar **artefactos auditables** con garantía de longitud y **verificación criptográfica** inmediata.
- - Pequeños ajustes (salida JSON real, portabilidad de verificación, limpieza de imports y coherencia de manifest) lo llevarían a un nivel **production-grade** para pipelines o entregas automatizadas.
- - Eliminar `tti_min_seconds` salvo que se documente como anti-cheating; si se conserva, definir criterio (p.ej., runs <15s requieren verificación manual).
- - **Verificación:** Cove activo por defecto; hasta 2–4 preguntas por hallazgo (defecto 3); auto-chequeo `selfcheck_method` ∈ {`QA`,`NLI`} con umbral 0.6. fileciteturn0file0
- - **Verificación**: cove, guards, env
- - Verificación: Cove activo, 3 preguntas por hallazgo, `selfcheck: QA`, umbral 0.6.
- - Verificación: Cove activo, `selfcheck: "QA"`, umbral 0.6
- - Opcional de seguridad: añade a `metadata` el estado de firma Authenticode de cada archivo auditado y política de ejecución efectiva usada durante pruebas. citeturn3search1turn3search5
- - Cuando exportes dinámico con `$exports`, valida su contenido antes de `Export-ModuleMember`.
- - Añadir controles de "efectos secundarios del módulo" para detectar cambios en el directorio de trabajo actual (CWD) y mutaciones de variables de preferencia ($ErrorActionPreference, $ProgressPreference, $PSModulePath), con comparaciones antes/después.
- - Incorporar verificación de cumplimiento de "ShouldProcess" utilizando la regla de PSScriptAnalyzer para funciones que realicen operaciones.
- - Revisar `Export-ModuleMember -Function $exports` y validar la lista antes de exportar.
- - Defaults si el usuario no especifica: profile=local-fixed; consistency k=3 method=majority; verificación Cove activada; selfcheck="QA" umbral 0.6; reglas como en plantilla; emit ["snapshot","json","summary","sarif"]; salidas en /mnt/data/postmortem_v5 (JSON, snapshots, SARIF).
- - Defaults si el usuario no especifica: profile=local-fixed; consistency k=3 method=majority; verificación Cove activada; selfcheck="QA" con umbral 0.6; reglas como en Ejemplo.json; emit ["snapshot","json","summary"]; salidas en /mnt/data/postmortem_v5 (JSON y snapshots).
- - Parches .ps1 en 5 backticks: sanitizar fences, idempotente, renombrar Write-SessionInfoFile→Write-SessionInfoFile_Internal, insertar Export-SessionInfo antes de Export-ModuleMember si falta, exportar Export-SessionInfo, -Backup opcional, sin [CmdletBinding()] a nivel de script ni backticks sueltos.
- - Antes de asumir falta de acceso: listar/abrir/leer con Python.
- - Identificar pregunta y output esperado antes de ejecutar.

## Errores comunes y mitigaciones

- - El verificador usa `Write-Host` para el “OK”. Si sigues convenciones que **prohíben `Write-Host`**, cámbialo por `Write-Output` o `"`OK: ...`"` y mantén los errores con `Write-Error`.
- - La variable NonInteractive establece $confirmPref, pero no se aplica globalmente. Tal vez sea un error no asignar $global:ConfirmPreference.

## Métricas / criterios de calidad

- - **Entorno Windows y `<root>`** (validación de nombres/rutas, TZ America/Mexico_City).
- - **`scores[]` de `consistency_cv`**: ¿qué puntuación exactamente (gov/repro/final/otro)? Recomiendo usar **final_score de runs deterministas** o una métrica fija por caso.
- - Eliminar `tti_min_seconds` salvo que se documente como anti-cheating; si se conserva, definir criterio (p.ej., runs <15s requieren verificación manual).
- - `findings[]`: cada hallazgo incluye `id`, `rule` (catálogo fijo Sxx/Rxx/Axx/Qxx/Pxx), `category` (Seguridad|Robustez|Exactitud|Calidad|Privacidad), `severity` (Critical|High|Medium|Low), `confidence` [0,1], `verified` bool, `selfcheck` {QA|NLI, score [0,1], pass}, ubicación (`file`,`line`,`column`), `snippet`, `rationale`, `occurrences`≥1, `suppressed` bool; `fix_template/ fix_patch_hint/ group_id` opcionales. fileciteturn1file0
- - El uso de "Set-Location -Path $PSScriptRoot" dentro del módulo no es recomendado porque puede cambiar el directorio de trabajo del usuario. Esto afecta la **calidad** y **robustez**, con severidad media a alta.
- - Schema de salida: 5.0. Perfil: `local-fixed`. Validación interna conforme a tu contrato.
- - Incorpora resultados de pruebas Pester como evidencia adicional de calidad y reproducibilidad; persiste versión de Pester y resúmenes. citeturn3search0
- - **Validación de exportación**: usar Test-ModuleManifest y Export-ModuleMember.
- - Añadir métricas objetivas: complejidad ciclomática, longitud y anidamiento; calidad-gate configurable. citeturn3search2turn3search0
- - Categorías: Robustez=15, Calidad=9, Exactitud=1.
- - Validación: si el usuario proporciona schemas, valido solicitud y reporte contra ellos; en caso contrario uso validación interna equivalente.
- - Los scripts se entreguen en un único bloque de código, con: propósito, parámetros, ejemplos, validación de entradas y manejo de errores (try/catch con `-ErrorAction Stop`).
- - El usuario define schemas de solicitud y reporte; no fijar versión. Si no hay, usar validación interna equivalente.
- - Calidad y seguridad con principios consensuados

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-22-21-Lee_y_analiza_script.md | 56b20c11d9f92e7f45b04c88f200b155792575183d642acd4cdc28b3234df2b1 | Lee y analiza script | assistant, system, user | sí |
| 2025-9-29/6-7-43-An_lisis_SOP_01.md | 005a0b7f06f119304411aa24ff9b0cb4126a3eaae42a87ae8d4058c108fa7708 | Análisis SOP-01 | assistant, system, user | sí |
| 2025-9-15/20-31-17-Resumen_autom_tico_correos.md | e3ad1de2cedf84c14bb224ff06bcc5ed863c71708a001aa0151fb530337057bc | Resumen automático correos | assistant, system, tool, user | sí |
| 2025-9-20/7-25-19-Entendimiento_de_documento_JSON.md | b10e012ed72eed259203a77c3e7f313d41d06af2b91122e338cca069ab58e840 | Entendimiento de documento JSON | assistant, system, tool, user | sí |
| 2025-9-25/4-2-30-Redacci_n_concisa_y_estructurada.md | 28bfdc53050efe624c2179aca2785b18151e90bc192e4186da975f20050eeed6 | Redacción concisa y estructurada | assistant, system, user | sí |
