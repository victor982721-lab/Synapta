# Marketing y SEO

## Resumen ejecutivo

Este informe sintetiza 3 conversación(es) consolidadas del tema **Marketing y SEO**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1. Si no viene, usa `$env:ANASTASIS_REPO_ROOT`.
2. Si no existe, cae a `~\Desktop\Anastasis_Revenari`.
3. Valida existencia (`Test-Path`) y devuelve la ruta resuelta (`Resolve-Path`).
1. Resuelve y obtiene el archivo, crea `Backups/` adyacente.
2. Busca el primer nombre libre `Base_n.bak` (n=1,2,…).
3. Copia el original a ese `.bak` y devuelve la ruta.
1. Crea `Changelogs/` adyacente.
2. Genera nombre `yyyyMMdd_HHmmss_<FileNameSanitizado>_<Mode>.md` (UTC).
3. Escribe una ficha breve en Markdown y devuelve la ruta.
1. Crea backup.
2. `Add-Content` con `-Encoding UTF8` (anexa tal cual).
3. Escribe changelog `Mode='Append'`.
4. Devuelve objeto con `{Backup, Changelog, Path}`.
1. Carga todo el archivo en memoria (`-Raw`).
2. Escapa los marcadores con `Regex.Escape`.
3. Arma patrón:
4. Si no hay match → `throw`.
5. Crea backup, arma `replacement`:
6. `Regex.Replace` (reemplaza **todas** las ocurrencias).
7. Sobrescribe el archivo (`Out-File UTF8`) y registra changelog.
1. Busca `<RepoRoot>\scripts\bootstrap.ps1`.
2. Si no existe, devuelve `$false`.
3. Define línea a inyectar: `. "$PSScriptRoot\HereStrings-Utils.ps1"`.
4. Si el contenido **no** menciona `HereStrings-Utils.ps1` (búsqueda case-insensitive), **anexa** comentario + línea de import; devuelve `$true`.
1. **WhatIf/Confirm** para operaciones de escritura:
2. **Escritura atómica** y preservación de finales de línea:
3. **Portabilidad de rutas**:
4. **Control de reemplazos múltiples**:
5. **Preservar/normalizar EOL**:
6. **Metadatos y extensiones en backups**:
7. **Mensajes y manejo de faltantes**:
8. **Ayuda integrada**:
1. **Regex en `Test-FenceSafety` no es multilinea y tiene escape frágil**
2. **CRLF “portátil”**
3. **`Out-File -Encoding utf8` en ejemplos**
4. **Detección de cierre here-string con indentación**
5. **Regla de 4 backticks en repos con ejemplos**
6. **Here-string con línea `@` literal en columna 1**
1. Verificación inicial de hash para .dcy
2. Comparación a nivel de bloques
3. Verificación de hashes para .ysd
4. Mapeo de equivalencias
5. Análisis de las diferencias: 1118 bloques de 16 bytes
6. Descripción de los pares: temp0==temp1; temp2==Ejemplo.ysd; 济南.ysd==济南西门子240821.ysd
7. División en grupos A, B, C
8. Opcional: generar el CSV con las diferencias
1. Recepción de archivos: temp0.dcy, temp1.dcy, temp2.dcy, 济南.ysd, 济南西门子240821.ysd, Ejemplo.ysd.
2. Hashing y tamaño: 29,423 bytes cada uno. Se calcularon MD5, SHA1, SHA256. Incluyo solo MD5 como huella (sha1/sha256 coinciden).
3. Resultado: temp0.dcy == temp1.dcy (MD5 da5039a2...), temp2.dcy diferente (MD5 dfaf...).
1. Detectamos 1118 diferencias en bloques de 16 bytes, distribuidas a lo largo del archivo. No mostraremos el contenido en hexadecimal, pero mencionamos los rangos y las diferencias.
2. Hashes: 济南.ysd == 济南西门子240821.ysd (MD5 c33f4...), Ejemplo.ysd igual a temp2.dcy (MD5 dfaf3...); tamaños coinciden.
3. Conclusión: los archivos .ysd y .dcy son el mismo contenedor/ formato, solo varía el contenido del conjunto de datos.

## Mejores prompts / plantillas

- ⚠️ FALTA: Prompts/plantillas (sin evidencia)

## Ejemplos completos

