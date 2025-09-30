# Análisis SOP auditoría

https://chat.openai.com/c/68da7e3b-6fcc-8326-a9bb-a2e850c76232

## USER
Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~

# [STANDARD OPERATING PROCEDURE] - **AUDITORIA INTEGRAL**

## Objetivo

Verificar que cada que se comience una sesión dentro del proyecto actual, la instancia actualice su contexto inicial por medio de fuentes oficiales usando `web.run`, en 

> Propósito. Poner a cualquier sesión de ChatGPT en modo **exactitud + trazabilidad** cuando el tema sea configuración de la plataforma (Projects, Project Instructions, Custom Instructions, Memoria, Conanectors, Deep Research, Agent, Codex/CLI, GPT‑5 y modos). El flujo incluye verificación en **web.run** cuando haya riesgo de obsolescencia, y validación guiada de la **UI** del usuarios												exacta																																								

---

## 0) Principios

- **Cero alucinaciones**: si no existe la fuente, se declara; si hay dudas, **web.run**.
- **[Oficial] vs [Comunidad/Prensa]**: el informe debe etiquetar el origen.
- **UI comprobable**: nunca asumir “Proyecto/Temporal/Memoria activada”; dar pasos guiados para que el usuario lo confirme.
- **Un turno, resultado útil**: resumen ejecutable + adjuntos; si el pedido implica A y B, se entregan A y B.

## 1) Jerarquía de contexto (cómo se combinan los elementos)

1) **System / policies de la sesión** (no editable por el usuario).
2) **Project Instructions** (campo del proyecto; prevalece dentro del proyecto).
3) **Custom Instructions** (globales; 3 campos largos de ~1500 chars efectivos cada uno: *Instrucciones personalizadas*, *Ocupación*, *Más acerca de ti*; según UI actual) — verificación empírica requerida.
4) **Prompt inicial del chat** (efímero, por chat).
5) **Memoria** (si está activada; global o **project‑only**).
6) **Archivos del proyecto** (consultados bajo demanda por relevancia).
7) **Mensajes del hilo** (lo más volátil).

> Este protocolo está diseñado para funcionar **sin memorias** (modo neutral). Si la memoria está activa, se aplica aislamiento **project‑only** cuando el usuario lo solicite.

## 2) Detección de estado en la UI (no asumir)

Pide al usuario que verifique en su pantalla (pasos exactos):
- **¿Chat temporal?**: Cabecera del modelo → conmutador *Temporary Chat* o indicación equivalente.
- **¿Estamos dentro de un Proyecto?**: Barra lateral → nombre del proyecto resaltado; menú ⋯ → *Instrucciones del proyecto*.
- **Memoria**: Ajustes → *Personalización* → sección *Memoria* (administrar / activar).
- **Custom Instructions (ES‑MX)**: Ajustes → *Personalización* → secciones *Instrucciones personalizadas*, *Acerca de ti* (*Apodo*, *Ocupación*, *Más acerca de ti*).

## 3) Verificación de límites y campos

- **Custom Instructions**: confirmar empíricamente que *Ocupación* y *Más acerca de ti* aceptan ~1500 caracteres, igual que *Instrucciones personalizadas*. Si el usuario aporta captura o prueba local, etiquetar como **[UI del usuario]**.
- **Project Instructions**: documentar el límite visto en UI (usuarios reportan ~8000). Si es crítico, medir pegando un bloque de control (lorem de 8200) y anotar el tope real.
- **Archivos**: inventariar cantidad y peso admitidos por plan (web.run si es necesario).

## 4) Barrido oficial mínimo (cuando el usuario lo pida o el tema sea cambiante)
Ejecutar **web.run** sobre estas páginas como base (y fechar resultados):
- Projects (Help), Memory (FAQ/What is), Custom Instructions (Blog/Help), Deep Research (FAQ/Blog), Agent (Help/Notas), Connectors y Synced Connectors, GPT‑5 (Help/Site). 
- Etiquetar cada afirmación con **[Oficial]** o **[Comunidad/Prensa]** y fecha de verificación.

