# AGENTS – Neurologic, General.

Este documento define las reglas globales para los agentes **Codex Web y ChatGPT Web** al trabajar en el repositorio **Neurologic**.

Se debe leer y aplicar **junto con** la **“Política cultural y de calidad – Ecosistema Neurologic”** (documento estándar global de cultura y calidad).

Los `AGENTS.md` específicos de cada proyecto (por ejemplo `Neurologic/Sandbox/<Proyecto>/AGENTS.md`) pueden añadir reglas más estrictas, pero **no pueden rebajar** el estándar cultural y técnico definido en esa política global.

---

## 1. Alcance y prioridad de reglas

1. Este AGENTS aplica a **todo el trabajo de Codex** dentro de `Neurologic`.
2. El orden de prioridad es:
   1. Política cultural y de calidad – Ecosistema Neurologic.
   2. `AGENTS.md` específico del proyecto o subproyecto.
   3. Este AGENTS general de Neurologic.
3. Si hay conflicto entre este documento y un `AGENTS.md` específico, prevalece el **más específico**, siempre que **no contradiga** la política cultural y de calidad.

---

## 2. Entorno técnico global

1. **Sistema operativo de trabajo**: Windows 10. (Compatibilidad con Windows 7, 8.1, 11)
2. **Shell principal**: Pwsh en Windows Terminal.
3. **Lenguajes de programación usados**:
   - C# (En .NET 8.0, con compatibilidad en .NET 7.0 y .NET 6.0)
   - PowerShell (7.5.4. con compatibilidad en PowerShell 5+)
   - Python (Solo cuando .NET no cuente con las dependencias necesarias para realizar algún proyecto)
   - Bash en WSL (Solo cuando C# y Python no cuenten con las dependencias necesarias para realizar algún proyecto)
4. **Editor por defecto**: Sublime Text

---

## 3. Estándar .NET y multi-framework

De acuerdo con el estándar técnico global del ecosistema, cualquier proyecto nuevo creado por Cortex debe:

1. Reutilizar tecnologías existentes previamente desarrolladas, si no hay, evaluar la creación de artefactos reutilizables que puedan aplicar en el proyecto actual y desarrollarlas antes de desarrollar el proyecto completo, esto será evaluado por el asistente en su primer proceso de iteración de acuerdo con el `Procedimiento_ChatGPT_Web`

2. Estar habilitado para desarrollar efectivamente proyectos tanto .NET como proyectos en PowerShell, optando siempre por realizar artefactos .NET cuando haya soluciones existentes en sus dependencias.

2. Debe ser creado pensando en el desarrollo CLI, con compilación portable y autocontenida en una pieza. No considerar UI / GUI por iniciativa propia, salvo solicitud directa del usuario, en cuyo caso se tiene que considerar el desarrollo de una UI / GUI con compatibilidad total con CLI.

3. Se debe considerar siempre la implementación de un "Wizard Interactivo" para los proyectos .NET en CLI, este Wizard será ajeno al propio proyecto de compilación y será desarrollado en un script .ps1, el cual deberá volver interactivo en su totalidad el uso del proyecto .NET

4. Cualquier **proyecto .NET nuevo** creado por Codex dentro de `Neurologic` debe usar **multi-targeting**:

   - Aplicaciones Windows/WPF:
     ```xml
     <TargetFrameworks>net8.0-windows;net7.0-windows;net6.0-windows</TargetFrameworks>
     <UseWPF>true</UseWPF>
     ```
   - Librerías:
     ```xml
     <TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>
     ```
2. No convertir proyectos multi-target existentes a **single-target** sin una justificación explícita y documentada.
3. Si un `AGENTS.md` específico define un esquema concreto de frameworks, seguirlo además de estas reglas.

---

## 4. Organización de código y módulos

1. Regla general para C#:
   - **`namespace = ruta de carpeta`** siempre que aplique.
2. ChatGPT Web puede crear carpetas si se está configurando Cortex, pero Codex Web no debe crear directorios nuevos, debe apegarse al diseño de la solicitud.
3. Funcionalidades complejas (indexadores, motores de búsqueda, recorridos recursivos masivos, infraestructura de logging, etc.) deben implementarse como **módulos reutilizables**, no como scripts aislados.
4. Los módulos compartidos deben:
   - Estar desacoplados de UI.
   - Exponer APIs claras (métodos/funciones bien definidos).
   - Ser consumibles por múltiples scripts o aplicaciones sin modificaciones.
5. Antes de crear un módulo nuevo, Codex debe considerar la política global de **reutilización antes que reinvención**:
   - Revisar la estructura del repositorio.
   - Revisar la documentación del proyecto (README, AGENTS específicos, mapas de archivos, CSV de inventario, etc.).
   - Confirmar si ya existe algo equivalente o similar.
6. **`Core/` es el repositorio canónico de librerías reutilizables** (C# o PowerShell). Cuando un artefacto sea genérico para múltiples proyectos, debe residir o promoverse a `Core/` de forma planificada; `Sandbox/` se reserva para aplicaciones o pruebas específicas.

---

## 5. Indexadores y motores compartidos

1. Cuando un subproyecto define un **Artefacto Reutilizable Canonico** este se considera la **fuente de verdad** para el desarrollo de otros proyectos que requieran una tecnología similar.
2. La acción por defecto para Codex es **extender** o mejorar ese Artefacto, no crear uno paralelo.
3. Cualquier nueva funcionalidad relacionada debe integrarse como:
   - Nuevos métodos o servicios dentro del módulo existente.
   - Nuevos modos de operación o adaptadores que llamen al motor actual.
4. Si se construye una versión mejorada de un motor existente:
   - Se deben migrar gradualmente sus usos para evitar ramas paralelas incompatibles.
   - Mantener varias variantes casi iguales en producción se considera una deuda técnica a reducir.
5. Los motores críticos deben tener como mínimo:
   - Comentarios claros en el código.
   - Una breve descripción en la documentación de proyecto (README, AGENTS específico o archivo equivalente).

---

## 6. Scripts y archivos generados

1. Codex debe entregar **scripts completos y ejecutables**, no diffs ni fragmentos sueltos, especialmente cuando corrige o refactoriza código existente.
2. En correcciones o refactors de un script o archivo:
   - Volver a emitir el archivo completo, consistente y listo para ejecutar.
3. Los scripts deben:
   - Tener parámetros claros (evitar valores mágicos hardcodeados cuando no sea necesario).
   - Evitar depender de rutas no documentadas.
   - Ser razonablemente idempotentes o reanudables cuando el trabajo sea largo.
4. Cuando el flujo de trabajo de la plataforma lo requiera (por ejemplo, Canvas/Canmore):
   - Crear archivos con nombres estables y coherentes con su propósito.
   - Mantener el mismo nombre entre iteraciones, salvo cambio explícito.

---

## 7. Restricciones adicionales

1. Preferir librerías **open-source** estándar en el ecosistema .NET / Python / PowerShell.
2. Respetar el enfoque de **determinismo y previsibilidad** del ecosistema:
   - Mismos inputs → mismos outputs.
   - No introducir aleatoriedad sin control (usar semillas reproducibles si fuera necesario).
3. No simplificar ni degradar un motor sólido a una versión inferior solo por comodidad.

---

## 8. Comportamiento esperado de Codex / ChatGPT Web.

De acuerdo con la política cultural y de calidad, Codex debe comportarse como un agente técnico responsable:

1. **Lectura de contexto antes de generar código**
   - Revisar este AGENTS general.
   - Revisar el `AGENTS.md` específico del subproyecto, si existe.
   - Revisar la arquitectura (indexadores, motores, módulos comunes) antes de proponer soluciones.

2. **Reutilización antes que reinvención**
   - No asumir que “no existe nada” sin revisar primero:
     - Árbol de código.
     - Documentación y CSV de inventario.
   - Si existe un motor o módulo similar, preferir **extenderlo** o añadir adaptadores.

3. **Entrega A→Z, no trabajos a medias**
   - Cuando el usuario pide un script, módulo o configuración, la respuesta debe ser un resultado **completo y accionable**, no un esqueleto incompleto.
   - Evitar dejar pasos críticos en manos del usuario cuando Codex puede generarlos de forma segura.

4. **Respeto al estándar global**
   - No proponer scripts desechables que ignoren los motores e indexadores existentes.
   - No degradar proyectos .NET de multi-framework a single-target sin justificación.
   - No introducir duplicaciones evidentes de lógica ya presente en otros módulos.

---

## 9. Interacción con AGENTS específicos

Antes de generar o modificar código en un subárbol del repositorio, Codex debe:

1. Buscar si existe un `AGENTS.md` en ese subdirectorio o en el directorio padre inmediato.
2. Leer sus reglas y aplicarlas **además** de este AGENTS general.
3. En caso de conflicto:
   - Prevalece el `AGENTS.md` más específico, siempre que no contradiga la política cultural y de calidad.

---

## 10. Resumen operativo rápido

1. Asumir entorno Windows 10, PowerShell 7.5.4, compatible desde Windows 7 y Powershell 5+.
2. Cumplir la política cultural y de calidad del ecosistema Neurologic.
3. Para .NET, aplicar siempre multi-framework (8/7/6) según el tipo de proyecto.
4. Mantener `namespace = ruta de carpeta` y no inventar estructura sin instrucción.
5. Reutilizar motores, indexadores y módulos existentes; evitar duplicaciones.
6. Entregar código completo, ejecutable y alineado con las convenciones del proyecto.
7. Consultar y respetar cualquier `AGENTS.md` específico del subproyecto donde se esté trabajando.
