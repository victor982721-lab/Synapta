# AGENTS – Neurologic (General)

Este documento define las reglas globales para el agente **Codex** al trabajar en el repositorio **Neurologic**.  Se aplica junto con la **Política cultural y de calidad** del ecosistema.  Los `AGENTS.md` específicos de cada proyecto pueden añadir reglas más estrictas, pero nunca debilitar este estándar.

## 1. Prioridad de reglas

1. **Política cultural y de calidad** – principios culturales y estándares mínimos.
2. `AGENTS.md` **específico del proyecto o subproyecto** (si existe).
3. Este **AGENTS general**.

En caso de conflicto, prevalece la regla más específica siempre que no contradiga la política global.

## 2. Entorno y lenguajes

* **Sistema operativo principal**: Windows 10.  Se requiere compatibilidad desde Windows 7 hasta Windows 11.
* **Shell principal**: PowerShell 7.5.x (`pwsh`).  Se admite compatibilidad desde PowerShell 5 en adelante (5.x, 6.x, 7.x) para preservar entornos legacy.
* **Lenguajes permitidos**: C# (.NET), PowerShell, Python y Bash (solo cuando tenga sentido en este entorno).
* **Compatibilidad con Linux**: no se requiere compatibilidad con Linux en esta fase; los flujos basados en WSL/WSL2 siguen prohibidos salvo instrucción explícita.
* **Proyectos .NET**: se deben desarrollar para **.NET 8**, manteniendo compatibilidad con .NET 7 y .NET 6 mediante multi‑targeting (`net8.0;net7.0;net6.0` para librerías y `net8.0‑windows;net7.0‑windows;net6.0‑windows` para aplicaciones).  No degradar a single‑target sin una justificación documentada.  Priorizar el funcionamiento en el entorno real del usuario y dejar listo el camino para futuras versiones.

## 3. Principios globales

1. **Reutilización antes que reinvención** – Antes de crear un motor o módulo nuevo, revisar la estructura del repositorio, la documentación y los CSV de inventario para ver si ya existe algo similar.
2. **Modularidad y determinismo** – Implementar funcionalidades complejas como módulos reutilizables desacoplados de la UI; garantizar que mismos inputs producen mismos outputs.
3. **No duplicación de motores** – Los indexadores y motores existentes se consideran la fuente de verdad.  Extenderlos mediante nuevas funciones o adaptadores en lugar de crear clones.
4. **Entrega completa** – Codex debe entregar scripts o archivos completos y listos para ejecutar; no diffs parciales ni fragmentos sueltos.
5. **Respeto a la estructura** – Mantener `namespace = ruta de carpeta`; no crear carpetas ni mover archivos sin instrucción o regla explícita.
6. **Compatibilidad y pruebas** – Mantener compatibilidad hacia atrás en APIs públicas; acompañar cada módulo con pruebas automáticas.

## 4. Comportamiento esperado de Codex

Antes de generar código, Codex debe:

* Leer este AGENTS general, la **Política** y el `AGENTS.md` específico del subproyecto.
* Revisar la arquitectura (motores, indexadores y módulos comunes) antes de proponer soluciones.
* Extender motores o módulos existentes en vez de duplicarlos.
* Entregar resultados de extremo a extremo: código listo para ejecutar, con documentación mínima, pruebas y actualización de CSV y docs.
* No introducir dependencias pesadas ni simplificar un motor sólido a una versión inferior sin justificación.

## 5. Resumen rápido

1. Leer el contexto y las reglas antes de actuar.
2. Reutilizar lo existente y mantener modularidad y determinismo.
3. Cumplir el esquema multi‑target de .NET.
4. Entregar código completo, ejecutable y alineado con las convenciones.
5. Consultar y respetar los `AGENTS.md` específicos donde se trabaje.