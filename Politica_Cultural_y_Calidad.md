# Política cultural y de calidad – Ecosistema Neurologic

Este documento define los principios culturales y los estándares técnicos mínimos que deben respetar todos los trabajos realizados dentro del ecosistema **Neurologic / Synapta**, tanto por personas como por agentes automatizados (incluyendo modelos IA como Codex o asistentes similares).

Se aplica a **todo el repositorio** y a cualquier proyecto que forme parte de él. Los documentos `AGENTS.md` específicos de cada proyecto pueden **endurecer** estas reglas, pero nunca rebajarlas.

---

## 1. Principios culturales

1. **Respeto al trabajo previo**  
   - El código, scripts, índices y motores existentes se consideran parte de un ecosistema vivo.  
   - No se desechan ni reescriben desde cero por comodidad, desconocimiento o impaciencia.  
   - Si algo no se entiende, primero se estudia y se documenta mejor; solo después se plantea una refactorización.

2. **Reutilización antes que reinvención**  
   - Ante cualquier nueva tarea, la pregunta por defecto es:  
     - “¿Ya existe un motor, módulo o script que resuelva parcial o totalmente esto?”  
   - Si existe algo reutilizable, se extiende o adapta.  
   - Crear un motor nuevo que duplique lo que otro ya hace se considera una regresión, no una mejora.

3. **Ecosistema coherente, no scripts desechables**  
   - Los scripts y herramientas no son piezas sueltas; forman parte de un ecosistema que debe mantenerse coherente y sostenible.  
   - Cada nueva pieza debe integrarse con las existentes (logs, índices, formatos de salida, módulos compartidos, etc.).

4. **Determinismo y previsibilidad**  
   - Mismos inputs → mismos outputs.  
   - Misma ruta / mismo contexto → mismas reglas.  
   - No se aceptan cambios que introduzcan comportamiento errático o dependiente de factores no controlados sin necesidad.

5. **Responsabilidad técnica**  
   - No se escogen soluciones “rápidas pero frágiles” cuando hay alternativas robustas razonables.  
   - Cada cambio debe pensarse como algo que va a convivir años con el resto del ecosistema.

---

## 2. Estándar técnico mínimo

Estos puntos definen el estándar técnico mínimo aceptable en el ecosistema. Cualquier solución que no cumpla esto debe considerarse un borrador o prototipo, no un trabajo terminado.

1. **Modularidad extrema**  
   - Motores de alto nivel (lectura de NTFS, recorridos recursivos, indexadores, motores de búsqueda, etc.) deben implementarse como **módulos reutilizables**, no como scripts monolíticos.  
   - El código de estos motores debe:
     - Estar separado de la UI.  
     - Exponer APIs claras (funciones/métodos bien definidas).  
     - Poder ser consumido por múltiples scripts o aplicaciones sin modificaciones.

2. **Indexadores e infraestructura de memoria**  
   - Cuando existe un indexador (por ejemplo, en proyectos como `Ws_Insights`), este se considera la **fuente de verdad** para paths, hashes, metadatos y resultados de búsqueda.  
   - Los nuevos componentes deben integrarse con el indexador existente antes de inventar estructuras paralelas.

3. **Rendimiento y escalabilidad**  
   - Evitar recorridos masivos sin filtros (`Get-ChildItem` recursivo a ciegas, escaneos completos sin necesidad, etc.).  
   - Priorizar:
     - Lectura por lotes (batching).  
     - Paralelismo razonable ajustado a recursos del sistema.  
     - Procesamiento en streaming cuando el volumen de datos lo justifique.  
   - El consumo de CPU y RAM debe ser explícitamente considerado en el diseño.

4. **Entradas y salidas estructuradas**  
   - Los procesos de larga duración deben producir salidas estructuradas (NDJSON, JSON, CSV, etc.) y logs útiles.  
   - Las salidas intermedias deben poder reutilizarse por otros scripts (por ejemplo, NDJSON que luego se consolida a CSV/JSON final).  
   - Evitar generar grandes cantidades de archivos basura; cualquier artefacto temporal debe tener una política clara de limpieza.

5. **Hashing y deduplicación**  
   - Para identificación y deduplicación de archivos:
     - Preferir algoritmos rápidos (por ejemplo, xxHash3).  
     - Usar hashes más pesados solo cuando exista una razón explícita.

6. **Diseño de scripts**  
   - Los scripts deben ser:
     - Completos y ejecutables (no fragmentos sueltos).  
     - Parametrizables, sin depender de valores hardcodeados donde no sea necesario.  
     - Capaces de reanudar o continuar trabajos largos cuando tenga sentido (idempotencia y/o checkpoints).  
   - No se aceptan scripts que dependan de rutas mágicas no documentadas.

7. **.NET y multi-framework**  
   - En proyectos .NET, los archivos de proyecto deben usar **multi-targeting** salvo justificación explícita documentada:  
     - Aplicaciones Windows/WPF:
       ```xml
       <TargetFrameworks>net8.0-windows;net7.0-windows;net6.0-windows</TargetFrameworks>
       <UseWPF>true</UseWPF>
       ```
     - Librerías:
       ```xml
       <TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>
       ```
   - Nunca degradar un proyecto multi-framework a single-target sin un motivo documentado.

