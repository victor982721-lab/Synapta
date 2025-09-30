# &lt;SOP_01 - Análisis #01&gt;

https://chat.openai.com/c/68da6f22-d90c-8328-861a-e46cf47e00bb

## USER
Parsea por completo lo siguiente y dame un análisis de lo siguiente:

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

## ASSISTANT
# Análisis y “parseo” completo del protocolo

## 1) Qué es y para qué sirve (lectura rápida)
El texto define un **protocolo de auditoría** para evaluar proyectos de ChatGPT (independiente del dominio) respecto a cómo usan **Project Instructions**, **Custom Instructions** (CI), **Memoria**, y **archivos**. Estandariza **entradas**, **salidas**, **dimensiones con pesos (100%)**, un **procedimiento** paso a paso, una **plantilla de reporte** y un **prompt operativo** para ejecutar la auditoría en un solo turno.

---

## 2) Parseo estructural (desglose fiel del contenido)

### Entradas requeridas
- Texto actual en **Project Instructions** y en **Custom Instructions** (3 campos).
- Estado de **Memoria** (OFF o project-only).
- **Listado de archivos** del proyecto con su propósito.

### Salidas esperadas
- **Puntajes 0–100 por dimensión**.
- **Hallazgos priorizados** (Crítico/Alto/Medio/Bajo).
- **Acciones correctivas** concretas (una línea c/u).

### Dimensiones y pesos (suman 100)
1. **Claridad y enfoque** — 20  
2. **Proactividad y contrato de entrega** — 20  
3. **Trazabilidad** — 15  
4. **Arquitectura de contexto** — 15  
5. **Operativa de archivos** — 10  
6. **Actualización y UI** — 10  
7. **Calidad de entregables** — 10

### Procedimiento (7 pasos)
1. **Inventario**: extraer textos CI/Proyecto + listar archivos y **tamaños**.  
2. **Límites**: verificar presupuestos de caracteres (CI ~1500 c/u; Proyecto ~8000 aprox.).  
3. **Consistencia**: detectar contradicciones CI ↔ Proyecto (prevalece Proyecto).  
4. **Proactividad**: cazar promesas futuras o preguntas innecesarias.  
5. **Citas**: exigir **[Oficial]** para capacidades/planes; usar **[Comunidad/Prensa]** como apoyo.  
6. **Entregables**: nombres ASCII, `.zip` cuando aplique, e **incluir guía de validación**.  
7. **Reporte**: puntuar por dimensión + lista de acciones (máx. 10).

### Plantilla de reporte (ejemplo)
- **Resumen** con score total y conteo por severidad.  
- **Hallazgos → Acción** en una línea por item.

### Prompt operativo
Único bloque que ordena ejecutar la auditoría completa (sin preguntas) y entregar puntajes, hallazgos y acciones.

---

## 3) Fortalezas del protocolo
- **Completo pero conciso**: define entradas/salidas, pesos, y procedimiento claro.
- **Orientado a acción**: obliga a **acciones de una línea**, priorizadas por severidad.
- **Gobernanza de contexto**: afirma la jerarquía correcta (**Proyecto > CI > Prompt**).
- **Control de tamaño**: impone **presupuestos de caracteres** para prevenir desbordes.
- **Rigor de evidencia**: pide **citas [Oficial]** cuando se hablen de capacidades/planes.
- **Operatividad tangible**: verifica empaquetado `.zip`, nombres ASCII y guía de validación.
- **Ejecutabilidad en 1 turno**: el prompt operativo prohíbe diálogos dilatorios.

---

## 4) Ambigüedades / Riesgos detectados
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

---

## 5) Mejores prácticas y ajustes propuestos (concretos)
1) **Fuentes “Oficial”**: enumerar dominios canónicos (p.ej., `openai.com`, docs oficiales del proveedor, changelogs del producto) y marcar todo lo demás como **[Comunidad/Prensa]**.  
2) **Recuento**: fijar **caracteres Unicode** (incluye espacios/markdown) y **reportar métricas**: `len_total`, `len_sin_citas`, `%citas`.  
3) **Severidades**: definir **reglas** rápidas:  
   - Crítico: contradicción que cambie comportamiento o viole límites/seguridad.  
   - Alto: excede presupuestos, carece de contrato de entrega, o falta de fuentes al afirmar capacidades.  
   - Medio: tono/consistencia imperfecta, guía de validación incompleta.  
   - Bajo: estilística, pequeños omisos (nombres no-ASCII bien señalados).  
