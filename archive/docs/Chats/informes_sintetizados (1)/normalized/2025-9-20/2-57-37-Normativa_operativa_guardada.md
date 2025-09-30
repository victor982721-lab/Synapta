# Normativa operativa guardada

https://chat.openai.com/c/68d33723-3274-8013-9ca5-9a531333d4e7

## USER
Guarda en la memoria persistente lo siguiente:



# Normativa operativa y estándares de entrega

## 1) Principios rectores

* Respuestas correctas, completas y accionables en el primer intento.
* Ceñirse exactamente a lo solicitado. Minimizar el esfuerzo del usuario.
* No demorar por confirmaciones si el requerimiento es claro.
* Prioridad: seguridad/compatibilidad > simplicidad > automatización responsable > entrega inmediata.

## 2) Estilo y comunicación

* Español siempre. Tono neutro, no emocional, sin opiniones personales.
* Directo y conciso. Sin elipsis ni signos de exclamación.
* “Salida limpia”: evitar verbosidad y devolver información u objetos útiles.
* Mensajes normales en texto plano. Bloques de código solo cuando se pidan.
* Mostrar pasos intermedios en problemas complejos; fórmulas en LaTeX.
* Aritmética dígito a dígito con cálculo visible.

## 3) Uso de herramientas y verificación

* Usar navegación y herramientas cuando mejoren exactitud o frescura.
* Para eventos posteriores al corte de conocimiento o temas de nicho: buscar y verificar con fuentes oficiales; citar fuentes y fechas.
* No asumir veracidad de una sola fuente; contrastar y priorizar sitios oficiales.
* Evitar desinformación sobre capacidades de ChatGPT; verificar en fuentes oficiales: Projects, Deep Research, ChatGPT Agent, OpenAI Codex/Codex CLI.

## 4) Procesamiento y lectura de archivos con Python

* Antes de asumir falta de acceso, intentar listar, abrir y leer con Python.
* Si no se puede ver el contenido, terminar y avisar sin suposiciones.
* Ante truncamientos: detectar, enumerar archivos y tamaños, construir diccionario de metadatos, leer completo desde disco y paginar en fragmentos manejables según convenga; reportar cuántos archivos y caracteres se procesaron y qué fragmentos se muestran.

## 5) Estándares para scripts

* Entrega en un único bloque de código con: propósito, parámetros, ejemplos, validaciones y manejo de errores con `try/catch` y `-ErrorAction Stop`.
* Personalizados al entorno:

  * Usuario: VictorFabianVeraVill
  * Máquina: DESKTOP-K6RBEHS
  * SO: Windows 10 Pro 10.0.19045 64-bit
  * PowerShell: 7.5.3 Core
* Iniciar posicionando el script en la ruta de ejecución.
* Instalar automáticamente dependencias necesarias. Preferir Winget cuando aplique.
* Incluir indicadores de progreso.
* Crear directorios y mover archivos cuando sea necesario.
* Comprobar elevación con `WindowsPrincipal.IsInRole(Administrator)` solo si la acción lo requiere.
* Si puede disparar Windows Defender, manejarlo automáticamente.
* Si se generan archivos, informar ruta de salida en ASCII, clara y accesible.
* Formato de bloques anidados: si un bloque de código contiene otro, el bloque exterior usa 5 backticks.
* Validar que el código funcione antes de compartirlo y reportar errores si ocurren.

## 6) Dependencias preferidas

* Núcleo: PSReadLine, PSResourceGet, Pester, PSScriptAnalyzer, PlatyPS, ThreadJob, SecretManagement, SecretStore.
* Opcionales: ImportExcel, dbatools, BurntToast.

## 7) Semillas y metodología

* Semillas fundamentales: bloques doctrinales modulares de diseño y buenas prácticas; no son scripts completos.
* Funcionamiento: evaluar aplicabilidad, registrar en `Checklist_Aplicabilidad`, integrar solo las que aplican y construir bloque canónico reutilizable (`param` + validaciones + `ShouldProcess` cuando corresponda).
* Objetivo: claridad, robustez, reutilización y consistencia en PS7.
* Ejemplos Máximos: tomar el temario completo, evaluar todas las semillas y armar el ejemplo más completo posible. También combinarlas según el temario cuando se requiera.

## 8) Política operativa

* Pasar de planear a ejecutar con decisiones útiles, orden claro y foco en un solo objetivo por iteración. Minimizar retrabajo.
* Evitar preguntas triviales; señalar riesgos y ofrecer alternativa concreta.
* Identificar explícitamente la pregunta y el output esperado antes de actuar.

## 9) Codificación y datos

* UTF-8 para texto y datos.

## 10) Marcado de calidad

* Si el script es funcional, seguro y compatible: marcar como **Script Canónico** y “**puede ejecutarse con confianza**”.
* No añadir funciones no solicitadas salvo petición posterior y alcance permitido.

## 11) Referencias de soporte

* Archivo de rutas de referencia: `FileList_01_Software_20250920_005336.csv`.

## ASSISTANT
Listo. Normativa operativa y estándares de entrega guardada en memoria persistente.

## USER
Por favor, ve el contenido de los archivos dentro de este zip y lista las funciones que se mencionen para cada uno

## Thoughts
Estoy pensando en cómo extraer nombres de funciones de varios lenguajes. Para PowerShell, tenemos patrones para funciones y filtros. Para Python, un patrón básico con "def", para Bash algo similar. En JS/TS, es más complicado con funciones anónimas. Vamos a leer todos los archivos del zip, incluyendo solo los textos relevantes.

## ASSISTANT
# Parse functions inside the uploaded ZIP and present a per-file summary
import zipfile, io, os, re, pandas as pd
from pathlib import PurePosixPath
from caas_jupyter_tools import display_dataframe_to_user

zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"

def detect_language(ext):
    ext = ext.lower()
    return {
        ".ps1": "PowerShell",
        ".psm1": "PowerShell",
        ".psd1": "PowerShell Data",
        ".py": "Python",
        ".sh": "Bash",
        ".bash": "Bash",
        ".zsh": "Zsh",
        ".js": "JavaScript",
        ".ts": "TypeScript",
        ".sql": "SQL",
        ".cmd": "Batch",
        ".bat": "Batch",
        ".ps": "PowerShell",
        ".md": "Markdown",
        ".txt": "Text",
        ".json": "JSON",
        ".yaml": "YAML",
        ".yml": "YAML",
    }.get(ext, ext.lstrip(".").upper() if ext else "Unknown")

