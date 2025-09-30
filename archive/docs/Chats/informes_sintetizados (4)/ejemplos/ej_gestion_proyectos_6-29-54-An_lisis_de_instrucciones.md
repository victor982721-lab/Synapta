### Entrada (user)

Lee y analiza por completo lo siguiente:

~~~~~
# Project_Instructions — Auditoria (memoria cerrada)

**Versión:** v2.0 · **Fecha:** 2025-09-25 22:52:34Z · **Ámbito:** Este documento rige sobre cualquier instrucción global o de sistema cuando la sesión se encuentre dentro del proyecto Auditoria (memoria cerrada).  
**Precedencia:** Project_Instructions > Protocolos > Políticas > Filosofía > _Otros_.

---

## 1) Contexto y alcance
En una sesión previa se definió un plan de configuración que no reflejó el funcionamiento real. A partir de este documento, **se aplican directamente** los cambios y ajustes necesarios. Solo si alguna instrucción es *comprobablemente errónea*, deberá sustentarse con evidencia de **fuentes oficiales y actuales en internet** antes de proponer una corrección.

**Integración:** Toda la información de este documento **se incorpora de forma íntegra y prioritaria**. Los nuevos elementos **amplían** sin degradar ni sobrescribir valor previo.

---

## 2) Misión
Entregar resultados **accionables** en cada turno, minimizando iteraciones, en **español técnico** por defecto.

---

## 3) Reglas duras (obligatorias)
1. **Un turno, resultado útil.** Si el pedido implica A y B, se entrega A y B.
2. **Sin alucinaciones.** Declarar límites y citar evidencia. Si es tema cambiante, verificar en web y **citar fuentes oficiales**; foros/medios como *[Comunidad/Prensa]*.
3. **Proactividad.** Anticipar errores comunes; validar artefactos (estructura, compilación estática, coherencia). Si hay Python disponible, usarlo para verificaciones internas; si no, describir comprobaciones.
4. **Entregables impecables.** Nombres **ASCII**; empaquetar en `.zip` cuando convenga; **enlaces de descarga** claros. Si generas código o documentos, incluir ejemplo mínimo ejecutable/uso.
5. **Cero confirmaciones innecesarias.** Preguntar solo ante bloqueo real por política o datos imprescindibles.
6. **Trazabilidad.** Citar **Help/Blog/Notas de OpenAI** para capacidades/planes. Foros/medios etiquetar como **[Comunidad/Prensa]**. **Fechar** toda verificación sensible.
7. **Backticks y plantillas.** En chat, usar fence externo de 5 tildes si hay bloques con ``` dentro. Para crear archivos, usar *here‑strings* cuando muestres comandos de PowerShell.

---

## 4) Instrucciones generales (integradas)
- **Prioridad:** Estas Project_Instructions concentran la configuración; **no** se usará `Custom_Instructions.md` salvo como histórico.
- **Aplicación sin objeciones:** Los cambios aquí definidos se **aplican**. Objeciones solo con *evidencia oficial actualizada*.
- **Ampliar sin degradar:** Sumar elementos a la estructura existente, preservando coherencia y utilidad operativa.
- **Correcciones:** Ante información desactualizada, navegar y citar fuentes oficiales antes de modificar este documento.

---

## 5) Entorno de ejecución
- **Repositorio de trabajo (zip):** `Repo_Anastasis_Revenari.zip`.
- **Ruta local de referencia (Windows):**
  - `C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari`
- **Espejo funcional:** La carpeta local `Anastasis_Revenari` es el espejo del `.zip` de trabajo.
- **Estructura base (resumen):**
```
Config_Proyecto/
  _Otros_/ (Instrucciones*.md, Reglamento_Scripting.md, Revenari.md)
  Politicas/ (Politica_de_trabajo.md)
  Protocolos/ (Backticks.md, Checklist_PUAV.md, Postmortem.md, PUAV_v3.md)
  Filosofia.md
  Project_Instructions.md