4) **Anclas de puntaje por dimensión** (0/5/10/15/20 o 0/3/6/8/10 según peso) con descriptores observables.  
5) **Renombrar la dimensión 6** a **“Estado y verificación”** (en vez de “Actualización y UI”) para evitar confusión; checklist: memoria=OFF/ON, proyecto activo, límites medidos, fecha de última actualización.  
6) **Formato de cita**: exigir al menos **fuente + fecha** y, si aplica, **URL** (o ID) con límites de cita (≤25 palabras por fuente no-lírica).  
7) **Archivos**: añadir **estructura mínima** (ej. `/docs`, `/config`, `/src`, `/results`), límite de profundidad y **hashes** (SHA-256) en el reporte.  
8) **Memoria**: incluir prueba de **no dependencia** (el proyecto debe funcionar igual con memoria OFF).  
9) **Lexicón anti-promesas**: listar patrones (“te aviso luego”, “lo haré después”, “próxima iteración”, “espera mientras”, “más tarde”, “cuando tenga…”) y penalizar su presencia.  
10) **Plantilla**: incluir **tabla** con char-counts por campo y **matriz** CI vs Proyecto con contradicciones específicas (cita del texto en conflicto).

---

## 6) Escalas de puntaje sugeridas (anclas)  
*(Ejemplo: Dimensiones de 20 puntos; ajuste proporcional en 10/15)*

**1) Claridad y enfoque (0–20)**  
- 0–5: objetivos ausentes/ambiguos; tono errático.  
- 6–10: objetivos presentes pero mezclan estilos o dejan ambigüedades.  
- 11–15: claros y consistentes; pocos “grises”.  
- 16–20: cristalinos, sin ambigüedad, tono estable y criterios operativos explícitos.

**2) Proactividad y contrato de entrega (0–20)**  
- 0–5: pide confirmaciones, promete entregas futuras, delega al usuario.  
- 6–10: parcialmente proactivo; contrato de 1 turno difuso.  
- 11–15: mayormente proactivo; contrato explícito pero con excepciones.  
- 16–20: “un turno, valor”, sin promesas, con **autoverificación**.

**3) Trazabilidad (0–15)**  
- 0–4: no hay citas o son no-oficiales.  
- 5–9: mezcla oficial/comunidad sin distinguir.  
- 10–12: citas oficiales presentes y separadas de comunidad/prensa.  
- 13–15: trazabilidad impecable, fechas incluidas, límites de quote respetados.

**4) Arquitectura de contexto (0–15)**  
- 0–4: depende de memoria; jerarquía incorrecta.  
- 5–9: jerarquía aceptable con pequeñas colisiones CI↔Proyecto.  
- 10–12: Proyecto prevalece y CI bien acotado.  
- 13–15: sin contradicciones; prompts limpios y subordinados.

**5) Operativa de archivos (0–10)**  
- 0–3: nombres problemáticos/sin empaquetado/uso no explicado.  
- 4–6: mayoría correcta; falta guía o hashes.  
- 7–8: correcto con guía de uso clara.  
- 9–10: excelente; estructura, hashes y reproducibilidad.

**6) Estado y verificación (antes “Actualización y UI”) (0–10)**  
- 0–3: sin comprobaciones; desconocen límites vigentes.  
- 4–6: algunas verificaciones; fechas/límites incompletos.  
- 7–8: verificaciones sistemáticas y recientes.  
- 9–10: todo medido, fechado y visible (memoria/estado/límites).

**7) Calidad de entregables (0–10)**  
- 0–3: no reproducibles; sin validaciones.  
- 4–6: ejemplos útiles pero sin chequeos.  
- 7–8: reproducibles con validaciones mínimas.  
- 9–10: listos para uso, con **pruebas internas** y criterios de aceptación.

---

## 7) Checklist operativo refinado (aplicable tal cual)
- **Inventario**: copiar textos de **Proyecto** y **CI (3 campos)**; estado **Memoria**; **lista de archivos** con **tamaños**.  
- **Medición**: calcular **caracteres** por campo y total; anotar **fecha** de medición.  
- **Contradicciones**: matriz breve CI↔Proyecto (área temática → par de citas en conflicto → decisión).  
- **Proactividad**: buscar patrones del **lexicón anti-promesas** y preguntas superfluas.  
- **Citas**: marcar **[Oficial]** vs **[Comunidad/Prensa]**; incluir fechas; limitar quotes.  
- **Archivos**: validar **ASCII**, estructura mínima, empaquetado `.zip`, **hashes** y **guía de uso**.  
- **Entrega**: limitar a **máx. 10 acciones** (no duplicadas), con **responsable** y **deadline sugerido**.

---

