# Procedimiento de Integración de Nuevos Módulos
Este procedimiento define cómo deben añadirse nuevos módulos al proyecto sin romper modularidad, sin generar dependencias innecesarias y siguiendo la arquitectura establecida.

---

## 1. Principio General
Un nuevo módulo debe integrarse sin alterar la estabilidad del sistema existente.  
Cada módulo debe cumplir:

- Independencia estructural.  
- Dependencia descendente (solo hacia el Core, no hacia capas superiores).  
- Ausencia de reescrituras innecesarias.  

No se agrega ningún módulo sin aprobación explícita del usuario.

---

## 2. Validación Inicial
Antes de crear un nuevo módulo, el asistente debe confirmar:

1. Su propósito exacto.  
2. Si pertenece al Core, CLI, Wizard o GUI.  
3. Si requiere dependencias adicionales.  
4. Si afecta módulos existentes.  
5. Si su implementación respeta la arquitectura del proyecto.  

Si existe ambigüedad, se debe solicitar aclaración.

---

## 3. Creación del Módulo
El asistente debe:

- Crear el módulo completo en un solo archivo o carpeta (según corresponda).  
- Respetar la ubicación esperada dentro de la estructura.  
- Asegurar que no introduce dependencias cruzadas.  
- No mezclar responsabilidades: un módulo = una función clara.  
- No incluir lógica duplicada del Core.  

El módulo se entrega únicamente en formato estable y final, listo para usarse.

---

## 4. Integración con Etapas Existentes
Cada módulo nuevo debe integrarse así:

### 4.1. Si pertenece al Core
- Debe ser totalmente independiente.  
- No puede depender de CLI, Wizard o GUI.  
- Sus métodos deben ser consumibles sin cambios por etapas superiores.

### 4.2. Si pertenece a la CLI
- Debe usar solo funciones del Core.  
- No debe alterar parsers previos sin aprobación del usuario.  
- Debe mantenerse simple y extensible.

### 4.3. Si pertenece al Wizard
- Debe construir parámetros compatibles con el CLI.  
- No debe duplicar lógica del Core o CLI.  
- Debe integrar pasos nuevos sin alterar flujos anteriores.

### 4.4. Si pertenece a la GUI
- Debe ser exclusivamente una capa de presentación.  
- No incluir lógica nueva que no exista en etapas previas.  
- No mover operaciones hacia code-behind.  

---

## 5. Validación después de integrar
Una vez generado el módulo, el asistente debe verificar:

- Que compila sin errores.  
- Que no rompe la arquitectura existente.  
- Que no genera reescrituras futuras.  
- Que se integra correctamente con su capa inmediata.  

---

## 6. Correcciones del Módulo
Si el módulo requiere cambios:

- El asistente aplica el procedimiento de corrección modular descrito en *CorreccionModular.md*.  
- Entrega el módulo completo corregido.  
- Nunca solicita correcciones manuales al usuario.  

---

## 7. Cierre de la Integración
Para considerar completada la integración:

1. El módulo compila.  
2. Las interacciones con capas existentes funcionan.  
3. No se detectan dependencias indebidas.  
4. El usuario valida y aprueba.  
5. Se evita deuda técnica.  

---

## 8. Objetivo General
Mantener un crecimiento ordenado del proyecto, donde cada módulo nuevo:

- Se añade de forma limpia.  
- Se integra sin romper nada previo.  
- Es completamente estable desde su nacimiento.  
