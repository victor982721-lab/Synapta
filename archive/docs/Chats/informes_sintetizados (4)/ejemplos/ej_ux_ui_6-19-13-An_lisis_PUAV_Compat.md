### Entrada (user)

Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~
# Protocolo de Actualización y Verificación de Configuración — **PUAV‑Compat (2025‑09)**
**Fecha de este paquete:** 2025-09-24 05:56 UTC

> Propósito. Poner a cualquier sesión de ChatGPT en modo **exactitud + trazabilidad** cuando el tema sea configuración de la plataforma (Projects, Project Instructions, Custom Instructions, Memoria, Connectors, Deep Research, Agent, Codex/CLI, GPT‑5 y modos). El flujo incluye verificación en **web.run** cuando haya riesgo de obsolescencia, y validación guiada de la **UI** del usuario.

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
> **Activa PUAV‑Compat**. Verifica esta sesión: (a) si estoy en Proyecto, (b) estado de Memoria, (c) 3 campos de Custom Instructions (~1500). Resume con etiquetas **[UI del usuario]**, **[Oficial]**, **[Comunidad/Prensa]**. Para afirmaciones sobre límites o disponibilidad, usa **web.run** y coloca fecha. Si algo no es verificable, márcalo *Pendiente* y sugiere cómo medirlo en mi pantalla.

## 8) Notas
- Este protocolo se inspira en PUAV v3 del proyecto y mantiene su disciplina de citas y verificación.
- Diseñado para convivir con “Project Instructions” y archivos sin depender de memoria.
~~~~~

### Salida (assistant)

# Análisis detallado — PUAV-Compat (2025-09)

## 1) Qué es y para qué sirve
PUAV-Compat es un protocolo operativo para poner una sesión de ChatGPT en **modo exactitud + trazabilidad** cuando el tema es **configuración de la plataforma** (Projects, Project Instructions, Custom Instructions, Memoria, Connectors, Deep Research, Agent, GPT-5, etc.). Establece:
- Jerarquía de contexto (de System → mensajes del hilo).
- Verificación **empírica en UI** (no asumir estados).
- Uso de **web.run** cuando haya riesgo de obsolescencia.
- **Plantilla de informe** con etiquetado de fuentes **[Oficial] / [Comunidad/Prensa] / [UI del usuario]**.
- Reglas de entrega en **un solo turno** con auto-verificación.

## 2) Fortalezas (bien resuelto)
- **Antialucinación por diseño:** obliga a citar y a verificar límites/estados en UI o con web.run.
- **Prioriza trazabilidad:** etiquetas de origen y fecha de verificación.
- **Jerarquía clara de señales:** System > Project Instructions > Custom Instructions > Prompt > Memoria > Archivos > Mensajes.
- **Procedimiento de UI accionable:** pasos concretos para confirmar Proyecto, Memoria y campos de CI.
- **Gestión de incertidumbre:** todo lo no confirmable queda *Pendiente* con tareas explícitas.
- **Contrato de salida:** “un turno, valor real”; entrega A y B si la petición lo implica.

## 3) Ambigüedades / vacíos a considerar
- **Páginas “oficiales” concretas:** se mencionan áreas (Help/FAQ/Blog) pero no una lista mínima canónica por tema (IDs o rutas preferentes).
- **Límites de campos:** se sugiere ~1500 CI y ~8000 Project Instructions, pero falta el **método de medición** estandarizado (bloque lorem, codificación, control de caracteres vs bytes).
- **Estados de Memoria:** define global vs *project-only*, pero no contempla **tenant/plan** con políticas personalizadas (Enterprise) ni cómo proceder si la UI difiere por idioma/región.
- **Conectores / Deep Research / Agent:** se incluyen en el “barrido” pero sin **criterios mínimos de validación** (p.ej., requisitos, disponibilidad por plan/región, límites de cuota).
- **Gestión de evidencias:** el protocolo pide “resumen ejecutable + adjuntos”, pero no fija **formato de evidencia** (capturas, hashes, manifest) ni retención.
- **Fallo de UI o acceso limitado:** no define plan B si el usuario no puede abrir Ajustes (restricciones corporativas) o si el idioma de UI no es ES-MX.

## 4) Riesgos operativos (y mitigación)
- **Variantes de UI por rollout:** textos como *Temporary Chat* pueden cambiar de rótulo → incluir **sinónimos/i18n** y prueba por posición o icono.
- **Confusión caracteres vs bytes:** al medir límites, definir “unidad” (caracteres Unicode) y método (p.ej., `len()` lógico, no tamaño en bytes).
- **Diferencias por plan/licenciamiento:** Plus/Pro/Enterprise pueden divergir → siempre marcar **[Oficial]** con fecha y versión del plan.
- **Dependencia en cooperación del usuario:** si no hay capturas, etiquetar todo como **Pendiente** y proporcionar **script de prueba** (bloques de control para pegar).

## 5) Mejoras concretas (propuestas accionables)
1) **Lista mínima canónica de fuentes [Oficial]:** Help Center (Products/Features), Status/Release notes, Blog técnico. Añadir “fallback [Comunidad/Prensa]” si falta oficial.
2) **Método de medición de límites:**
   - Preparar **tres bloques lorem**: 1400, 1500, 1600 para CI; 7800, 8000, 8200 para Project Instructions.
   - Definir **criterio de éxito** (acepta/recorta/errores) y registrar **pantalla + timestamp**.
