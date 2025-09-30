```
~~~~~

## Thoughts
El usuario me pide que lea y analice detalladamente el contenido, que está en español. Recibo instrucciones claras: analizar fortalezas, brechas, ambigüedades, áreas de riesgo y mejoras accionables. También se solicita una verificación de consistencia, mapeo a los SOPs, garantizando definiciones claras y sugerencias para aclaraciones.
Al revisar las instrucciones, noto confusión con la numeración en "Al iniciar una nueva sesión" (1 y 1)). También hay duplicación y referencias al archivo SOP.zip en una ubicación específica. Se mencionan reglas de "CB/Fences", pendiente de detallar bien cómo usar triple backticks y tildes. Además, faltan detalles claros en algunas reglas, como el umbral de las advertencias y el esquema de objetos de salida.
El nombre de la función 'RepoAR-EnsureDir' parece adecuado, pero el ejemplo de la función 'RepoAR-NewTS' usa 'PadRight' para rellenar la marca de tiempo. Aunque es válido llamarlo con el carácter '0', podría simplificarse. El retorno debería ser [string], ya que actualmente devuelve tipo 'string', pero se recomienda especificar en el tipo de salida.
Es recomendable usar el atributo OutputType y configurar "Set-StrictMode versión 3.0" a nivel de módulo para evitar efectos secundarios repetidos. En cuanto a las reglas de "Backups", se menciona inconsistencia en las rutas de SCRIPTS\GENERADOR\BACKUPS, que deberían ajustarse. También, especificar cómo generar el formato NUnitXml con Pester y cómo obtener la fecha en UTC para SemVer.

## ASSISTANT
¡Listo! Aquí tienes un análisis a fondo de tu **“Project Instructions — AutoScript_AR”** con hallazgos, riesgos y acciones concretas para dejarlo listo para operar sin fricciones.

# Resumen ejecutivo
El documento está bien encaminado: define objetivo (modularizar el macroscript a micro-funciones testeables), calidad mínima (PSSA + Pester + manifest), trazabilidad (CHANGELOG), y reglas de formato (fences/here-strings). Lo que falta para hacerlo “ejecutable sin ambigüedades” es: unificar rutas de backups, fijar umbrales/convenciones concretas (warnings PSSA, convención SemVer/fecha), precisar la matriz de outputs y clarificar el “contrato de sesión” (qué es obligatorio en cada turno y qué hacer ante fallos).

---

# Fortalezas (lo que ya está sólido)
- **Meta y alcance claros.** Modularización, pruebas y verificación están definidos; delimita lo que no entra (CI/CD, secretos).  
- **Quality Gate explícito.** Corta si hay errores PSSA, fallos Pester o manifiesto inválido.  
- **Trazabilidad.** CHANGELOG append-only con SemVer + fecha; carpeta `VERIFICATION\` con artefactos (JSON, SARIF, NUnit).  
- **Estandarización de I/O.** UTF-8 sin BOM, CRLF, `Join-Path`, here-strings literales para contenido “peligroso”.  
- **Estructura del repo funcional.** Separa macroscript (`GENERADOR`) y módulo (`MODULES\RepoAR.Core.psm1`).  
- **Guía de micro-funciones.** Firma con `[CmdletBinding()]`, una responsabilidad, salidas en objeto, pruebas Pester v5.

---

# Ambigüedades / inconsistencias a corregir
1) **Backups: dos ubicaciones distintas.**  
   - En Principios (#3.2) pides espejo en `SCRIPTS\GENERADOR\BACKUPS`.  
   - En Estructura (#4) incluyes `SCRIPTS\BACKUPS\`.  
   **Riesgo:** confusión de destino, duplicidad y drift.  
   **Acción:** elegir **una sola** ruta (recomiendo `SCRIPTS\BACKUPS\`) y referenciarla en todo el doc.

2) **Contrato de sesión — numeración y obligatoriedad.**  
   Mezcla `1.` con `1) 2) 3) 4)` y no define qué pasa si no existe `/mnt/data/SOP.zip/SOP_AVCM.md`.  
   **Acción:** uniformar numeración y añadir “degradación elegante”: si no se encuentra el SOP, continuar con auditoría mínima local (PI/CI/Memoria/Files).

3) **Umbral PSScriptAnalyzer (warnings).**  
   Indicas “≤ umbral del repo” pero no lo fijas ni dónde vive.  
   **Acción:** definir valor (p.ej., `MaxWarnings = 5`) en `PSScriptAnalyzerSettings.psd1` y citarlo aquí.

4) **Cobertura de pruebas.**  
   Dices “cobertura mínima sobre funciones nuevas/críticas” pero no cifras.  
   **Acción:** fijar objetivo (p.ej., ≥ **80%** funciones nuevas; ≥ **60%** del módulo si se toca código legacy).

5) **Salida “objeto” sin contrato de forma.**  
   No hay esquema de salida (p.ej., PSCustomObject con campos estándar).  
   **Acción:** definir un **contrato de objeto** (mínimo: `Name`, `Version`, `Status`, `Details`, `Path`).

6) **Ejemplo de micro-función** (RepoAR-NewTS):  
   - `PadRight` sobre un timestamp completo no aporta (ya excede 6 chars).  
   - `Set-StrictMode` dentro de cada función es inusual; mejor a nivel de módulo.  
   **Acción:** simplificar ejemplo, añadir `[OutputType([string])]`, y mover StrictMode al módulo.

7) **SemVer + fecha UTC sin formato.**  
   No se especifica formato de línea en CHANGELOG.  
   **Acción:** estandarizar: `## [x.y.z] - 2025-09-29T14:07:00Z` + bullet de motivo.

