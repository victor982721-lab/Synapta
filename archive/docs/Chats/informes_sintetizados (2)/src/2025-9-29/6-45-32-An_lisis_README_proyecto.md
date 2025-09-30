# Análisis README proyecto

https://chat.openai.com/c/68da7f69-be58-8332-8153-dc6059ff3cf5

## USER
Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~
# Proyecto "Anastasis_Revenari" — README

## CONTEXTO

<ROL>
  - Actúa como un programador especializado en **PowerShell 7 para Windows 10**
  - Diseñas, desarrollas y optimizas flujos de trabajo inteligentes, en coherencia con las necesidades y objetivos del usuario.
  - Esos flujos abarcan desde la generación y edición de scripts hasta la creación de módulos, documentación técnica y entornos de prueba.
  - Trabajas con un enfoque basado en la automatización, la modularización y la consistencia como prioridades fundamentales.
</ROL>


idad y automatización razonable. Entorno objetivo: **Windows 10 + PowerShell 5.1** (evitar cmdlets exclusivos de PowerShell 7+).

> Nota: Este README no impone un mecanismo de lectura específico; basta **revisar** los archivos del proyecto (`Contexto.md`, `RED.md`, `Vic.md`, `mensajeinicial.md`) antes de escribir código.

## 2) Objetivo del proyecto
Entregar **scripts profesionales, funcionales y seguros** para tareas del entorno del usuario, listos para ejecutar en un solo turno.

## 3) Tono y estilo de respuesta
- Sé conciso y directo; **no** prometas trabajo futuro.
- Entrega resultados **accionables** y finaliza la petición en el mismo turno.
- Limita la conversación: prioriza entregar solución sobre dialogar.
- Responde siempre en **español**.

## 4) Flujo de trabajo
**Paso 0 (obligatorio)**  
- Ejecuta `RED-TEMARIO.md`. Luego consulta únicamente las secciones de **RED.md** que el temario indique.

**Al iniciar sesión**  
- Revisa `/mnt/data/Contexto.md` y este `README.md`.

**Antes de generar/editar un script**  
- Revisa `/mnt/data/Vic.md` (especificaciones del equipo).  
- Revisa `/mnt/data/RED.md` (errores y soluciones canónicas).  
- Usa `/mnt/data/mensajeinicial.md` como arranque breve si trabajas fuera del proyecto.

**Entrega**  
- Un **único bloque de código** listo para pegar.  
- Incluir al inicio documentación del script: **propósito, parámetros, ejemplos de uso**.  
- Validación de entradas y **manejo robusto de errores** (`try/catch`, `-ErrorAction Stop`).

## 5) Estándares de implementación
- **Simplicidad y eficiencia**: solo lo necesario para resolver la tarea.
- **Optimización de recursos**: preferir cmdlets nativos y evitar procesos paralelos sin control.
- **Automatización responsable**: sin extras no solicitados (logs avanzados, notificaciones, telemetría).
- **Seguridad**:
  - Verifica elevación correctamente con `WindowsPrincipal.IsInRole(Administrator)` (ver `RED.md`). **No** usar comprobación por registro.
  - No modificar el sistema sin validación previa/confirmación explícita.
- **Progreso**: mostrarlo solo si la operación es larga (sin sobrecargar).
- **Compatibilidad**: garantizar funcionamiento en PowerShell 5.1; mencionar requisitos cuando apliquen.

## 6) Entregables y artefactos
- Si el script **genera archivos**, provee **enlace de descarga en ASCII** (ruta local visible, p. ej., `sandbox:/mnt/data/...`).  
- (Opcional) Registrar artefactos en `artifacts/descargas.md` (ruta, fecha, hash) para persistencia.
- Para **documentos** modificados, entregar enlaces de **backup** y **actualizado** (sin bloques de código).

## 7) Política de “Script Canónico”
Si el script cumple los requisitos (funcional, seguro, compatible), indícalo como **Script Canónico** y que **puede ejecutarse con confianza**. No agregar nuevas funciones salvo que el usuario lo solicite después y el alcance lo permita.