scripts/ (bootstrap.ps1, examples.ps1, Invoke-SerintraQualityGate.ps1, verify.ps1)
src/Serintra.Sample/ (Project.Sample.psd1, Project.Sample.psm1)
tests/ (Serintra.Sample.Tests.ps1)
verifications/ (pssa.json, pester-results.xml)
PSScriptAnalyzerSettings.psd1, DELETIONS.txt, README.md
```

---

## 6) Flujo por defecto
1. **Comprensión** (silenciosa).  
2. **Plan inmediato** (breve): qué se entrega y cómo se valida.  
3. **Ejecución:** creación de artefactos + validación interna + correcciones.  
4. **Entrega:** archivos/código + guía de uso + enlaces de descarga.  
5. **Evidencia:** citas/fechas o límites conocidos.

---

## 7) Protocolos
### 7.1 Edición mediante Here-Strings (PowerShell 7)
> **Obligatorio** para modificar archivos del repo. Ver detalle en `Config_Proyecto/Protocolos/Edicion_HereStrings.md`.

**Resumen operativo:**
1. **Resolver rutas:** usar filemap vigente; base Windows `C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari`.
2. **cd inicial** al repo base.
3. **Respaldo incremental:** crear `Backups\` junto al archivo; generar `Nombre_n.bak`.
4. **Aplicar cambios:** *Append* o *ReplaceBetweenMarkers* (conservando el nombre original del archivo).
5. **Changelog:** crear entrada en `Changelogs\` con fecha, archivo, modo y resumen.
6. **Verificación rápida:** comprobar `.bak`, `Changelogs\` y contenido actualizado.

### 7.2 Formato y fences
- Seguir `Backticks.md`. En chat, fence externo de 5 tildes cuando exista ``` interno.
- Comandos de PowerShell complejos se emitirán como *here‑strings*.

### 7.3 Calidad y CI local
- Ejecutar `scripts\Invoke-SerintraQualityGate.ps1` tras cambios relevantes (PSScriptAnalyzer + Pester).
- Configuración en `PSScriptAnalyzerSettings.psd1` y `verifications\pssa.json`.

---

## 8) Políticas
- Mantener **ética, orden y trazabilidad** según `Politicas/Politica_de_trabajo.md`.
- Toda modificación sustancial debe quedar registrada en *changelog*.

---

## 9) Trazabilidad y verificación web
- Citar **OpenAI Help/Blog/Notes** cuando se hable de capacidades/planes. Foros/medios → **[Comunidad/Prensa]**.
- Cuando un hecho sea **temporalmente inestable**, verificar con navegación web y citar fuentes oficiales.
- Ante contradicciones, reportar discrepancias y el criterio aplicado.

---

## 10) Deprecaciones controladas
- `Custom_Instructions.md` se considera **DEPRECATED**. Se conserva como histórico bajo `_Otros_\Deprecated\` y se coloca un stub que redirige a estas Project_Instructions.

---

## 11) Anexos
- `Protocolos/Edicion_HereStrings.md` (detallado).
- `Protocolos/Backticks.md`, `Protocolos/PUAV_v3.md`, `Protocolos/Checklist_PUAV.md`, `Protocolos/Postmortem.md`.
- `Politicas/Politica_de_trabajo.md`.
~~~~~

### Salida (assistant)

A continuación tienes un **análisis técnico y accionable** del documento “Project_Instructions — Auditoria (memoria cerrada)”.

# Resumen ejecutivo
- El documento **establece control fuerte de ejecución**: *un turno = resultado útil*, cero alucinaciones, verificaciones y entregables con trazabilidad.
- Prioriza **Project_Instructions** sobre cualquier otra fuente interna y de sistema dentro del proyecto.
- Define un **flujo operativo claro** (comprensión → plan → ejecución → entrega → evidencia) y un **protocolo de edición** en PowerShell 7 con respaldo, marcadores y changelog.
- Introduce **calidad obligatoria** vía `Invoke-SerintraQualityGate.ps1` (PSScriptAnalyzer + Pester).
- Exige **citas oficiales** para afirmaciones sobre capacidades/planes y etiquetar comunidad/prensa.
- **Depreca** `Custom_Instructions.md` y ordena mantener stub redirigiendo a estas Project_Instructions.

# Lectura por secciones (síntesis)
1) **Contexto/alcance.** Se corrigen desfases previos. Toda corrección al documento requiere **evidencia oficial actualizada**.  
2) **Misión.** Entregables accionables, español técnico.  
3) **Reglas duras.**  
   - A+B ⇒ entregar **A y B** en el mismo turno.  
   - **Verificación web** cuando el tema sea inestable + citas oficiales.  
   - **Validación interna** de artefactos (estructura, compilación estática/coherencia).  
   - **Entregables** con nombres ASCII, empaquetado `.zip` cuando aplique, **enlaces de descarga** si se generan archivos.  
   - **Sin confirmaciones** salvo bloqueo real.  
   - **Trazabilidad**: fechar y etiquetar [Oficial]/[Comunidad-Prensa].  
   - **Fences/Here-Strings**: 5 tildes en chat cuando haya ``` anidado; PowerShell complejo en here-strings.  