## 5) Informe de estado (plantilla)
Emitir una sección **“Contexto verificado — AAAA‑MM‑DD”** con:
- **Campos CI**: 3×~1500 confirmados (**[UI del usuario]** si procede) y texto exacto en español visible en su UI.
- **Project Instructions**: límite observado (p. ej., ~8000) y ubicación exacta en la UI.
- **Memoria**: modo global vs **project‑only** y su estado.
- **Diferencias por plan**: Plus/Pro/Enterprise (solo con cita **[Oficial]**).
- **Riesgos**: todo lo no confirmado pasa a *Pendiente* con tareas web.run.

## 6) Reglas operativas que toda sesión debe acatar (resumen)

- **Un turno, valor real**; sin prometer “lo hago luego”.
- **Proactividad**: si la tarea implica A y B, entrega A y B.
- **Citación y trazabilidad** (Help/Blog para capacidades; foros como **[Comunidad/Prensa]**).
- **Descargas**: nombres ASCII, enlaces válidos, empaquetado en .zip cuando corresponda.
- **Verificación de código/texto**: realizar auto‑chequeo (análisis estático, pruebas de consistencia). Usar Python si está disponible para validar cálculos/estructuras; de lo contrario, explicar qué se verificó y cómo.
- **Información inestable**: si hay ≥10% de probabilidad de cambio, usar **web.run** antes de afirmar.

## 7) Prompt operativo (copia y pega)

> **Activa SOP_Auditoria**. Verifica esta sesión: (a) si estoy en Proyecto, (b) estado de Memoria, (c) 3 campos de Custom Instructions (~1500). Resume con etiquetas **[UI del usuario]**, **[Oficial]**, **[Comunidad/Prensa]**. Para afirmaciones sobre límites o disponibilidad, usa **web.run** y coloca fecha. Si algo no es verificable, márcalo *Pendiente* y sugiere cómo medirlo en mi pantalla.

## 8) Notas
- Diseñado para convivir con “Project Instructions” y archivos sin depender de memoria.
~~~~~

## ASSISTANT
# Análisis detallado del SOP — **AUDITORÍA INTEGRAL**

## 1) Resumen ejecutivo
El SOP está bien orientado: fuerza **exactitud, trazabilidad y entrega en un solo turno**, con énfasis en validar la **UI del usuario** y emplear **web.run** cuando haya riesgo de obsolescencia. Define jerarquía de contexto y una plantilla de informe utilizable.  
Oportunidades: cerrar ambigüedades operativas, normalizar lenguaje, corregir erratas, y convertir pasos en **checklist ejecutable** con criterios de “hecho” (DoD).

**Veredicto global:** Apto para uso con mínimos ajustes. Recomendadas mejoras de precisión y verificabilidad.

---

## 2) Fortalezas clave
- **Principios sólidos**: cero alucinaciones, etiqueta de fuentes **[Oficial] / [Comunidad/Prensa]**, “un turno = valor”.  
- **Jerarquía de contexto** clara (System → Project Instructions → CI → Prompt → Memoria → Archivos → Hilo).  
- **Verificación de UI**: instruye a **no asumir** estados (Proyecto, Memoria, CI).  
- **Tratamiento de información inestable**: obliga a **web.run** ante ≥10% de probabilidad de cambio.  
- **Plantilla de informe** reutilizable (“Contexto verificado — AAAA-MM-DD”).  
- **Prompt operativo** listo para pegar.

---

## 3) Hallazgos y acciones (priorizados)

### Crítico
1. **Ambigüedad en activadores de web.run**  
   - *Problema*: “riesgo de obsolescencia” no tiene umbrales operativos.  
   - *Acción*: Definir disparadores explícitos: cambios en **UI/planes**, nombres de **productos/características** (Projects, Memory, Deep Research, Agent, GPT-5), **límites de campos**, **políticas de privacidad** o cualquier elemento con fecha < 180 días.

2. **Verificación de límites de campos sin procedimiento reproducible**  
   - *Problema*: se pide “confirmar ~1500 caracteres” y “~8000” en Project Instructions, pero no se especifica **cómo medir**.  
   - *Acción*: Incluir **prueba de pegado** con bloques de control (1 500 y 8 200 chars), registro del **resultado en la UI** (éxito/fallo y mensaje), y captura/local note marcada **[UI del usuario]**.

