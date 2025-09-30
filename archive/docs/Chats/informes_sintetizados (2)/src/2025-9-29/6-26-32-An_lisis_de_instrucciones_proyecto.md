# Análisis de instrucciones proyecto

https://chat.openai.com/c/68da7af5-21a4-8324-9fa9-db983ecb71e5

## USER
Lee y analiza por completo lo siguiente:

~~~~~
# Project_Instructions

---

## Contexto

1. ROL    ⟶ Eres un **Ingeniero DevOps** con enfoque en administración de proyectos y control documental.
2. Tono   ⟶ Directo y conciso, escribe en español técnico, sin redundancias ni adornos.
3. Evitar ⟶ Explicaciones innecesarias: solo responde lo que el usuario solicita.

---

## Misión

Generación y edición de documentos y scripts ejecutables en PowerShell 7, aplicando efectiva y consistentemente los protocolos correspondientes para cada caso.

---

## Políticas

Las siguientes políticas definen los **principios obligatorios** que guían la generación de entregables dentro del proyecto, definen el marco mínimo de calidad y consistencia que ChatGPT debe aplicar en todos los turnos.


- ### **POLÍTICA DE ARTEFACTOS OPERACIONALES**
  
  Se denomina *Artefacto* a todo bloque de código **NO PROCESADO CON PYTHON** que en su interior contenga un script o un documento embebido en un script con herestrings, además su contenido  debe cumplir con los siguientes atributos:

  1. Accionables   ⟶ Listos para ejecución directa en consola, sin pasos adicionales.
  2. Definitivos   ⟶ Solo un artefacto por turno, sin opciones adicionales ni variables por definir. 
  3. Blindados     ⟶ Con un buen renderizado del bloque de código principal abriendo y cerrando el artefacto con **cinco tildes (`~~~~~`)** a fin de evitar afectaciones de renderizado por bloques anidados.
  4. Automatizados ⟶ La gestión de parámetros (rutas, dependencias, creación de directorios) debe estar integrada en el script. La generación y edición de documentos deberá realizarse mediante **herestrings direccionados** a las rutas especificadas en la sección de rutas locales.
  5. Validados     ⟶ Todo artefacto será verificado mediante simulación con **PSSA** y **Pester**, siguiendo el flujo de validación establecido.
  6. Seguros       ⟶ Cualquier modificación deberá generar previamente una copia de seguridad `.bak` en la misma carpeta.
  7. Modularizados ⟶ Los artefactos deberán redactarse de forma **modular interna** (secciones intercambiables), permitiendo actualizaciones mediante **herestrings y parches**.
  8. Compatibles   ⟶ Se debe de cuidar la compatibilidad entre Windows 10 y 11, así como PowerShell 5 y 7, pero sin preocuparse por la portabilidad "nix/macOS"
  9. Trazables     ⟶ Los cambios deben quedar documentados con metadatos de versión, fecha y descripción del cambio por medio de registros añadidos con parches en `/mnt/data/Repo_AR/CHANGELOG.md`, cada registro debe estar separado por una regla horizontal y no debe eliminar ni modificar nada de los registros existentes, solo añadir nuevos registros.

  La explicación detallada de criterios y procedimientos se encuentra en los protocolos referenciados y disponibles en la ruta: `/mnt/data/Repo_AR/Protocolos/`

  ---

  **Rutas de documentos y archivos visibles en entorno local (`C:\Users\VictorFabianVeraVill\Desktop\Repo_AR`):**

  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\Project_Instructions.md`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\BACKUPS\`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SCRIPTS\Invoke-RepoReorg.ps1`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SCRIPTS\BACKUPS\Invoke-RepoReorg_20250926_201928305.bak`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SOP\SOP_Auditoria_Proyecto.md`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SOP\SOP_CB_Blindado.md`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SOP\SOP_Context_Update.md`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SOP\SOP_Herestrings.md`
  - `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SOP\BACKUPS\`

  ---

  **Referencias SOP:**

  - `SOP_Auditoria_Proyecto.md`  ⟶ Lineamientos para auditoría del proyecto.  
  - `SOP_CB_Blindado.md`         ⟶ Procedimientos de blindaje y control documental.  
  - `SOP_Context_Update.md`      ⟶ Instrucciones para actualización de contexto.  
  - `SOP_Herestrings.md`         ⟶ Normativa sobre el uso de herestrings en scripts y documentos.  


---

- ### **POLÍTICA DE ESFUERZO EQUITATIVO**

En toda interacción colaborativa entre ChatGPT y el usuario, las responsabilidades deben distribuirse de manera proporcional a las capacidades de cada parte.

1. Capacidades comparativas

- *ChatGPT-5* ⟶ Hasta 300× más memoria de trabajo y hasta 1 000× mayor velocidad en ingestión/producción de texto frente a un humano promedio, en tareas de corto y mediano plazo (lectura, razonamiento, escritura, programación).
- *Usuario*   ⟶ Ventaja en contexto, criterio y memoria de largo plazo.

2. Distribución de responsabilidades

- *ChatGPT-5* ⟶ Automatización, generación, análisis y validación (incluyendo simulación PSSA + Pester).
- *Usuario*   ⟶ Toma de decisiones, aporte de contexto.
~~~~~

## Thoughts
El usuario pide un análisis técnico en español, sin necesidad de usar herramientas de búsqueda. Se debe brindar un resumen estructurado: fortalezas, riesgos, recomendaciones y posibles implicaciones para la generación de artefactos. No se deben hacer preguntas de aclaración, y el estilo debe ser casual, respetando el tono técnico.
Parece que el usuario busca alinear políticas, por lo que debemos ofrecer elementos clave como:

- Resumen ejecutivo
- Matriz de requisitos con criterios atómicos
- Identificación de ambigüedades y contradicciones
- Riesgos de implementación y procedimiento de artefactos
- Validación del proceso de PSSA + Pester
- Plantilla para CHANGELOG y propuestas de rutas

Se debe interpretar cuidadosamente cada elemento, especialmente en cuanto a las instrucciones contradictorias sobre Python.
El usuario pidió un análisis completo, pero al mismo tiempo, debe ser directo y sin sobrecargar de detalles. Por eso, ofreceremos un análisis conciso con cláusulas atómicas enumeradas para trazabilidad y una evaluación rápida de "OK/Gap". También propondré una plantilla mínima para el script y criterios de aceptación, pero sin generar artefactos, ya que solo se requiere análisis.
Dado que el usuario solo pidió análisis y no la generación de artefactos, evitaremos crear scripts o bloques de código, ya que eso podría considerarse artefacto. Podemos sugerir una plantilla en formato de puntos, sin código. Además, incluiré un "Checklist de cumplimiento" con el estatus de "No evaluable" debido a la falta de contenido SOP.

## ASSISTANT
Aquí tienes el análisis solicitado —directo y técnico— del bloque **Project_Instructions**.

# Resumen ejecutivo
El documento fija un **rol DevOps**, una **misión** centrada en generación/edición de documentos y scripts **PowerShell 7** y una **política de artefactos** estricta (blindaje de bloques, modularidad, backups, validación PSSA/Pester, trazabilidad en CHANGELOG). La **política de esfuerzo** asigna a ChatGPT la parte automatizable (generación, análisis, validación) y al usuario las decisiones de negocio/contexto. El marco es coherente y accionable, con algunos puntos a precisar (ver hallazgos).

# Requisitos atómicos (trazabilidad)
**Contexto**
- C1. Rol: Ingeniero DevOps con foco en PM/control documental.
- C2. Tono: directo, español técnico, sin adornos.
- C3. Evitar explicaciones innecesarias.

**Misión**
- M1. Generar/editar documentos y scripts *ejecutables* en **PowerShell 7** aplicando protocolos.

**Política de artefactos**
- A1. Definición de artefacto: bloque de código **no procesado con Python** con script o documento via *herestrings*.
- A2. Accionables: ejecutables sin pasos extra.
- A3. Definitivos: **un artefacto por turno**; sin variantes ni placeholders.
- A4. Blindados: bloque principal delimitado con **cinco tildes (`~~~~~`)** (anti-anidación).
- A5. Automatizados: parámetros/rutas/deps/dirs integrados; documentos por **herestrings direccionados** a rutas locales.
- A6. Validados: simulación con **PSSA** y **Pester** conforme a flujo establecido.
- A7. Seguros: **backup `.bak`** previo en la misma carpeta.
- A8. Modularizados: estructura **modular interna** (secciones intercambiables) con *patching* vía herestrings.
- A9. Compatibles: Windows 10/11; **PowerShell 5 y 7** (sin preocuparse por nix/macOS).
- A10. Trazables: registro de cambios con metadatos (versión/fecha/descr.) en **`/mnt/data/Repo_AR/CHANGELOG.md`**, agregando al final, separados por regla horizontal, sin editar entradas previas.

**Inventario de rutas (visibles en entorno local)**
- R1. Proyecto y SOPs bajo `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\...`
- R2. Scripts y backups locales (`SCRIPTS`, `BACKUPS`, `SOP\BACKUPS`).

**Referencias SOP**
- S1. SOP_Auditoria_Proyecto
- S2. SOP_CB_Blindado
- S3. SOP_Context_Update
- S4. SOP_Herestrings

**Política de esfuerzo**
- E1. ChatGPT: automatización, generación, análisis, **validación (PSSA/Pester)**.
- E2. Usuario: decisiones y contexto.

# Hallazgos (gaps/ambigüedades)
1) **PS7 vs compatibilidad PS5+PS7**  
   - La misión enfatiza PS7, pero A9 exige compatibilidad 5+7. No es contradictorio, pero conviene **declarar explícitamente el objetivo de compatibilidad mínima** (p. ej., “target: PS5.1+, optimizado para PS7”).  
2) **Doble espacio de rutas (Windows vs `/mnt/data`)**  
   - A10 manda escribir el **CHANGELOG** en `/mnt/data/Repo_AR/CHANGELOG.md`, mientras el inventario de rutas solo lista **Windows**. Falta una **regla de espejado/sincronía** (¿es obligatorio escribir en ambos?, ¿cuál es la fuente de verdad?).  
3) **“No procesado con Python”**  
   - A1 define qué es un artefacto; sugiere **no usar Python para postproceso del bloque**. Conviene precisar si se prohíbe cualquier soporte Python (p. ej., generar archivos auxiliares) o solo se refiere al **contenido del bloque**.  
4) **Flujo de validación “establecido” (A6)**  
   - Se invoca PSSA/Pester pero **no se incluyen parámetros mínimos** (reglas, severidades, criterios de aprobación). Falta **umbral objetivo** (p. ej., “0 errores PSSA; 0 fallos Pester; advertencias permitidas: ≤N”).  
5) **Formato exacto de entrada en CHANGELOG (A10)**  
   - Se pide metadatos y “regla horizontal”, pero no se fija **plantilla** (orden de campos, formato de fecha, versión semántica).  
6) **Backups .bak (A7)**  
   - No se especifica **nomenclatura** (timestamp, hash, sufijos), **política de retención** ni **qué archivos** requieren backup (¿solo scripts? ¿también Markdown?).  
7) **Modularidad/patched herestrings (A8)**  
   - Se indica el *cómo* (herestrings y parches) pero no el **contrato de secciones** (IDs, encabezados canónicos, orden).  
8) **Un artefacto por turno (A3)**  
   - Correcto para control; sin embargo, faltan **reglas para entregas que exigen múltiples archivos** (p. ej., script + Pester tests + README). ¿Se empaqueta todo **dentro de un único bloque** que genere los archivos?  
9) **SOPs referenciados pero no adjuntos**  
   - El cumplimiento de blindaje/validación depende de SOP_* no incluidos aquí. Se requiere **cargar/validar esos SOPs** para cerrar brechas.

# Recomendaciones accionables (concretas)
1) **Compatibilidad**: declarar en cabecera `#requires -Version 5.1` y **feature-detect** para PS7 (por ejemplo, uso opcional de `ForEach-Object -Parallel` detrás de `if ($PSVersionTable.PSVersion.Major -ge 7)`), manteniendo equivalentes para PS5.  
2) **Espejado de rutas**: definir **fuente de verdad** del CHANGELOG (sug.: `/mnt/data/Repo_AR/CHANGELOG.md`) y, si se pide, **sincronizar** con `C:\...\Repo_AR\CHANGELOG.md` (escritura doble o tarea de espejado). Documentarlo en SOP_Context_Update.  
3) **Plantilla de CHANGELOG**: fijar formato único:  
   - `---` (regla)  
   - `## YYYY-MM-DD HH:mm Z — vMAJOR.MINOR.PATCH`  
   - `- Área: Scripts/Docs/Infra`  
   - `- Archivo(s):`  
   - `- Descripción:`  
   - `- Autor/Fuente:`  
   - `- Hash/Ref:`  
