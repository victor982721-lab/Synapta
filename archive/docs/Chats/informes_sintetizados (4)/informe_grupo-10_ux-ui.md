# UX/UI

## Resumen ejecutivo

Este informe sintetiza 2 conversación(es) consolidadas del tema **UX/UI**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1. **Ambigüedad en activadores de web.run**
2. **Verificación de límites de campos sin procedimiento reproducible**
3. **Falta de criterios de “Definición de Hecho (DoD)” del informe**
4. **Trazabilidad de fuentes sin tabla estandarizada**
5. **Errores tipográficos y ruido visual**
6. **Jerarquía de contexto: memoria “project-only” condicionada**
7. **Alcance de planes (Plus/Pro/Enterprise)**
8. **Plantilla de informe sin campos de metadatos**
1) **Metadatos**
2) **Ubicación en Proyecto (UI)**
3) **Estado de Chat temporal**
4) **Memoria**
5) **Custom Instructions (3 campos)**
6) **Project Instructions**
7) **Condición para web.run**
8) **Matriz de Trazabilidad**
9) **Informe final**
1) **Lista mínima canónica de fuentes [Oficial]:** Help Center (Products/Features), Status/Release notes, Blog técnico. Añadir “fallback [Comunidad/Prensa]” si falta oficial.
2) **Método de medición de límites:**
3) **Esquema de evidencia:**
4) **i18n / alias de UI:** tabla de sinónimos (ES-MX/EN) para *Temporary Chat*, *Project Instructions*, *Custom Instructions*, *Memory*.
5) **Criterios mínimos para Connectors / DR / Agent:** campos a validar (disponibilidad, límites, planes, dónde se enciende en UI) y **qué se considera “verificado”**.
6) **Salida estandarizada adicional:** acompañar el informe humano con **JSON** (estructura fija) para automatizar comparativas entre sesiones.
1) **Identificar contexto**: ¿Proyecto activo? ¿Memoria? ¿Idioma de la UI? (marcar evidencia).
2) **UI check** (usuario): Proyecto/Temporary Chat, Memoria (ON/OFF y scope), Custom Instructions (3 campos visibles), ubicación/limite de Project Instructions.
3) **Medición de límites** (opcional/si crítico): pegar bloques control. Registrar resultado.
4) **Barrido web.run** mínimo (si hay afirmaciones inestables ≥10%): Help/FAQ/Blog de las áreas pedidas; fechar hallazgos y etiquetar.
5) **Emitir informe**: “Contexto verificado — AAAA-MM-DD”, con etiquetas por afirmación, riesgos y pendientes.
6) **Adjuntos**: evidencia + manifest (hashes, fechas, versiones).
1) **Lista canónica de fuentes oficiales** por tema.
2) **Kit de medición de límites** (bloques lorem + guía de captura).
3) **Esquema JSON de salida** + manifest de evidencia.
4) **Tabla i18n de rótulos de UI**.

## Mejores prompts / plantillas

- 8) “Prompt operativo” (revisado, listo para usar)

## Ejemplos completos

- [ej_ux_ui_6-40-30-An_lisis_SOP_auditor_a.md] — sha256: a1e8ceb86e13caa8425e1c8011324781e4c562b16bef408eb7197d36a13cee24 — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_ux_ui_6-19-13-An_lisis_PUAV_Compat.md] — sha256: 021cdc89cf8b9b1423341c14e29db6865ac001fc76e27e49bf46ac7c3bafebf4 — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

## Snippets de código / comandos

- [sn_ux_ui_6-40-30-An_lisis_SOP_auditor_a_001.txt] — sha256: 73a66e827ac1a502c50cfe94b0a5632ec24f4750bf99df5f837803bccb132597 — resumen


  # [STANDARD OPERATING PROCEDURE] - **AUDITORIA INTEGRAL**

  ## Objetivo


- [sn_ux_ui_6-19-13-An_lisis_PUAV_Compat_002.txt] — sha256: 8369b9e671b86263a8902dacfaf89f9de408e3cafbaff1921e834d7006a95d85 — resumen

  # Protocolo de Actualización y Verificación de Configuración — **PUAV‑Compat (2025‑09)**
  **Fecha de este paquete:** 2025-09-24 05:56 UTC

  > Propósito. Poner a cualquier sesión de ChatGPT en modo **exactitud + trazabilidad** cuando el tema sea configuración de la plataforma (Projects, Project Instructions, Custom Instructions, Memoria, Connectors, Deep Research, Agent, Codex/CLI, GPT‑5 y modos). El flujo incluye verificación en **web.run** cuando haya riesgo de obsolescencia, y validación guiada de la **UI** del usuario.


- [sn_ux_ui_6-19-13-An_lisis_PUAV_Compat_003.json] — sha256: 03720c9a5255cece2a692dffd29b13c6dc00134116ef55554439551e239f7ccf — resumen

  {
    "timestamp_utc": "2025-09-29T12:00:00Z",
    "ui": {
      "project_active": {"value": true, "source": "[UI del usuario]"},
      "temporary_chat": {"value": false, "source": "[UI del usuario]"},

## Checklists (previo, durante, posterior)

- - **Verificación de UI**: instruye a **no asumir** estados (Proyecto, Memoria, CI).
- - *Acción*: Añadir una **matriz**: Afirmación | Origen | URL/Dominio | Fecha de verificación | Etiqueta | Evidencia breve.
- - **Obsolescencia silenciosa** (cambios de UI o planes): usar disparadores y fechar toda verificación.
- - Verificación **empírica en UI** (no asumir estados).
- - Reglas de entrega en **un solo turno** con auto-verificación.
- - **Prioriza trazabilidad:** etiquetas de origen y fecha de verificación.

## Errores comunes y mitigaciones

- - *Problema*: “riesgo de obsolescencia” no tiene umbrales operativos.
- - Uso de **web.run** cuando haya riesgo de obsolescencia.

## Métricas / criterios de calidad

- - **Conectores / Deep Research / Agent:** se incluyen en el “barrido” pero sin **criterios mínimos de validación** (p.ej., requisitos, disponibilidad por plan/región, límites de cuota).
- - Definir **criterio de éxito** (acepta/recorta/errores) y registrar **pantalla + timestamp**.
- - **Encaja con “un turno, valor real”** del proyecto AR y el gate de calidad: exige salida verificable + adjuntos.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-40-30-An_lisis_SOP_auditor_a.md | 25a0b0c2b5d4fcf0b0cc214156e87d5fe5026dbfbeb2163551182af5bfd82fa5 | Análisis SOP auditoría | assistant, system, user | sí |
| 2025-9-29/6-19-13-An_lisis_PUAV_Compat.md | 3c877c264ebe1d5bb5da452220f765699a3ec46e49db9e8b5915d8ae127b62bf | Análisis PUAV-Compat | assistant, system, user | sí |
