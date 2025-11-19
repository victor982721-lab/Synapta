# AGENTS - PruebaSup

Lee docs/Procedimiento_de_solicitud_de_artefactos.md antes de completar este archivo. Esta personalizacion ocurre durante la Iteracion 2 y debe quedar sin placeholders antes de compartirla con Codex.

## 1. Personalizacion obligatoria
- [ ] Resumir el proposito actual del proyecto y el estado de avance (investigacion, solicitudes previas, entregables pendientes).
- [ ] Enumerar artefactos reutilizables y dependencias Core tal como aparecen en csv/artefacts.csv y csv/modules.csv.
- [ ] Definir que elementos estan fuera de alcance y como se coordinara con otros proyectos.

## 2. Entorno y herramientas
* **Sistema operativo objetivo:** Windows 10+ (actualiza si aplica).
* **Shell principal:** PowerShell 7.5.x (pwsh).
* **Lenguajes permitidos:** C# (.NET); PowerShell.
* **Target frameworks:** net8.0;net7.0;net6.0 (ajusta si el proyecto requiere otra combinacion).

## 3. Proposito del proyecto
Describe la finalidad concreta de PruebaSup dentro del ecosistema Neurologic, indicando si genera artefactos reutilizables, un producto final o ambos. Referencia el README y la investigacion inicial.

## 4. Artefactos y dependencias
1. Lista de modulos Core que se deben reutilizar o extender. Relaciona cada elemento con las filas de csv/artefacts.csv.
2. Artefactos nuevos planeados para este proyecto. Explica donde viviran (Core vs Sandbox) y que solicitud respaldara su creacion.

## 5. Principios especificos
1. Reglas de codificacion o arquitectura que este proyecto debe seguir (por ejemplo, composicion sobre herencia, pipelines deterministas, limites claros entre UI y dominio).
2. Estrategia de documentacion: archivos que deben mantenerse sincronizados por iteracion (Procedimiento, solicitud, tabla de jerarquia, filemap, bitacora).
3. Expectativas de pruebas (framework, cobertura minima, datos de fixtures).

## 6. Entradas, salidas y seguridad
Define formatos esperados (JSON, CSV, streams), validaciones obligatorias, politicas de logging y consideraciones de secretos/credenciales.

## 7. Checklist previo a solicitar trabajo
1. AGENTS.md y README.md sin placeholders.
2. docs/solicitud_de_artefactos.md, docs/table_hierarchy.json y csv/*.csv alineados.
3. Scripts requeridos documentados en Scripts/ y validados.
4. Resultado reciente de Scripts/Validate-Structure.ps1 y cualquier otra prueba relevante.

> Elimina estas notas auxiliares una vez que el documento refleje la configuracion real del proyecto.