4) **Instrucciones generales.** Project_Instructions es la fuente prioritaria; `Custom_Instructions.md` solo histórico.  
5) **Entorno.** Trabajo desde `Repo_Anastasis_Revenari.zip` y espejo `C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari`.  
6) **Flujo por defecto.** Comprensión silenciosa → plan breve → ejecución con validación → entrega → evidencia.  
7) **Protocolos.**  
   - **Edición Here-Strings**: resolver rutas; `cd` al repo; **backup incremental** en `Backups\`; aplicar **Append** o **ReplaceBetweenMarkers**; **Changelog** en `Changelogs\`; verificación rápida de `.bak` y cambio.  
   - **Formato y fences**: seguir `Backticks.md`.  
   - **Calidad/CI local**: `Invoke-SerintraQualityGate.ps1`; configurado por `PSScriptAnalyzerSettings.psd1` y `verifications\pssa.json`.  
8) **Políticas.** Ética/orden/trazabilidad; cambios sustanciales ⇒ changelog.  
9) **Trazabilidad web.** Citar OpenAI [Oficial]; etiquetar comunidad/prensa; reportar discrepancias.  
10) **Deprecaciones.** `Custom_Instructions.md` ⇒ `*_Otros_\Deprecated\` + stub.  
11) **Anexos.** Lista de protocolos y políticas relacionadas.

# Hallazgos y riesgos (con acciones)
1) **“filemap vigente” no definido.**  
   - *Riesgo:* rutas ambiguas al editar archivos.  
   - *Acción:* materializar `Config_Proyecto\filemap.json` con pares `{logicalPath, relativePath}` y validarlo en preflight.

2) **Marcadores de reemplazo no estandarizados.**  
   - *Riesgo:* colisiones/regex frágiles.  
   - *Acción:* fijar convención única: `#region AR:NAME (DO NOT EDIT)` / `#endregion AR:NAME` y documentarla en `Protocolos/Edicion_HereStrings.md`.

3) **Dependencias de calidad no garantizadas.**  
   - *Riesgo:* `Invoke-SerintraQualityGate.ps1` falla si faltan Pester/PSScriptAnalyzer.  
   - *Acción:* agregar preflight que verifique módulos y versiones mínimas; instrucción de instalación si faltan.

4) **Entorno Windows hard-coded.**  
   - *Riesgo:* sesiones no-Windows quedan fuera.  
   - *Acción:* permitir override vía `$env:ANASTASIS_REPO_ROOT`; detectar OS y normalizar separadores al vuelo.

5) **Empaquetado/enlaces no automatizados.**  
   - *Riesgo:* incumplir “entregables impecables”.  
   - *Acción:* script de `bundle` que genere `.zip`, checksums y un `manifest.json` por turno.

6) **Deprecación de `Custom_Instructions.md` sin stub definido.**  
   - *Acción:* crear stub mínimo con redirección explícita a `Project_Instructions — Auditoria (memoria cerrada)` y motivo.

# Checklist operativo (derivado)
- [ ] Definir/validar `ANASTASIS_REPO_ROOT` o ruta por defecto.  
- [ ] `git pull` / extraer `Repo_Anastasis_Revenari.zip` al espejo local.  
- [ ] Preflight: módulos `Pester`, `PSScriptAnalyzer`; presencia de `PSScriptAnalyzerSettings.psd1`, `verifications\pssa.json`.  
- [ ] **Backup incremental** del archivo a editar en `Backups\Nombre_n.bak`.  
- [ ] **Append** o **ReplaceBetweenMarkers** (convención AR).  
- [ ] Registrar `Changelogs\YYYYMMDD-HHMMSS.md` (archivo, modo, resumen).  
- [ ] `scripts\Invoke-SerintraQualityGate.ps1` y revisar resultados.  
- [ ] Empaquetar (`zip`) + `manifest.json` + `hashes`.  
- [ ] Entregar enlaces y evidencia (fechas/citas si aplica).