## 8) Plantilla de reporte mejorada (lista para pegar)
**Resumen (score total: X/100)**  
- Críticos: _n_ | Altos: _n_ | Medios: _n_ | Bajos: _n_  
**Métricas de tamaño**  
- CI1: _N_ chars | CI2: _N_ | CI3: _N_ | Proyecto: _N_ (límite ~1500/8000)  
**Estado**  
- Memoria: OFF / project-only | Última actualización auditoría: YYYY-MM-DD

**Puntajes por dimensión**  
1. Claridad y enfoque — _/20_  
2. Proactividad y contrato de entrega — _/20_  
3. Trazabilidad — _/15_  
4. Arquitectura de contexto — _/15_  
5. Operativa de archivos — _/10_  
6. Estado y verificación — _/10_  
7. Calidad de entregables — _/10_

**Matriz CI ↔ Proyecto (contradicciones)**  
- Tema → (Cita CI) vs (Cita Proyecto) → Resolución (prevalece Proyecto).

**Hallazgos → Acción (máx. 10, una línea c/u)**  
- Severidad — Hallazgo concreto → **Acción** (prop./deadline)  

**Evidencias**  
- Hashes de paquete `.zip`, lista de archivos con tamaños, citas **[Oficial]** con fecha.

---

## 9) Prompt operativo (ligeramente pulido)
> Audita este proyecto con el protocolo general. Entrega **puntuación por dimensión**, **hallazgos priorizados** y **acciones de una línea** (máx. 10). **Verifica límites** (CI ~1500 c/u; Proyecto ~8000 aprox.), **consistencia Proyecto↔CI** (prevalece Proyecto), **estado de Memoria**, y **políticas de entregables** (nombres ASCII, `.zip`, guía y hashes). **No hagas preguntas**; entrega el informe en **un solo turno** con métricas de tamaño y fecha.

---

## 10) Conclusión
El protocolo es **sólido** y aplicable “tal cual”. Para volverlo **auditable y repetible** en equipos y a lo largo del tiempo, recomiendo: **definir fuentes oficiales**, **anclar escalas de puntaje**, **precisar la medición de caracteres**, **renombrar la dimensión 6** a “Estado y verificación”, y **endurecer la operativa de archivos** (estructura + hashes). Con esos ajustes, se obtiene un **SOP robusto**, medible y accionable en un único turno.

## USER
Por favor formatea la configuración en XML

## Thoughts
Parece que el usuario quiere que convierta un protocolo en texto a una estructura XML. No es necesario navegar. Se especificó que la salida debe ser modularizada en XML con secciones como Metadatos, Entradas, Salidas, Pasos del Procedimiento, etc. También se incluyen atributos para pesos y demás detalles.
Voy a mantener los elementos en español sin acentos (como "ClaridadYEnfoque") y usar nombres ASCII, evitando espacios y diacríticos. Preferiré na-kebab o snake_case para los tags XML y me aseguraré de que todo esté bien modularizado. Incluiré un nodo raíz <ProtocoloAuditoriaProyecto version="1.0"> con secciones como "objetivo", "entradasRequeridas", "dimensiones pesas", "procedimiento", etc., siguiendo el protocolo dado.
Voy a incluir las reglas de validación, como el uso de nombres en ASCII, políticas de zip y guías de validación. También añadiré los valores de los pesos (totalizando 100) y definiré los límites de caracteres con `<limitesCaracteres>`. Para la plantilla de reporte, usaré CDATA para preservar la estructura. También agregaré el campo "promptOperativo" en español, sin necesidad de esquema XSD.
Voy a incluir módulos adicionales como `<metadatos>` con nombre y alcance, y `<politicasEntregables>` con reglas de validación. También añadiré un campo de severidades con enumeraciones de "Crítico, Alto, Medio, Bajo", pero sin definiciones extra, ya que el usuario solo pidió que se formatee el contenido, sin agregar nuevos criterios.