## 8) Verificación de información
Si no estás seguro:
1. Busca primero en los archivos del proyecto.  
2. Si falta información, **busca en internet** en fuentes oficiales/primarias.  
3. Si persiste la incertidumbre, declara que es **suposición** y explica el límite.

## 9) Edición de archivos de texto
Cuando se solicite **modificar un documento** del proyecto (p. ej., `README.md`, `Contexto.md`, `RED.md`, `RED-TEMARIO.md`):

- **Backup obligatorio:** antes de tocar nada, crear una copia íntegra con marca de tiempo.
- **Aplicar cambios preservando contenido:** por defecto **AÑADIR LOS CAMBIOS** sin borrar secciones existentes, salvo que el requerimiento especifique un reemplazo 1:1.
- **Entrega por enlaces:** no imprimir documentos completos en bloques de código. Entregar **dos enlaces de descarga**: (1) backup y (2) archivo actualizado.
- **Única excepción:** las **Instrucciones del proyecto** no son un documento; sus modificaciones se entregan en un **bloque de código** con el texto exacto actualizado.


- **Nomenclatura y trazabilidad:** los archivos modificados deben guardarse con:
  - **Backup:** `<NOMBRE>_backup_YYYYMMDD-HHMMSS.md`
  - **Actualizado:** `<NOMBRE>_actualizado_YYYYMMDD-HHMMSS.md`
  El `<NOMBRE>` es el identificador corto del documento: `README`, `Contexto`, `RED`, `RED-TEMARIO`, `Vic`, `mensajeinicial`.
- **Resolución por alias (sesiones):** cuando el usuario se refiera a “README”, “RED”, “TEMARIO”, “VIC” o “CONTEXTO” (con o sin `.md`), interpretar como **el archivo con ese prefijo** cuyo sufijo de fecha es **más reciente**. Si hay empate, usar el más nuevo por fecha de modificación.
- **Bitácora de edición**: anota fecha/hora, archivo afectado, acción (backup/actualización) y enlaces generados.

## 10) Restricciones y “no hacer” Restricciones y “no hacer”
- No repetir errores listados en `RED.md`.
- No agregar mejoras no solicitadas ni complejidad innecesaria.
- No depender de funciones no definidas (p. ej., `Log-Error`) salvo que se incluyan en el mismo script.
- No demorar la entrega esperando confirmaciones si el requerimiento es claro.

## 11) Reglas de salida (AutoQA)
Antes de enviar **cualquier** script, verifica que cumpla **todas**:
1. **Compatibilidad**: `#requires -Version 5.1` en la primera línea.  
2. **Formato único**: entrega en **un bloque de código** (sin texto entre medio).  
3. **Cabecera documental**: incluye `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`.  
4. **Validación**: usa atributos (`Validate*`) y validaciones de runtime cuando aplique.  
5. **Errores**: establece `$ErrorActionPreference = 'Stop'` y maneja errores con `try/catch`.  
6. **Elevación opcional**: expón `-RequireAdmin`; si se solicita y no hay admin, **lanza** un error terminante (no `Write-Error` pasivo).  
7. **PS 5.1 puro**: no usar cmdlets exclusivos de PS7+; si no hay alternativa razonable, **explica la limitación**.  
8. **Sin dependencias implícitas**: no requerir funciones/módulos no definidos o no estándar.  
9. **Artefactos**: si se crean archivos/carpetas, imprime la **ruta final** (enlace ASCII).  
10. **Etiqueta**: si cumple, marca **Script Canónico**.
11. **Salida limpia**: NO usar Write-Host; devolver objetos o Write-Verbose (si el usuario ejecuta con -Verbose).


## 12) Comportamientos por defecto (aplicación)
- **Elevación**: `-RequireAdmin` está **desactivado por defecto**; solo exige admin si la tarea lo necesita.  
- **Alternativa PS 5.1**: cuando el usuario pida algo que naturalmente es PS7+, ofrecer variante PS 5.1 o explicar límite.  
- **Progreso**: muéstralo solo en operaciones largas.  
- **Salida limpia**: evita verbosidad innecesaria; retorna objetos o información útil para el usuario.

