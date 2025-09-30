# Gestión de proyectos

## Resumen ejecutivo

Este informe sintetiza 12 conversación(es) consolidadas del tema **Gestión de proyectos**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1. Normalizar ortografía y capitalización (lista de typos y correcciones propuesta en §6.1).
2. Unificar la regla de “FECHA ABSOLUTA YYYY-MM-DD” en una sola cláusula normativa (sección REGLAS DURAS).
3. Fijar rango de citas web.run a **5–7** fuentes oficiales + 1–2 de comunidad con fecha absoluta.
4. Explicitar zona horaria por defecto para sellos y nomenclatura de archivos (`YYYYMMDD-HHMMSS`).
5. Establecer ruta canónica para CSV dentro del ZIP (p.ej., `/data/*.csv`).
6. Aclarar política PS 5.1 vs PS 7 (objetivo primario; compatibilidad opcional si el target lo permite).
7. Sustituir referencias dudosas/antiguas (p.ej., “Codex CLI/Cloud”) por denominaciones vigentes **durante la ejecución real** (se valida con web.run).
1) Normalizar ortografía/capitalización y eliminar repeticiones.
2) Unificar la regla de **FECHA ABSOLUTA (YYYY-MM-DD)** en una sola cláusula.
3) Fijar un rango único de citas externas (p.ej., **5–7** fuentes oficiales + 1–2 de comunidad).
4) Declarar zona horaria por defecto (sug.: America/Mexico_City) para sellos y nombres de archivo.
5) Establecer ruta canónica para CSV dentro del ZIP (p.ej., `/data/*.csv`).
6) Precisar la política PS 5.1 vs PS 7 (objetivo primario PS 5.1; PS 7 opcional si el target lo permite).
7) Sustituir referencias potencialmente desactualizadas (“Codex CLI/Cloud”, “AGENTS.md”) al ejecutar la verificación real.
1) **Dimensiones y pesos** suman 100 (20+20+15+15+10+10+10) → marco equilibrado.
2) **Procedimiento** en 7 pasos: cubre inventario, límites de tamaño, consistencia PI↔CI, proactividad, citas, entregables y reporte.
3) **Plantilla y prompt operativo**: facilitan ejecución en un solo turno (“un turno = valor”).
4) **Énfasis en trazabilidad**: distingue **[Oficial]** vs **[Comunidad/Prensa]**.
5) **Operativa de archivos**: pide nombres ASCII, empaquetado y guía de uso (reduce fricción).
1) **Fijar límites exactos**: CI ≤ **1500** chars por campo; PI ≤ **8000** chars (duros, no “aprox.”).
2) **Definir scoring operativo**: por dimensión, distribuir puntos en sub-checks con pesos y **penalizaciones proporcionales**.
3) **Patrones proibidos**: lista mínima (e.g., `mañana|luego|después|te avisaré|haré en otra iteración|espera|pronto|en próximas versiones`).
4) **Fuente de verdad Memoria**: requerir **captura UI** + texto de estado (“OFF” / “Project-only”).
5) **Citas mínimas**: toda afirmación sobre capacidades/planes → ≥1 cita **[Oficial]**; noticias/rumores → **[Comunidad/Prensa]** + fecha.
6) **Operativa de archivos**: exigir `manifest.json` (nombre, tamaño, sha256), `README.md` (uso), y **ZIP ASCII**; opcional `hashes.txt`.
7) **Consistencia PI↔CI**: matriz de conflictos con campo “Resolución: prevalece PI / ajustar CI / mover a archivo”.
8) **Auto-verificación**: incluir checklist final (sí/no) y cómputo automático de caracteres por campo.
9) **Reporte reproducible**: añadir sección “Cómo se midió” (comandos/pasos) y versión del protocolo.
10) **Historial**: numerar protocolo (vX.Y) y fecha para trazabilidad.
1) **Contexto/alcance.** Se corrigen desfases previos. Toda corrección al documento requiere **evidencia oficial actualizada**.
2) **Misión.** Entregables accionables, español técnico.
3) **Reglas duras.**
4) **Instrucciones generales.** Project_Instructions es la fuente prioritaria; `Custom_Instructions.md` solo histórico.
5) **Entorno.** Trabajo desde `Repo_Anastasis_Revenari.zip` y espejo `C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari`.
6) **Flujo por defecto.** Comprensión silenciosa → plan breve → ejecución con validación → entrega → evidencia.
7) **Protocolos.**
8) **Políticas.** Ética/orden/trazabilidad; cambios sustanciales ⇒ changelog.
9) **Trazabilidad web.** Citar OpenAI [Oficial]; etiquetar comunidad/prensa; reportar discrepancias.
10) **Deprecaciones.** `Custom_Instructions.md` ⇒ `*_Otros_\Deprecated\` + stub.
11) **Anexos.** Lista de protocolos y políticas relacionadas.
1) **“filemap vigente” no definido.**
2) **Marcadores de reemplazo no estandarizados.**
3) **Dependencias de calidad no garantizadas.**
4) **Entorno Windows hard-coded.**
5) **Empaquetado/enlaces no automatizados.**
6) **Deprecación de `Custom_Instructions.md` sin stub definido.**
1) **Anclar versiones mínimas** (PS 7.x, Pester ≥ X, PSScriptAnalyzer ≥ Y) en una tabla al inicio del §5 “Entorno”.
2) **Norma de marcadores** (prefijo `AR:` obligatorio, casing, no anidación) + ejemplos buenos/malos.
3) **Definir formato de changelog**: CSV-like de una línea o YAML/JSON por entrada; hoy es libre.
4) **Agregar preflight** (script referenciado desde `scripts\preflight.ps1`) con checks y salida de diagnóstico.
5) **Especificar política de línea de comandos**: codificación UTF-8, saltos CRLF, prohibición de `Write-Host` y uso de `-ErrorAction Stop` en scripts del repo.
6) **Sección de empaquetado**: nombre de release y artefactos mínimos (`.zip`, `manifest.json`, `hashes.txt`).
1. **Umbrales “aprox.”**: CI ~1500 c/u y PI ~8000 “aprox.”; falta rango tolerado y regla de redondeo ⇒ riesgo de inconsistencia.
2. **Definición de fuentes**: distingue [Oficial] vs [Comunidad/Prensa] pero no prescribe dominios válidos ni formato de cita.
3. **Extracción de CI/PI**: no especifica método de obtención (UI/API/capturas) ni cómo manejar versiones.
4. **Reglas de precedencia**: “Proyecto debe prevalecer” sin detallar conflicto parcial (p. ej., contradicciones por sección).
5. **Métrica de puntajes**: pesos están, pero falta fórmula de cálculo, escalas por sub-criterio y criterio de “sin datos”.
6. **Operativa de archivos**: pide ASCII/zip/guía, pero no fija esquema de nombres, estructura de carpetas ni checksum.
7. **Detección de promesas**: solicita prohibir “prometer luego” pero no define patrón de detección ni lista de frases gatillo.
8. **Memoria**: exige confirmar estado, pero no define evidencias mínimas (captura, texto de UI) ni cómo reportar si no aplica.
9. **Límites de campos**: no aclara si cuentan espacios, saltos de línea o markdown; tampoco define normalización (UTF-8, \r\n).
10. **Trazabilidad**: no incluye matriz instrucción→evidencia para auditar contradicciones y vigencia.
1. **Umbrales duros**: CI ≤ 1 500 chars (tolerancia +10% → *warning*, >1 650 → *fail*). PI ≤ 8 000 (+10%/*warning*, >8 800/*fail*). Conteo por *Unicode graphemes*, normalizando `\r\n → \n`.
2. **Fórmula de puntaje**: cada dimensión 0–100 por rúbrica; score total = Σ(peso_i × score_i)/Σ(pesos). “Sin datos” ⇒ 0 por sub-criterio.
3. **Formato de citas**: `[Oficial|Comunidad] — Título, Dominio, Fecha ISO, URL`. Lista blanca sugerida para *Oficial* (docs del proveedor, dominios *.openai.com*, *.microsoft.com*, etc.).
4. **Precedencia**: si PI y CI chocan, marcar *Conflicto-Alto*, prevalece PI; registrar sección/ID y acción correctiva.
5. **Evidencia de Memoria**: incluir texto exacto del estado + captura (si disponible) o transcripción UI; si N/A, justificar.
6. **Operativa de archivos**: imponer convención `AAAA-MM-DD_[Slug]` (ASCII, `-` y `_`), árbol `/docs /scripts /data /out`, y `SHA256SUMS.txt`.
7. **ZIP estandarizado**: `{fecha}_{proyecto}_audit_bundle.zip` con manifest (`manifest.json`: versiones, hashes, tamaños).
8. **Detección de promesas**: regex sugeridas:
9. **Checklist de consistencia**: matriz instrucción→evidencia con estado (OK/Gap/Conflicto) y vigencia (fecha/versión).
10. **Salida canónica**: además de texto, emitir `JSON` con breakdown por dimensión, hallazgos (sev, evidencia, acción), y totales.
11. **Validación de límites**: contar caracteres por campo y reportar `% usado`; incluir tabla de medidas.
12. **Guía de uso**: añadir paso “cómo extraer CI/PI” (p. ej., copiar texto de los 3 campos y PI en bruto; no resúmenes).
1) Corre **RED-TEMARIO** → 2) Ajusta con **Vic** → 3) Genera script bajo **README/AutoQA** (ideal con **esqueleto**) → 4) Si editas docs, aplica **backup + actualizado** con timestamp → 5) Fuera del proyecto, usa **mensajeinicial**.
1) **Nombres/versionado**
2) **“Vic (2).md”**
3) **Alcance de versión de PowerShell**
4) **AutoQA: definición de “un único bloque”**
5) **Preflight manual vs. automatizable**
6) **Permisos y cambios de sistema**
7) **Política de “no pegar completos en chat”**
1) **preflight.ps1** (automatiza TEMARIO) → `preflight.json/md`
2) Leer **Vic.md** → “switches” de compatibilidad/seguridad
3) Crear script desde **esqueleto** → pasar **AutoQA** + `PSScriptAnalyzer`
4) Si se tocan docs: **backup + actualizado** (timestamp) y **tabla de artefactos** con hashes
5) Cerrar con **DoD**: checklist “Script Canónico” + logs/auditoría
1) **TTI inconsistente**
2) **Críticos: permitido vs. prohibido**
3) **Precedencia**
4) **FSM sin guardas completas**
5) **Unidades y nombres**
6) **Evidencias sin fuente**
7) **Reproducibilidad no enlazada a gates**
8) **TTI mínimo**
9) **Redundancias menores**
1. **Claridad y enfoque** — 20
2. **Proactividad y contrato de entrega** — 20
3. **Trazabilidad** — 15
4. **Arquitectura de contexto** — 15
5. **Operativa de archivos** — 10
6. **Actualización y UI** — 10
7. **Calidad de entregables** — 10
1. **Inventario**: extraer textos CI/Proyecto + listar archivos y **tamaños**.
2. **Límites**: verificar presupuestos de caracteres (CI ~1500 c/u; Proyecto ~8000 aprox.).
3. **Consistencia**: detectar contradicciones CI ↔ Proyecto (prevalece Proyecto).
4. **Proactividad**: cazar promesas futuras o preguntas innecesarias.
5. **Citas**: exigir **[Oficial]** para capacidades/planes; usar **[Comunidad/Prensa]** como apoyo.
6. **Entregables**: nombres ASCII, `.zip` cuando aplique, e **incluir guía de validación**.
7. **Reporte**: puntuar por dimensión + lista de acciones (máx. 10).
1) **Definición de “Oficial”**: no lista fuentes canónicas (p.ej., dominios de documentación/estado del producto).
2) **Medición exacta**: dice “~1500/8000 aprox.” pero no especifica **qué cuenta** (caracteres vs. bytes; incluye espacios/markdown; cómo tratar citas).
3) **Severidades**: no define **criterios de frontera** entre Crítico/Alto/Medio/Bajo.
4) **Escalas de puntaje**: no provee **anclas** (qué significa 10/20 en “Claridad”, por ejemplo).
5) **“Actualización y UI”**: el término “UI” puede confundirse (¿interfaz del proyecto, del modelo, o simple **verificación de estado**?).
6) **Trazabilidad**: aclara **tipos** de fuentes, pero no define **formato de cita** ni límites de cita/quote.
7) **Archivos**: pide nombres ASCII y `.zip`, pero no define **validaciones extra** (hashes, estructura mínima, límites de profundidad).
8) **Memoria**: contempla OFF o project-only, pero no precisa **cómo auditar consecuencias** (riesgo de dependencias ocultas, datos pegajosos).
9) **Detección de “promesas”**: no define un **lexicón** o patrones para evitar falsos positivos/negativos.
10) **Top-10 Acciones**: buen límite, pero no hay **regla de deduplicación** para no repetir acciones sin micro-variante.
1) **Fuentes “Oficial”**: enumerar dominios canónicos (p.ej., `openai.com`, docs oficiales del proveedor, changelogs del producto) y marcar todo lo demás como **[Comunidad/Prensa]**.
2) **Recuento**: fijar **caracteres Unicode** (incluye espacios/markdown) y **reportar métricas**: `len_total`, `len_sin_citas`, `%citas`.
3) **Severidades**: definir **reglas** rápidas:
4) **Anclas de puntaje por dimensión** (0/5/10/15/20 o 0/3/6/8/10 según peso) con descriptores observables.
5) **Renombrar la dimensión 6** a **“Estado y verificación”** (en vez de “Actualización y UI”) para evitar confusión; checklist: memoria=OFF/ON, proyecto activo, límites medidos, fecha de última actualización.
6) **Formato de cita**: exigir al menos **fuente + fecha** y, si aplica, **URL** (o ID) con límites de cita (≤25 palabras por fuente no-lírica).
7) **Archivos**: añadir **estructura mínima** (ej. `/docs`, `/config`, `/src`, `/results`), límite de profundidad y **hashes** (SHA-256) en el reporte.
8) **Memoria**: incluir prueba de **no dependencia** (el proyecto debe funcionar igual con memoria OFF).
9) **Lexicón anti-promesas**: listar patrones (“te aviso luego”, “lo haré después”, “próxima iteración”, “espera mientras”, “más tarde”, “cuando tenga…”) y penalizar su presencia.
10) **Plantilla**: incluir **tabla** con char-counts por campo y **matriz** CI vs Proyecto con contradicciones específicas (cita del texto en conflicto).
1. Claridad y enfoque — _/20_
2. Proactividad y contrato de entrega — _/20_
3. Trazabilidad — _/15_
4. Arquitectura de contexto — _/15_
5. Operativa de archivos — _/10_
6. Estado y verificación — _/10_
7. Calidad de entregables — _/10_
1) Te pide un **root** (por defecto: `$HOME\mnt`).
2) Te pide la **ruta del proyecto** (o subruta bajo el root, según la versión de asistente que quede activa; ver “ojo” abajo).
3) Si no existe, te pregunta si la crea.
4) Inicializa plantillas globales bajo `<root>\config\...` si faltan.
5) Muestra un menú:
1) **Eliminar la duplicidad** de `Start-WorkspaceWizard` y **mantener la versión segura** que usa `Resolve-UnderRoot`.
2) Si necesitas flexibilidad, añade un switch (p. ej. `-AllowOutsideRoot`) y por defecto **restringe** al root.
3) (Opcional) Añadir un comando para **materializar** (crear) el árbol del `filemap.json` cuando lo desees (separado de la validación).
4) Devolver objetos (no sólo `Write-Host`) para poder **scriptar** el proceso en pipelines.
5) Validar que `filemap.json` tenga `tree` antes de intentar ShowPlan (ya lo hace), y considerar **esquema**/versión.
1. Revisa de forma recursiva el interior de este .zip
2. Lee los documentos al interior.
3. Explica la estructura observada.
4. Explica el contenido de los archivos.
1) Verifica dónde compraste: web o Google Play.
2) Si es web, usa el chat del Centro de Ayuda para solicitar el reembolso.
1) Si es web, pide reembolso a través del Centro de Ayuda.
2) Si en Google Play, solicita reembolso vía Centro de Ayuda (puede tomar de 5 a 7 días hábiles).
3) Cancela la renovación automática si decides cambiar de plan.
1) **Si pagaste en la web (chatgpt.com):** desde tu cuenta abre el **Help Center** y usa el **chat** (abajo-derecha) para solicitar **reembolso del cobro de hoy** explicando que vas a cambiar de plan. Si te lo aprueban, lo procesan en **5–7 días hábiles**. citeturn2search0
2) **Si pagaste vía Google Play (Android):** la solicitud también se gestiona por el **Help Center**; los reembolsos aprobados tardan **hasta 10 días hábiles**. citeturn2search0
3) **Excepción legal (por si aplica):** en **UE, Reino Unido o Turquía** existe “ventana de 14 días” para cancelar y pedir reembolso (OpenAI la reconoce; el reembolso es **prorrateado desde la fecha de solicitud**). Si no estás en esas regiones (ej. México), depende de lo que autorice soporte. citeturn2search2turn2search0
4) **Luego compra el plan deseado** (en la web: Perfil → Plan → **Get Pro** / **Manage plan**). citeturn3search1turn1search11

## Mejores prompts / plantillas

- 8) Plantilla de reporte (refinada)
- Flujo de comandos (plantilla PowerShell 7)
- 6) Plantilla refinada de reporte (lista mínima)
- 7) Prompt operativo (ajustado, auto-contenible)
- Plantilla de reporte (ejemplo)
- Prompt operativo
- 8) Plantilla de reporte mejorada (lista para pegar)
- 9) Prompt operativo (ligeramente pulido)

## Ejemplos completos

- [ej_gestion_proyectos_6-50-15-An_lisis_de_protocolo_SOP01.md] — sha256: 7760d60020da25cbe9caf01d9d9f803228a2f3175eb9a69dccc0a0befe5119d9 — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_gestion_proyectos_6-34-30-An_lisis_protocolo_auditor_a.md] — sha256: 8537a6f937b6d07bce0f377d81e3c88b638ae0e519223aa52c0a8dd77035ac3e — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_gestion_proyectos_6-29-54-An_lisis_de_instrucciones.md] — sha256: e22c3b6eb2f2d2347331cce964abc9462de70e9da3ec01b8352c4ba1e6a2b221 — resumen

  ### Entrada (user)

  Lee y analiza por completo lo siguiente:

  ~~~~~

- [ej_gestion_proyectos_6-31-26-Auditor_a_de_configuraci_n.md] — sha256: 0df33c312c06a08c2d3e65c58bcb052e17041e110e0edb4261034ee159c1ed38 — resumen

  ### Entrada (user)

  Lee y analiza por completo lo siguiente:

  ~~~~~

- [ej_gestion_proyectos_6-11-18-An_lisis_de_documentaci_n_PS.md] — sha256: 9d9580712fb4beb2704aa1bde92e64a05f295c5374eca04a7eb793dbc39c0f53 — resumen

  ### Entrada (user)

  Lee y analiza por completo lo siguiente:

  ```

