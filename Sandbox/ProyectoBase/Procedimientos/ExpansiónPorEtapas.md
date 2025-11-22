# Procedimiento de Expansión por Etapas
Este procedimiento define la manera en la que el proyecto debe crecer de forma modular, sin generar reescrituras innecesarias y manteniendo un orden cronológico estricto en capas: **Core → CLI → Wizard → GUI**.

---

## 1. Principio General de Expansión
La expansión del proyecto se realizará únicamente por etapas consecutivas.  
Cada nueva capa depende de la anterior, pero **no la modifica**.  
Cada etapa debe quedar completamente estable antes de pasar a la siguiente.

---

## 2. Etapa 1 — Núcleo (Core)
### Objetivo  
Crear la lógica fundamental del proyecto, aislada de interfaces, entrada de usuario o modos de operación.

### Reglas  
- No incluir dependencias hacia CLI, Wizard o GUI.  
- Mantener clases y métodos independientes del entorno.  
- Priorizar claridad, estabilidad y facilidad de prueba.  
- Asegurar que la lógica sea consumible por cualquier capa futura.  

### Cierre de etapa  
- Validar que el Core funciona con una entrada mínima.  
- Verificar que no existen dependencias cruzadas.  
- Confirmar con el usuario antes de avanzar.

---

## 3. Etapa 2 — Interfaz de Línea de Comandos (CLI)
### Objetivo  
Exponer el Core a través de argumentos y flags.  
El CLI es la primera capa que “opera” sobre el Core.

### Reglas  
- No modificar el Core para acomodar la CLI.  
- Implementar un parser simple, mantenible y extensible.  
- Integrar validación mínima antes de enviar parámetros al Core.  
- Mantener un modo de ayuda claro (--help).  
- No agregar modos Wizard ni GUI en esta etapa.

### Cierre de etapa  
- Validar ejecución CLI real.  
- Probar flags principales.  
- Confirmar estructura antes de continuar.

---

## 4. Etapa 3 — Wizard Interactivo
### Objetivo  
Construir una interfaz paso a paso que facilite el armado de parámetros del CLI sin obligar al usuario a memorizar flags.

### Reglas  
- El Wizard genera opciones y luego llama al Core o al CLI.  
- No duplicar lógica presente en el Core o CLI.  
- No crear flujos complejos aún; mantener simplicidad.  
- Asegurar navegabilidad clara entre pasos.  
- Solicitar confirmación antes de ejecutar.

### Cierre de etapa  
- Validar que el Wizard produzca exactamente las mismas opciones que el CLI.  
- Confirmar que no se generan dependencias hacia la GUI.  
- Asegurar que no se altera ningún comportamiento del Core.

---

## 5. Etapa 4 — GUI (Interfaz Gráfica)
### Objetivo  
Añadir una interfaz visual (WPF) para usar el proyecto mediante formularios, vistas y botones.

### Reglas  
- La GUI no reemplaza al Wizard ni al CLI.  
- No mover lógica del Core hacia code-behind de la GUI.  
- Evitar integrar funciones que no existan previamente en las etapas anteriores.  
- Mantener la GUI como una “capa de presentación” únicamente.  
- La GUI recoge datos → los transforma en opciones → llama al Core.

### Cierre de etapa  
- Verificar estabilidad de la GUI.  
- Validar integración sin romper las etapas previas.  
- Confirmar compatibilidad y modularidad final.

---

## 6. Condiciones para avanzar entre etapas
Solo se avanza cuando:
- La etapa actual está estable.  
- No hay dependencias incorrectas.  
- Se cumple modularidad.  
- El usuario da aprobación explícita.

---

## 7. Correcciones dentro de las etapas
Las correcciones deben:

- Aplicarse siguiendo el archivo **CorreccionModular.md**.  
- Entregarse en módulos completos.  
- Proteger la arquitectura Core → CLI → Wizard → GUI.  
- Evitar reescrituras innecesarias.

---

## 8. Objetivo general del procedimiento
Asegurar que el proyecto crezca de forma ordenada, sin improvisaciones, sin romper etapas previas y sin pérdida de control técnico ni emocional por parte del usuario.

Cada etapa añade una capa, nunca altera la anterior.
