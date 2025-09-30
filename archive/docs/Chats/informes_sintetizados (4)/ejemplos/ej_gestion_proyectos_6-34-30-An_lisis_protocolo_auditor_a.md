### Entrada (user)

Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~
# Auditoría de Configuración de Proyecto — **Protocolo General**
**Objetivo.** Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.

## Entradas requeridas
- Texto actual en **Project Instructions** y en **Custom Instructions** (los 3 campos).
- Capturas/confirmaciones de estado de **Memoria** (OFF o project‑only).
- Listado de **archivos** del proyecto y su propósito.

## Salidas esperadas
- **Puntaje** (0–100) por dimensiones.  
- **Hallazgos** priorizados (Crítico/Alto/Medio/Bajo).  
- **Acciones correctivas** concretas (una línea cada una).

## Dimensiones y pesos
1) **Claridad y enfoque** (20): objetivos definidos, tono consistente, cero ambigüedad.  
2) **Proactividad y contrato de entrega** (20): “un turno, valor”, sin promesas, verificación propia.  
3) **Trazabilidad** (15): citas a fuentes **[Oficial]** para capacidades, foros como **[Comunidad/Prensa]**.  
4) **Arquitectura de contexto** (15): jerarquía correcta (Proyecto > CI > Prompt), sin depender de memoria.  
5) **Operativa de archivos** (10): nombres ASCII, empaquetado, instrucciones de uso.  
6) **Actualización y UI** (10): comprobaciones de estado (Proyecto/Memoria), límites de campos medidos.  
7) **Calidad de entregables** (10): ejemplos reproducibles, validaciones internas.

## Procedimiento
1) **Inventario**: extrae texto de CI (3 campos) y Project Instructions; lista archivos y tamaños.  
2) **Límites**: verifica que cada campo respete su presupuesto (CI ~1500 c/u; Proyecto ~8000 aprox.).  
3) **Consistencia**: detecta contradicciones entre CI vs Proyecto; Proyecto debe prevalecer.  
4) **Proactividad**: busca frases de “prometer más tarde” o preguntas innecesarias; deben estar prohibidas.  
5) **Citas**: comprueba presencia de citas **[Oficial]** cuando se hable de capacidades o planes.  
6) **Entregables**: verifica que se pidan nombres ASCII, `.zip` cuando aplique y guía de validación.  
7) **Reporte**: emite puntaje por dimensión + lista de acciones (máx. 10 ítems).

## Plantilla de reporte (ejemplo)
**Resumen (score total: 84/100)**  
- Críticos: 0 | Altos: 1 | Medios: 3 | Bajos: 2  
**Hallazgos → Acción (una línea):**  
- Alto — Proyecto excede 8000 char: Reducir y mover detalle a archivos.  
- Medio — CI carece de “un turno, valor”: Añadir contrato de entrega.  
- Bajo — Falta política de `.zip`: Incluir en sección de entregables.

## Prompt operativo (copia y pega)
> Audita este proyecto con el protocolo general. Reporta puntuación por dimensión, hallazgos priorizados y acciones de una línea. Verifica límites (1500/8000 aprox.), consistencia Proyecto↔CI, y políticas de entregables. No hagas preguntas; entrega el informe en un turno.
~~~~~

### Salida (assistant)

Aquí va un análisis técnico y accionable del **Protocolo General de Auditoría de Configuración de Proyecto** que compartiste.

# 1) Propósito y alcance
- **Qué resuelve:** Evalúa si un proyecto de ChatGPT usa correctamente *Project Instructions (PI)*, *Custom Instructions (CI)* (3 campos), archivos y estado de *Memoria*.  
- **Dónde aplica:** Agnóstico al dominio (bueno para reutilización).  
- **Salida esperada:** Puntuación 0–100 por dimensión, hallazgos priorizados y **acciones correctivas en una línea**.

# 2) Fortalezas
1) **Dimensiones y pesos** suman 100 (20+20+15+15+10+10+10) → marco equilibrado.  
2) **Procedimiento** en 7 pasos: cubre inventario, límites de tamaño, consistencia PI↔CI, proactividad, citas, entregables y reporte.  
3) **Plantilla y prompt operativo**: facilitan ejecución en un solo turno (“un turno = valor”).  
4) **Énfasis en trazabilidad**: distingue **[Oficial]** vs **[Comunidad/Prensa]**.  
5) **Operativa de archivos**: pide nombres ASCII, empaquetado y guía de uso (reduce fricción).

