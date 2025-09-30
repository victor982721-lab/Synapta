### Entrada (user)

Lee y analiza por completo lo siguiente:

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

# Análisis del “Protocolo General de Auditoría de Configuración de Proyecto”

## 1) Propósito y alcance
- **Propósito**: evaluar si un proyecto de ChatGPT aprovecha correctamente *Project Instructions (PI)*, *Custom Instructions (CI)* y archivos, con o sin Memoria, produciendo un reporte con puntajes, hallazgos y acciones.  
- **Alcance**: transversal a cualquier dominio; se centra en configuración y operativa de entregables.

## 2) Fortalezas
- **Estructura clara**: entradas, salidas, dimensiones con pesos y procedimiento paso a paso.  
- **Enfoque “un turno, valor”**: desalienta preguntas innecesarias.  
- **Orientación a evidencia**: exige inventario de textos/archivos y verificación de límites de longitud.  
- **Plantilla de reporte**: facilita estandarización e interpretación.

## 3) Ambigüedades / vacíos (impacto operativo)
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

## 4) Mejoras propuestas (concretas y accionables)
1. **Umbrales duros**: CI ≤ 1 500 chars (tolerancia +10% → *warning*, >1 650 → *fail*). PI ≤ 8 000 (+10%/*warning*, >8 800/*fail*). Conteo por *Unicode graphemes*, normalizando `\r\n → \n`.  
2. **Fórmula de puntaje**: cada dimensión 0–100 por rúbrica; score total = Σ(peso_i × score_i)/Σ(pesos). “Sin datos” ⇒ 0 por sub-criterio.  
3. **Formato de citas**: `[Oficial|Comunidad] — Título, Dominio, Fecha ISO, URL`. Lista blanca sugerida para *Oficial* (docs del proveedor, dominios *.openai.com*, *.microsoft.com*, etc.).  
4. **Precedencia**: si PI y CI chocan, marcar *Conflicto-Alto*, prevalece PI; registrar sección/ID y acción correctiva.  
5. **Evidencia de Memoria**: incluir texto exacto del estado + captura (si disponible) o transcripción UI; si N/A, justificar.  
6. **Operativa de archivos**: imponer convención `AAAA-MM-DD_[Slug]` (ASCII, `-` y `_`), árbol `/docs /scripts /data /out`, y `SHA256SUMS.txt`.  
7. **ZIP estandarizado**: `{fecha}_{proyecto}_audit_bundle.zip` con manifest (`manifest.json`: versiones, hashes, tamaños).  
8. **Detección de promesas**: regex sugeridas:  
   - `\b(luego|después|más\s+tarde|próxim[oa]s?)\b` cerca de `entregar|hacer|enviar`  
   - `\b(te aviso|te diré|podría|intentaré)\b`  
   Reportar coincidencias con contexto (±40 chars).  
9. **Checklist de consistencia**: matriz instrucción→evidencia con estado (OK/Gap/Conflicto) y vigencia (fecha/versión).  
10. **Salida canónica**: además de texto, emitir `JSON` con breakdown por dimensión, hallazgos (sev, evidencia, acción), y totales.  
11. **Validación de límites**: contar caracteres por campo y reportar `% usado`; incluir tabla de medidas.  
12. **Guía de uso**: añadir paso “cómo extraer CI/PI” (p. ej., copiar texto de los 3 campos y PI en bruto; no resúmenes).

## 5) Checklist ejecutable (resumido)
- [ ] Inventario CI/PI (texto crudo + longitudes) y archivos (nombre, bytes, propósito).  
- [ ] Validación de límites (CI×3, PI) con tolerancias.  
- [ ] Consistencia PI↔CI (conflictos, precedencia, secciones afectadas).  
- [ ] Proactividad (detección de promesas/preguntas superfluas con regex).  
- [ ] Trazabilidad (matriz instrucción→evidencia, fecha/versión).  
- [ ] Citas etiquetadas [Oficial]/[Comunidad] con formato estandar.  
- [ ] Entregables: ASCII, zip, manifest, checksums, guía de validación.  
- [ ] Reporte final: puntuaciones por dimensión + top-10 acciones.

## 6) Plantilla refinada de reporte (lista mínima)
- **Resumen**: `score_total`, conteo por severidad (Crít/Alto/Medio/Bajo).  
- **Medidas**: tabla de longitudes (campo, chars, % de uso, estado).  
- **Puntajes**: tabla 7 dimensiones (score, notas, evidencia clave).  
- **Hallazgos → Acción (≤10)**: “Sev — problema — evidencia — acción (una línea)”.  
- **Anexos**: matriz trazabilidad, lista de citas formateadas, inventario de archivos, `manifest.json` y `SHA256SUMS.txt`.

## 7) Prompt operativo (ajustado, auto-contenible)
> Audita este proyecto con el Protocolo General. Entrega **en un solo turno**: puntuación por dimensión (0–100), **score total**, tabla de longitudes (CI×3, PI), conflictos PI↔CI (con precedencia a PI), citas etiquetadas **[Oficial]/[Comunidad]**, y **máx. 10** acciones de una línea. Exige nombres ASCII, bundle `.zip` con `manifest.json` y `SHA256SUMS.txt`. No hagas preguntas.

**Fuentes usadas:** no se usaron fuentes externas.
