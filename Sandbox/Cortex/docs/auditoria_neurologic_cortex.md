# Informe de auditoría – Neurologic / Cortex (documentación para Codex)

## 0. Propósito

Evaluar la coherencia y completitud del ecosistema documental de **Neurologic** y del proyecto **Cortex** antes de enviar la solicitud de refactor a Codex, identificando pequeñas incongruencias, huecos de especificación y mejoras puntuales para dejar el sistema preparado para automatización.

---

## 1. Resumen ejecutivo

1. La arquitectura documental global (Política, AGENTS general, AGENTS Cortex, Procedimiento en iteraciones, Solicitud formal, CSV, mapas de archivos y bitácora) es **coherente y suficiente** para que Codex trabaje sin inventar el 80–90% de las decisiones.
2. Existen **pequeñas incongruencias y zonas grises** relacionadas con:
   - versiones de PowerShell y Windows,
   - documentación de la capa `Cortex.Services.*`,
   - esquema del plan JSON/YAML de Automation,
   - esquema de logs y resultados,
   - criterios para elegir CLI vs UI y C# vs PowerShell,
   - momento y responsabilidad de las pruebas automatizadas,
   - mezcla de información en el README raíz de Neurologic.
3. Ninguna de estas observaciones impide trabajar, pero todas consumen tiempo de razonamiento del agente. Documentarlas explícitamente reducirá iteraciones y hará que el refactor de Cortex salga más limpio.

---

## 2. Fortalezas del diseño documental

1. **Cadena de reglas clara**:
   - Política cultural y de calidad (global).
   - AGENTS – Neurologic (general para Codex).
   - AGENTS – Cortex (específico de proyecto).
   - Procedimiento de solicitud en 3 iteraciones.
   - Solicitud formal de artefacto.
