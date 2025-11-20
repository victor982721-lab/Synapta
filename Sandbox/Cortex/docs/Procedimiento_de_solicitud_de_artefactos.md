# Procedimiento_de_solicitud_de_artefactos - Cortex

> Entrega este documento a ChatGPT antes de elaborar la solicitud para Codex Web y eliminalo en cuanto la solicitud quede consistente y lista para enviarse.

## Primera iteracion - Investigacion sobre Cortex
1. Genera un informe de investigacion libre que describa el dominio del proyecto, tecnologias abiertas comparables, patrones arquitectonicos compatibles con .NET y cualquier dependencia critica (datos, APIs, frameworks).
2. Identifica que componentes podrian convertirse en artefactos reutilizables para otros proyectos y como se relacionan con modulos existentes en Core o Sandbox.
3. Evalua riesgos tecnicos y oportunidades de integracion (seguridad, rendimiento, escalabilidad, automatizacion de pruebas).
4. Resume hallazgos en secciones numeradas con referencias explicitas a los archivos de docs/ y csv/ que se deberan completar en las iteraciones posteriores.
5. Entrega conclusiones accionables que preparen a la siguiente iteracion para construir el plan y la solicitud.

## Segunda iteracion - Elaboracion de plan y solicitud
1. Con la investigacion aprobada, rellena docs/solicitud_de_artefactos.md con todos los apartados obligatorios (agente destino, tipo de solicitud, antecedentes, objetivo tecnico, alcance, interfaz, estructura de archivos, dependencias y criterios de aceptacion).
2. Actualiza AGENTS.md y README.md con el proposito, dependencias, artefactos objetivo e instrucciones operativas alineadas a la investigacion; elimina los placeholders antes de compartirlos fuera del equipo.
3. Define el **tipo de proyecto** (`PS-CLI`, `DotNet-CLI`, `DotNet-UI`) y justifica la elección en la solicitud. Documenta también si se necesitarán pruebas UI o solo CLI.
4. Propone un plan operativo para el agente que incluya lectura de AGENTS, generación de artefactos reutilizables, validaciones y diseño preliminar de pruebas (lista de casos Pester/xUnit que se esperan implementar).
5. Actualiza docs/table_hierarchy.json para reflejar la relacion entre artefactos reutilizables y productos finales, indicando que partes pertenecen a Core y cuales a Sandbox.
6. Documenta cualquier insumo pendiente (credenciales, datos, decisiones de negocio) y valida que la solicitud sea suficiente para que Codex trabaje de forma autonoma.
7. Indica explicitamente que este procedimiento debe eliminarse al preparar el paquete para Codex; si deseas conservarlo, mueve una copia a `docs/Archive/` o resume los cambios en la bitacora antes de eliminarlo del root de docs.

## Tercera iteracion - CSV y verificaciones estructurales
1. Completa csv/modules.csv y csv/artefacts.csv con la nomenclatura final, responsables y estado de cada componente, alineandolos con la estructura declarada en docs/table_hierarchy.json.
2. Crea o actualiza `docs/Cortex_Plan_Schema.md` y, si aplica, un plan JSON/YAML inicial para validar el flujo Automation.
3. Verifica la congruencia entre los CSV, el JSON y la solicitud; cualquier discrepancia debe corregirse antes de cerrar la iteracion.
4. Actualiza docs/filemap_ascii.txt para reflejar la estructura final del proyecto, incluyendo nuevos directorios o scripts.
5. Registra en docs/bitacora.md los acuerdos, riesgos y proximos pasos derivados de esta iteracion, incluyendo el estado de las pruebas (Pester/xUnit) y el resultado en PowerShell 5.1 y 7+.
6. Confirma que los archivos docs/solicitud_de_artefactos.md, csv/*.csv, docs/table_hierarchy.json y docs/filemap_ascii.txt cuentan la misma historia; despues elimina este procedimiento antes de enviar el paquete a Codex (recordando archivar su contenido si se requiere trazabilidad).

### Entregables por iteracion
- Iteracion 1: Informe de investigacion + lista preliminar de artefactos y dependencias.
- Iteracion 2: Solicitud completa + jerarquia actualizada + plan operativo.
- Iteracion 3: CSV consolidados + mapa ASCII actualizado + bitacora con acuerdos finales.
