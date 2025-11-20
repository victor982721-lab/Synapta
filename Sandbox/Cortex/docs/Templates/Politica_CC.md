# Política cultural y de calidad – Ecosistema Neurologic

Este documento define los principios culturales y los estándares técnicos mínimos que deben respetar todos los trabajos realizados dentro del ecosistema **Neurologic/Synapta**, tanto por personas como por agentes automatizados (incluyendo modelos de IA como Codex o ChatGPT).  Se aplica a todo el repositorio y a cualquier proyecto que forme parte de él.  Los documentos `AGENTS.md` específicos de cada proyecto pueden **endurecer** estas reglas, pero nunca rebajarlas.

---

## 1. Principios culturales

1. **Respeto al trabajo previo** – El código, los scripts, índices y motores existentes forman parte de un ecosistema vivo.  No se desechan ni se reescriben desde cero por comodidad o desconocimiento; si algo no se entiende, primero se estudia y se documenta mejor.
2. **Reutilización antes que reinvención** – Ante cualquier nueva tarea se debe comprobar si ya existe un motor, módulo o script que la resuelva parcial o totalmente.  Si existe algo reutilizable, se extiende o se adapta; duplicar un motor existente se considera una regresión.
3. **Ecosistema coherente, no scripts desechables** – Las herramientas no son piezas sueltas: cada nueva pieza debe integrarse con logs, índices, formatos de salida y módulos compartidos existentes.
4. **Determinismo y previsibilidad** – Mismos inputs → mismos outputs.  Las decisiones pseudoaleatorias deben evitarse o controlarse mediante semillas reproducibles.
5. **Responsabilidad técnica** – No se eligen soluciones rápidas pero frágiles cuando existen alternativas robustas razonables.  Cada cambio debe pensarse como algo que convivirá años con el resto del ecosistema.

---

## 2. Estándar técnico mínimo

1. **Modularidad extrema** – Motores de alto nivel (lectura de NTFS, indexadores, motores de búsqueda, etc.) deben implementarse como módulos reutilizables desacoplados de la UI.  El código debe exponer APIs claras y poder ser consumido por múltiples scripts o aplicaciones sin modificaciones.
2. **Indexadores e infraestructura de memoria** – Cuando exista un indexador, éste se considera la fuente de verdad para rutas, hashes, metadatos y resultados de búsqueda.  Los nuevos componentes deben integrarse con él antes de inventar estructuras paralelas.
3. **Rendimiento y escalabilidad** – Evitar recorridos masivos sin filtros.  Priorizar lectura por lotes, paralelismo razonable y procesamiento en streaming cuando sea necesario.  Considerar explícitamente el consumo de CPU y RAM en el diseño.
4. **Entradas y salidas estructuradas** – Los procesos de larga duración deben producir salidas estructuradas (NDJSON, JSON, CSV) y logs útiles; evitar archivos basura y establecer una política clara de limpieza.
5. **Hashing y deduplicación** – Preferir algoritmos rápidos (por ejemplo, xxHash3) para identificación y deduplicación; usar hashes más pesados solo cuando esté justificado.
6. **Diseño de scripts** – Entregar scripts completos, parametrizables e idempotentes en la medida de lo posible.  No depender de rutas mágicas no documentadas.
7. **.NET y multi‑framework** – En proyectos .NET se debe desarrollar para **.NET 8** y mantener compatibilidad con .NET 7 y .NET 6.  Los archivos de proyecto deben usar multi‑targeting (`net8.0;net7.0;net6.0` para librerías y `net8.0‑windows;net7.0‑windows;net6.0‑windows` para aplicaciones).  Nunca degradar un proyecto multi‑framework a single‑target sin una justificación documentada.  Se prioriza el funcionamiento en las condiciones reales del entorno del usuario y se deja abierta la integración a futuras versiones.

---

## 3. Reutilización de motores e indexadores

1. **Búsqueda de componentes existentes** – Antes de crear un motor nuevo se debe revisar la estructura del repositorio, la documentación disponible y los CSV de inventario para confirmar si ya existe algo equivalente o similar.
2. **Extensión en lugar de duplicación** – Si existe un módulo funcional que cubre parte del problema, por defecto se debe extender o adaptar en lugar de duplicar.  Nuevas funcionalidades deben integrarse mediante métodos adicionales, modos de operación o adaptadores que llamen al motor existente.
3. **Migración hacia versiones mejores** – Cuando se construya una versión mejorada de un motor, se deben migrar gradualmente sus usos actuales para evitar ramas paralelas incompatibles.  Mantener múltiples motores casi iguales se considera una deuda técnica a corregir.
4. **Documentación mínima obligatoria** – Los motores e indexadores deben tener comentarios claros en el código y una descripción básica en la documentación relevante (README, AGENTS del proyecto).  La falta de documentación en un motor crítico es un problema a resolver.

---

## 4. Determinismo y no regresión

1. **Determinismo** – Un mismo conjunto de entradas debe producir el mismo conjunto de salidas salvo cambios deliberados en configuración o entorno.  Las decisiones pseudoaleatorias deben controlarse con semillas reproducibles.
2. **Bases estables** – Un componente probado y estable se considera base para trabajos futuros.  No se reemplaza una base sólida por una versión más simple pero peor por comodidad.
3. **Reescrituras desde cero** – Reescribir un motor desde cero porque “no se encuentra” o “no se entiende” el código actual se considera un fallo del sistema.  La respuesta adecuada es localizar el código, mejorar la documentación y refactorizar de forma incremental.
4. **Criterio de aceptación** – Un cambio que empeora rendimiento, integrabilidad o determinismo no debe considerarse aceptable aunque “funcione” en un caso simple.

---

## 5. Rol de los agentes IA

1. **Lectura previa del contexto** – Antes de generar código o scripts, el agente debe leer este documento, consultar los `AGENTS.md` específicos del proyecto y considerar la arquitectura e indexadores definidos.
2. **Búsqueda de reutilización** – La acción por defecto no es “escribir código nuevo” sino revisar módulos, scripts o motores ya documentados que puedan usarse.  Solo después se genera código nuevo que encaje en el ecosistema.
3. **Entrega A→Z** – Las respuestas deben ofrecer soluciones completas y accionables (scripts, configuraciones, módulos), no esqueletos vagos; no delegar al usuario la tarea de rellenar la mitad del código cuando el agente puede generarlo.
4. **Respeto a este estándar** – Cualquier sugerencia que vaya en contra de estos principios (scripts desechables, duplicación de motores, degradación de proyectos multi‑framework) debe considerarse errónea y corregirse.

---

## 6. Checklist de calidad antes de integrar cambios

Antes de aceptar un trabajo en el ecosistema Neurologic, debe pasarse por la siguiente lista mínima:

1. ¿Reutiliza o extiende motores/indexadores/módulos existentes cuando corresponde?
2. ¿Evita duplicar funcionalidades que ya existen en otra parte del repositorio?
3. ¿Respeta la estructura de módulos, namespaces y proyectos definida para su área?
4. ¿Cumple el estándar técnico mínimo (modularidad, rendimiento razonable, salidas estructuradas)?
5. En proyectos .NET, ¿respeta el esquema multi‑framework (`net8/net7/net6`) o está justificada cualquier excepción?
6. ¿Ofrece un comportamiento determinista y reproducible?
7. ¿Está acompañado de la documentación mínima necesaria para que otro agente o persona pueda entenderlo y reutilizarlo?

Si alguna respuesta es “no”, el trabajo debe tratarse como un borrador a mejorar, no como un resultado final.