# Índice de Procedimientos del Proyecto

Este directorio contiene los procedimientos formales que rigen la forma de trabajo, generación de código y mantenimiento dentro del proyecto.

## 1. Procedimientos incluidos

### 1.1. Corrección Modular  
**Archivo:** CorreccionModular.md  
**Descripción:**  
Establece las reglas para aplicar correcciones completas a módulos, archivos o componentes sin delegar trabajo al usuario.  
Define el método de reemplazo modular, consistencia entre capas y prevención de reescrituras futuras.

### 1.2. Integraciones
**Carpeta:** Integraciones/  
**Descripción:**  
Contiene procedimientos os específicos de cada integración externa (indexador, Dedupe, etc.) que reutilizan el esqueleto base sin alterar su estructura. Actualmente incluye `Indexador.md`, que explica cómo conectar la GUI/Wizard con el motor `Indexador.Core`.

- `ProyectoBase\Integraciones\IndexadorViewModel.cs` es el ejemplo de código que muestra cómo enlazar la GUI con `Indexador.Core`; puedes replicarlo en otros projects.

---

## 2. Procedimientos pendientes / en desarrollo
- Procedimiento de Trabajo General (si se requiere)  
- Procedimiento de Expansión por Etapas (para CLI → Wizard → GUI)  
- Procedimiento de Integración de Nuevos Módulos  
- Procedimiento de Validación de Arquitectura  
- Procedimiento de Portabilidad y Compatibilidad  
- Procedimiento de Estilo de Scripts PowerShell  

Estos pueden añadirse cuando el usuario lo solicite explícitamente, manteniendo modularidad y claridad.

---

## 3. Estructura recomendada de este directorio

/Procedimientos  
├── IndiceProcedimientos.md  
├── CorreccionModular.md  
└── (Otros procedimientos futuros)

---

## 4. Notas generales  
- Todos los procedimientos deben ser respetados por el asistente.  
- Ningún procedimiento debe contradecir las instrucciones del proyecto.  
- La expansión de este índice debe hacerse solo cuando el usuario lo pida.  
- Los ejemplos de código ubicados en `ProyectoBase\Integraciones\` son parte de estas integraciones y deben mantenerse sincronizados con la documentación.