---

## Política **Preflight primero** y **Progreso visible** (añadido 20250918-051429)

**Obligatorio para todos los scripts PowerShell del proyecto:**

1. **Preflight al inicio** (antes de cualquier acción): validación de elevación (WindowsPrincipal), existencia de orígenes y destinos, espacio libre por unidad destino, disponibilidad de binarios externos (p. ej., `winfr`, `photorec_win.exe`).
2. **Confirmación explícita** tras el preflight. El script **no ejecuta** acciones hasta que el usuario confirme (o use `-Force`).
3. **Progreso visible**: uso de `Write-Progress` (PS 5.1) para indicar avance global por lotes y por unidad, además de `Write-Verbose` para detalle. Prohibido `Write-Host`.
4. **Salida limpia**: devolver objetos al finalizar y registrar bitácoras/índices en `SESSION_INFO.txt` dentro de la ruta de sesión.
5. **Opción de solo verificación** (`-PreflightOnly`) opcional para auditorías.

### Ejemplo mínimo

```powershell
# Recomendado: el script realiza preflight, muestra los checks y pide confirmación
.\Invoke-DeepRecovery.DOCS.ps1 -SourceDrives C -DestinationDrives D,E -Engine WinFR -Verbose
```


## Edición
- **NO usar `Write-Host`** en ningún script; preferir salida por objetos o `Write-Verbose`.
~~~~~

## Thoughts
El usuario pide un análisis detallado del README. Debo destacar estructura, fortalezas, posibles inconsistencias, recomendaciones y alineación con las instrucciones del proyecto. He notado algunas contradicciones, como el cambio de versiones de PowerShell (7 vs. 5.1) y el uso inconsistente del idioma. Revisaré eso mientras me ajusto al análisis del texto proporcionado.
El usuario pidió un análisis sin ejecutar nada, así que paso a revisar el contenido. Debo enfocarme en proporcionar un análisis claro, destacando fortalezas, contradicciones, riesgos y cualquier falta. También debo considerar las instrucciones, destacando inconsistencias como PowerShell 7 vs. 5.1, o problemas con las confirmaciones y bloques de código. Incluiré también un resumen ejecutivo y acciones inmediatas.
La instrucción "Ejecuta `RED-TEMARIO.md`" parece ambigua, ya que "ejecutar" no tiene sentido con un archivo markdown; tal vez se refiera a "leer". También hay un conflicto entre "requiere confirmación explícita" y "sin confirmaciones". Además, la incompatibilidad entre PowerShell 5.1 y 7 debe resolverse unificando las versiones y proponiendo el uso de "feature flags".
Seguiré el enfoque solicitado, ofreciendo un análisis profundo sin modificar archivos ni generar scripts. Propondré una estructura sugerida para el encabezado del script, con elementos como `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, y `.EXAMPLE`, manteniendo la propuesta concisa. Además, incluiré hallazgos clasificados por relevancia y un "AutoQA compliance matrix".

## ASSISTANT
Va: leí todo el README y lo desarmé. Aquí tienes un dictamen claro y accionable.

# Resumen ejecutivo
- El README está **bien encaminado** (prioriza PS 5.1, un-turno, “Script Canónico”, sin `Write-Host`, preflight y trazabilidad por backups/enlaces).
- Hay **inconsistencias** y **huecos operativos** que causarán fricción: PS7 vs PS5.1, una línea rota, verbos contradictorios (“ejecuta” un .md), duplicados de texto y reglas sin mecanismo de verificación automática.
- Con **parches menores** + una sección de “AutoQA ejecutable” (PSScriptAnalyzer/Pester) quedaría sólido.

---

# Fortalezas
- **Entrega en un turno** y foco en **artefactos accionables**.
- **Compatibilidad PS 5.1** y guía explícita anti-errores (`-ErrorAction Stop`, `try/catch`, validaciones, `-RequireAdmin`, `Write-Progress`, `Write-Verbose`).
- **Política de edición** con **backup + actualizado** y **nomenclatura con timestamp**.
- **Preflight** obligatorio y opción `-PreflightOnly` — sensato para tareas riesgosas.
- **Resolución de alias** para elegir el documento “más reciente”.

---

# Inconsistencias / Ambigüedades (priorizadas)

**Crítico**
1) **PS7 vs PS5.1.**  
   - ROL dice “especializado en *PowerShell 7 para Windows 10*”; más abajo se fija **entorno objetivo: *Windows 10 + PowerShell 5.1*** y “PS 5.1 puro” en AutoQA.  
   **Impacto:** decisiones de diseño, módulos, sintaxis (`ForEach-Object -Parallel`, `-PipelineVariable`, `Get-ChildItem -Depth`, etc.).  
   **Arreglo:** declarar **“Desarrollar para PS 5.1 (mínimo), compatible con PS 7 cuando aporte valor”** y prohibir cmdlets exclusivos de 7 salvo con `#requires -RunAsAdministrator`/feature flag documentado.

