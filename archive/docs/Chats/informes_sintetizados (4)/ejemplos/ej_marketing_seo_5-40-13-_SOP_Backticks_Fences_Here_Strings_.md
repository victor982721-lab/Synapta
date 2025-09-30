### Entrada (user)

Analiza lo siguiente:

~~~~~
# Backticks, Fences y Here-Strings — **Protocolo Oficial v2**

> **Objetivo:** evitar render mal y errores de sintaxis en **SmartDAMP**, **Markdown** y **PowerShell (.ps1/.psm1/.psd1)**, con y sin bloques anidados.  
> **Ámbito  :** chat, documentación (.md) y generación de archivos desde PowerShell.

---

## 1) Principios y convenciones (obligatorias)

- **En el chat o cuando haya bloques anidados:** envuelve con **valla externa de tildes** (~~~ o **~~~~~**) cualquier contenido que **contenga ``` internamente**. Estándar del proyecto: **5 tildes** (~~~~~) como fence externo para anidación.
- **Prohibido usar 4 backticks**. No existe en el estándar del proyecto.
- **En `.md`:** usa ``` por defecto; si necesitas mostrar literalmente ``` dentro, cambia la valla externa a **tildes**.
- **En `.ps1/.psm1/.psd1`:**
  - Para texto literal (sin expandir `$`, ``` o `{}`), usa **here-string literal** `@' ... '@`.
  - Si requieres variables, concatena un **footer expandible** con `"@ ... "@` o usa un bloque expandible separado.
  - El cierre `'@` o `"@` debe ir **solo** y en **columna 1** (sin espacios ni tabs).
  - Evita `-f` cuando el texto contenga `{}` (JSON/plantillas). Si es inevitable, **duplica llaves** `{{` y `}}`.
- **Lenguaje en fences:** especifica el lenguaje siempre que aplique (` ```powershell`, ` ```json`, ` ```text`, etc.).
- **Saltos de línea y codificación:** normaliza a **CRLF** (`"`r"`n"`) cuando generes archivos Windows desde PowerShell. Escribe en **UTF‑8 sin BOM** de forma **portátil** (ver helper en Apéndice A).

---

## 2) Árbol de decisión (rápido)

```text
¿El bloque contiene ``` internas?
 ├─ Sí → Usa valla EXTERNA de TILDES (~~~~~) en el chat o en .md de ejemplo
 │        └─ ¿Además es archivo desde PowerShell?
 │             ├─ Sí → Here-string LITERAL (@'... '@) + (opcional) footer EXPANDIBLE ("@ ... "@)
 │             └─ No → Mantén valla de tildes en el .md
 └─ No → ¿Es archivo desde PowerShell?
          ├─ Sí → ¿Hay interpolación compleja?
          │        ├─ Sí → Here-string EXPANDIBLE ("@ ... "@) y escapa lo literal
          │        └─ No → Here-string LITERAL (@'... '@)
          └─ No → Usa ``` normales con lenguaje
```

**Matriz de decisión (resumen):**

| Escenario | Fence externo | Interior | Nota |
|---|---|---|---|
| Chat con ``` internas | **~~~~~** | ``` | Evita cierres accidentales |
| `.md` con ejemplo que contiene ``` | **~~~~~** | ``` | Documentación de patrones |
| Script PowerShell (literal) | n/a | `@' ... '@` | No expande `$` ni ``` ni `{}` |
| Script PowerShell con variables | n/a | `"@ ... "@` | Expande `$` y subexpresiones |
| Uso de `-f` + `{}` | n/a | `'{{ ... }}' -f ...` | Duplica `{}` o evita `-f` |

---

## 3) Patrones canónicos

**3.1 — Chat (bloque con backticks internos)**  
*(Se muestra con valla externa de 5 tildes)*
~~~~~text
```powershell
Write-Host "Backticks internos no cierran la valla de tildes"
```
~~~~~

**3.2 — Escribir archivo desde PowerShell (literal + footer expandible)**

```powershell
$body = @'
# Título
Contenido con `$ variables, ```backticks``` y { llaves } sin expandir.
'@

$footer = @"
© 2025 — Proyecto Anastasis Revenari · Versión: $version · Fecha: $fecha
"@

($body + "`r`n`r`n" + $footer) | Out-File $dest -Encoding utf8
```