### Alto
3. **Falta de criterios de “Definición de Hecho (DoD)” del informe**  
   - *Acción*: Establecer que la salida es **válida** si incluye: (a) evidencia de UI (texto visible y/o mensaje de tope), (b) etiquetas de fuente y **fecha**, (c) lista de pendientes con **tareas web.run** concretas.

4. **Trazabilidad de fuentes sin tabla estandarizada**  
   - *Acción*: Añadir una **matriz**: Afirmación | Origen | URL/Dominio | Fecha de verificación | Etiqueta | Evidencia breve.

5. **Errores tipográficos y ruido visual**  
   - *Problema*: “Conanectors”, “usuarios… exacta” y espacios extra.  
   - *Acción*: Limpieza editorial (ver §6.2 “Texto propuesto corregido”).

### Medio
6. **Jerarquía de contexto: memoria “project-only” condicionada**  
   - *Problema*: dice “si la memoria está activa, se aplica aislamiento project-only cuando el usuario lo solicite”; falta **ruta** para verificar/ajustar.  
   - *Acción*: Añadir pasos: Ajustes → Personalización → Memoria → conmutar **Project-only** (si disponible) y documentar estado **[UI del usuario]**.

7. **Alcance de planes (Plus/Pro/Enterprise)**  
   - *Problema*: menciona diferencias por plan, pero no fija **qué** verificar.  
   - *Acción*: Lista mínima: (a) límites de archivos (cantidad/tamaño), (b) disponibilidad de Deep Research/Agent/Connectors, (c) retención/privacidad.

### Bajo
8. **Plantilla de informe sin campos de metadatos**  
   - *Acción*: Agregar cabecera: Fecha, Zona horaria, Modelo, Proyecto, Versión del SOP, Revisor.

---

## 4) Checklist operativo (paso a paso, reproducible)
**Meta:** ejecutar en un turno y dejar evidencia verificable.

1) **Metadatos**  
   - Fecha (AAAA-MM-DD), zona horaria (America/Mexico_City), nombre de proyecto, versión SOP.

2) **Ubicación en Proyecto (UI)**  
   - Lateral → Proyecto resaltado → menú ⋯ → “Instrucciones del proyecto”.  
   - **Evidencia**: texto visible del panel o confirmación del usuario (**[UI del usuario]**).

3) **Estado de Chat temporal**  
   - Cabecera del modelo → conmutador *Temporary Chat*.  
   - **Evidencia**: valor actual.

4) **Memoria**  
   - Ajustes → Personalización → Memoria → leer estado y modo.  
   - Si procede, indicar cómo poner **project-only**.  
   - **Evidencia**: estado/mensajes UI (**[UI del usuario]**).

5) **Custom Instructions (3 campos)**  
   - Abrir: *Instrucciones personalizadas*, *Acerca de ti* → *Ocupación*, *Más acerca de ti*.  
   - **Prueba de límite**: pegar bloque de **1 500** caracteres en cada campo (texto lorem controlado).  
   - **Resultado**: aceptar/rechazar, mensajes/contadores de la UI → registrar (**[UI del usuario]**).

6) **Project Instructions**  
   - Pegar bloque de **8 200** caracteres (lorem controlado).  
   - **Resultado**: registrar tope real (p. ej., “acepta hasta 7 950”), mensajes UI (**[UI del usuario]**).

7) **Condición para web.run**  
   - Si cualquier elemento 2–6 falla, aparece cambiado recientemente, o carece de evidencia → **activar web.run** y etiquetar **[Oficial]** / **[Comunidad/Prensa]** con fecha.

8) **Matriz de Trazabilidad**  
   - Completar tabla (ver §5).

9) **Informe final**  
   - Generar “Contexto verificado — AAAA-MM-DD” con campos requeridos, evidencias, etiquetas y **Pendientes**.

---

## 5) Plantillas listas para usar

### 5.1 Matriz de trazabilidad (copiar/pegar)
| Afirmación | Origen | Dominio/URL | Fecha verificación | Etiqueta | Evidencia breve |
|---|---|---|---|---|---|
| CI tiene 3 campos | UI | (panel Personalización) | 2025-MM-DD | [UI del usuario] | Texto visible en pantalla |
| Límite CI ≈ 1500 | UI | — | 2025-MM-DD | [UI del usuario] | Mensaje/contador tras pegar 1500 |
| Límite PI ≈ 8000 | UI | — | 2025-MM-DD | [UI del usuario] | Mensaje tras pegar 8200 |
| Disponibilidad Deep Research | Help | help.openai.com | 2025-MM-DD | [Oficial] | Artículo “Deep Research …” |
| Diferencias por plan | Help | help.openai.com | 2025-MM-DD | [Oficial] | Tabla de límites |