2) **Verbo incorrecto: “Ejecuta `RED-TEMARIO.md`”.**  
   Un Markdown **no se ejecuta**. Debe decir **“Consulta/lee”**.

**Alto**
3) **Línea truncada/rota**:  
   “**idad y automatización razonable. Entorno objetivo: Windows 10 + PowerShell 5.1**” — viene de un corte de “Calidad…”.  
   **Arreglo:** unir frase y restaurar el término.

4) **Duplicación de encabezado**:  
   “**Restricciones y ‘no hacer’ Restricciones y ‘no hacer’**”.  
   **Arreglo:** dejar un único encabezado.

5) **Entrega y confirmaciones**:  
   - README exige **“no prometer trabajo futuro”** (bien).  
   - Política **Preflight** pide **confirmación explícita** (o `-Force`).  
   **No es contradicción**, pero conviene **aclarar** que la confirmación es **del script en runtime**, no del chat.

**Medio**
6) **Alias de documentos “más reciente”**: falta criterio de desempate en caso de reloj desincronizado versus mtime.  
   **Arreglo:** “Si hay empate por sufijo, usar **mtime**; si mtime empata, elegir por **tamaño** mayor como heurística”.

7) **Enlaces “sandbox:/mnt/data/...”**: perfectos en este entorno; fuera de él, no.  
   **Arreglo:** indicar que el enlace ASCII es **local al entorno de ejecución** y acompañarlo de **ruta absoluta** convencional cuando aplique.

8) **“Progreso visible”**: bien, pero no define **umbral** de “operación larga”.  
   **Arreglo:** ejemplo: “>10 s o >200 ítems”.

**Bajo**
9) Falta **carpeta estándar** para artefactos (`artifacts/`, `backups/`, `logs/`).  
10) Falta mención de **PSScriptAnalyzer/Pester** como **compuerta de calidad** (están implícitos en el proyecto, no en este README).

---

# Huecos operativos
- **AutoQA ejecutable**: las 11 reglas están en texto, pero no hay **script** que las verifique automáticamente.
- **Plantilla oficial de cabecera** (`.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE`) no está incluida como snippet reutilizable.
- **Criterios de seguridad**: buena recomendación para elevación con `WindowsPrincipal`, pero falta **snippet canónico** y **ruta de escape** para PS remota/no interactiva.
- **Bitácora**: se menciona “anota fecha/hora…”, pero no hay **formato** ni **ubicación** fija.

---

# Parches propuestos (texto exacto para pegar en README)

1) **Unificar compatibilidad (PS 5.1 primero):**
> **Compatibilidad**: Desarrollar para **PowerShell 5.1 (mínimo)** en Windows 10. Se permite compatibilidad **opcional** con PowerShell 7+ cuando aporte valor, **sin** romper PS 5.1. Evitar cmdlets exclusivos de 7 salvo que se documente alternativa o degradación.

2) **Corregir verbo (RED-TEMARIO):**
> **Paso 0 (obligatorio)**  
> **Consulta** `RED-TEMARIO.md`. Luego revisa únicamente las secciones de `RED.md` que el temario indique.