**3.3 — Solo bloque expandible (cuando todo requiere variables)**

```powershell
$doc = @"
# Informe $($meta.Name)
Generado: $([DateTime]::Now.ToString('u'))
"@
$doc | Out-File $dest -Encoding utf8
```

**3.4 — Mostrar literalmente ``` en `.md` (usar tildes externas)**

~~~~~markdown
```text
Para mostrar ``` dentro de Markdown, usa valla EXTERNA de tildes.
```
~~~~~

**3.5 — Si DEBES usar `-f` con llaves** *(no recomendado)*

```powershell
'{ "key": "{{value}}" }' -f @()
```

**3.6 — Cierre de here-strings en columna 1** *(incorrecto vs correcto)*

~~~~~text
[Incorrecto]
    '@
[Correcto]
'@
~~~~~

---

## 4) Calidad y validaciones (checklist)

- `Set-StrictMode -Version 3.0` al iniciar scripts.
- Rutas con `$PSScriptRoot` + `Join-Path` (sin concatenaciones manuales).
- Escritura **UTF‑8 sin BOM** consistente entre PowerShell 5.1 y 7+ (usa helper `Write-Utf8NoBom`).
- `SupportsShouldProcess` **y** llamada a `ShouldProcess()` en funciones que cambian estado.
- **Linters**: `PSScriptAnalyzer` (PS) y `markdownlint` (MD040: fence con lenguaje; MD038: backticks inline).
- **Pre-commit opcional**: regla que rechace `\`\`\`\`` (4 backticks) y cierres `'@`/`"@` con indentación.

> **Integración con el repo:** este protocolo se alinea con los artefactos existentes (`Backticks.md`, `bootstrap.ps1`, `Invoke-SerintraQualityGate.ps1`) para unificar criterios de generación y verificación. Ver **Filemap** del proyecto para la ubicación de estos archivos.


---

## 5) Errores comunes y correcciones

**E1. Usar 4 backticks**  
*Solución*: nunca usar 4 backticks; para anidación, usar **tildes** externas.

**E2. Cierre de here-string no alineado**  
*Solución*: `'@` / `"@` deben ir solos en **columna 1**.

**E3. `-f` con JSON/plantillas**  
*Solución*: evitar `-f`; si es forzoso, duplicar llaves `{{` `}}`.

**E4. Codificación inconsistente entre PS5.1 y PS7**  
*Solución*: usar `Write-Utf8NoBom` (Apéndice A) que fuerza UTF‑8 sin BOM en ambas versiones.