8) **Rutas y entorno mixto PS 5.1/7.x.**  
   En PS 5.1 `Set-Content` no es UTF-8 sin BOM por defecto; en 7.x sí.  
   **Acción:** documentar mandatorio: usar `utf8NoBOM` / API .NET para PS5.1.

9) **“Un artefacto por turno” vs. entregas compuestas.**  
   Verificación genera 3 archivos; tu regla podría interpretarse como bloqueo.  
   **Acción:** aclarar: *“un entregable principal por turno; los artefactos de verificación pueden ser múltiples”*.

10) **Camino absoluto del comando de verificación.**  
   `"$env:USERPROFILE\Desktop\Repo_AR\..."` asume layout fijo.  
   **Acción:** recomendar `%REPO_ROOT%` o parámetro `-RepoRoot` + `Join-Path`.

---

# Riesgos operativos
- **Drift de backups / rutas** → pérdidas o duplicados.  
- **Gate laxo por warnings no definidos** → código de menor calidad pasa.  
- **Salidas heterogéneas** → difícil automatizar validaciones/reportes.  
- **Dependencia de PS 7 features en PS 5.1** (encoding) → falsos positivos en verificación.

---

# Acciones correctivas (una línea cada una)
1. Unifica **backups** en `SCRIPTS\BACKUPS\` y elimina menciones a `GENERADOR\BACKUPS`.  
2. Fija `PSSA.MaxWarnings = 5` en `PSScriptAnalyzerSettings.psd1` y referencia el valor aquí.  
3. Establece **cobertura mínima**: nuevas ≥ 80%, módulo ≥ 60%; reportar con `Invoke-Pester -OutputFormat NUnitXml`.  
4. Define **contrato de salida** (PSCustomObject) con campos estándar y úsalo en todas las funciones.  
5. Mueve `Set-StrictMode` al **módulo** y simplifica `RepoAR-NewTS` con `[OutputType([string])]`.  
6. Normaliza **CHANGELOG**: `## [MAJOR.MINOR.PATCH] - ISO8601Z` + motivos.  
7. Documenta encoding PS5.1: usar `-Encoding utf8NoBOM` o `.WriteAllText(…, new UTF8Encoding($false))`.  
8. Aclara “un artefacto por turno” → permite artefactos de verificación múltiples.  
9. Parametriza **RepoRoot** para evitar rutas de escritorio hardcoded.  
10. Añade **plan de degradación** si no existe `/mnt/data/SOP.zip/SOP_AVCM.md`.

---

# Comprobaciones de coherencia con tus SOPs internos
- **Fences/CB:** Consistente con tu protocolo (wrapper `~~~~~` para bloques anidados, ``` para internos). ✔️  
- **SemVer/CHANGELOG append-only:** Alineado con trazabilidad. ✔️ (falta formato explícito).  
- **“Un turno = valor real”:** Compatible con Quality Gate (fallo → no entregar). ✔️  
- **Here-strings literales:** Bien definidos; recuerda cierre `'@` en columna 1. ✔️

---

# Propuestas de definición concreta (listas para copiar al manual)
**Contrato de salida (objeto mínimo):**
```