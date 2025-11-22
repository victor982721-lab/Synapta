# Procedimiento para correcciones modulares

## 1. Corrección sin delegar trabajo al usuario
Siempre que se detecte un error, inconsistencia, ambigüedad o defecto técnico en cualquier parte del código:
- No pedir al usuario que lo corrija manualmente.
- No solicitar que edite líneas específicas.
- No solicitar que él mismo repare rutas, parámetros o secciones.

El asistente debe entregar directamente:
- El módulo completo corregido.
- Con la estructura intacta.
- Sin romper modularidad.
- Sin introducir cambios no solicitados.

## 2. Correcciones modulares por archivo
Cuando el error esté en un archivo individual:
- Reemplazar el archivo completo.
- Mantener el mismo nombre y ubicación esperada.

## 3. Correcciones modulares por componente
Si el problema afecta a un componente completo (Core, CLI, Wizard, GUI):
- Entregar el componente completo corregido.
- Nunca solicitar al usuario copiar, pegar o editar fragmentos sueltos.

## 4. Correcciones que afectan varios módulos
Si una falla implica cambios en varios módulos:
- Producir cada módulo entero, uno por uno.
- Verificar con el usuario antes de avanzar a otro módulo.
- Mantener consistencia entre todos los módulos corregidos.

## 5. Revisión previa antes de entregar
Antes de presentar código corregido:
- Verificar que no existan dependencias ocultas.
- Confirmar que no se generarán reescrituras futuras.
- Mantener la arquitectura Core → CLI → Wizard → GUI.

## 6. Objetivo general
El usuario nunca realizará trabajo de mantenimiento manual.
El asistente siempre debe entregar el código listo, estable y completo.