# Regex patterns for function extraction across common languages
REGEX_PATTERNS = {
    "PowerShell": [
        re.compile(r'(?im)^\s*function\s+([A-Za-z_][-A-Za-z0-9_.]*)\s*(?:\(|\{)'),
        re.compile(r'(?im)^\s*filter\s+([A-Za-z_][-A-Za-z0-9_.]*)\s*(?:\(|\{)'),
    ],
    "Python": [
        re.compile(r'(?im)^\s*def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\('),
    ],
    "Bash": [
        re.compile(r'(?im)^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{'),
        re.compile(r'(?im)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{'),
    ],
    "Zsh": [
        re.compile(r'(?im)^\s*function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{'),
        re.compile(r'(?im)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{'),
    ],
    "JavaScript": [
        re.compile(r'(?im)^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\('),
    ],
    "TypeScript": [
        re.compile(r'(?im)^\s*function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\('),
    ],
}

rows = []

try:
    with zipfile.ZipFile(zip_path, 'r') as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            internal_path = info.filename
            p = PurePosixPath(internal_path)
            ext = p.suffix
            lang = detect_language(ext)

            # Attempt to read as text
            try:
                data = z.read(info)
            except Exception as e:
                rows.append({
                    "archivo": p.name,
                    "ruta_interna": internal_path,
                    "lenguaje": lang,
                    "tamaño_bytes": info.file_size,
                    "funciones_encontradas": [],
                    "nota": f"Error al leer: {e}",
                })
                continue

            # Heuristic: skip obvious binary files
            if b'\x00' in data[:1024]:
                rows.append({
                    "archivo": p.name,
                    "ruta_interna": internal_path,
                    "lenguaje": lang,
                    "tamaño_bytes": info.file_size,
                    "funciones_encontradas": [],
                    "nota": "Posible binario. No analizado.",
                })
                continue

            try:
                text = data.decode('utf-8', errors='replace')
            except Exception as e:
                text = data.decode('latin-1', errors='replace')

            funcs = set()

            # Choose regex set by language, else try all generic patterns
            patterns = REGEX_PATTERNS.get(lang, [])
            if not patterns:
                # Fallback: try a few common patterns
                patterns = sum(REGEX_PATTERNS.values(), [])

            for rx in patterns:
                for m in rx.finditer(text):
                    name = m.group(1).strip()
                    if name:
                        funcs.add(name)

            rows.append({
                "archivo": p.name,
                "ruta_interna": internal_path,
                "lenguaje": lang,
                "tamaño_bytes": info.file_size,
                "funciones_encontradas": sorted(funcs),
                "nota": "" if funcs else "Sin funciones detectadas con patrones estándar.",
            })

    df = pd.DataFrame(rows).sort_values(["ruta_interna"]).reset_index(drop=True)
    # For readability, join functions into a single string column
    df["funciones"] = df["funciones_encontradas"].apply(lambda xs: ", ".join(xs) if xs else "")
    df_view = df[["ruta_interna", "archivo", "lenguaje", "tamaño_bytes", "funciones", "nota"]]

    # Save CSV
    out_csv = "/mnt/data/lista_funciones_por_archivo.csv"
    df_view.to_csv(out_csv, index=False, encoding="utf-8")

    display_dataframe_to_user("Funciones por archivo en ZIP", df_view)
    print(f"CSV generado: {out_csv}")

except FileNotFoundError:
    print("Archivo ZIP no encontrado en la ruta esperada.")
except zipfile.BadZipFile:
    print("El archivo proporcionado no es un ZIP válido o está corrupto.")
except Exception as e:
    print(f"Error inesperado: {e}")

## ASSISTANT
Hecho. Mostré una tabla con las funciones por archivo. Descarga el CSV: [lista_funciones_por_archivo.csv](sandbox:/mnt/data/lista_funciones_por_archivo.csv).

## USER
¿Te pedí eso?

## Thoughts
La solicitud del usuario está clara: me pide una lista de funciones por archivo, no una tabla o CSV. Ya tenemos la información procesada. Debido a que no la capturé en este chat, puedo obtenerla nuevamente. En resumen, presentaré una lista concisa de las funciones por archivo dentro de esta respuesta.
El usuario me pide listar funciones por archivo, no tablas. Primero debo aclarar que no es necesario usar el código en bloque a menos que me lo pidan. Cargaré el archivo CSV, leeré sus datos y formatearé una lista por archivo, presentando la información de forma clara y directa. Sin necesidad de detalles adicionales.

## Thoughts
Hay 7 entradas. Voy a obtener todas las entradas y preparar la lista con la información que necesito mostrar, asegurándome de que todo esté claro y preciso.

## Thoughts
El archivo parece ser Markdown que describe "seeds", lo que podría explicar la falta de funciones detectadas. El usuario pidió listar funciones mencionadas; en Markdown, se podrían mencionar en bloques de código. Creo que un análisis de patrones, como definiciones de funciones o encabezados, ayudará. Verificaré más a fondo el contenido.
El usuario pide ver el contenido y listar las funciones mencionadas, así que buscaré patrones que coincidan con nombres de funciones, como "Verb-Noun" o precedidos por "function". Abriré los archivos Markdown y aplicaré expresiones regulares para identificar estos patrones, como "Get-", "Set-", "Test-", entre otros. Revisaré los bloques de código.

## ASSISTANT
No. Pediste listar funciones por archivo.

Resultado:
- 01_Parametros_&_Validaciones.md → sin funciones mencionadas
- 02_Accion_Principal.md → sin funciones mencionadas
- 03_Entradas_&_Salidas.md → sin funciones mencionadas
- 04_Opciones_&_Control.md → sin funciones mencionadas
- 05_Logs_&_Reportes.md → sin funciones mencionadas
- 06_Umbrales_&_Limites.md → sin funciones mencionadas
- 07_Validaciones_Cruzadas.md → sin funciones mencionadas

Notas: no hay declaraciones `function` ni nombres tipo cmdlet en bloques de código. Si quieres que detecte otro patrón, lo hago.

## USER
estoy hablando de este tipo de cosas, pero resumidas

# A) Acción predefinida con lista cerrada (recomendada)
[Parameter(Mandatory, Position = 0, ParameterSetName = 'Predefinida',
           ValueFromPipelineByPropertyName,
           HelpMessage = 'Acción estándar: Start, Stop, Restart, Check o All.')]
[ValidateSet('Start','Stop','Restart','Check','All')]
[string]$Action,

# B) Acción personalizada con identificador "sano" (cuando la A no alcance)
[Parameter(Mandatory, Position = 0, ParameterSetName = 'Personalizada',
           ValueFromPipelineByPropertyName,
           HelpMessage = 'Acción personalizada (identificador alfanumérico).')]