- [ej_marketing_seo_6-14-34-An_lisis_de_script_PowerShell.md] — sha256: 5d1226d7217b5214df66d1726972505855008146bca657d6ceeb136ac2d7c12e — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ```

- [ej_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings_.md] — sha256: 59e0dfcb0bda57b2c39fae68ad8bc7be2dc509a3979100fecc1fe7d07a1ed713 — resumen

  ### Entrada (user)

  Analiza lo siguiente:

  ~~~~~

- [ej_marketing_seo_17-36-26-Archivos_id_nticos_o_diferentes.md] — sha256: 7b1937605d10053174ab5cec645078fe5c5032c67be7299efcaaacb480bdbe32 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

## Snippets de código / comandos

- [sn_marketing_seo_6-14-34-An_lisis_de_script_PowerShell_001.txt] — sha256: 2b207b32bf38efc4251018fc0cdd163084f6a4e722d14951d84f8706c88dd69c — resumen

  Set-StrictMode -Version Latest

  function Resolve-RepoRoot {
      [CmdletBinding()]
      param(

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__002.txt] — sha256: f00f79e27bcd0a1d807ca3e6c3d27bb3ffbe979f7ffaf88e6348d45f4b0df4b0 — resumen

  # Backticks, Fences y Here-Strings — **Protocolo Oficial v2**

  > **Objetivo:** evitar render mal y errores de sintaxis en **SmartDAMP**, **Markdown** y **PowerShell (.ps1/.psm1/.psd1)**, con y sin bloques anidados.  
  > **Ámbito  :** chat, documentación (.md) y generación de archivos desde PowerShell.


- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__003.ps1] — sha256: 3396d3f91c08328ffa53b39044e1015ec86d47dcc2c5989d72364576a4150259 — resumen

  Write-Host "Backticks internos no cierran la valla de tildes"

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__004.txt] — sha256: d2a191ab9bbec4d7bd225e9c4dfcaeb43de448f794afe81b96e6467b494234de — resumen


  **3.2 — Escribir archivo desde PowerShell (literal + footer expandible)**

  ```powershell
  $body = @'

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__005.txt] — sha256: 400298b6019a81c696cd471b479cfdfecccb41a31f3e5b382d0af92432fd7ac9 — resumen

  Para mostrar ``` dentro de Markdown, usa valla EXTERNA de tildes.

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__006.txt] — sha256: fd95f06b1f297265d0f4e4ce41cda61a6d532a71bc8fea8c4ff5ceffe9427f4e — resumen


  **3.5 — Si DEBES usar `-f` con llaves** *(no recomendado)*

  ```powershell
  '{ "key": "{{value}}" }' -f @()

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__007.txt] — sha256: 5d508fcae439cf17ba9fdda338fb2aca5e83adb346fae625b7bc15f58081f674 — resumen


  ---

  ## 4) Calidad y validaciones (checklist)


- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__008.ps1] — sha256: 1455b8eac2705b4e4b0e329d8eefce1ef2b46f346df5f581c4bb99b0722dba0b — resumen

  function Test-FenceSafety {
      [CmdletBinding()]
      param(
          [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
          [string[]]$Path

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__009.ps1] — sha256: 0a85c3e85db656d2751ab3d122c28508cf6223430bc508de8f9c04d6a88ac8db — resumen

  function Write-Utf8NoBom {
      [CmdletBinding()]
      param(
          [Parameter(Mandatory)] [string]$Path,
          [Parameter(Mandatory)] [string]$Content,

- [sn_marketing_seo_5-40-13-_SOP_Backticks_Fences_Here_Strings__010.ps1] — sha256: 0ddc71b3ef12b04ed7fea700bf8cf4c76eb84ee0f1b5e0a1e996d9352bbce8c0 — resumen

  function Write-BacktickSafeFile {
      [CmdletBinding(SupportsShouldProcess)]
      param(
          [Parameter(Mandatory)] [string]$Path,
          [Parameter(Mandatory)] [string]$BodyLiteral,    # contenido @' ... '@

## Checklists (previo, durante, posterior)

- - **Detalle:** no fuerza salto de línea antes/después; depende de cómo venga `-Content`.
- - **Bien:** idempotente simple por verificación textual.
- - **Helpers y checklist**: `Write-Utf8NoBom`, `Write-BacktickSafeFile`, lints (`PSScriptAnalyzer`, `markdownlint`) y pre-commit.

## Errores comunes y mitigaciones

- - Conjunto de marcadores desbalanceado (Start sin End o viceversa) → reemplazos no deseados o error “no encontrados”.
- - **Errores:** no hay `try/catch` ni `$ErrorActionPreference='Stop'` explícitos; muchas llamadas ya lanzan error por su cuenta, pero un `try/catch` envolvería mejor las operaciones de IO para devolver mensajes más accionables o limpiar estados.

## Métricas / criterios de calidad

- ⚠️ FALTA: Métricas/criterios (sin evidencia)

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-14-34-An_lisis_de_script_PowerShell.md | 5b73a864dd1ea1d1ff8e4a3a38b666de227862f83ca4444c96b7657e861fe836 | Análisis de script PowerShell | assistant, system, user | sí |
| 2025-9-29/5-40-13-_SOP_Backticks_Fences_Here_Strings_.md | 9bc6c87365ead73f160e596e3b01492b112b130b42fbe8dc581851bf9897f299 | <SOP_Backticks_Fences_Here-Strings> | assistant, system, user | sí |
| 2025-9-20/17-36-26-Archivos_id_nticos_o_diferentes.md | 0a78a4e3a22a043a4864c35b2237e3462e60f6fa44e84ca611b802142ff744f5 | Archivos idénticos o diferentes | assistant, system, tool, user | sí |