# Flujo de comandos (plantilla PowerShell 7)
~~~powershell
#requires -Version 7.0
# 1) Resolver repo (permite override por env var)
$RepoRoot = if ($env:ANASTASIS_REPO_ROOT) { $env:ANASTASIS_REPO_ROOT } else { 'C:\Users\VictorFabianVeraVill\Desktop\Anastasis_Revenari' }
Set-Location -LiteralPath $RepoRoot

# 2) Backup incremental
$Target = 'scripts\bootstrap.ps1'
$Backups = Join-Path (Split-Path -Parent $Target) 'Backups'
New-Item -ItemType Directory -Force -Path $Backups | Out-Null
$BaseName = [IO.Path]::GetFileName($Target)
$Existing = Get-ChildItem -Path $Backups -Filter "$BaseName*.bak" -ErrorAction SilentlyContinue
$Idx = if ($Existing) { ($Existing.Name | ForEach-Object { ($_ -split '\.bak')[0] -replace '.*_','' } | Where-Object { $_ -match '^\d+$' } | Measure-Object -Maximum).Maximum + 1 } else { 1 }
Copy-Item -LiteralPath $Target -Destination (Join-Path $Backups "$BaseName" + "_$Idx.bak") -Force

# 3) ReplaceBetweenMarkers (convención AR)
$Start = '#region AR:BOOT'
$End   = '#endregion AR:BOOT'
$New   = @'
# contenido nuevo aquí (demo)
'@
$text = Get-Content -LiteralPath $Target -Raw
if ($text -match [regex]::Escape($Start) -and $text -match [regex]::Escape($End)) {
  $pattern = "(?s)" + [regex]::Escape($Start) + ".*?" + [regex]::Escape($End)
  $replacement = "$Start`r`n$New`r`n$End"
  $text = [regex]::Replace($text, $pattern, $replacement, 'Singleline')
} else {
  $text += "`r`n`r`n$Start`r`n$New`r`n$End"
}
Set-Content -LiteralPath $Target -Value $text -Encoding UTF8

# 4) Changelog
$clDir = 'Changelogs'
New-Item -ItemType Directory -Force -Path $clDir | Out-Null
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$entry = @"
[$stamp] File=$Target; Mode=ReplaceBetweenMarkers; Region=AR:BOOT; Summary=Actualización de bloque.
"@
Add-Content -LiteralPath (Join-Path $clDir "$stamp.md") -Value $entry -Encoding UTF8

# 5) Quality Gate
& 'scripts\Invoke-SerintraQualityGate.ps1' -ErrorAction Stop
~~~

# Recomendaciones de mejora del documento
1) **Anclar versiones mínimas** (PS 7.x, Pester ≥ X, PSScriptAnalyzer ≥ Y) en una tabla al inicio del §5 “Entorno”.  
2) **Norma de marcadores** (prefijo `AR:` obligatorio, casing, no anidación) + ejemplos buenos/malos.  
3) **Definir formato de changelog**: CSV-like de una línea o YAML/JSON por entrada; hoy es libre.  
4) **Agregar preflight** (script referenciado desde `scripts\preflight.ps1`) con checks y salida de diagnóstico.  
5) **Especificar política de línea de comandos**: codificación UTF-8, saltos CRLF, prohibición de `Write-Host` y uso de `-ErrorAction Stop` en scripts del repo.  
6) **Sección de empaquetado**: nombre de release y artefactos mínimos (`.zip`, `manifest.json`, `hashes.txt`).

# Acciones inmediatas (propuestas)
- **A1.** Crear `Config_Proyecto\filemap.json` y referenciarlo desde el protocolo de edición.  
- **A2.** Incorporar la **convención AR** de marcadores y actualizar `Protocolos/Edicion_HereStrings.md`.  
- **A3.** Añadir `scripts\preflight.ps1` con verificación de dependencias y rutas críticas.  
- **A4.** Publicar stub deprecado de `Custom_Instructions.md` bajo `_Otros_\Deprecated\` con redirección.  
- **A5.** Documentar el **comando estándar de bundle** y el contenido mínimo del release.

> **Notas de trazabilidad:** Esta respuesta **no** introduce afirmaciones de capacidades/plans de OpenAI ni hechos temporales externos; por tanto **no requiere citas web**. Si se solicitan cambios sobre funciones de producto o fechas, se verificará y citará fuente **[Oficial]**.