**E5. Fence sin lenguaje**  
*Solución*: especificar ` ```powershell`, ` ```json`, ` ```text`, etc.

---

## Apéndice A — Helpers PowerShell

**A.1 — Escritura UTF‑8 sin BOM (PS5.1 y PS7+)**

```powershell
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if ($NoNewLine) {
            [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
        } else {
            [System.IO.File]::WriteAllText($Path, $Content + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        }
        return
    }

    # PS5.1: forzar UTF-8 sin BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8NoBom.GetBytes($(if ($NoNewLine) { $Content } else { $Content + [Environment]::NewLine }))
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}
```

**A.2 — Guardado “backtick-safe” (literal + footer expandible)**

```powershell
function Write-BacktickSafeFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$BodyLiteral,  # contenido @' ... '@
        [Parameter()]           [string]$FooterExpandable = ''
    )
    Set-StrictMode -Version 3.0

    $sep = "`r`n`r`n"
    $final = if ($FooterExpandable) { $BodyLiteral + $sep + $FooterExpandable } else { $BodyLiteral }

    if ($PSCmdlet.ShouldProcess($Path, "Escribir contenido UTF-8 sin BOM")) {
        Write-Utf8NoBom -Path $Path -Content $final
    }
}
```

**A.3 — Chequeos rápidos de estilo (antipatrones)**

```powershell
function Test-FenceSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path
    )
    begin { Set-StrictMode -Version 3.0 }
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }
            $text = Get-Content -Path $p -Raw

            $issues = @()

            if ($text -match '````') {  # 4 backticks
                $issues += 'Uso prohibido de 4 backticks (````)'
            }
            if ($text -match "^\s+['""]@") { # cierre here-string con indentación
                $issues += "Cierre de here-string con indentación (debe ir en columna 1)"
            }
            if ($text -match '-f\s+.*\{.*\}') {
                $issues += "Uso de -f con llaves {}; duplica llaves o evita -f"
            }

            [PSCustomObject]@{
                Path   = $p
                Issues = if ($issues) { $issues -join '; ' } else { '<OK>' }
            }
        }
    }
}
```

---

## 6) Ejemplo de uso (end-to-end)

```powershell
$version = '1.2.3'
$fecha   = (Get-Date).ToString('yyyy-MM-dd')

$body = @'
# Título
Contenido con `$ y ``` sin expandir.
'@

$footer = @"
© 2025 — Proyecto Anastasis Revenari · Versión: $version · Fecha: $fecha
"@

Write-BacktickSafeFile -Path (Join-Path $PSScriptRoot 'salida\documento.md') -BodyLiteral $body -FooterExpandable $footer -WhatIf

# Validación rápida
Test-FenceSafety -Path (Join-Path $PSScriptRoot 'salida\documento.md')
```
~~~~~

### Salida (assistant)

¡Buen protocolo! Está muy sólido y cubre los dolores clásicos (anidación, here-strings, UTF-8 sin BOM, CRLF, linters). Abajo te dejo un análisis breve y accionable.

# Qué está muy bien
- **Regla de 5 tildes (~~~~~)** para anidación y la **prohibición de 4 backticks**: elimina el 90% de cierres accidentales.
- **Here-strings bien encuadrados**: literal vs expandible, y el cierre en **columna 1**.
- **Codificación y EOL**: define UTF-8 sin BOM y CRLF (coherente con Windows).
- **Helpers y checklist**: `Write-Utf8NoBom`, `Write-BacktickSafeFile`, lints (`PSScriptAnalyzer`, `markdownlint`) y pre-commit.

# Riesgos / ambigüedades detectadas
1. **Regex en `Test-FenceSafety` no es multilinea y tiene escape frágil**  
   - `^\s+...` sin modo multilinea solo detecta al inicio del archivo.  
   - El patrón con `['""]` dentro de comillas dobles requiere escape del `"`; mejor usar comillas simples y `(?m)`.

2. **CRLF “portátil”**  
   - `Write-Utf8NoBom` usa `Environment.NewLine`. En Windows es CRLF, pero si algún día se ejecuta fuera de Windows, tendrás LF. Tu protocolo exige CRLF para archivos Windows: **conviene forzarlo**.

3. **`Out-File -Encoding utf8` en ejemplos**  
   - En PS5.1 **añade BOM**; en PS7 no. Para consistencia con tu norma, **reemplazar por `Write-Utf8NoBom`** en los ejemplos.

4. **Detección de cierre here-string con indentación**  
   - El patrón puede dar falsos negativos/positivos. Mejor detectar el **cierre en línea sola** con `(?m)` y fin de línea.

5. **Regla de 4 backticks en repos con ejemplos**  
   - Si documentas el antipatrón, el pre-commit puede bloquear el propio doc. Añade excepciones por ruta o marcador de “test docs”.

6. **Here-string con línea `@` literal en columna 1**  
   - Es un borde raro pero real: si el contenido incluye una línea `@` exactamente en col. 1, cerrará el here-string. Conviene documentarlo (solución: indentar esa línea o anteponer un carácter inofensivo).

# Correcciones puntuales (propuestas)

**1) `Test-FenceSafety`: patrón robusto y multilinea**
```powershell
function Test-FenceSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path
    )
    begin { Set-StrictMode -Version 3.0 }
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }
            $text = Get-Content -Path $p -Raw

            $issues = @()

            if ($text -match '````') {  # 4 backticks
                $issues += 'Uso prohibido de 4 backticks (````)'
            }

            # Cierre de here-string con indentación (debe ir en col 1, sin espacios/tabs)
            if ($text -match '(?m)^\s+([\'"])@\s*$') {
                $issues += "Cierre de here-string con indentación o trailing spaces (debe ir en columna 1, sin espacios)"
            }

            # Uso de -f con llaves {}; nota: es heurística
            if ($text -match '-f\s+.*\{.*\}') {
                $issues += "Uso de -f con llaves {}; duplica llaves o evita -f"
            }

            [PSCustomObject]@{
                Path   = $p
                Issues = if ($issues) { $issues -join '; ' } else { '<OK>' }
            }
        }
    }
}
```

