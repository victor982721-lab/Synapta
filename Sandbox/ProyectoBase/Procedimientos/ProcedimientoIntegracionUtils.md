# Procedimiento de Integración de Utils en el Proyecto
Este procedimiento define cómo se integran, administran y mantienen las utilidades (Utils) dentro del proyecto, garantizando compatibilidad, modularidad y estabilidad total.

---

# 1. Ubicación de las Utilidades
Todas las funciones reutilizables de PowerShell deben almacenarse en:

- /Utils → funciones aprobadas y estables  
- /Utils_Experimental → funciones en revisión, no cargadas automáticamente

---

# 2. Carga Automática del Módulo Utils
El módulo Utils.psm1 se carga automáticamente desde el perfil de PowerShell, por lo que todas las funciones aprobadas están disponibles sin intervención del usuario.

Reglas:
- Solo se cargan .ps1 ubicados en /Utils.
- Los .ps1 de /Utils_Experimental no se cargan hasta aprobación explícita.

---

# 3. Agregar Nuevas Funciones
Para incorporar una nueva utilidad:

1. El asistente debe generar un .ps1 completo, listo para escribirse en /Utils_Experimental.
2. Debe contener la función totalmente corregida y lista.
3. El archivo NO debe sustituir a otro hasta ser aprobado.
4. Una vez aprobada, se mueve automáticamente a /Utils reemplazando el existente si aplica.

El asistente nunca debe pedir al usuario que copie, pegue o modifique manualmente.

---

# 4. Estructura de Cada Función
Cada .ps1 debe cumplir:

- Contener exactamente UNA función.  
- Sin lógica externa, sin variables sueltas.  
- Sin escribir en disco salvo autorización explícita.  
- Con buffer interno para logs temporales.  
- Con nombres descriptivos, claros y consistentes.  

---

# 5. Actualización de Funciones
Si una función requiere corrección:

- El asistente entrega el archivo completo, corregido.  
- Manteniendo exactamente el mismo nombre.  
- Sin versiones previas, sin numeraciones, sin comentarios del historial.  
- Reemplaza automáticamente el archivo dentro de /Utils.  

---

# 6. Integración con Otros Componentes del Proyecto
Los Utils pueden ser utilizados por:

- Core  
- CLI  
- Wizard  
- GUI  

Pero no deben generar dependencias hacia ellos.  
Utils debe ser independiente y autónomo.

---

# 7. Objetivo Final del Procedimiento
Asegurar que todas las utilidades del proyecto:

- sean robustas,  
- estén centralizadas,  
- carguen automáticamente,  
- sean fáciles de mantener,  
- y no generen deuda técnica futura.

Este procedimiento garantiza que el módulo Utils crezca de manera ordenada y estable, manteniendo coherencia con la arquitectura general del proyecto.
