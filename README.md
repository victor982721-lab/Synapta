# **README — Synapta.SearchEngine**

## **Propósito general**

`Synapta.SearchEngine` es un motor especializado para búsqueda de texto de alta velocidad dentro del ecosistema **Synapta**, encargado de localizar contenido dentro de grandes volúmenes de archivos con máxima eficiencia, mínima latencia y soporte para cargas de trabajo intensivas.

El motor está diseñado como un subsistema autónomo que se integra con la aplicación principal de Ws_Insights, proporcionando una capa interna responsable de **indexación**, **resolución de consultas**, **filtrado avanzado**, y **servicio de búsqueda incremental**.

No implementa UI, no administra ventanas y no genera elementos visuales; su único objetivo es proporcionar a Synapta un motor de búsqueda completo, robusto y escalable.

---

## **Rol dentro de Synapta**

El motor actúa como:

* **Proveedor interno de búsqueda** para el módulo de análisis y extracción de información.
* **Componente central** responsable de detectar coincidencias en texto dentro de millones de archivos.
* **Base de apoyo** para vistas, paneles y funciones donde Ws_Insights debe mostrar resultados rápidos, prefiltrados y consistentes.
* **Infraestructura de indexación persistente**, permitiendo que Ws_Insights mantenga un estado optimizado entre sesiones.
* **Capa de alto rendimiento** que descarga a la UI de trabajo intensivo.

---

## **Por qué existe**

Synapta requiere:

* Consultas de texto con tiempos constantes incluso en repositorios enormes.
* Evitar volver a escanear disco en cada búsqueda.
* Reducir al mínimo la latencia al abrir rutas, revisar segmentos, filtrar por extensiones y analizar contenidos.
* Escalabilidad real: desde cientos hasta millones de archivos sin degradación significativa.
* Procesamiento intensivo en paralelo sin bloquear la UI principal.
* Soporte para patrones complejos (regex, whole-word, case-sensitive).

El motor encapsula estos requerimientos y los presenta mediante una API estandarizada.

---

## **Funciones que proporciona**

Aunque este README no describe implementación, sí deja claro el alcance funcional:

### **1. Indexación**

* Construcción completa del índice sobre un árbol de archivos.
* Indexación incremental: nuevos, modificados, eliminados.
* Segmentos inmutables y merges controlados.

### **2. Búsqueda**

* Resolución de consultas de texto sobre el índice o directamente sobre disco cuando sea necesario.
* Soporte para:

  * Literales
  * Regex (con backend extensible)
  * Whole-word
  * Case-sensitive
* Resultados en streaming para integración directa con la UI.

### **3. Optimización**

* Lecturas memory-mapped.
* Filtros preliminares mediante Bloom filters.
* Tokenización SIMD.
* Matching con DFA/NFA.
* Caches internas para minimizar accesos a disco.

### **4. Integración con Synapta**

* Expuesto mediante la capa `Public/` (`SearchEngine`, `IndexService`, `Analyzer`, `Diagnostics`).
* Se integra con los ViewModels de Ws_Insights mediante `SearchOptions` y enumerables asincrónicos de resultados.

---

## **Qué no es**

* No es un módulo de UI.
* No administra ventanas ni paneles.
* No define estilos, XAML ni controles.
* No maneja navegación ni interacción visual.
* No es responsable de exportar CSV, Markdown ni HTML (Synapta lo hace).

El motor se limita al **trabajo pesado de búsqueda e indexación**.

---

## **Arquitectura general**

El motor está dividido en subsistemas independientes organizados así:

* **Core**: opciones, contexto, pipeline y tipos fundamentales.
* **Index**: segmentos, metadatos, diccionarios, postings, Bloom filters.
* **IO**: enumeración de archivos, metadatos, lectura memory-mapped, scheduler IO.
* **Processing**: tokenizador SIMD, automatas DFA/NFA, regex extensible.
* **Cache**: hot files, query cache, buffer pools.
* **Public**: API que Ws_Insights utiliza.

Cada subsistema está aislado y puede ser probado individualmente.

---

## **Consumo desde Synapta**

La capa pública expone las operaciones necesarias para que Synapta:

* Construya índices.
* Los actualice cuando cambia el sistema de archivos.
* Ejecute búsquedas sobre el índice o sobre disco.
* Reciba resultados parciales rápidamente.
* Obtenga estadísticas de uso y rendimiento.

Todo lo demás (UI, UX, representaciones visuales, exportación) es responsabilidad de Ws_Insights.

---

## **Estado del proyecto**

El diseño es modular, extensible y preparado para optimizaciones progresivas como:

* Compilación JIT de patrones.
* Hyperscan opcional.
* Column stores más densos.
* Indexación distribuida.

Nada en el diseño depende de servicios de pago o licencias no-gratuitas.

Si quieres que produzca también un **`AGENT.spec.json`** o un **archivo `ARCHITECTURE.md`** para que Codex genere implementaciones automáticas, lo hago en el siguiente mensaje.