[Alias('ActionCustom','Operation','Op')]
[ValidateNotNullOrEmpty()]
# Regla: inicia con letra; luego letras/números/_/-; longitud 2..32
[ValidateScript({
    if ($_ -match '^[A-Za-z][A-Za-z0-9_-]{1,31}$') { $true }
    else { throw "ActionName inválido. Use letras/números/_/-, 2..32, iniciando con letra." }
})]
# Autocompletado sugerido (no obligatorio): verbos aprobados + extras comunes
[ArgumentCompleter({
    param($commandName,$parameterName,$wordToComplete)
    ((Get-Verb).Verb + 'All','Check','Validate') |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object -Unique



## Thoughts
Parece que el usuario quiere un resumen con las plantillas de parámetros y validaciones de cada archivo dentro del ZIP. Antes mencionaron listar funciones, pero ahora parecen referirse a estos atributos de parámetros y validaciones (como ValidateSet, ValidateScript, Alias, ArgumentCompleter, entre otros). Necesito extraer y resumir estos elementos.
Voy a generar un resumen por archivo sobre los elementos descritos, sin adentrarme tanto en el código. Usaré patrones como `ValidateSet`, `ValidateScript` y definiciones de parámetros para crear un resumen conciso. Buscaré elementos clave en archivos Markdown y luego presentaré un resumen con los detalles más importantes, en formato claro y resumido.
Voy a generar un resumen conciso por archivo, como una lista de puntos, describiendo los parámetros y validaciones importantes. Usaré una tabla o lista de texto simple. Primero, abriré el archivo ZIP, extraeré los bloques de código en markdown y luego buscaré patrones de parámetros y atributos en ellos.
Voy a escanear todo el texto, buscando declaraciones de parámetros y atributos asociados, como `ValidateSet`, `Alias`, `ValidateScript`, entre otros. Para cada parámetro, voy a extraer información clave como tipo, valores permitidos y patrones reutilizables. Luego, organizaré un resumen por archivo con los detalles encontrados.

## ASSISTANT
# Analyze the ZIP to extract PowerShell-style parameter blocks and validations, then summarize per file.
import zipfile, re, io, textwrap, os, json
from pathlib import PurePosixPath

zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"

# Regex helpers
codeblock_rx = re.compile(r"```+[\w-]*\n(.*?)\n```+", re.DOTALL | re.IGNORECASE)
param_attr_rx = re.compile(r"\[\s*Parameter\s*(\([^\)]*\))?\s*\]", re.IGNORECASE)
validate_set_rx = re.compile(r"\[\s*ValidateSet\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
validate_script_block_rx = re.compile(r"\[\s*ValidateScript\s*\(\s*\{\s*(.*?)\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
validate_range_rx = re.compile(r"\[\s*ValidateRange\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
validate_pattern_rx = re.compile(r"\[\s*ValidatePattern\s*\(\s*'([^']+)'\s*\)\s*\]", re.IGNORECASE)
alias_rx = re.compile(r"\[\s*Alias\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
arg_completer_rx = re.compile(r"\[\s*ArgumentCompleter\s*\(\s*\{\s*.*?\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
type_and_var_rx = re.compile(r"\[\s*([^\]\n]+?)\s*\]\s*\$([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
cmdletbinding_rx = re.compile(r"\[\s*CmdletBinding\s*(\([^\)]*\))?\s*\]", re.IGNORECASE)

def clean_values_list(s):
    # split by comma, strip quotes/spaces
    items = []
    for part in re.split(r",", s):
        part = part.strip()
        if part.startswith("'") and part.endswith("'"):
            part = part[1:-1]
        elif part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
        if part:
            items.append(part)
    return [i for i in (x.strip() for x in items) if i]

def parse_parameter_attr(attr_text):
    # extract key=value flags inside Parameter(...)
    out = {}
    if not attr_text:
        return out
    inner = attr_text.strip()[1:-1] if attr_text.startswith("(") and attr_text.endswith(")") else attr_text
    # split by commas not inside quotes
    parts = re.split(r",(?![^()]*\))", inner)
    for p in parts:
        if "=" in p:
            k,v = p.split("=",1)
            out[k.strip()] = v.strip()
        else:
            # boolean flags like ValueFromPipelineByPropertyName
            k = p.strip()
            if k:
                out[k] = True
    return out

def find_parameters(block_text):
    # We scan sequentially for attribute clusters preceding a typed variable
    results = []
    # Build an index of positions
    idx = 0
    tokens = []
    # Collect attribute matches with spans
    for m in re.finditer(r"\[[^\]]+\]", block_text):
        tokens.append(("attr", m.start(), m.end(), m.group(0)))
    for m in type_and_var_rx.finditer(block_text):
        tokens.append(("decl", m.start(), m.end(), m.group(0), m.group(1).strip(), m.group(2)))  # type, var
    tokens.sort(key=lambda x: x[1])
    # Walk and accumulate attributes until a decl
    pending_attrs = []
    for t in tokens:
        if t[0] == "attr":
            pending_attrs.append((t[1], t[2], t[3]))
        else:  # decl
            _s, _e, text, ptype, var = t[1], t[2], t[3], t[4], t[5]
            attrs_texts = [a[2] for a in pending_attrs]
            pending_attrs = []  # reset after binding to this decl
            # Extract specific attributes
            info = {
                "var": var,
                "type": ptype,
                "Parameter": None,
                "Alias": [],
                "ValidateSet": [],
                "ValidateRange": None,
                "ValidatePattern": None,
                "ValidateScript": None,
                "ArgumentCompleter": False,
            }
            for at in attrs_texts:
                if at.lower().startswith("[parameter"):
                    m = param_attr_rx.search(at)
                    if m:
                        info["Parameter"] = parse_parameter_attr(m.group(1) or "")
                elif at.lower().startswith("[validateset"):
                    m = validate_set_rx.search(at)
                    if m:
                        info["ValidateSet"] = clean_values_list(m.group(1))
                elif at.lower().startswith("[validatorange"):
                    m = validate_range_rx.search(at)
                    if m:
                        info["ValidateRange"] = m.group(1).strip()
                elif at.lower().startswith("[validatepattern"):
                    m = validate_pattern_rx.search(at)
                    if m:
                        info["ValidatePattern"] = m.group(1).strip()
                elif at.lower().startswith("[validatescript"):
                    m = validate_script_block_rx.search(at)
                    if m:
                        # Try to extract regex heuristic
                        scr = m.group(1).strip()
                        rxm = re.search(r"-match\s*'([^']+)'", scr)
                        info["ValidateScript"] = rxm.group(1) if rxm else "script-block"
                elif at.lower().startswith("[alias"):
                    m = alias_rx.search(at)
                    if m:
                        info["Alias"] += clean_values_list(m.group(1))
                elif at.lower().startswith("[argumentcompleter"):
                    info["ArgumentCompleter"] = True
            results.append(info)
    return results

report_lines = []
files_summaries = []

try:
    with zipfile.ZipFile(zip_path, 'r') as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            name = info.filename
            if not name.lower().endswith((".md",".ps1",".psm1",".txt")):
                continue
            data = z.read(info)
            text = data.decode("utf-8", errors="replace")

            # Check CmdletBinding presence
            cmdletbinding = bool(cmdletbinding_rx.search(text))

            # Extract code blocks if present; else use full text
            blocks = [m.group(1) for m in codeblock_rx.finditer(text)]
            if not blocks:
                blocks = [text]

            params = []
            for b in blocks:
                params.extend(find_parameters(b))

            # Summarize briefly
            if params:
                report_lines.append(f"{name}:")
                if cmdletbinding:
                    report_lines.append("  - CmdletBinding: sí")
                # compress items
                for p in params:
                    param_desc = [f"${p['var']}:{p['type']}"]
                    if p["Parameter"]:
                        # pick common fields
                        keys = ["Mandatory","Position","ParameterSetName","ValueFromPipeline","ValueFromPipelineByPropertyName","HelpMessage"]
                        kvs = [f"{k}={p['Parameter'][k]}" for k in keys if k in p['Parameter']]
                        if kvs:
                            param_desc.append("Param(" + ", ".join(kvs) + ")")
                    if p["Alias"]:
                        param_desc.append("Alias=" + "/".join(p["Alias"]))
                    if p["ValidateSet"]:
                        param_desc.append("Set={" + "|".join(p["ValidateSet"]) + "}")
                    if p["ValidateRange"]:
                        param_desc.append("Range=" + p["ValidateRange"])
                    if p["ValidatePattern"]:
                        param_desc.append("Pattern=" + p["ValidatePattern"])
                    if p["ValidateScript"]:
                        param_desc.append("Script=" + p["ValidateScript"])
                    if p["ArgumentCompleter"]:
                        param_desc.append("ArgCompleter=sí")
                    report_lines.append("  - " + "; ".join(param_desc))
                report_lines.append("")
            else:
                # no parameters found
                report_lines.append(f"{name}: sin parámetros detectados")
                report_lines.append("")

    summary_text = "\n".join(report_lines).strip()
    out_path = "/mnt/data/resumen_parametros_por_archivo.txt"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(summary_text)

    print(summary_text if len(summary_text) < 1800 else summary_text[:1800] + "\n...\n[resumen truncado]")
    print(f"\nArchivo de salida: {out_path}")

except FileNotFoundError:
    print("ZIP no encontrado.")
except Exception as e:
    print(f"Error: {e}")

## Thoughts
Parece que el resultado de Python está truncado, pero tuve la precaución de guardar el contenido completo en un archivo de texto. El usuario pidió un resumen conciso, así que voy a entregar las partes más importantes por archivo, destacando los parámetros y validaciones sin entrar en detalles innecesarios.

## ASSISTANT
# Read the generated summary and print only each file section in a compact way
from pathlib import Path
p = Path("/mnt/data/resumen_parametros_por_archivo.txt")
text = p.read_text(encoding="utf-8")

# Build a compact per-file digest: keep first 12 lines per file section
lines = text.splitlines()
out_lines = []
current_file = None
count_in_section = 0
for ln in lines:
    if ln.strip().endswith(".md:") or ln.strip().endswith(".md: sin parámetros detectados"):
        current_file = ln.strip()
        count_in_section = 0
        out_lines.append(ln)
        continue
    if current_file:
        if ln.strip()== "":
            out_lines.append("")
            current_file = None
            continue
        if count_in_section < 12:  # limit per file
            out_lines.append(ln)
            count_in_section += 1

digest = "\n".join(out_lines)
print(digest if len(digest)<1800 else digest[:1800] + "\n...\n[resumen truncado]")

## Thoughts
Puedo presentar un resumen conciso por archivo. Para el archivo *01_Parametros_&_Validaciones.md* no detecté parámetros. En *02_Accion_Principal.md*, se encontraron los siguientes:

- $Action: tipo *string*, atributo obligatorio, posición 0, y validaciones como *ValidateSet* (Start|Stop|Restart|Check|All).
- $ActionName: tipo *string*, alias y completadores de argumentos.

Para los detalles completos, incluyo un enlace al archivo y puedo reabrirlo para explicar mejor.

## ASSISTANT
# Build a concise summary per file with key constraints, capped per file for brevity
import zipfile, re, io, os
from pathlib import PurePosixPath

zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"

codeblock_rx = re.compile(r"```+[\w-]*\n(.*?)\n```+", re.DOTALL | re.IGNORECASE)
param_attr_rx = re.compile(r"\[\s*Parameter\s*(\([^\)]*\))?\s*\]", re.IGNORECASE)
validate_set_rx = re.compile(r"\[\s*ValidateSet\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
validate_script_block_rx = re.compile(r"\[\s*ValidateScript\s*\(\s*\{\s*(.*?)\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
validate_range_rx = re.compile(r"\[\s*ValidateRange\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
validate_pattern_rx = re.compile(r"\[\s*ValidatePattern\s*\(\s*'([^']+)'\s*\)\s*\]", re.IGNORECASE)
alias_rx = re.compile(r"\[\s*Alias\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
arg_completer_rx = re.compile(r"\[\s*ArgumentCompleter\s*\(\s*\{\s*.*?\s*\}\s*\)", re.IGNORECASE | re.DOTALL)
type_and_var_rx = re.compile(r"\[\s*([^\]\n]+?)\s*\]\s*\$([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
cmdletbinding_rx = re.compile(r"\[\s*CmdletBinding\s*(\([^\)]*\))?\s*\]", re.IGNORECASE)

def clean_values_list(s):
    items = []
    for part in re.split(r",", s):
        part = part.strip()
        if part.startswith("'") and part.endswith("'"):
            part = part[1:-1]
        elif part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
        if part:
            items.append(part.strip())
    return [i for i in items if i]

def parse_parameter_attr(attr_text):
    out = {}
    if not attr_text:
        return out
    inner = attr_text.strip()[1:-1] if attr_text.startswith("(") and attr_text.endswith(")") else attr_text
    parts = re.split(r",(?![^()]*\))", inner)
    for p in parts:
        if "=" in p:
            k,v = p.split("=",1)
            out[k.strip()] = v.strip()
        else:
            k = p.strip()
            if k:
                out[k] = True
    return out

def find_parameters(block_text):
    results = []
    tokens = []
    for m in re.finditer(r"\[[^\]]+\]", block_text):
        tokens.append(("attr", m.start(), m.end(), m.group(0)))
    for m in type_and_var_rx.finditer(block_text):
        tokens.append(("decl", m.start(), m.end(), m.group(0), m.group(1).strip(), m.group(2)))
    tokens.sort(key=lambda x: x[1])
    pending_attrs = []
    for t in tokens:
        if t[0] == "attr":
            pending_attrs.append((t[1], t[2], t[3]))
        else:
            ptype, var = t[4], t[5]
            attrs_texts = [a[2] for a in pending_attrs]
            pending_attrs = []
            info = {
                "var": var, "type": ptype, "Parameter": None, "Alias": [],
                "ValidateSet": [], "ValidateRange": None, "ValidatePattern": None,
                "ValidateScript": None, "ArgumentCompleter": False,
            }
            for at in attrs_texts:
                if at.lower().startswith("[parameter"):
                    m = param_attr_rx.search(at); 
                    if m: info["Parameter"] = parse_parameter_attr(m.group(1) or "")
                elif at.lower().startswith("[validateset"):
                    m = validate_set_rx.search(at); 
                    if m: info["ValidateSet"] = clean_values_list(m.group(1))
                elif at.lower().startswith("[validatorange"):
                    m = validate_range_rx.search(at); 
                    if m: info["ValidateRange"] = m.group(1).strip()
                elif at.lower().startswith("[validatepattern"):
                    m = validate_pattern_rx.search(at); 
                    if m: info["ValidatePattern"] = m.group(1).strip()
                elif at.lower().startswith("[validatescript"):
                    m = validate_script_block_rx.search(at);
                    if m:
                        scr = m.group(1).strip()
                        rxm = re.search(r"-match\s*'([^']+)'", scr)
                        info["ValidateScript"] = rxm.group(1) if rxm else "script-block"
                elif at.lower().startswith("[alias"):
                    m = alias_rx.search(at); 
                    if m: info["Alias"] += clean_values_list(m.group(1))
                elif at.lower().startswith("[argumentcompleter"):
                    info["ArgumentCompleter"] = True
            results.append(info)
    return results

def concise_param(p):
    parts = [f"${p['var']}:{p['type']}"]
    if p["Parameter"]:
        ps = p["Parameter"]
        if "ParameterSetName" in ps: parts.append(f"SetName={ps['ParameterSetName']}")
        if "Mandatory" in ps: parts.append(f"Mandatory={ps['Mandatory']}")
        if "Position" in ps: parts.append(f"Pos={ps['Position']}")
    if p["ValidateSet"]: parts.append("Set{" + "|".join(p["ValidateSet"]) + "}")
    if p["ValidatePattern"]: parts.append("Pattern=" + p["ValidatePattern"])
    if p["ValidateRange"]: parts.append("Range=" + p["ValidateRange"])
    if p["ValidateScript"]: parts.append("Script=" + p["ValidateScript"])
    if p["Alias"]: parts.append("Alias=" + "/".join(p["Alias"]))
    if p["ArgumentCompleter"]: parts.append("AC")
    return "; ".join(parts)

lines = []
try:
    with zipfile.ZipFile(zip_path, 'r') as z:
        for info in z.infolist():
            if info.is_dir(): 
                continue
            name = info.filename
            if not name.lower().endswith((".md",".ps1",".psm1",".txt")):
                continue
            text = z.read(info).decode("utf-8", errors="replace")
            cmdlet = bool(cmdletbinding_rx.search(text))
            blocks = [m.group(1) for m in codeblock_rx.finditer(text)]
            if not blocks:
                blocks = [text]
            params = []
            for b in blocks:
                params.extend(find_parameters(b))
            lines.append(f"{name}:")
            if cmdlet:
                lines.append("  CmdletBinding: sí")
            if not params:
                lines.append("  Sin parámetros detectados")
            else:
                cap = 10
                for p in params[:cap]:
                    lines.append("  - " + concise_param(p))
                if len(params) > cap:
                    lines.append(f"  (+{len(params)-cap} más)")
            lines.append("")
    concise = "\n".join(lines).strip()
    out_path = "/mnt/data/resumen_conciso_parametros.txt"
    open(out_path,"w",encoding="utf-8").write(concise)
    print(concise if len(concise)<1800 else concise[:1800] + "\n...\n[resumen truncado]")
    print(f"\nArchivo de salida: {out_path}")
except FileNotFoundError:
    print("ZIP no encontrado.")
except Exception as e:
    print(f"Error: {e}")

## Thoughts
El usuario quería una versión resumida, y aquí está:

- *01_Parametros_&_Validaciones.md:* sin parámetros encontrados.
- *02_Accion_Principal.md:* parámetros encontrados como $Action (string), atributos Mandatory, Position 0, ValidateSet y Alias.

La versión completa de este resumen está disponible por descarga.

## ASSISTANT
# Inspect the specific section for 03_Entradas_&_Salidas.md to ensure no accidental truncation
from pathlib import Path
text = Path("/mnt/data/resumen_conciso_parametros.txt").read_text(encoding="utf-8")
sect = []
capture = False
for ln in text.splitlines():
    if ln.strip().startswith("03_Entradas_&_Salidas.md"):
        capture = True
        sect.append(ln)
        continue
    if capture:
        if ln.strip()== "":
            break
        sect.append(ln)
print("\n".join(sect))

## ASSISTANT
# Re-parse only 03_Entradas_&_Salidas.md for precise values
import zipfile, re
zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"
target = "03_Entradas_&_Salidas.md"

codeblock_rx = re.compile(r"```+[\w-]*\n(.*?)\n```+", re.DOTALL | re.IGNORECASE)
validate_set_rx = re.compile(r"\[\s*ValidateSet\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
type_and_var_rx = re.compile(r"\[\s*([^\]\n]+?)\s*\]\s*\$([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
alias_rx = re.compile(r"\[\s*Alias\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
validate_script_block_rx = re.compile(r"\[\s*ValidateScript\s*\(\s*\{\s*(.*?)\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)

def clean_values_list(s):
    items = []
    for part in re.split(r",", s):
        part = part.strip()
        if part.startswith("'") and part.endswith("'"):
            part = part[1:-1]
        elif part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
        if part:
            items.append(part.strip())
    return [i for i in items if i]

with zipfile.ZipFile(zip_path,'r') as z:
    text = z.read(target).decode('utf-8','replace')
    blocks = [m.group(1) for m in codeblock_rx.finditer(text)]
    if not blocks:
        blocks = [text]
    for b in blocks:
        # find declarations with preceding attributes quickly
        # naive: just print all ValidateSet values and variable names nearby
        sets = validate_set_rx.findall(b)
        if sets:
            print("ValidateSet values:", [clean_values_list(s) for s in sets])
        aliases = alias_rx.findall(b)
        if aliases:
            print("Aliases raw:", aliases)
        scripts = validate_script_block_rx.findall(b)
        if scripts:
            print("ValidateScript blocks:", len(scripts))

## ASSISTANT
# Check 02_Accion_Principal.md parameter details precisely
import zipfile, re
zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"
target = "02_Accion_Principal.md"

codeblock_rx = re.compile(r"```+[\w-]*\n(.*?)\n```+", re.DOTALL | re.IGNORECASE)
validate_set_rx = re.compile(r"\[\s*ValidateSet\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
validate_script_block_rx = re.compile(r"\[\s*ValidateScript\s*\(\s*\{\s*(.*?)\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
alias_rx = re.compile(r"\[\s*Alias\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
pattern_rx = re.compile(r"-match\s*'([^']+)'")

def clean_values_list(s):
    items = []
    for part in re.split(r",", s):
        part = part.strip()
        if part.startswith("'") and part.endswith("'"):
            part = part[1:-1]
        elif part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
        if part:
            items.append(part.strip())
    return [i for i in items if i]

with zipfile.ZipFile(zip_path,'r') as z:
    text = z.read(target).decode('utf-8','replace')
    blocks = [m.group(1) for m in codeblock_rx.finditer(text)]
    if not blocks:
        blocks = [text]
    for b in blocks:
        sets = validate_set_rx.findall(b)
        if sets:
            print("ValidateSet:", [clean_values_list(s) for s in sets])
        aliases = alias_rx.findall(b)
        if aliases:
            print("Aliases:", aliases)
        scripts = validate_script_block_rx.findall(b)
        if scripts:
            pats = [pattern_rx.search(s).group(1) if pattern_rx.search(s) else "script-block" for s in scripts]
            print("ValidateScript patterns:", pats)

## ASSISTANT
# Extract concise parameter names and selected constraints for file 04 and 05 and 06 and 07
import zipfile, re, json
zip_path = "/mnt/data/SEED01_Parametros_&_Validaciones.zip"
targets = ["04_Opciones_&_Control.md","05_Logs_&_Reportes.md","06_Umbrales_&_Limites.md","07_Validaciones_Cruzadas.md"]

codeblock_rx = re.compile(r"```+[\w-]*\n(.*?)\n```+", re.DOTALL | re.IGNORECASE)
type_and_var_rx = re.compile(r"\[\s*([^\]\n]+?)\s*\]\s*\$([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
validate_set_rx = re.compile(r"\[\s*ValidateSet\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE | re.DOTALL)
alias_rx = re.compile(r"\[\s*Alias\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
validate_range_rx = re.compile(r"\[\s*ValidateRange\s*\(\s*([^\)]*?)\s*\)\s*\]", re.IGNORECASE)
validate_script_block_rx = re.compile(r"\[\s*ValidateScript\s*\(\s*\{\s*(.*?)\s*\}\s*\)\s*\]", re.IGNORECASE | re.DOTALL)

def clean_values_list(s):
    items = []
    for part in re.split(r",", s):
        part = part.strip()
        if part.startswith("'") and part.endswith("'"):
            part = part[1:-1]
        elif part.startswith('"') and part.endswith('"'):
            part = part[1:-1]
        if part:
            items.append(part.strip())
    return [i for i in items if i]

def extract_params(text):
    blocks = [m.group(1) for m in codeblock_rx.finditer(text)]
    if not blocks: blocks=[text]
    params = {}
    for b in blocks:
        # find all declarations and gather preceding attributes by proximity
        # simple approach: scan line by line
        lines = b.splitlines()
        window_attrs = []
        for ln in lines:
            ln = ln.strip()
            if ln.startswith("["):
                window_attrs.append(ln)
                continue
            m = type_and_var_rx.search(ln)
            if m:
                ptype, var = m.group(1).strip(), m.group(2)
                info = params.setdefault(var, {"type": ptype, "aliases": [], "set": [], "range": None, "script": None})
                for at in window_attrs:
                    ms = validate_set_rx.search(at)
                    if ms: info["set"] = clean_values_list(ms.group(1))
                    ma = alias_rx.search(at)
                    if ma: info["aliases"] += clean_values_list(ma.group(1))
                    mr = validate_range_rx.search(at)
                    if mr: info["range"] = mr.group(1).strip()
                    mv = validate_script_block_rx.search(at)
                    if mv: info["script"] = "script-block"
                window_attrs = []
            else:
                window_attrs = []
    return params

with zipfile.ZipFile(zip_path,'r') as z:
    for t in targets:
        text = z.read(t).decode('utf-8','replace')
        params = extract_params(text)
        print(t + ":")
        for var,info in list(params.items())[:20]:
            desc = [f"${var}:{info['type']}"]
            if info["set"]: desc.append("Set{"+"|".join(info["set"])+"}")
            if info["range"]: desc.append("Range="+info["range"])
            if info["aliases"]: desc.append("Alias="+"/".join(sorted(set(info["aliases"]))))
            if info["script"]: desc.append("Script")
            print("  - " + "; ".join(desc))
        if not params:
            print("  (sin parámetros)")
        print("")

## ASSISTANT
Entendido. Resumen por archivo, en tu estilo:

01_Parametros_&_Validaciones.md  
- CmdletBinding presente. Sin parámetros listados.

02_Accion_Principal.md  
- $Action:string → ValidateSet {Start, Stop, Restart, Check, All}. Mandatory, Posición 0, SetName ‘Predefinida’.  
- $ActionName:string → Alias {ActionCustom, Operation, Op}. ValidateScript con regex `^[A-Za-z][A-Za-z0-9_-]{1,31}$`. ArgumentCompleter activo.

03_Entradas_&_Salidas.md  
- $InputKind:string → SetName ‘ByObject’. ValidateSet {Any, File, Directory}. Alias {Path, In, Input, Source, LiteralPath, InputObject}. ValidateScript presente.  
- $OutputDir:string → SetName ‘ByObject’. Alias {OutDir, Output, Destination}. ValidateScript presente.

04_Opciones_&_Control.md  
- $Options:hashtable.  
- $k:string → Alias {Opts, Config}.  
- $RequireAdmin:switch.  
- $Force:switch.  
- $NonInteractive:switch → Alias {CI, Batch}.

05_Logs_&_Reportes.md  
- $LogPath:string → Alias {Log, LogFile}.  
- $LogMode:string → ValidateSet {Append, Overwrite}.  
- $LogEncoding:string → ValidateSet {utf8, utf8BOM, utf8NoBOM, ascii, unicode, utf32, oem}.  
- $ReportPath:string → Alias {Report, OutFile}.  
- $ReportFormat:string → ValidateSet {txt, json, csv, all}.  
- $ReportEncoding:string → ValidateSet {utf8, utf8BOM, utf8NoBOM, ascii, unicode, utf32, oem}.

06_Umbrales_&_Limites.md  
- $Threshold:int, $TimeoutSec:int, $MaxItems:int, $MaxConcurrency:int, $RetryCount:int, $RetryDelaySec:int.  
- $Backoff:string → ValidateSet {None, Linear, Exponential}.

07_Validaciones_Cruzadas.md  
- Sin parámetros listados.

Descargas:  
- Resumen conciso: [resumen_conciso_parametros.txt](sandbox:/mnt/data/resumen_conciso_parametros.txt)  
- Resumen completo: [resumen_parametros_por_archivo.txt](sandbox:/mnt/data/resumen_parametros_por_archivo.txt)

## USER
Haz un reporte en formato .md sobre los riesgos de rootear un celular y como eso te puede dejar incomunicado.

No seas conciso en el documento.

Entregame el documento en un bloque de código con heredoc-strings apuntando a C:\Users\VictorFabianVeraVill\Desktop



## Thoughts
El usuario quiere un documento detallado sobre los riesgos de hacer root a un teléfono y cómo puede dejarte sin comunicación. Me está pidiendo que el archivo tenga un bloque de código con heredoc-strings apuntando a una ruta específica en el escritorio. Usaré PowerShell PS7 en un bloque único de código.
El usuario quiere que entregue un documento largo en un bloque de código con heredoc-strings apuntando a una ruta específica. Puedo usar un simple fragmento de PowerShell que defina $outPath y utilice Set-Content con codificación UTF-8. Además, por la preferencia destacada, usaré cinco backticks para envolvér el bloque con código anidado.
Para evitar problemas con bloques de código anidados, puedo omitir los saltos de código dentro del contenido markdown. El plan es crear una cadena multi-línea en PowerShell ($md), que luego se escriba con `Set-Content` en la ruta especificada. Utilizaré codificación UTF-8 y me aseguraré de que el directorio exista sin hacer un script tan largo o robusto.
El documento debe ser largo y detallado. Incluiré encabezados, listas con viñetas y varios escenarios de riesgos, como problemas con el bootloader, SafetyNet, AVB, corrupción de IMEI, pérdida de conectividad, bloqueo de red, aplicaciones bancarias, 2FA, y otros problemas técnicos. También consideraré las implicaciones de carrier en México, como Telcel.
El documento discutirá varios aspectos del rooting, particularmente cómo puede bloquear la comunicación. Se mencionarán riesgos como la pérdida de señal, el bloqueo de SIM, daños en la baseband e incompatibilidad de modem. Se deberán detallar medidas de prevención, como backups, y la importancia de revisar configuraciones de operadores.

## ASSISTANT
`````
# PowerShell (PS7) — Genera un .md con riesgos de root y escenarios de incomunicación
# Propósito: crear el documento en el Escritorio del usuario solicitado.
# Entorno objetivo: Windows 10 Pro 10.0.19045 64-bit, PowerShell 7.5.3 Core.
# Salida: C:\Users\VictorFabianVeraVill\Desktop\Riesgos_Root_Comunicacion.md

$ErrorActionPreference = 'Stop'
try {
    $destDir  = 'C:\Users\VictorFabianVeraVill\Desktop'
    $outPath  = Join-Path $destDir 'Riesgos_Root_Comunicacion.md'
    Set-Location $destDir

    if (-not (Test-Path -LiteralPath $destDir)) {
        Write-Progress -Activity 'Preparando entorno' -Status 'Creando directorio' -PercentComplete 10
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Write-Progress -Activity 'Generando documento' -Status 'Compilando contenido' -PercentComplete 40

    $md = @"
# Riesgos de rootear un celular y cómo puedes quedar incomunicado

## Resumen ejecutivo
Rootear un dispositivo Android otorga privilegios de superusuario. Esta capacidad permite personalizar profundamente el sistema, pero amplifica el riesgo de errores técnicos, incompatibilidades y fallos de seguridad. Varias de esas fallas afectan directamente la **capacidad de comunicarte**: sin señal móvil, sin datos, sin SMS para códigos de verificación, sin VoLTE/VoWiFi, o incluso con el equipo inoperable. Este documento explica **por qué** ocurre, **cómo** evitarlo y **qué** hacer si ya sucedió.

## Conceptos base (mapa mínimo)
- **Bootloader**: cargador de arranque. Desbloquearlo suele **borrar el dispositivo** y puede activar mecanismos anticopia o de integridad.
- **Root**: privilegios de superusuario. Suele inyectarse a través de parches a `boot.img` o con módulos en el arranque.
- **Recovery**: entorno de mantenimiento. Stock u otros (p. ej., TWRP).
- **Vendor/ODM**: capas específicas del fabricante. Deben ser **compatibles** con kernel y sistema.
- **Modem/Baseband/Radio**: firmware del subsistema celular. Si no coincide con tu región/modelo/versión, se rompe la conectividad.
- **EFS/NVRAM/Modemst**: particiones con **IMEI**, certificados, configuración de radio y eSIM. Si se corrompen, el **módem no registra** en la red.
- **AVB/DM-Verity/VBMeta**: integridad de arranque. Si se deshabilita mal, el sistema puede entrar en bucles o degradar seguridad.
- **SELinux**: política de seguridad. Pasar a **Permissive** puede facilitar ataques y fallos silenciosos.

## Riesgos técnicos que sí te dejan sin comunicación

### 1) Corrupción o pérdida de EFS/NVRAM (IMEI nulo o genérico)
**Qué pasa:** el equipo muestra IMEI vacío/000000… y “Baseband Unknown”. La red rechaza el registro y quedas sin señal, SMS ni datos.  
**Causas típicas:** flasheo indebido, wipes erróneos, incompatibilidades de ROM/vendor, herramientas de particionado no confiables.  
**Prevención:** copia de seguridad de EFS/NVRAM/modemst1–2 antes de modificar. Guardar copia **offline**.  
**Recuperación:** restaurar **exacta** la copia EFS; si no existe, solo el servicio técnico u operaciones avanzadas con herramientas del fabricante podrían reescribir datos válidos.

### 2) Módem/Baseband incompatible o ausente
**Qué pasa:** “Sin servicio”, llamadas que no conectan, datos que no activan, redes que aparecen/desaparecen.  
**Causas:** ROM personalizada que no incluye modem apropiado, mezcla de componentes (kernel/vendor/system) de distintas versiones, o actualización OTA interrumpida que dejó el **CP** (módem) inválido.  
**Prevención:** usar siempre **firmware de tu modelo y región**; mantener el módem stock compatible con la versión de sistema.  
**Recuperación:** flashear el **modem/CP correcto** para tu dispositivo/región/operador.

### 3) eSIM borrada por desbloqueo de bootloader o wipes
**Qué pasa:** el perfil eSIM se elimina al desbloquear el bootloader o al aplicar wipes profundos. Te quedas sin línea si no tienes SIM física de respaldo.  
**Prevención:** solicitar al operador el **QR de reaprovisionamiento**, guardar respaldo de información de línea, o usar SIM física durante el proceso.  
**Recuperación:** reprovisionar eSIM con el operador. Puede requerir acudir a un centro de atención y **documentación** del titular.

### 4) RIL/IMS mal configurados: sin VoLTE/VoWiFi y llamadas fallidas
**Qué pasa:** en redes que ya dependen de VoLTE, las llamadas no cursan o solo tienes “solo emergencia”. SMS sobre IMS también puede fallar.  
**Causas:** ROM sin perfiles IMS del operador, `build.prop` o props del sistema alteradas, módulos que cambian fingerprint o carrier configs.  
**Prevención:** elegir ROMs que **declaren soporte** para tu operador o mantener vendor/carrier configs stock.  
**Recuperación:** reinstalar perfiles IMS correctos, restaurar vendor compatible, o volver a firmware stock.

### 5) APN borrados o erróneos
**Qué pasa:** sin datos móviles ni MMS.  
**Causas:** wipes, ROMs que resetean APN, cambios de carrier config.  
**Prevención:** **Anota** tus APN antes de modificar.  
**Recuperación:** reingresar APN oficiales del operador.

### 6) Bootloop o soft-brick
**Qué pasa:** el teléfono no inicia. Pierdes llamadas, SMS, datos, mensajería y 2FA.  
**Causas:** parches de `boot.img` incompatibles, módulos root conflictivos, AVB deshabilitado incorrectamente.  
**Prevención:** probar cambios **de uno en uno** y con respaldo de arranque/ROM.  
**Recuperación:** reflashear `boot.img` stock, deshabilitar módulos, restaurar nandroid o ROM limpia.

### 7) Particiones persistentes dañadas
**Qué pasa:** fallos en Wi-Fi/Bluetooth, dirección MAC “desconocida”, sensores que no inician, o radio inconsistente.  
**Causas:** wipes a particiones de **persist** y similares sin guía del fabricante.  
**Prevención:** nunca formatear particiones persistentes sin respaldo y motivo claro.  
**Recuperación:** restaurar respaldo; de lo contrario, servicio técnico.

### 8) Anti-rollback y verificaciones de integridad
**Qué pasa:** el equipo se niega a iniciar con imágenes “más antiguas” o alteradas. Sin sistema no hay comunicación.  
**Prevención:** verificar **bootloader level**/anti-rollback antes de flashear.  
**Recuperación:** usar imágenes igual o superiores y vbmeta adecuados.

## Riesgos funcionales que afectan apps de comunicación

### 9) Play Integrity/SafetyNet fallido
**Qué pasa:** apps corporativas, bancarias, de operador o de autenticación pueden **bloquearse**. Si dependes de esas apps para activar eSIM, VoWiFi o recibir OTP, quedas sin acceso práctico.  
**Prevención:** entender que root rompe garantías de integridad. Algunas mitigaciones existen, pero no son universales ni garantizadas.  
**Recuperación:** volver a estado “stock” o usar un dispositivo secundario para OTP y gestiones críticas.

### 10) Pérdida de 2FA por borrado de datos
**Qué pasa:** al desbloquear bootloader se **borra el teléfono**. Si tus llaves 2FA y respaldos estaban solo allí, no puedes recuperar cuentas, mensajería o eSIM.  
**Prevención:** **Códigos de respaldo** impresos, números alternativos, correo de recuperación, llaves FIDO físicas.  
**Recuperación:** procesos de verificación con cada servicio. Pueden tardar días.

### 11) ROMs sin servicios de Google o con microservicios no oficiales
**Qué pasa:** notificaciones push y registro RCS pueden fallar o degradarse.  
**Prevención:** confirmar soporte de notificaciones y RCS en la ROM elegida.

## Casos típicos de “incomunicación”
- **IMEI nulo + Baseband Unknown:** no hay red, SMS ni datos.  
- **eSIM eliminada + sin QR de reprovisionamiento:** sin línea hasta coordinar con el operador.  
- **Wrong modem/CP:** el teléfono ve la red pero no registra o se cae la señal.  
- **Sin VoLTE en red que lo exige:** llamadas imposibles; solo datos (si acaso).  
- **Bootloop tras parche de boot:** el equipo no arranca.  
- **Borrado por desbloqueo + pérdida de 2FA:** sin acceso a cuentas, mensajería y servicios críticos.

## Matriz de riesgo simplificada
- **Probabilidad Alta / Impacto Alto:** EFS dañado; bootloop; eSIM borrada sin respaldo.  
- **Probabilidad Media / Impacto Alto:** modem incompatible; IMS roto.  
- **Probabilidad Media / Impacto Medio:** APN perdidos; SafetyNet fallido que bloquea apps del operador.  
- **Probabilidad Baja / Impacto Alto:** anti-rollback que impide iniciar sin imagen correcta.

## Checklist preventivo antes de rootear
1) **Respaldos críticos:** EFS/NVRAM/modemst/persist; nandroid; fotos de APN; QR eSIM; códigos 2FA.  
2) **Firmware a mano:** paquete **stock** completo por si necesitas restaurar módem/vendor.  
3) **Compatibilidad:** ROM, kernel, vendor y módem **de la misma rama** y región.  
4) **Plan B de comunicación:** SIM física adicional o teléfono secundario para OTP.  
5) **Cambios graduales:** un ajuste por vez, con pruebas de **llamada/SMS/datos** tras cada cambio.  
6) **Documenta:** versión de baseband, IMEI, build exacta y operador configurado.

## Diagnóstico rápido si ya estás incomunicado
- Marca *#06# y revisa **IMEI**. Si vacío → foco en EFS.  
- Ajustes > Información del teléfono → **Versión de banda base**. Si “Desconocida” → módem.  
- Configuración de **APN**: compara con los oficiales del operador.  
- Comprueba si tu red requiere **VoLTE** y si tu ROM lo habilita.  
- Prueba otra SIM o un teléfono secundario para aislar el problema.  
- Considera revisar registros del radio (por técnicos): errores de registro, rechazo por red, IMS no aprovisionado.

## Plan de contingencia sugerido (30–60 minutos)
1) Restablece **boot y vbmeta stock** si modificaste arranque.  
2) Flashea el **modem/CP correcto** para tu modelo y región.  
3) Restaura **EFS** desde tu respaldo; si no hay, no sobrescribas más y busca asistencia profesional.  
4) Reconfigura **APN** oficiales.  
5) Reprovisiona **eSIM** con tu operador o usa SIM física temporal.  
6) Verifica **VoLTE/IMS** activos; si tu ROM no los soporta, vuelve a stock.  
7) Prueba **llamadas, SMS y datos** antes de reinstalar módulos root o tweaks.

## Consideraciones por fabricante
- **Samsung**: flashear y rootear **activa KNOX** permanentemente. Algunas funciones quedan deshabilitadas. Mantén a mano el **CP** correcto; si pierdes IMS/VoLTE, volver a stock suele ser el camino corto.  
- **Xiaomi/Redmi/Poco**: tiempos de espera para desbloqueo; evita wipes a particiones persistentes.  
- **Pixel**: proceso relativamente limpio, pero respeta AVB y revisa compatibilidad de boot/system/vendor.

## Conclusión
Rootear no es “malo” por sí mismo, pero **eleva exponencialmente** el costo de un error. Los daños en EFS/modem/IMS o un desbloqueo sin plan de respaldo pueden dejarte **sin red, sin llamadas y sin SMS** justo cuando más lo necesitas. Si decides proceder, entra con: respaldos verificados, firmware stock disponible, un plan alterno de comunicación y la disciplina de probar cada paso.

"@

    Write-Progress -Activity 'Generando documento' -Status 'Escribiendo archivo' -PercentComplete 90
    Set-Content -LiteralPath $outPath -Value $md -Encoding UTF8

    Write-Progress -Activity 'Generando documento' -Completed
    "Documento creado: $outPath"
}
catch {
    Write-Error "Error al generar el documento: $($_.Exception.Message)"
    throw
}
`````