4) **Backups**: nomenclatura `Nombre_YYYYMMDD_HHmmssfff.bak` en la **misma carpeta** del archivo original; retención configurable (p. ej., conservar últimos N=10).  
5) **Validación PSSA/Pester**: establecer umbrales mínimos:  
   - PSSA: 0 errores; advertencias ≤N (configurable); reglas: `PSUseApprovedVerbs`, `PSAvoidUsingWriteHost`, `PSUseDeclaredVarsMoreThanAssignments`, etc.  
   - Pester: suite mínima `Unit` + `Lint` + `Smoke` con salida en JUnit/NUnit si aplica.  
6) **Contrato de secciones (modularidad)**: definir IDs de sección (`[HEADER]`, `[PARAMS]`, `[ROUTES]`, `[BACKUP]`, `[BODY]`, `[VALIDATION]`, `[LOG]`) para permitir *patches* localizados.  
7) **Un artefacto/turno con multi-outputs**: cuando se necesiten varios archivos, el **único bloque blindado** debe: crear rutas, generar archivos vía **herestrings**, ejecutar PSSA/Pester (simulación si no están presentes), y registrar en CHANGELOG.  
8) **Prohibición/alcance Python**: aclarar en SOP_CB_Blindado que **el bloque blindado** no depende de Python para su ejecución o render; el asistente puede usar Python **fuera** del artefacto solo para análisis, nunca para “postprocesar” el bloque.  
9) **Mensajes/tono**: reforzar en SOP_Auditoria que las respuestas **no incluyan relleno** y que **no se generen artefactos** salvo solicitud explícita.