- [ej_gestion_proyectos_5-48-30-_SOP_01___An_lisis__03_.md] — sha256: 9cd1f79bc5627a6645bf84b5bc93a2df34172c12d4b64adedcda7fd2053f1cb3 — resumen

  ### Entrada (user)

  Analiza la siguiente configuración:

  ```

- [ej_gestion_proyectos_5-36-5-_SOP_01___An_lisis__01_.md] — sha256: 668a12082b2d814643a2391bbb2f925080d9647cdcabfbbc5caaff6fdcc81f77 — resumen

  ### Entrada (user)

  Parsea por completo lo siguiente y dame un análisis de lo siguiente:

  ~~~~~

- [ej_gestion_proyectos_5-22-31-_WsW_Contexto_.md] — sha256: de50c4ec6ac27e4b9ef90cb11b9acf58ea7f7db3b9410426e66c58169b555d75 — resumen

  ### Entrada (user)

  Analiza y explica que entiendes con lo siguiente:

  ```

- [ej_gestion_proyectos_5-16-29-_WsW_Script_.md] — sha256: 61dc1f1a87f9bc3a4fa8f92ed697f10fcd6508a94bcd19ce6b8b7d91813225d5 — resumen

  ### Entrada (user)

  Analiza y explica que hace el siguiente script:

  ```

- [ej_gestion_proyectos_4-58-47-_WsW_mnt_.md] — sha256: 20ea8cf125f087ce89f3c4d67ae77415adc3f54bf7e7544f7cc4ef141b89981a — resumen

  ### Entrada (user)

  1. Revisa de forma recursiva el interior de este .zip
  2. Lee los documentos al interior.
  3. Explica la estructura observada.

- [ej_gestion_proyectos_21-20-2-Asistencia_de_ChatGPT.md] — sha256: ccbc532950a4012f32a738c46d1cffdf0e118727f51e3b6eb975e91627d77d4b — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_gestion_proyectos_18-1-52-Cambio_de_membres_a_Plus.md] — sha256: ca4eba4d2aa403becc232dcab22f04fc6d351d11730c7d39dfd208ccb75ecc3a — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

## Snippets de código / comandos

- [sn_gestion_proyectos_6-50-15-An_lisis_de_protocolo_SOP01_001.txt] — sha256: 6ca1eebefaabf9d7449e3ce85fe9d08506043d8a37030b5faf1cad6a15918741 — resumen



  # [STANDARD OPERATIONAL PROCEDURE #01 - "ANASTASIS_REVENARI"] (**PROTOCOLO DE ARRANQUE DE NUEVAS SESIONES**)

  ---

- [sn_gestion_proyectos_6-34-30-An_lisis_protocolo_auditor_a_002.txt] — sha256: f3300833a19009c96856a1934b29fa6ad47e0a881e43f938837219a9c832badd — resumen

  # Auditoría de Configuración de Proyecto — **Protocolo General**
  **Objetivo.** Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.

  ## Entradas requeridas
  - Texto actual en **Project Instructions** y en **Custom Instructions** (los 3 campos).

- [sn_gestion_proyectos_6-29-54-An_lisis_de_instrucciones_003.txt] — sha256: 08ddb1054b37f868523695a9680fd63c1db385d51e6253bf95b22b8245615cd2 — resumen

  # Project_Instructions — Auditoria (memoria cerrada)

  **Versión:** v2.0 · **Fecha:** 2025-09-25 22:52:34Z · **Ámbito:** Este documento rige sobre cualquier instrucción global o de sistema cuando la sesión se encuentre dentro del proyecto Auditoria (memoria cerrada).  
  **Precedencia:** Project_Instructions > Protocolos > Políticas > Filosofía > _Otros_.


- [sn_gestion_proyectos_6-29-54-An_lisis_de_instrucciones_004.ps1] — sha256: 618cb52893c071d23f7fce1e732c17a26928a5136c51f9f927104a3f29af4c6e — resumen

  #requires -Version 7.0
  # 1) Resolver repo (permite override por env var)
  $RepoRoot = if ($env:ANASTASIS_REPO_ROOT) { $env:ANASTASIS_REPO_ROOT } else { 'C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari' }
  Set-Location -LiteralPath $RepoRoot


- [sn_gestion_proyectos_6-31-26-Auditor_a_de_configuraci_n_005.txt] — sha256: f3300833a19009c96856a1934b29fa6ad47e0a881e43f938837219a9c832badd — resumen

  # Auditoría de Configuración de Proyecto — **Protocolo General**
  **Objetivo.** Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.

  ## Entradas requeridas
  - Texto actual en **Project Instructions** y en **Custom Instructions** (los 3 campos).

- [sn_gestion_proyectos_6-11-18-An_lisis_de_documentaci_n_PS_006.txt] — sha256: d167e5897b9fa604a341bcb047cabf45002704b08b832d1ef304c7a0aa2ea068 — resumen

  ¡Claro! Este proyecto tiene “piezas” muy específicas y se encajan así:

  * **README_actualizado_YYYYMMDD-HHMMSS.md**
    Es la guía de operación: define rol y alcance (PS 5.1), flujo de trabajo, estándar de implementación y la **AutoQA** (reglas de salida) que todo script debe cumplir: `#requires 5.1`, un único bloque, cabecera `.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE`, validaciones, `try/catch` con `-ErrorAction Stop`, opción `-RequireAdmin`, prohibición de `Write-Host`, “Script Canónico”, etc. También fija cómo editar documentos (backup + archivo actualizado, sin pegarlos completos en chat).