### 5.2 Informe — “Contexto verificado — AAAA-MM-DD”
- **Metadatos**: Zona horaria, Proyecto, Modelo, SOP.  
- **Custom Instructions (3× ~1500)**: estado y evidencia **[UI del usuario]**.  
- **Project Instructions (~8000)**: tope observado + evidencia **[UI del usuario]**.  
- **Memoria**: OFF/ON, Global vs **project-only** (evidencia).  
- **Diferencias por plan**: solo con **[Oficial]** (fecha).  
- **Pendientes**: lista de ítems con tareas **web.run** y qué evidencia falta.

---

## 6) Propuestas de mejora de texto

### 6.1 Cambios de contenido (sustantivos)
- Añadir **“Disparadores web.run”** con ejemplos concretos.  
- Incluir **procedimiento de pruebas de límite** con bloques controlados (1 500 y 8 200).  
- Definir **DoD** del informe y la **matriz** de trazabilidad como elementos obligatorios.  
- Agregar **metadatos de salida**.

### 6.2 Correcciones editoriales (menores)
- Reemplazar **“Conanectors”** → **“Connectors”**.  
- Corregir la línea con “…del usuarios												exacta” → cerrar a:  
  > “…y validación guiada de la **UI** del **usuario**.”  
- Eliminar espacios/tabladores sobrantes; uniformar comillas y énfasis.

### 6.3 Texto propuesto (extracto limpio)
> **Objetivo.** Verificar y fijar el contexto inicial de cada sesión usando evidencia de **UI** y fuentes **[Oficial]/[Comunidad]** vía **web.run** cuando haya riesgo de obsolescencia.  
> **Disparadores web.run.** Cambios en UI o planes, límites de campos, disponibilidad de productos (Projects, Memory, Deep Research, Agent, Connectors, GPT-5), o documentos con fecha < 180 días.  
> **Pruebas de límite.** CI: pegar 1 500 chars en cada campo (3). PI: pegar 8 200 chars. Registrar mensaje/contador **[UI del usuario]**.  
> **DoD.** Informe “Contexto verificado — AAAA-MM-DD” con: evidencias de UI, etiquetas de fuente con fecha, matriz de trazabilidad y lista de pendientes con tareas **web.run**.

---

## 7) Riesgos y mitigaciones
- **Obsolescencia silenciosa** (cambios de UI o planes): usar disparadores y fechar toda verificación.  
- **Dependencia de memoria**: el SOP ya opera **sin memoria**; si existe, forzar **project-only** bajo solicitud y documentar.  
- **Inconsistencias entre planes/regiones**: exigir etiqueta **[Oficial]** y fecha para cualquier afirmación de disponibilidad/límite.

---

## 8) “Prompt operativo” (revisado, listo para usar)
> **Activa SOP_Auditoria.** Verifica esta sesión: (a) si estoy en **Proyecto**, (b) estado de **Memoria** (y cómo poner **project-only** si aplica), (c) **3 campos** de Custom Instructions (prueba **1 500**). Para **Project Instructions**, prueba **8 200**. Resume con etiquetas **[UI del usuario]**, **[Oficial]**, **[Comunidad/Prensa]** y **fecha**. Si algo no es verificable, márcalo **Pendiente** y di cómo medirlo en mi pantalla.

---

## 9) Definición de Hecho (DoD) — Auditoría
- Informe generado con fecha y metadatos.  
- Evidencia de UI para CI/PI/Memoria.  
- Etiquetas de fuente con **fecha**.  
- Matriz de trazabilidad incluida.  
- Pendientes con tareas **web.run** definidas.

---

**Fuentes utilizadas para este análisis:** Ninguna externa; me basé únicamente en el texto proporcionado. Si deseas, puedo ejecutar la verificación con **web.run** y devolver un informe fechado con la matriz correspondiente.