2. **Separación de capas del ecosistema**:
   - Neurologic raíz: cultura, preferencias de usuario, estructura global.
   - Core: lugar canónico para librerías reutilizables (C#, PowerShell) a nivel ecosistema.
   - Sandbox/<Proyecto>: proyectos de aplicación (Cortex, Ws_Insights, etc.).
3. **Documentos bien alineados**:
   - CSV (`modules.csv`, `artefacts.csv`) describen módulos y artefactos.
   - `table_hierarchy.json` y `filemap_ascii.txt` describen la estructura de carpetas.
   - Bitácora registra decisiones y cambios.
4. **Proceso explícito para trabajar con Codex**:
   - Iteración 1: investigación y análisis.
   - Iteración 2: plan + solicitud.
   - Iteración 3: CSV, mapas y verificaciones estructurales.
5. **Claridad del objetivo de Cortex**:
   - Script maestro que automatiza scaffolding, GitOps, análisis, descargas y exportación.
   - Capas internas (Core, Services, CLI, Automation, Exporter) claramente definidas.

---

## 3. Hallazgos y pequeñas incongruencias

### 3.1 Entorno y versiones

**H1 – PowerShell 7+ vs compatibilidad 5.1**
- AGENTS general prohíbe usar Windows PowerShell 5.1 por defecto y privilegia `pwsh` 7+.
- AGENTS de Cortex exige que el script sea compatible con PowerShell 5.1 y 7+, y que detecte la versión.
- Esto se puede interpretar (correctamente) como: desarrollo y pruebas principales en pwsh 7.x, pero el producto debe soportar 5.1 como entorno destino.
- Problema: esta interpretación requiere que el agente piense unos minutos; no está escrita de forma explícita.

**Recomendación**
- En **AGENTS – Neurologic (general)** o en **AGENTS – Cortex**, añadir una nota explícita:
  - "El entorno de desarrollo y pruebas por defecto es PowerShell 7.x.
  - Algunos proyectos (como Cortex) requieren compatibilidad de ejecución con Windows PowerShell 5.1; esto se considera una excepción autorizada a la regla general, siempre y cuando el código se mantenga portable entre 5.1 y 7.x".

---

**H2 – Windows 10 vs Windows 7+**
- El estándar global habla de Windows 10 como sistema objetivo.
- Cortex menciona soporte Windows 7+.

**Recomendación**
- Aclarar en AGENTS Cortex una frase del estilo:
  - "El entorno mínimo de ejecución soportado por Cortex es Windows 7, pero la validación oficial y las pruebas de desarrollo se consideran en Windows 10 o superior".

---

### 3.2 Estructura y roles de repositorios

**H3 – README raíz con contenido mezclado**
- El README de Neurologic contiene restos de conflicto de merge y mezcla contenido de `Neurologic` con la descripción de `Ws_Insights`.

**Recomendación**
- Resolver el conflicto y dividir en dos documentos:
  - `Neurologic/README.md`: descripción general del ecosistema.
  - `Neurologic/Sandbox/Ws_Insights/README.md`: documentación específica de ese proyecto.

---

**H4 – Core no está mencionado explícitamente en AGENTS general**
- La estructura real del repositorio incluye `Core/` como lugar para librerías reutilizables.
- AGENTS general habla de proyectos en `Sandbox/<Proyecto>`, pero no nombra `Core` directamente.

**Recomendación**
- Añadir en AGENTS general una sección breve:
  - "La carpeta `Core/` contiene librerías reutilizables a nivel ecosistema. Los proyectos en `Sandbox/` deben considerar primero `Core` antes de crear nuevos motores o librerías".

---

### 3.3 Diseño de Cortex y artefactos

**H5 – Capa `Cortex.Services.*` ausente de los CSV**
- AGENTS Cortex define explícitamente `Cortex.Services.*` (RequestBuilder, ProjectFactory, ArtifactSync).
- `modules.csv` y `artefacts.csv` solo listan `Cortex.Core.*`, `Cortex.CLI`, `Cortex.Automation`, `Cortex.Exporter`.

**Recomendación**
- Añadir entradas para `Cortex.Services.RequestBuilder`, `Cortex.Services.ProjectFactory` y otros servicios planificados en ambos CSV, aunque sea como estado "Pendiente". Así el inventario cuenta la misma historia que AGENTS.

---

**H6 – Rango y mapeo de `-AutoOption`**
- El código ya acepta `1..8` en `ValidateSet`, mientras que algunos textos de diseño/criterios de aceptación hablan de `1..6` o no documentan el mapeo exacto.

**Recomendación**
- En AGENTS Cortex o README de Cortex:
  - Documentar una tabla "AutoOption → operación" con las opciones definitivas.
  - Alinear criterios de aceptación para que hablen de `1..N` coherentes con el código.

---

**H7 – Falta de esquema formal para el plan JSON/YAML de Automation**
- Se menciona que `Cortex.Automation` aceptará un plan de jobs (JSON/YAML), pero no se define estructura, claves obligatorias ni ejemplo.

**Recomendación**
- Crear un pequeño documento `docs/Cortex_Plan_Schema.md` o una sección en el README de Cortex que incluya:
  - esquema lógico (jobs, repos, operaciones, flags),
  - ejemplo mínimo funcional,
  - reglas de validación (campos obligatorios/opcionales).

---

**H8 – Esquema de logs y resultados**
- Los documentos exigen logs estructurados (texto y JSON) y resúmenes multi-repo, pero no definen campos mínimos ni ubicación estándar de los archivos.

**Recomendación**
- Definir un esquema simple de log JSON:
  - campos como `RunId`, `Timestamp`, `Repo`, `Operation`, `Status`, `Duration`, `Errors`, etc.
  - carpeta por defecto para logs (por ejemplo `logs/` bajo el proyecto o ruta configurable).
  - añadir una breve sección "Logging" al README/AGENTS de Cortex.

---

**H9 – Rol de `Cortex.csproj`**
- El `.csproj` multi-target existe, pero su función (helpers .NET, host del Exporter, pruebas) solo está implícita.

**Recomendación**
- En el README de Cortex, añadir una subsección "Cortex.csproj" explicando:
  - que se usa como proyecto auxiliar para helpers .NET y/o como base para el Exporter,
  - que no es el objetivo principal, pero forma parte del entorno de pruebas y compilación a EXE.

---

**H10 – Directrices para elegir CLI vs UI y C# vs PowerShell**
- Se menciona que Cortex puede generar proyectos PowerShell y .NET multi-target que expongan CLI o UI, pero no se detallan criterios para elegir uno u otro ni cuándo involucrar C# además de PowerShell.

**Recomendación**
- Extender el Procedimiento y/o la plantilla de solicitud con un apartado:
  - "Tipo de proyecto": `PS-CLI`, `DotNet-CLI`, `DotNet-UI (WPF)`.
  - Reglas orientativas:
    - por defecto, CLI;
    - UI solo cuando existan requisitos claros de interacción gráfica;
    - C# cuando haya necesidades de rendimiento, integración avanzada .NET o reutilización como librería.

---

### 3.4 Procesos, pruebas y Pester

**H11 – Momento y responsabilidad de las pruebas (Pester/xUnit)**
- AGENTS y README mencionan tests en `tests/`, pero no se especifica en qué iteración se definen ni quién los diseña (humano vs Codex).

**Recomendación**
- En el Procedimiento de iteraciones, añadir:
  - Iteración 2: definir casos de prueba de alto nivel y, si aplica, esqueleto de tests Pester/xUnit.
  - Iteración 3: verificar que la solicitud incluye los requisitos de pruebas que Codex debe implementar o completar.
- En AGENTS Cortex, aclarar:
  - que las funciones Core críticas deben tener al menos tests básicos,
  - y que, si el usuario proporciona plantillas de tests, Codex debe respetarlas y completarlas.

---

### 3.5 Lenguajes permitidos y preferencias reales

**H12 – Python permitido globalmente vs preferencia real de uso**
- Los lineamientos generales permiten Python como lenguaje válido.
- Las preferencias del usuario y la práctica actual muestran una clara preferencia por C# + PowerShell, usando Python sólo en contadas ocasiones.

**Recomendación**
- En `Preferencias_del_Usuario` o en AGENTS general, añadir una frase explícita:
  - "Python solo debe proponerse o usarse cuando el usuario lo solicite de forma explícita; la prioridad por defecto para nuevos artefactos es PowerShell y C#".

---

### 3.6 Documentos efímeros

**H13 – Eliminación de `Procedimiento_de_solicitud_de_artefactos`**
- El procedimiento indica que debe eliminarse cuando la solicitud y su soporte estén completos, para no enviar ruido a Codex.
- Desde el punto de vista de trazabilidad, puede ser útil conservar una copia.

**Recomendación**
- Mantener la regla de "no incluirlo en el paquete para Codex", pero valorar:
  - mover la última versión aprobada a un subdirectorio `docs/Archive/` o renombrarla con fecha,
  - o bien guardar el contenido en la bitácora antes de eliminar el archivo.

---

## 4. Cambios recomendados en orden sugerido

1. **Ajustar AGENTS – Neurologic y AGENTS – Cortex** para explicitar:
   - uso de pwsh 7.x como entorno de desarrollo,
   - soporte de ejecución en PS 5.1 en proyectos que lo requieran,
   - relación entre Windows 7+ (compatibilidad) y Windows 10+ (validación).
2. **Corregir el README raíz de Neurologic**, separando contenido general del ecosistema y README de Ws_Insights.
3. **Actualizar AGENTS general** para mencionar explícitamente la carpeta `Core/` como almacén oficial de librerías reutilizables.
4. **Actualizar los CSV de Cortex** (`modules.csv`, `artefacts.csv`) para incluir la capa `Cortex.Services.*` y alinear el rango final de `AutoOption`.
5. **Extender el README/AGENTS de Cortex** con:
   - rol detallado de `Cortex.csproj`,
   - tabla de mapeo `AutoOption → operación`,
   - sección de logging (esquema mínimo + ruta por defecto).
6. **Crear o completar un documento breve para el plan de Automation** (`Cortex_Plan_Schema`), con estructura de JSON/YAML y uno o dos ejemplos.
7. **Actualizar el Procedimiento de iteraciones** para:
   - incluir la decisión explícita de tipo de proyecto (PS-CLI, DotNet-CLI, DotNet-UI),
   - fijar el momento de diseño de pruebas (Pester/xUnit),
   - garantizar que la solicitud final incluya esos detalles.
8. **Refinar las preferencias de lenguaje** para reflejar claramente que la prioridad por defecto es C# + PowerShell, usando Python solo bajo petición.
9. **Definir una política de archivado para documentos efímeros** como el Procedimiento, de modo que no se envíen a Codex pero queden rastros históricos.

---

## 5. Pautas que Codex puede aplicar al auto-ajustar su propia configuración

Cuando Codex consuma esta auditoría para refinar su propia documentación de proyecto, puede aplicar las siguientes reglas prácticas:

1. Añadir secciones de "Entorno" y "Compatibilidad" claras en los AGENTS de cada proyecto, diferenciando entorno de desarrollo vs entorno de ejecución soportado.
2. Mantener inventarios (CSV, mapas de archivos) totalmente alineados con las capas declaradas en los AGENTS y en la solicitud.
3. Siempre que se mencione automatización (planes JSON/YAML, logs, resultados), acompañarlo de al menos un ejemplo concreto.
4. Priorizar C# y PowerShell como lenguajes por defecto para nuevos artefactos y reservar Python para casos justificados.
5. Distinguir explícitamente entre artefactos de ecosistema (que deberían vivir en `Core/`) y artefactos específicos de proyecto (que pueden vivir en `Sandbox/<Proyecto>`), y documentar cuándo algo es candidato a promoción a Core.
6. Asegurar que cada proyecto define, aunque sea brevemente, el enfoque de pruebas automatizadas (tipo, ubicación, alcance mínimo) antes de pedir código a Codex.

Con estos ajustes, el ecosistema Neurologic y, en particular, el proyecto Cortex, quedarán mejor alineados con la política cultural y de calidad y ofrecerán a Codex un contexto casi libre de ambigüedades para realizar el refactor y la modularización futura.