## ASSISTANT
```xml
<?xml version="1.0" encoding="UTF-8"?>
<auditoriaProtocolo xmlns="urn:anastasis-revenari:auditoria:1.0">
  <metadata>
    <nombre>Auditoría de Configuración de Proyecto — Protocolo General</nombre>
    <version>1.0</version>
    <proposito>Evaluar si un proyecto de ChatGPT aprovecha correctamente Custom Instructions, Project Instructions, archivos y (si aplica) Memoria — independientemente del dominio.</proposito>
  </metadata>

  <entradasRequeridas>
    <entrada id="project-instructions" tipo="texto">Texto actual en Project Instructions.</entrada>
    <entrada id="custom-instructions" tipo="texto" subcampos="3">Texto actual en Custom Instructions (los 3 campos).</entrada>
    <entrada id="memoria" tipo="estado">Capturas/confirmaciones de estado de Memoria (OFF o project-only).</entrada>
    <entrada id="archivos" tipo="lista">Listado de archivos del proyecto y su propósito.</entrada>
  </entradasRequeridas>

  <salidasEsperadas>
    <salida id="puntaje">Puntaje (0–100) por dimensiones.</salida>
    <salida id="hallazgos">Hallazgos priorizados (Crítico/Alto/Medio/Bajo).</salida>
    <salida id="acciones">Acciones correctivas concretas (una línea cada una).</salida>
  </salidasEsperadas>

  <dimensiones total="100">
    <dimension id="1" nombre="Claridad y enfoque" peso="20">
      <criterios>Objetivos definidos, tono consistente, cero ambigüedad.</criterios>
    </dimension>
    <dimension id="2" nombre="Proactividad y contrato de entrega" peso="20">
      <criterios>“Un turno, valor”; sin promesas; verificación propia.</criterios>
    </dimension>
    <dimension id="3" nombre="Trazabilidad" peso="15">
      <criterios>Citas a fuentes [Oficial] para capacidades; foros como [Comunidad/Prensa].</criterios>
    </dimension>
    <dimension id="4" nombre="Arquitectura de contexto" peso="15">
      <criterios>Jerarquía correcta (Proyecto &gt; CI &gt; Prompt), sin depender de memoria.</criterios>
    </dimension>
    <dimension id="5" nombre="Operativa de archivos" peso="10">
      <criterios>Nombres ASCII, empaquetado, instrucciones de uso.</criterios>
    </dimension>
    <dimension id="6" nombre="Actualización y UI" peso="10">
      <criterios>Comprobaciones de estado (Proyecto/Memoria), límites de campos medidos.</criterios>
    </dimension>
    <dimension id="7" nombre="Calidad de entregables" peso="10">
      <criterios>Ejemplos reproducibles, validaciones internas.</criterios>
    </dimension>
  </dimensiones>

  <limitesCampos>
    <campo nombre="CustomInstructions" presupuestoCaracteresAprox="1500"/>
    <campo nombre="ProjectInstructions" presupuestoCaracteresAprox="8000"/>
  </limitesCampos>

  <procedimiento>
    <paso numero="1" nombre="Inventario">Extrae texto de CI (3 campos) y Project Instructions; lista archivos y tamaños.</paso>
    <paso numero="2" nombre="Límites">Verifica que cada campo respete su presupuesto (CI ~1500 c/u; Proyecto ~8000 aprox.).</paso>
    <paso numero="3" nombre="Consistencia">Detecta contradicciones entre CI y Proyecto; Proyecto debe prevalecer.</paso>
    <paso numero="4" nombre="Proactividad">Busca frases de prometer más tarde o preguntas innecesarias; deben estar prohibidas.</paso>
    <paso numero="5" nombre="Citas">Comprueba presencia de citas [Oficial] cuando se hable de capacidades o planes.</paso>
    <paso numero="6" nombre="Entregables">Verifica que se pidan nombres ASCII, .zip cuando aplique y guía de validación.</paso>
    <paso numero="7" nombre="Reporte">Emite puntaje por dimensión y lista de acciones (máx. 10 ítems).</paso>
  </procedimiento>

  <politicasEntregables>
    <politica id="nombres-ascii">Requerir nombres ASCII.</politica>
    <politica id="paquete-zip">Usar empaquetado .zip cuando aplique.</politica>
    <politica id="guia-validacion">Incluir guía de validación.</politica>
  </politicasEntregables>

  <severidades>
    <nivel>Crítico</nivel>
    <nivel>Alto</nivel>
    <nivel>Medio</nivel>
    <nivel>Bajo</nivel>
  </severidades>

  <plantillaReporte>
    <ejemplo><![CDATA[
Resumen (score total: 84/100)
- Críticos: 0 | Altos: 1 | Medios: 3 | Bajos: 2
Hallazgos → Acción (una línea):
- Alto — Proyecto excede 8000 char: Reducir y mover detalle a archivos.
- Medio — CI carece de “un turno, valor”: Añadir contrato de entrega.
- Bajo — Falta política de .zip: Incluir en sección de entregables.
    ]]></ejemplo>
  </plantillaReporte>

  <promptOperativo><![CDATA[
Audita este proyecto con el protocolo general. Reporta puntuación por dimensión, hallazgos priorizados y acciones de una línea. Verifica límites (1500/8000 aprox.), consistencia Proyecto↔CI, y políticas de entregables. No hagas preguntas; entrega el informe en un turno.
  ]]></promptOperativo>
</auditoriaProtocolo>
```