---

## 3. Reutilización de motores e indexadores

1. **Búsqueda de componentes existentes**  
   Antes de crear un nuevo motor, indexador o utilidad compleja, se debe:
   - Revisar la estructura del repositorio.  
   - Consultar la documentación disponible (README, AGENTS específicos, mapas de archivos, CSV de inventario, etc.).  
   - Confirmar si ya existe algo equivalente o similar.

2. **Extensión en lugar de duplicación**  
   - Si existe un módulo funcional que cubre parte del problema, la regla por defecto es **extenderlo**, no duplicarlo.  
   - Cualquier nueva funcionalidad debe integrarse como:
     - Métodos adicionales.  
     - Nuevos modos de operación.  
     - Nuevos adaptadores que llamen al motor existente.

3. **Migración hacia versiones mejores**  
   - Cuando se construye una versión mejorada de un motor, se deben migrar gradualmente sus usos actuales para evitar ramas paralelas incompatibles.  
   - Dejar múltiples motores “casi iguales” en producción se considera una deuda técnica a corregir.

4. **Documentación mínima obligatoria**  
   - Los motores e indexadores deben tener:
     - Comentarios claros en el código.  
     - Una descripción básica en la documentación relevante (README, AGENTS del proyecto, o archivo equivalente).  
   - La falta de documentación en un motor crítico es un problema a resolver, no un estado aceptable permanente.

---

## 4. Determinismo y no regresión

1. **Determinismo**  
   - Un mismo conjunto de entradas debe producir el mismo conjunto de salidas, salvo cambios deliberados en configuración o entorno.  
   - Las decisiones pseudoaleatorias deben evitarse o, si son necesarias, controlarse mediante semillas reproducibles.

2. **Bases estables**  
   - Cuando un componente demuestra comportamiento correcto y estable, se considera **base** para trabajos futuros.  
   - No se reemplaza una base sólida por una versión más simple pero peor solo por comodidad.

3. **Reescrituras desde cero**  
   - Reescribir un motor desde cero porque “no se encontró el script anterior” o “no se entiende el código actual” se considera un fallo del sistema de trabajo.  
   - La respuesta adecuada es:
     - Localizar el código.  
     - Mejorar documentación.  
     - Refactorizar incrementalmente, no borrar y empezar de cero sin análisis.

4. **Criterio de aceptación**  
   - Un cambio que empeora rendimiento, integrabilidad o determinismo no debe considerarse aceptable, aunque “funcione” en un caso simple.

---

## 5. Rol de los agentes IA

Estas reglas aplican tanto a personas como a agentes automatizados. Para agentes IA (por ejemplo, Codex, asistentes de ChatGPT u otros modelos), se añaden los siguientes puntos explícitos:

1. **Lectura previa del contexto**  
   - Antes de generar código o scripts, el agente debe:
     - Revisar las reglas de este documento.  
     - Consultar los `AGENTS.md` específicos del proyecto (si existen).  
     - Considerar la arquitectura e indexadores definidos.

2. **Búsqueda de reutilización**  
   - La acción por defecto no es “escribir código nuevo”, sino:
     - Ver si hay módulos, scripts o motores ya documentados que puedan usarse.  
     - Solo después, generar código nuevo que encaje con ese ecosistema.

3. **Entrega A→Z, no trabajos a medias**  
   - Las respuestas deben ofrecer soluciones completas y accionables (scripts, configuraciones, módulos), no esqueletos vagos.  
   - No delegar al usuario la tarea de “rellenar la mitad del código” cuando el agente puede generarlo.

4. **Respeto a este estándar**  
   - Cualquier sugerencia que vaya en contra de estos principios (scripts desechables, duplicación de motores, degradación de proyectos multi-framework, etc.) debe considerarse errónea y corregirse.

---

## 6. Checklist de calidad antes de integrar cambios

Antes de considerar un trabajo como "aceptado" dentro del ecosistema, debe pasar por la siguiente lista mínima:

1. ¿Reutiliza o extiende motores / indexadores / módulos existentes cuando corresponde?  
2. ¿Evita duplicar funcionalidades que ya existen en otra parte del repositorio?  
3. ¿Respeta la estructura de módulos, namespaces y proyectos definida para su área?  
4. ¿Cumple el estándar técnico mínimo (modularidad, rendimiento razonable, salidas estructuradas)?  
5. En .NET, ¿respeta el esquema de multi-framework (net8/net7/net6) o está justificada cualquier excepción?  
6. ¿Ofrece un comportamiento determinista y reproducible?  
7. ¿Está acompañado de la documentación mínima necesaria para que otro agente o persona pueda entenderlo y reutilizarlo?

Si alguna de estas respuestas es “no”, el trabajo debe tratarse como un borrador a mejorar, no como un resultado final.
