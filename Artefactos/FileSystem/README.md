# FileSystem

**Estado:** Plantilla inicial – Sin implementación aún.

Este módulo contendrá utilidades de alto rendimiento para interactuar con el sistema de archivos NTFS en Windows. Su intención es centralizar funciones que hoy se replican en varios scripts y proyectos del ecosistema Neurologic.

## Objetivos

* Exponer API para leer y suscribirse al **USN Journal**, permitiendo detectar cambios en tiempo real.
* Proveer funciones de recorrido recursivo de directorios con filtros avanzados (por extensión, fecha, tamaño, exclusión de carpetas, etc.).
* Calcular hashes rápidos (xxHash3) y hashes criptográficos (MD5/SHA256) sobre archivos o fragmentos.
* Permitir extensiones para buscar archivos duplicados y detectar movimientos/renombrados a través de comparaciones de hashes y tamaños.

## Uso previsto

Como biblioteca, otros proyectos (como `Ws_Insights` o futuras utilidades CLI) podrán referenciar este módulo para acceder a sus funciones sin necesidad de reimplementar la lógica. Cuando la API esté lista se incluirán ejemplos de uso en este README.

## Cómo colaborar

* Antes de añadir código, revisa la estructura propuesta en `Core/AGENTS.md` y la Política cultural.
* Abre un issue o pull request describiendo la API que planeas implementar. Adjunta pruebas unitarias para cada función pública.
* Asegúrate de que tu código funciona en net6/7/8 y no utiliza APIs de Windows que limiten la portabilidad si el objetivo pudiera cambiar en el futuro.