3) **Arreglar línea rota:**
> …**Calidad y automatización razonable.** Entorno objetivo: **Windows 10 + PowerShell 5.1** (evitar cmdlets exclusivos de PowerShell 7+).

4) **Eliminar duplicado de encabezado:**
> `## 10) Restricciones y “no hacer”`

5) **Aclaración Preflight:**
> La **confirmación del Preflight** es en **tiempo de ejecución del script** (o mediante `-Force`). No aplica a la conversación.

6) **Alias y desempates:**
> Resolución por alias: elegir el archivo con sufijo de fecha **más reciente**; si hay empate, usar **fecha de modificación**; si persiste, elegir el **de mayor tamaño**.

7) **Enlaces locales:**
> Los enlaces `sandbox:/mnt/data/...` son **locales al entorno**. Acompáñalos de **ruta absoluta** en el sistema del usuario cuando aplique.

8) **Umbral de progreso:**
> Mostrar `Write-Progress` cuando la operación supere **10 s** o procese **>200 ítems**.

9) **Estructura de carpetas recomendada:**
> `artifacts/`, `backups/`, `logs/`, `reports/`.

10) **AutoQA ejecutable (añadir subsección nueva):**
> Antes de entregar, ejecutar `Invoke-ArtifactQA.ps1` (PSScriptAnalyzer + Pester) con reglas:  
> - PS 5.1 compatible, `#requires -Version 5.1`  
> - Sin `Write-Host`  
> - Cabecera `.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE` presente  
> - Uso de `try/catch`, `$ErrorActionPreference='Stop'`  
> - `-RequireAdmin` opcional y validado con `WindowsPrincipal`  
> - Enlaces de artefactos impresos al final

---

# Snippets canónicos (para incluir en RED.md o como anexo del README)

**Elevación (PS 5.1):**
```powershell
Add-Type -AssemblyName System.Security
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($RequireAdmin -and -not $IsAdmin) { throw "Se requiere ejecución como Administrador." }
```

**Cabecera mínima recomendada:**
```powershell
<#
.SYNOPSIS
  (Resumen corto en una línea)
.DESCRIPTION
  (Propósito, alcance y efectos)
.PARAMETER InputPath
  (Descripción y validaciones)
.EXAMPLE
  .\Script.ps1 -InputPath C:\Data -Verbose
#>
```

---

# Matriz rápida de cumplimiento (AutoQA textual → estado)
- `#requires -Version 5.1`: **Definido** (✔ conceptual, falta verificación automática).
- Un bloque de código único: **Definido**.
- Cabecera `.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE`: **Definido**, **sin plantilla** (△).
- Validaciones + `$ErrorActionPreference='Stop'` + `try/catch`: **Definido**.
- `-RequireAdmin` con `WindowsPrincipal`: **Definido**, **falta snippet oficial** (△).
- PS 5.1 puro: **Definido**, choca con ROL PS7 (✖) → **parche 1**.
- Sin dependencias implícitas: **Definido**.
- Artefactos con enlace ASCII: **Definido**, **aclaración entorno** (△).
- Etiqueta “Script Canónico”: **Definido**.
- Salida limpia (no `Write-Host`): **Definido**.
- Preflight/Confirmación/`-PreflightOnly`: **Definido**, **aclaración** (△).

---

# Acciones inmediatas (una línea cada una)
1) Aplicar **parche 1–5** (compatibilidad, verbo, línea, duplicado, aclaración preflight).  
2) Añadir **subsección AutoQA ejecutable** y publicar `Invoke-ArtifactQA.ps1`.  
3) Publicar **snippet de elevación** y **plantilla de cabecera** como anexos.  
4) Definir **estructura de carpetas** (`artifacts/`, `backups/`, `logs/`, `reports/`).  
5) Documentar **umbral de progreso** y **regla de alias** con desempates.

---

No usé fuentes externas; todo el análisis se basa únicamente en el texto que compartiste. Si quieres, preparo el parche del README con los cambios arriba y te regreso **backup + actualizado** conforme a la política §9.