3) **Esquema de evidencia:**
   - `evidence/` con `YYYYMMDD-HHMM/` → `{area}-{claim}.md` (texto), `*.png` (captura), `manifest.json` (hashes + fechas).
4) **i18n / alias de UI:** tabla de sinónimos (ES-MX/EN) para *Temporary Chat*, *Project Instructions*, *Custom Instructions*, *Memory*.
5) **Criterios mínimos para Connectors / DR / Agent:** campos a validar (disponibilidad, límites, planes, dónde se enciende en UI) y **qué se considera “verificado”**.
6) **Salida estandarizada adicional:** acompañar el informe humano con **JSON** (estructura fija) para automatizar comparativas entre sesiones.

## 6) Flujo operativo recomendado (paso a paso)
1) **Identificar contexto**: ¿Proyecto activo? ¿Memoria? ¿Idioma de la UI? (marcar evidencia).  
2) **UI check** (usuario): Proyecto/Temporary Chat, Memoria (ON/OFF y scope), Custom Instructions (3 campos visibles), ubicación/limite de Project Instructions.  
3) **Medición de límites** (opcional/si crítico): pegar bloques control. Registrar resultado.  
4) **Barrido web.run** mínimo (si hay afirmaciones inestables ≥10%): Help/FAQ/Blog de las áreas pedidas; fechar hallazgos y etiquetar.  
5) **Emitir informe**: “Contexto verificado — AAAA-MM-DD”, con etiquetas por afirmación, riesgos y pendientes.  
6) **Adjuntos**: evidencia + manifest (hashes, fechas, versiones).

## 7) Plantillas sugeridas

### 7.1 Informe (texto)
- **Contexto verificado — 2025-09-29**
  - **Proyecto**: {Sí/No} — **[UI del usuario]**  
  - **Temporary Chat**: {ON/OFF} — **[UI del usuario]**  
  - **Memoria**: {OFF/ON-global/ON-project-only} — **[UI del usuario]**  
  - **Custom Instructions (3×~1500)**: {Visto/Medido/No visible} — etiqueta y evidencia  
  - **Project Instructions (~8000)**: {Límite observado / No medido} — evidencia  
  - **Diferencias por plan**: {Hallazgos} — **[Oficial] (fecha)**  
  - **Riesgos/Pendientes**: {Ítems con próxima acción y fuente requerida}

### 7.2 Esquema JSON (para trazabilidad)
```json
{
  "timestamp_utc": "2025-09-29T12:00:00Z",
  "ui": {
    "project_active": {"value": true, "source": "[UI del usuario]"},
    "temporary_chat": {"value": false, "source": "[UI del usuario]"},
    "memory": {"state": "project-only", "source": "[UI del usuario]"},
    "ci_fields": {"count": 3, "approx_limit": 1500, "method": "visual", "source": "[UI del usuario]"}
  },
  "limits": {
    "custom_instructions_char_limit": {"approx": 1500, "status": "observed", "source": "[UI del usuario]"},
    "project_instructions_char_limit": {"approx": 8000, "status": "unverified", "source": "Pendiente"}
  },
  "plans": {
    "differences": [],
    "sources": []
  },
  "web_claims": [],
  "risks": [{"item": "Project Instructions limit", "status": "Pendiente", "next_step": "Medir con bloque 8200"}],
  "evidence_manifest": []
}
```

## 8) Casos de prueba (mínimos)
- **A. Usuario sin Proyecto, Memoria OFF:** verificar que el informe no asume nada y etiqueta todo como [UI del usuario].  
- **B. Proyecto activo, Project Instructions llenas:** medir límite con lorem y documentar rechazo/recorte.  
- **C. Enterprise con políticas personalizadas:** divergencias marcadas como *Pendiente* hasta confirmar **[Oficial]** de ese tenant.  
- **D. UI en inglés:** aliased labels (*Temporary Chat*, *Project Instructions*, *Custom Instructions*, *Memory*).

## 9) Compatibilidad con tu stack (AR / SOP-01 / Auditoría)
- **Encaja con “un turno, valor real”** del proyecto AR y el gate de calidad: exige salida verificable + adjuntos.
- **Se integra con matriz de trazabilidad** (instrucción→evidencia) y con el enfoque **[Oficial]/[Comunidad]/[UI]** ya usado.
- **No depende de memoria** (coincide con sesiones neutrales/aisladas), pero soporta *project-only* si el usuario lo pide.

## 10) Conclusión práctica
PUAV-Compat está **bien estructurado** para controlar alucinaciones y asegurar **evidencia verificable**. Para llevarlo a “producción” en tu flujo, sugiero implementar de inmediato:
1) **Lista canónica de fuentes oficiales** por tema.  
2) **Kit de medición de límites** (bloques lorem + guía de captura).  
3) **Esquema JSON de salida** + manifest de evidencia.  
4) **Tabla i18n de rótulos de UI**.  

Con esos cuatro ajustes, tendrás un circuito **reproducible y auditable** de principio a fin.