**2) `Write-Utf8NoBom`: fuerza CRLF siempre (según tu norma)**
```powershell
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0

    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    # Normaliza a CRLF siempre (norma del proyecto para archivos Windows)
    $crlf = "`r`n"
    $text = if ($NoNewLine) { $Content } else { $Content + $crlf }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}
```

**3) `Write-BacktickSafeFile`: usa el helper anterior y separador CRLF fijo**
```powershell
function Write-BacktickSafeFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$BodyLiteral,    # contenido @' ... '@
        [Parameter()]           [string]$FooterExpandable = ''
    )
    Set-StrictMode -Version 3.0

    $sep = "`r`n`r`n"
    $final = if ($FooterExpandable) { $BodyLiteral + $sep + $FooterExpandable } else { $BodyLiteral }

    if ($PSCmdlet.ShouldProcess($Path, "Escribir contenido UTF-8 sin BOM (CRLF)")) {
        Write-Utf8NoBom -Path $Path -Content $final
    }
}
```

**4) Sustituir `Out-File -Encoding utf8` en ejemplos por `Write-Utf8NoBom`**  
Ganas coherencia absoluta (PS5.1/PS7+) y evitas el BOM.

# Reglas de pre-commit (afinadas)
- Bloquear 4 backticks **fuera** de directorios permitidos (p. ej., `docs/examples/`):
  - Permitidos: rutas que incluyan `/docs/examples/` o marcador `<!-- allow-four-backticks -->`.
  - Patrón a bloquear (simple): `(?s)^(?!.*allow-four-backticks).*````.*$`
- Bloquear cierres here-string con espacios o tabs:
  - `(?m)^\s+(['"])@\s*$`
- Exigir lenguaje en fences:
  - `(?m)^```(?!\w)`

# Checklist ampliado (2 ítems nuevos)
- Verifica que **no haya BOM** en los artefactos `.md`, `.ps1/.psm1/.psd1` (heurística: primeros 3 bytes ≠ EF BB BF).
- Si el contenido pudiera incluir una línea `@` en col. 1 dentro de here-string, **documenta cómo evitarlo** (indentar o prefijar).

# Pruebas rápidas sugeridas
- Archivo `.md` con ejemplos que contienen ``` anidados → render correcto con `~~~~~`.
- Script PS con body literal que contiene: `$`, ``` y `{}` → guardado sin expansión; footer expandible inyecta `$version` y fecha.
- Linter: un archivo con ` ```` ` y otro con cierre `"@` indentado → **falla** como esperado; archivo limpio → **<OK>**.
- Validar EOL: abrir con editor que muestre EOL y confirmar **CRLF**.

---

## Veredicto
El **v2** está muy bien diseñado. Con los ajustes de **regex multilinea/escape**, **CRLF forzado** y **uso consistente del helper** en los ejemplos, queda **listo para adopción** y automatización (pre-commit/CI) sin falsos positivos.