# 3) Ambigüedades / huecos detectados
- **Límites “aprox.”**: CI ~1500 c/u y Proyecto ~8000 “aprox.” → deja margen de interpretación.  
- **Cálculo del score**: no define escala por sub-criterio ni método de redondeo (p.ej., ¿penalización proporcional por exceder límites?).  
- **Detección de “promesas futuras”**: se pide prohibirlas pero no se define criterio operativo (lista de patrones).  
- **Memoria**: se pide confirmar estado (OFF o project-only) pero no se fija **fuente de verdad** (captura UI, configuración exportada, etc.).  
- **Citas**: indica usar **[Oficial]** para capacidades, pero no pauta mínimos (p.ej., ≥1 cita por afirmación inestable).  
- **Archivos**: “empaquetado y guía de validación” sin check específico (p.ej., manifest, hash, instrucciones de verificación).  
- **Consistencia jerárquica**: establece que Proyecto prevalece sobre CI, pero falta un **método** para marcar y resolver conflictos (tabla con “conflicto, prevalece, corrección”).  
- **Automatización**: no define comandos/regex para inventario, conteo de caracteres y búsqueda de patrones prohibidos.

# 4) Riesgos operativos
- **Resultados no comparables** entre auditorías por falta de reglas de puntuación detalladas.  
- **Falsos positivos/negativos** en proactividad si no se listan expresiones objetivo.  
- **Dependencia en juicio humano** para “aprox.” y “prioridad” sin umbrales.

# 5) Sugerencias concretas (mejoras puntuales)
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

# 6) Mini-método de puntuación (propuesto)
- **Entrada**: resultados binarios o proporcionales por sub-check.  
- **Cálculo**: `Score_dimensión = Peso × (puntos_obtenidos / puntos_posibles)`.  
- **Redondeo**: al entero más cercano; total = suma dimensiones (0–100).  
- **Ejemplo de sub-checks (extracto)**  
  - Claridad y enfoque (20):  
    - Objetivo explícito (5), tono consistente (5), cero ambigüedad (10).  
  - Proactividad (20):  
    - “Un turno, valor” presente (10), **0** patrones prohibidos (10; −2 por patrón hallado, mínimo 0).  
  - Límites de tamaño (parte de “Actualización y UI”, 10):  
    - CI (3×) ≤1500 c/u (5), PI ≤8000 (5; −1 por cada 100 chars extra, mínimo 0).

# 7) Checklist operativa (lista breve)
- Inventario CI (3 campos) y PI con **conteo exacto** de caracteres.  
- Estado de **Memoria** con evidencia (captura + texto).  
- Lista de archivos con tamaño y extensión; confirmar **ASCII** en nombres.  
- Verificación de **ZIP** y `README.md` + `manifest.json` + `sha256`.  
- Detección de **promesas futuras** (regex) → debe ser **0**.  
- Citas **[Oficial]** para capacidades, **[Comunidad/Prensa]** para contexto; registrar fecha.  
- Matriz PI↔CI (conflicto, resolución).  
- Reporte con **score por dimensión**, hallazgos priorizados y **máx. 10 acciones** (1 línea c/u).

# 8) Plantilla de reporte (refinada)
**Resumen (score total: XX/100)**  
- Críticos: X | Altos: X | Medios: X | Bajos: X  

**Puntuación por dimensión**  
- Claridad y enfoque (20): **YY/20**  
- Proactividad y contrato de entrega (20): **YY/20**  
- Trazabilidad (15): **YY/15**  
- Arquitectura de contexto (15): **YY/15**  
- Operativa de archivos (10): **YY/10**  
- Actualización y UI (10): **YY/10**  
- Calidad de entregables (10): **YY/10**

**Hallazgos → Acción (una línea)** *(máx. 10)*  
- **Alto —** [Hallazgo breve]. **Acción:** [corrección concreta].  
- **Medio —** …  
- **Bajo —** …

**Cómo se midió**  
- Fecha de auditoría, versión del protocolo, método de conteo de caracteres, regex usadas, herramientas (si aplica).

# 9) Snippets útiles (operativos)
- **Conteo de caracteres rápido (manual):** copiar y usar contador confiable (evita duplicar saltos de línea).  
- **Regex de promesas (ejemplo base, sensible a minúsculas):**  
  `\b(mañana|luego|después|pronto|en\s+otra\s+iteración|te\s+avisaré|espera|en\s+el\s+futuro)\b`  
  *(Ajustar stop-words según estilo del proyecto).*
- **Política de nombres ASCII (regla mínima):** `[A-Za-z0-9._-]+` sin espacios ni acentos.

# 10) Veredicto
El protocolo es **sólido y aplicable** como “marco de auditoría express”. Para hacerlo **reproducible y comparable** entre sesiones/equipos, conviene endurecer límites, detallar el método de puntuación, fijar patrones prohibidos y formalizar evidencia de Memoria y archivos (manifest + hashes). Con los ajustes propuestos, obtienes una auditoría **determinista**, de un solo turno y con trazabilidad completa.