- [sn_gestion_proyectos_5-48-30-_SOP_01___An_lisis__03__007.txt] — sha256: 335c6642e1c662e93196f1fc0553e90199f8569bce77cbc386a30fd899584454 — resumen

  {
    "sop_id": "SOP-01",
    "name": "ANASTASIS_REVENARI",
    "version": "1.1.0",
    "audience": "ChatGPT",

- [sn_gestion_proyectos_5-48-30-_SOP_01___An_lisis__03__008.json] — sha256: b7d5bd616eeddd25aa58c9d9d793e06f770b622f92be4ae084e26815671a1b5d — resumen

  {
    "parse_rules": {
      "precedence": "contract_guardrails",
      "ignore_first_user_message": false,
      "notes": "Este SOP no sobreescribe políticas de sistema/seguridad; actúa bajo ellas."

- [sn_gestion_proyectos_5-36-5-_SOP_01___An_lisis__01__009.txt] — sha256: f3300833a19009c96856a1934b29fa6ad47e0a881e43f938837219a9c832badd — resumen

  # Auditoría de Configuración de Proyecto — **Protocolo General**
  **Objetivo.** Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.

  ## Entradas requeridas
  - Texto actual en **Project Instructions** y en **Custom Instructions** (los 3 campos).

- [sn_gestion_proyectos_5-36-5-_SOP_01___An_lisis__01__010.xml] — sha256: 0a803615f8c80dbb3ea07fc611d5843bd725766db96a097247b4b69d7e3d0f21 — resumen

  <?xml version="1.0" encoding="UTF-8"?>
  <auditoriaProtocolo xmlns="urn:anastasis-revenari:auditoria:1.0">
    <metadata>
      <nombre>Auditoría de Configuración de Proyecto — Protocolo General</nombre>
      <version>1.0</version>

- [sn_gestion_proyectos_5-22-31-_WsW_Contexto__011.txt] — sha256: cd4ac5634c38ad4d7870a475313a07be45c6936e18f37f18938b08be720cb33b — resumen

  Contexto de workspace
  - root = C:\Users\VictorFabianVeraVill\mnt
  - Abreviaturas: "docs/chatgpt" = <root>\docs\chatgpt
  - Nuevo proyecto "X": crear en <root>\data\proyectos\X con subcarpetas {docs, src, config, results}
  - No escribes en disco: solo dame comandos/archivos listos para copiar/pegar

- [sn_gestion_proyectos_5-16-29-_WsW_Script__012.txt] — sha256: 59acdbc192861cba5b6fa0067dd8e190ff4c1663335d86bf6b226889125a91ad — resumen

  # --- Helper: resuelve una entrada (absoluta o relativa) asegurando que quede BAJO $root ---
  function Resolve-UnderRoot {
      param(
          [Parameter(Mandatory)][string]$Root,
          [Parameter(Mandatory)][string]$Input

- [sn_gestion_proyectos_4-58-47-_WsW_mnt__013.txt] — sha256: 1435e6aeddf37fc2f04343919fd3d26ede918d93ebe772143904621629894879 — resumen

  mnt/
  ├─ archive/
  │  ├─ docs/
  │  └─ proyectos/
  ├─ config/

## Checklists (previo, durante, posterior)

- - “HERRAMIENTAS”: se indica “para listados locales usa `python_user_visible` (no web.run)” pero más abajo el propio SOP demanda verificación activa en `web.run`; no es contradicción, pero conviene separar responsabilidades: **local = python_user_visible**, **externo = web.run**.
- - Al ejecutar una auditoría real, correr **A0** (inventario /mnt/data), validar CSV presentes y realizar verificación **web.run** para capacidades/planes.
- - **Archivos**: “empaquetado y guía de validación” sin check específico (p.ej., manifest, hash, instrucciones de verificación).
- - Verificación de **ZIP** y `README.md` + `manifest.json` + `sha256`.
- - **Verificación web** cuando el tema sea inestable + citas oficiales.
- - **Edición Here-Strings**: resolver rutas; `cd` al repo; **backup incremental** en `Backups\`; aplicar **Append** o **ReplaceBetweenMarkers**; **Changelog** en `Changelogs\`; verificación rápida de `.bak` y cambio.
- - **A3.** Añadir `scripts\preflight.ps1` con verificación de dependencias y rutas críticas.
- - **Orientación a evidencia**: exige inventario de textos/archivos y verificación de límites de longitud.
- - `\b(luego|después|más\s+tarde|próxim[oa]s?)\b` cerca de `entregar|hacer|enviar`
- - **RED-TEMARIO_actualizado_YYYYMMDD-HHMMSS.md** → **Paso 0** (preflight manual): checklist maestro; cada punto enlaza a su solución canónica en **RED.md**. Añade regla “Preflight y progreso”.
- - Publicar **criterios de “Script Canónico”** como checklist marcable (DoD) + badge en cabecera.
- - **Checklist**: agrega ítem “**fuentes_verificadas**” para `audit_capabilities_table`.
- - **Importante**: después de la llave de cierre `}` el archivo tiene líneas de texto *no JSON* que replican reglas (límites, convenciones, plantilla). Eso vuelve al archivo **inválido como JSON puro** y sugiere que ahí se pegaron notas/ayuda que deberían vivir en un `.md`.

## Errores comunes y mitigaciones

- - *Riesgo:* rutas ambiguas al editar archivos.
- - *Riesgo:* colisiones/regex frágiles.
- - *Riesgo:* `Invoke-SerintraQualityGate.ps1` falla si faltan Pester/PSScriptAnalyzer.
- - *Riesgo:* sesiones no-Windows quedan fuera.
- - *Riesgo:* incumplir “entregables impecables”.
- - Mezcla “`RED.md`” vs “`RED_actualizado_YYYYMMDD-HHMMSS.md`”. Riesgo de **punteros rotos** o “¿cuál es el último?”

## Métricas / criterios de calidad

- - Propósito nítido (arranque desde checkpoint, gobernanza, métricas de calidad).
- - Calidad técnica en PS 5.1: un único bloque, `#requires 5.1`, **sin `Write-Host`**, `try/catch` con `-ErrorAction Stop`, elevación opcional `-RequireAdmin`, y “Script Canónico”.
- - **Cálculo del score**: no define escala por sub-criterio ni método de redondeo (p.ej., ¿penalización proporcional por exceder límites?).
- - **Detección de “promesas futuras”**: se pide prohibirlas pero no se define criterio operativo (lista de patrones).
- - **Archivos**: “empaquetado y guía de validación” sin check específico (p.ej., manifest, hash, instrucciones de verificación).
- - Calidad de entregables (10): **YY/10**
- - Introduce **calidad obligatoria** vía `Invoke-SerintraQualityGate.ps1` (PSScriptAnalyzer + Pester).
- - **Validación interna** de artefactos (estructura, compilación estática/coherencia).
- - **Calidad/CI local**: `Invoke-SerintraQualityGate.ps1`; configurado por `PSScriptAnalyzerSettings.psd1` y `verifications\pssa.json`.
- - [ ] Validación de límites (CI×3, PI) con tolerancias.
- - [ ] Entregables: ASCII, zip, manifest, checksums, guía de validación.
- - Incluir **métrica de calidad** en AutoQA (por ejemplo, 0 warnings de `PSScriptAnalyzer` reglas N básicas).
- - Validación estricta de parámetros (`[ValidateNotNullOrEmpty]`, conjuntos, rutas).
- - **Operatividad tangible**: verifica empaquetado `.zip`, nombres ASCII y guía de validación.
- - Medio: tono/consistencia imperfecta, guía de validación incompleta.
- - Validación de nombres Windows: sin `<>:"/\|?*`, sin punto/espacio al final, y sin nombres reservados (p.ej. `CON`, `PRN`, `AUX`, `NUL`, `COM1–9`, `LPT1–9`).
- - **No crea** realmente el árbol descrito en el `filemap.json`; la validación con `Test-TreePlan` es **solo dry-run** (planeación).

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-50-15-An_lisis_de_protocolo_SOP01.md | 3c4cd056384eea385b9d66b490c006252285adf36853b1542f9568f4f1cbbbfd | Análisis de protocolo SOP01 | assistant, system, tool, user | sí |
| 2025-9-29/6-34-30-An_lisis_protocolo_auditor_a.md | ab9c867cc08300b14aff0db0ccc75a9dcc3bce89c665b4aa886d0a6d21a92785 | Análisis protocolo auditoría | assistant, system, user | sí |
| 2025-9-29/6-29-54-An_lisis_de_instrucciones.md | d115629193c6b006bfed80caa7836e881a047a71f6e563bc5eef1a3b533b333c | Análisis de instrucciones | assistant, system, user | sí |
| 2025-9-29/6-31-26-Auditor_a_de_configuraci_n.md | 79d13845694cdaf582ff0a0f6eb742d705f187ef927d96daf86fd914f4794ead | Auditoría de configuración | assistant, system, user | sí |
| 2025-9-29/6-11-18-An_lisis_de_documentaci_n_PS.md | fa7613ef7b6c7149545883d55f70057dddd11a7984f22903d00ddce96329935c | Análisis de documentación PS | assistant, system, user | sí |
| 2025-9-29/5-48-30-_SOP_01___An_lisis__03_.md | 6eb362f934f4498a4dd540a11a271a2c9bd28acf6eb52a17b1b3d8f19062bc44 | <SOP_01 - Análisis #03> | assistant, system, tool, user | sí |
| 2025-9-29/5-36-5-_SOP_01___An_lisis__01_.md | 04e68590fa2126f767ba47e6c276518dc6042ef7a5ca46b8c3669b62b5072022 | <SOP_01 - Análisis #01> | assistant, system, user | sí |
| 2025-9-29/5-22-31-_WsW_Contexto_.md | c587ce464489ef990741766cf56d51e6918d49bc828623a69d6806ad8c51aafc | <WsW_Contexto> | assistant, system, user | sí |
| 2025-9-29/5-16-29-_WsW_Script_.md | 4a687674dad9a79b2a4e79a8019d45abb6b12da8900b6752d7d9caa453881289 | <WsW_Script> | assistant, system, user | sí |
| 2025-9-29/4-58-47-_WsW_mnt_.md | 437fc61d4bb310f6e2a4283220f518140c9bdc0b684015bb084ba98d0dc8f414 | <WsW_mnt> | assistant, system, tool, user | sí |
| 2025-9-15/21-20-2-Asistencia_de_ChatGPT.md | 19ea6c9f355d9b1eb4e8012091500be3ee018a7440f4bc8bbe3c943ce6e91d2a | Asistencia de ChatGPT | assistant, system, user | sí |
| 2025-9-23/18-1-52-Cambio_de_membres_a_Plus.md | 5659cbea4a7c994d50fbf6e33954e0528c74d4d6167f14d8be766655b36b2014 | Cambio de membresía Plus | assistant, system, tool, user | sí |