# Criterios de aceptación propuestos (DoD)
- DoD1. Script con `#requires -Version 5.1`, ejecutable en PS5.1 y PS7.  
- DoD2. **Un solo bloque blindado `~~~~~`** que genera todo y no requiere pasos manuales.  
- DoD3. **Backup `.bak`** creado antes de cualquier modificación (nomenclatura definida).  
- DoD4. **PSSA** sin errores; **Pester** sin fallos (o simulación con reporte claro cuando no haya módulos).  
- DoD5. **CHANGELOG** actualizado en la ubicación definida, con plantilla estándar y **sin alterar entradas previas**.  
- DoD6. Estructura **modular** con secciones identificables y *patchable*.  
- DoD7. Documentos generados vía **herestrings direccionados** a rutas declaradas.  
- DoD8. Tono/estilo conforme (C2, C3).

# Riesgos y mitigaciones
- **Ausencia de SOPs adjuntos** → bloquear la “validación establecida”. *Mitigación:* cargar SOPs y versionarlos; hasta entonces, aplicar criterios mínimos propuestos.  
- **Desalineación de rutas** (`/mnt/data` vs `C:\...`) → inconsistencias de auditoría. *Mitigación:* definir espejo y fuente de verdad.  
- **Falsos positivos PSSA** en PS5 vs PS7 → fijar **perfil de reglas** y excepciones justificadas por versión.

# Próximos pasos sugeridos (orden)
1) Confirmar **fuente de verdad** del CHANGELOG y política de espejo.  
2) Publicar **plantilla** de CHANGELOG y **umbral PSSA/Pester** en SOP_Auditoria_Proyecto.  
3) Añadir al SOP_CB_Blindado el **contrato de secciones** y la regla de **un artefacto por turno con multi-outputs**.  
4) Cargar los SOPs referenciados en el repositorio y vincular sus versiones en Project_Instructions.  
5) (Opcional) Incorporar ejemplo mínimo de **script canónico** en SOP_Herestrings.

Si quieres, puedo **generar el artefacto canónico** (un único bloque `~~~~~`) que implemente estas reglas: creación de rutas, backups, generación de docs por herestring, validación PSSA/Pester (con fallback de simulación) y escritura en CHANGELOG con la plantilla propuesta.

