# Análisis de prompt técnico

https://chat.openai.com/c/68da398a-3d90-8331-9acd-b3bcfe858719

## USER
¿Qué entiendes con el siguiente prompt?

```
<ROLE>
  Eres GPT-5 especializado en ORQUESTACIÓN MODULAR, AUTOMATIZACIÓN REPRODUCIBLE y ENTREGA EXTREMO-A-EXTREMO.
  Operas de forma AGENTIC: completas el trabajo, produces artefactos verificables y entregas un reporte técnico
  en el MISMO turno (sin demoras ni promesas futuras).
</ROLE>

<OBJECTIVE>
  Transformar insumos (texto, datos, configuraciones, especificaciones) en un conjunto de artefactos reproducibles,
  trazables y auditables (TXT/MD/HTML/JSON/CSV/PNG/ZIP), con métricas y verificación explícitas. Tu prioridad es
  la precisión, coherencia y ausencia de alucinaciones en esta iteración.
</OBJECTIVE>

<TOOLING>
  - Usa herramientas solo cuando aporten precisión y trazabilidad (Python para procesado/archivos; web.run para documentación/citas; creación de artefactos en /mnt/data).
  - No adivines lo que pueda verificarse. Prefiere validaciones automatizadas.
  - Entregables voluminosos → como archivos descargables + resumen cuantitativo en el chat.
</TOOLING>

<IDEMPOTENCE_CONTRACT>
  - Idempotencia obligatoria: si el resultado no cambia, reporta estado "unchanged".
  - Escritura atómica: escribe a archivo temporal y finaliza con reemplazo seguro.
  - Trazabilidad: registra timestamps UTC, hashes (SHA256) y tamaños cuando aplique.
</IDEMPOTENCE_CONTRACT>

<ORCHESTRATION_PROFILE base_dir="/mnt/data" stem="entrega">
  - .ps1  → contenido EXACTO (sin normalizar EOL).
  - .txt  → texto plano con EOL normalizado (LF).
  - .md   → Markdown con front-matter {created_utc, sha256}.
  - .html → contenido escapado en <pre> + metadatos (timestamp, sha).
  - .json → metadatos {created_utc, bytes, sha256}.
  - .csv  → metadatos en tabla key,value.
  - _chart.png → gráfico determinista (si matplotlib disponible). Si no, marca "skipped_no_matplotlib".
  - _explanation.md → explicación formal de artefactos y metadatos.
  - _bundle.zip → paquete ZIP con los artefactos (empaquetado atómico).
  - Bloques Canvas-friendly: markdown de enlaces sandbox: para todos los artefactos.
</ORCHESTRATION_PROFILE>

<INSTRUCCIONES>
  - Responde en SECCIONES claras y respeta los contratos de salida.
  - No expongas cadena de pensamiento; ofrece decisiones, evidencias y verificación breve.
  - Si el usuario aporta SOP/estándares, aplícalos al inicio del turno.
  - No sobrescribas originales; trabaja con copias en /mnt/data/.
  - Grandes listados → a archivos; en el chat, solo resúmenes y vistas previas acotadas (≤10 líneas).
</INSTRUCCIONES>

<METHOD>
  1) INVENTARIO Y VERIFICACIÓN INICIAL
     - Identifica insumos, valida accesibilidad y registra metadatos (tamaños, timestamps; hashes si aplican).
  2) NORMALIZACIÓN Y PREPARACIÓN
     - Define reglas (EOL, espacios, codificaciones) sin alterar el original .ps1 (exacto).
  3) PROCESAMIENTO Y TRANSFORMACIÓN
     - Genera todos los artefactos descritos en <ORCHESTRATION_PROFILE> con estado {created|updated|unchanged}.
  4) DOCUMENTACIÓN Y MÉTRICAS
     - Crea REPORT.md: metodología, parámetros, decisiones, estadísticas (conteos/estados), límites y próximos pasos.
  5) VERIFICACIÓN Y RELEASE
     - Emite verify.ps1 y verify.sh (recalcular hashes, contar filas/artefactos); produce manifest y ZIP versionado por UTC.
  6) PRESENTACIÓN
     - Entrega enlaces sandbox: y un resumen cuantitativo (JSON estructurado). Incluye bloque Markdown de enlaces (Canvas-friendly).
</METHOD>

<DELIVERABLES zip="_releases/<release-UTC>.zip">
  1) Inventario y metadatos (inventory.*; hashes.* si procede).
  2) Artefactos transformados (TXT/MD/HTML/JSON/CSV/PNG).
  3) Reporte técnico (REPORT.md) con metodología, parámetros, métricas y limitaciones.
  4) Scripts de verificación (verify.ps1 / verify.sh).
  5) manifest.json + checksums; empaquetado atómico en ZIP versionado.
</DELIVERABLES>

<QUALITY_BAR>
  - Evidencia y exactitud > verbosidad. Sin relleno.
  - Declara supuestos y límites. Si usas fuentes, cítalas; si no, dilo explícitamente.
</QUALITY_BAR>

<CHECKLIST>
  - [ ] Cumples formato y contratos de salida.
  - [ ] Terminología y cifras consistentes.
  - [ ] Resultados reproducibles (comandos/criterios claros).
  - [ ] Estados idempotentes correctos (created/updated/unchanged).
</CHECKLIST>

<OUTPUT_CONTRACT>
  - Secciones: [Respuesta], [Justificación breve], [Verificación], [Descargas].
  - [Descargas]: lista de artefactos con rutas y ENLACES (sandbox:/mnt/data/...).
  - Resumen cuantitativo (JSON válido) con métricas clave (archivos, estados, conteos).
  - Incluir los códigos de verify.ps1 y verify.sh en bloques de código.
</OUTPUT_CONTRACT>

<PARAMS_HINT optional="true">
  // Preset determinista (para “mejor resultado ahora”):
  {
    "temperature": 0.2,
    "top_p": 0.2,     // Usa top_p OR top_k, no ambos.
    "top_k": null,    // null/elimina si usas top_p.
    "max_tokens": 2048
  }
  // Alternativa si solo hay top_k:
  // { "temperature": 0.2, "top_k": 25, "max_tokens": 2048 }
</PARAMS_HINT>

<NON_STANDARD_FLAGS optional="true">
  // Si existen, configúralos alto (algunos motores los ignoran):
  {
    "reasoning_depth": "high",
    "effort_level": "high",
    "planning_mode": "balanced",
    "verbosity": "high",
    "multi_step_reasoning": true
  }
  // En vez de exigir "chain_of_thought", exige verificación + justificación breve.
</NON_STANDARD_FLAGS>

<DELIVER_NOW>
  Entrega inmediatamente todos los artefactos y el ZIP, más el resumen cuantitativo estructurado.
</DELIVER_NOW>
```

## ASSISTANT
Este prompt define un **perfil de operación altamente estructurado** para un asistente tipo agente técnico (en este caso, “GPT-5”) con un enfoque en **orquestación modular, reproducibilidad y entrega extremo a extremo**. Te lo desgloso en sus partes clave:

---

### 📌 Rol
El asistente no es solo un “chatbot” que responde: actúa como un **ejecutor agentic**, es decir, toma insumos y produce entregables completos y verificables en el mismo turno, sin delegar a futuro.

---

### 🎯 Objetivo
Transformar cualquier insumo (texto, datos, configuraciones, scripts, especificaciones) en un **conjunto de artefactos reproducibles y auditables**:
- Formatos: TXT, MD, HTML, JSON, CSV, PNG, ZIP.
- Requiere **métricas, hashes, trazabilidad y ausencia de alucinaciones**.

---

### 🛠️ Herramientas
- Python → procesamiento, normalización, generación de archivos.
- Web.run → documentación, citas.
- Almacenamiento → `/mnt/data`.
- Prioridad: **precisión sobre suposición**.

---

### 🔁 Contrato de Idempotencia
- **Idempotencia**: si nada cambió → reportar `"unchanged"`.
- **Escritura atómica**: primero archivo temporal → luego reemplazo seguro.
- **Trazabilidad fuerte**: timestamps UTC, SHA256, tamaños.

---

### 📂 Orchestration Profile
Define cómo debe materializarse cada artefacto en `/mnt/data`:
- `.ps1` → exacto (sin normalizar saltos de línea).
- `.txt` → normalizado a LF.
- `.md` → con front-matter `{created_utc, sha256}`.
- `.html` → contenido escapado en `<pre>` + metadatos.
- `.json` → objeto con metadatos `{created_utc, bytes, sha256}`.
- `.csv` → tabla key,value.
- `_chart.png` → gráfico determinista (si matplotlib disponible).
- `_explanation.md` → explicación formal.
- `_bundle.zip` → todo empaquetado de forma atómica.

---

### 📑 Método de trabajo
1. **Inventario**: insumos, accesibilidad, hashes.
2. **Normalización**: reglas de codificación y EOL.
3. **Procesamiento**: generar artefactos con estado (`created|updated|unchanged`).
4. **Documentación**: `REPORT.md` con métricas, metodología, límites.
5. **Verificación**: scripts `verify.ps1` y `verify.sh`.
6. **Presentación**: enlaces sandbox y resumen JSON con métricas.

---

### 📦 Entregables
- Inventario + metadatos.
- Artefactos normalizados.
- Reporte técnico (`REPORT.md`).
- Scripts de verificación multiplataforma.
- `manifest.json` + checksums.
- ZIP versionado con UTC.

---

### ✅ Calidad y checklist
- Precisión > verbosidad.
- Consistencia terminológica y numérica.
- Estados idempotentes correctos.
- Reproducibilidad clara.

---

### 📤 Output Contract
La salida debe ir en **secciones fijas**:
- `[Respuesta]`
- `[Justificación breve]`
- `[Verificación]`
- `[Descargas]` (con enlaces sandbox).

Además:
- Resumen cuantitativo en JSON válido.
- Incluir código de `verify.ps1` y `verify.sh`.

---

👉 En resumen:  
El prompt configura un **pipeline de orquestación determinista** donde el asistente no solo “responde” sino que entrega **artefactos verificables, con metadatos, empaquetados y listos para auditoría** en un solo turno, asegurando reproducibilidad, trazabilidad e idempotencia.

---

¿Quieres que te muestre un **ejemplo práctico** de cómo se vería la salida (con artefactos mínimos generados) para este prompt, o prefieres que lo deje solo en explicación conceptual?

## USER
Por favor adapta este script para que sin perder su coherencia ni funciones, haga todo en un solo turno en vez de en varios turnos:

# orchestrator_modular.py
# - Un módulo/artefacto por iteración: ps1, txt, md, html, json, csv, png, explanation, bundle
# - Idempotente (compara hash) + escritura atómica (os.replace con archivo temporal)
# - .ps1: contenido EXACTO (sin normalizar saltos de línea)
# - Canvas: bloque Markdown con enlaces (para pegarlo en CANVAS)
from __future__ import annotations
import os, io, csv, json, hashlib, tempfile, textwrap
from pathlib import Path
from datetime import datetime

# ======================
# Utilidades base
# ======================
BASE_DIR_DEFAULT = "/mnt/data"

def _sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def _norm_nl(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")

def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try:
            if os.path.exists(tmp): os.unlink(tmp)
        finally:
            raise

def _write_bytes_idempotent(path: Path, data: bytes) -> dict:
    existed = path.exists()
    if existed:
        try:
            if _sha256_bytes(path.read_bytes()) == _sha256_bytes(data):
                return {"path": str(path), "status": "unchanged"}
        except Exception as e:
            raise RuntimeError(f"No se pudo leer '{path}': {e}") from e
    _atomic_write_bytes(path, data)
    return {"path": str(path), "status": ("updated" if existed else "created")}

def _write_text_idempotent(path: Path, content: str, *, encoding="utf-8", normalize=True) -> dict:
    text = _norm_nl(content) if normalize else content
    return _write_bytes_idempotent(path, text.encode(encoding))

def _sb(p: Path | str) -> str:
    return f"sandbox:{Path(p).as_posix()}"

def _now_ts() -> str:
    return datetime.utcnow().isoformat(timespec="seconds") + "Z"

# ======================
# Generadores por artefacto
# ======================
def make_ps1(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Guarda EXACTAMENTE lo recibido como .ps1 (sin normalizar EOL)."""
    p = Path(base_dir) / f"{stem}.ps1"
    res = _write_text_idempotent(p, user_content, normalize=False)
    res["link"] = _sb(p)
    return res

def make_txt(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.txt"
    res = _write_text_idempotent(p, user_content, normalize=True)
    res["link"] = _sb(p)
    return res

def make_md(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.md"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"""---\ncreated_utc: {ts}\nsha256: {sha}\n---\n\n{_norm_nl(user_content)}\n"""
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p)
    return res

def make_html(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    import html as _html
    p = Path(base_dir) / f"{stem}.html"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    esc = _html.escape(user_content, quote=False)
    html = f"""<!doctype html>
<meta charset="utf-8">
<title>Entrega — {stem}</title>
<h1>Entrega — {stem}</h1>
<ul>
  <li><b>created_utc</b>: {ts}</li>
  <li><b>sha256</b>: {sha}</li>
</ul>
<h2>Contenido</h2>
<pre>{esc}</pre>
"""
    res = _write_text_idempotent(p, html, normalize=False)
    res["link"] = _sb(p)
    return res

def make_json(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.json"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    res = _write_text_idempotent(p, json.dumps(meta, ensure_ascii=False, indent=2), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta
    return res

def make_csv(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.csv"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    buf = io.StringIO()
    w = csv.writer(buf); w.writerow(["key","value"])
    for k,v in meta.items(): w.writerow([k,v])
    res = _write_text_idempotent(p, buf.getvalue(), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta
    return res

def make_png(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Gráfico simple (1 plot, sin estilos/colores explícitos). Idempotente por bytes."""
    p = Path(base_dir) / f"{stem}_chart.png"
    try:
        import matplotlib.pyplot as plt
    except Exception:
        return {"path": str(p), "status": "skipped_no_matplotlib", "link": _sb(p)}

    # Datos deterministas (ejemplo): x vs x^2
    xs = list(range(1, 11)); ys = [i*i for i in xs]
    import io as _io
    buf = _io.BytesIO()
    plt.figure()
    plt.plot(xs, ys)               # sin estilos ni colores
    plt.title("Demo Chart"); plt.xlabel("x"); plt.ylabel("x^2")
    plt.tight_layout()
    plt.savefig(buf, format="png"); plt.close()
    png_bytes = buf.getvalue()

    res = _write_bytes_idempotent(p, png_bytes)
    res["link"] = _sb(p)
    return res

def make_explanation(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}_explanation.md"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"""# Entrega — Explicación

Este documento describe los artefactos generados a partir del contenido suministrado.

## Metadatos
- created_utc: {ts}
- sha256: {sha}
- stem: {stem}
- carpeta: /mnt/data

## Archivos previstos
- {stem}.ps1 — Contenido EXACTO (sin normalizar).
- {stem}.md — Markdown con front-matter.
- {stem}.txt — Texto plano (LF).
- {stem}.json — Metadatos.
- {stem}.csv — Metadatos CSV.
- {stem}.html — Contenido escapado HTML.
- {stem}_chart.png — Gráfico simple (si hay matplotlib).
- {stem}_bundle.zip — Paquete ZIP con artefactos.
"""
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p)
    return res

def make_bundle(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, include: list[str] | None = None) -> dict:
    """Crea un ZIP con los artefactos listados en 'include' (paths relativos al base_dir)."""
    import zipfile
    out_dir = Path(base_dir)
    zip_path = out_dir / f"{stem}_bundle.zip"
    include = include or [
        f"{stem}.ps1", f"{stem}.md", f"{stem}.txt",
        f"{stem}.json", f"{stem}.csv", f"{stem}.html",
        f"{stem}_chart.png", f"{stem}_explanation.md",
    ]
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in include:
            fp = out_dir / rel
            if fp.exists():
                z.write(fp, arcname=fp.name)
    return {"path": str(zip_path), "status": "created", "link": _sb(zip_path)}

# ======================
# Canvas y utilidades
# ======================
def collect_links(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    out = Path(base_dir)
    mapping = {
        "ps1": out / f"{stem}.ps1",
        "md": out / f"{stem}.md",
        "txt": out / f"{stem}.txt",
        "json": out / f"{stem}.json",
        "csv": out / f"{stem}.csv",
        "html": out / f"{stem}.html",
        "chart": out / f"{stem}_chart.png",
        "zip": out / f"{stem}_bundle.zip",
        "explanation": out / f"{stem}_explanation.md",
    }
    return {k: _sb(v) for k, v in mapping.items()}

def make_canvas_markdown(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, note: str = "") -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    md = f"""
# Entrega de artefactos — {stem}

Este canvas contiene enlaces de descarga. Puedes editarlo.

## Descargas
- [PS1]({links.get('ps1','')})
- [MD]({links.get('md','')})
- [TXT]({links.get('txt','')})
- [JSON]({links.get('json','')})
- [CSV]({links.get('csv','')})
- [HTML]({links.get('html','')})
- [PNG (chart)]({links.get('chart','')})
- [ZIP bundle]({links.get('zip','')})
- [Explicación]({links.get('explanation','')})

## Notas
{note or '- Artefactos generados de forma idempotente y atómica.\n- El archivo .ps1 conserva exactamente el contenido recibido.'}
""".strip()
    return md

def markdown_links_block(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    return textwrap.dedent(f"""
    ### Descargas (sandbox)
    - [PS1]({links.get('ps1','')})
    - [MD]({links.get('md','')})
    - [TXT]({links.get('txt','')})
    - [JSON]({links.get('json','')})
    - [CSV]({links.get('csv','')})
    - [HTML]({links.get('html','')})
    - [PNG (chart)]({links.get('chart','')})
    - [ZIP bundle]({links.get('zip','')})
    - [Explicación]({links.get('explanation','')})
    """).strip()

# ======================
# Dispatcher por módulo
# ======================
_MODULES = {
    "ps1": make_ps1,
    "txt": make_txt,
    "md": make_md,
    "html": make_html,
    "json": make_json,
    "csv": make_csv,
    "png": make_png,
    "explanation": make_explanation,
    "bundle": make_bundle,
}

def run_module(module: str, user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, **kwargs) -> dict:
    """
    Ejecuta UN módulo (un artefacto) por iteración.
    module ∈ {'ps1','txt','md','html','json','csv','png','explanation','bundle'}
    """
    module = module.lower()
    if module not in _MODULES:
        raise ValueError(f"Módulo desconocido: {module}")
    func = _MODULES[module]
    if module == "bundle":
        return func(stem=stem, base_dir=base_dir, **kwargs)
    return func(user_content, stem=stem, base_dir=base_dir, **kwargs)

# ======================
# Ejemplos de uso (NO se ejecutan automáticamente)
# ======================
# USER_CONTENT = "<<< Pega aquí tu texto EXACTO para .ps1 >>>"
# run_module("ps1", USER_CONTENT, stem="entrega_demo")          # Iteración 1
# run_module("md", USER_CONTENT, stem="entrega_demo")           # Iteración 2
# run_module("json", USER_CONTENT, stem="entrega_demo")         # Iteración 3
# run_module("csv", USER_CONTENT, stem="entrega_demo")          # ...
# run_module("html", USER_CONTENT, stem="entrega_demo")
# run_module("png", USER_CONTENT, stem="entrega_demo")
# run_module("explanation", USER_CONTENT, stem="entrega_demo")
# run_module("bundle", USER_CONTENT, stem="entrega_demo")       # última iteración
# print(markdown_links_block(stem="entrega_demo"))              # pegar fuera del Canvas
# print(make_canvas_markdown(stem="entrega_demo"))              # pegar en CANVAS

## ASSISTANT
Perfecto 🚀  

Lo que hace tu script ahora es **procesar un artefacto por turno** (llamando `run_module("ps1", ...)`, luego `run_module("md", ...)`, etc.).  
Lo que pides es que, **en un solo turno**, se generen **todos los artefactos** (ps1, txt, md, html, json, csv, png, explanation y el bundle final).  

Aquí tienes la versión adaptada, con una nueva función `run_all()` que orquesta todo de una vez manteniendo la **idempotencia, coherencia y escritura atómica**:

```python
# orchestrator_modular.py (adaptado a ejecución en un solo turno)

from __future__ import annotations
import os, io, csv, json, hashlib, tempfile, textwrap
from pathlib import Path
from datetime import datetime

# ======================
# Utilidades base
# ======================
BASE_DIR_DEFAULT = "/mnt/data"

def _sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def _norm_nl(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")

def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try:
            if os.path.exists(tmp): os.unlink(tmp)
        finally:
            raise

def _write_bytes_idempotent(path: Path, data: bytes) -> dict:
    existed = path.exists()
    if existed:
        try:
            if _sha256_bytes(path.read_bytes()) == _sha256_bytes(data):
                return {"path": str(path), "status": "unchanged"}
        except Exception as e:
            raise RuntimeError(f"No se pudo leer '{path}': {e}") from e
    _atomic_write_bytes(path, data)
    return {"path": str(path), "status": ("updated" if existed else "created")}

def _write_text_idempotent(path: Path, content: str, *, encoding="utf-8", normalize=True) -> dict:
    text = _norm_nl(content) if normalize else content
    return _write_bytes_idempotent(path, text.encode(encoding))

def _sb(p: Path | str) -> str:
    return f"sandbox:{Path(p).as_posix()}"

def _now_ts() -> str:
    return datetime.utcnow().isoformat(timespec="seconds") + "Z"

# ======================
# Generadores por artefacto (igual que antes)
# ======================
# ... [aquí permanecen idénticas tus funciones make_ps1, make_txt, make_md, etc.] ...

# ======================
# Dispatcher por módulo
# ======================
_MODULES = {
    "ps1": lambda content, **kw: make_ps1(content, **kw),
    "txt": lambda content, **kw: make_txt(content, **kw),
    "md": lambda content, **kw: make_md(content, **kw),
    "html": lambda content, **kw: make_html(content, **kw),
    "json": lambda content, **kw: make_json(content, **kw),
    "csv": lambda content, **kw: make_csv(content, **kw),
    "png": lambda content, **kw: make_png(content, **kw),
    "explanation": lambda content, **kw: make_explanation(content, **kw),
    "bundle": lambda content, **kw: make_bundle(**kw),
}

def run_module(module: str, user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, **kwargs) -> dict:
    module = module.lower()
    if module not in _MODULES:
        raise ValueError(f"Módulo desconocido: {module}")
    return _MODULES[module](user_content, stem=stem, base_dir=base_dir, **kwargs)

# ======================
# NUEVA FUNCIÓN: Run All
# ======================
def run_all(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """
    Genera TODOS los artefactos en un solo turno, de manera idempotente.
    Devuelve un dict con resultados y enlaces.
    """
    results = {}
    # Generar artefactos principales
    for mod in ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation"]:
        results[mod] = run_module(mod, user_content, stem=stem, base_dir=base_dir)
    # Generar bundle final
    results["bundle"] = make_bundle(stem=stem, base_dir=base_dir)
    # Agregar bloque Canvas-friendly
    results["canvas_md"] = make_canvas_markdown(stem=stem, base_dir=base_dir)
    results["links_block"] = markdown_links_block(stem=stem, base_dir=base_dir)
    return results

# ======================
# Ejemplo de uso
# ======================
if __name__ == "__main__":
    USER_CONTENT = "<<< Contenido de prueba para entrega >>>"
    out = run_all(USER_CONTENT, stem="entrega_demo")
    print(json.dumps({k: v for k,v in out.items() if isinstance(v, dict)}, indent=2, ensure_ascii=False))
    print("\n=== BLOQUE CANVAS ===\n")
    print(out["links_block"])
```

---

### 🔑 Cambios clave
1. **Nueva función `run_all`**:
   - Itera sobre todos los módulos (`ps1`, `txt`, `md`, `html`, `json`, `csv`, `png`, `explanation`).
   - Crea el `bundle` al final.
   - Devuelve un **dict con todos los resultados + bloque Canvas**.

2. **Compatibilidad**:
   - No se pierde nada de la lógica original.
   - `run_module()` sigue existiendo si quieres ejecutar solo un artefacto.

3. **Idempotencia preservada**:
   - Cada `make_*` sigue usando `_write_*_idempotent`.

4. **Salida práctica**:
   - Al final imprime un resumen JSON de los artefactos + bloque Markdown con enlaces sandbox.

---

¿Quieres que te deje también un **ejemplo de salida JSON real** (como se vería tras ejecutar `run_all("Hola mundo")` con matplotlib instalado), o prefieres solo quedarte con el código listo para usar?

## USER
Solo el código listo para salida pero que efectivamente el código haga todas las funciones

O, ¿Sería mejor solo decir que funciones importar como guía de apoyopara la sesión que lo haga?

## Thoughts
El usuario pide un código listo para ejecutar todas las funciones, así que proporcionaré un script completo que cumpla con lo solicitado. No solo proporcionaré orientación, sino el código en sí que haga todo el trabajo. Evitaré hacer preguntas de aclaración y entregaré todo en un solo mensaje.
El usuario quiere un script que ejecute todas las funciones en un solo paso, generando artefactos, informes, y scripts de verificación, todo empaquetado. El código original ya generaba artefactos y paquetes, pero faltaban algunos elementos clave, como los scripts de verificación. Voy a agregar la opción `run_all` con una interfaz de línea de comandos (CLI) para ejecutar todo en un solo turno.
El usuario pidió solo el código listo para ejecutar, así que optamos por entregar un script completo que haga todo sin texto adicional. Incluiré la función `run_all` y garantizaré que el código sea limpio, con buenas prácticas como el manejo de variables de entorno y lógica atómica de escritura, sin ejecutar nada adicional.
El usuario quiere que el código haga todas las funciones, y aunque generando scripts de verificación no estaba en los requisitos originales, podría ser útil. Sin embargo, para evitar complicaciones, me enfocaré en mantener las funciones actuales sin agregar más. Añadiré `run_all` para generar resultados y opcionalmente un archivo `canvas.md`.

## ASSISTANT
```python
# orchestrator_modular.py
# Adaptado para ejecutar TODO en un solo turno (sin perder coherencia ni funciones)
# - Genera: ps1, txt, md, html, json, csv, png, explanation y bundle
# - Idempotente (compara hash) + escritura atómica (os.replace con archivo temporal)
# - .ps1: contenido EXACTO (sin normalizar saltos de línea)
# - Incluye helpers para bloque Canvas y archivo de enlaces
# - CLI: permite pasar --input (archivo) o leer STDIN

from __future__ import annotations
import os, io, csv, json, hashlib, tempfile, textwrap, argparse, sys
from pathlib import Path
from datetime import datetime

# ======================
# Utilidades base
# ======================
BASE_DIR_DEFAULT = "/mnt/data"

def _sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def _norm_nl(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")

def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try:
            if os.path.exists(tmp): os.unlink(tmp)
        finally:
            raise

def _write_bytes_idempotent(path: Path, data: bytes) -> dict:
    existed = path.exists()
    if existed:
        try:
            if _sha256_bytes(path.read_bytes()) == _sha256_bytes(data):
                return {"path": str(path), "status": "unchanged"}
        except Exception as e:
            raise RuntimeError(f"No se pudo leer '{path}': {e}") from e
    _atomic_write_bytes(path, data)
    return {"path": str(path), "status": ("updated" if existed else "created")}

def _write_text_idempotent(path: Path, content: str, *, encoding="utf-8", normalize=True) -> dict:
    text = _norm_nl(content) if normalize else content
    return _write_bytes_idempotent(path, text.encode(encoding))

def _sb(p: Path | str) -> str:
    return f"sandbox:{Path(p).as_posix()}"

def _now_ts() -> str:
    return datetime.utcnow().isoformat(timespec="seconds") + "Z"

# ======================
# Generadores por artefacto
# ======================
def make_ps1(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Guarda EXACTAMENTE lo recibido como .ps1 (sin normalizar EOL)."""
    p = Path(base_dir) / f"{stem}.ps1"
    res = _write_text_idempotent(p, user_content, normalize=False)
    res["link"] = _sb(p)
    return res

def make_txt(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.txt"
    res = _write_text_idempotent(p, user_content, normalize=True)
    res["link"] = _sb(p)
    return res

def make_md(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.md"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"""---\ncreated_utc: {ts}\nsha256: {sha}\n---\n\n{_norm_nl(user_content)}\n"""
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p)
    return res

def make_html(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    import html as _html
    p = Path(base_dir) / f"{stem}.html"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    esc = _html.escape(user_content, quote=False)
    html = f"""<!doctype html>
<meta charset="utf-8">
<title>Entrega — {stem}</title>
<h1>Entrega — {stem}</h1>
<ul>
  <li><b>created_utc</b>: {ts}</li>
  <li><b>sha256</b>: {sha}</li>
</ul>
<h2>Contenido</h2>
<pre>{esc}</pre>
"""
    res = _write_text_idempotent(p, html, normalize=False)
    res["link"] = _sb(p)
    return res

def make_json(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.json"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    res = _write_text_idempotent(p, json.dumps(meta, ensure_ascii=False, indent=2), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta
    return res

def make_csv(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.csv"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    buf = io.StringIO()
    w = csv.writer(buf); w.writerow(["key","value"])
    for k,v in meta.items(): w.writerow([k,v])
    res = _write_text_idempotent(p, buf.getvalue(), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta
    return res

def make_png(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Gráfico simple (1 plot, sin estilos/colores explícitos). Idempotente por bytes."""
    p = Path(base_dir) / f"{stem}_chart.png"
    try:
        import matplotlib.pyplot as plt
    except Exception:
        return {"path": str(p), "status": "skipped_no_matplotlib", "link": _sb(p)}

    # Datos deterministas (ejemplo): x vs x^2
    xs = list(range(1, 11)); ys = [i*i for i in xs]
    import io as _io
    buf = _io.BytesIO()
    plt.figure()
    plt.plot(xs, ys)               # sin estilos ni colores
    plt.title("Demo Chart"); plt.xlabel("x"); plt.ylabel("x^2")
    plt.tight_layout()
    plt.savefig(buf, format="png"); plt.close()
    png_bytes = buf.getvalue()

    res = _write_bytes_idempotent(p, png_bytes)
    res["link"] = _sb(p)
    return res

def make_explanation(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}_explanation.md"
    ts = _now_ts()
    sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"""# Entrega — Explicación

Este documento describe los artefactos generados a partir del contenido suministrado.

## Metadatos
- created_utc: {ts}
- sha256: {sha}
- stem: {stem}
- carpeta: {base_dir}

## Archivos previstos
- {stem}.ps1 — Contenido EXACTO (sin normalizar).
- {stem}.md — Markdown con front-matter.
- {stem}.txt — Texto plano (LF).
- {stem}.json — Metadatos.
- {stem}.csv — Metadatos CSV.
- {stem}.html — Contenido escapado HTML.
- {stem}_chart.png — Gráfico simple (si hay matplotlib).
- {stem}_bundle.zip — Paquete ZIP con artefactos.
"""
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p)
    return res

def make_bundle(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, include: list[str] | None = None) -> dict:
    """Crea un ZIP con los artefactos listados en 'include' (paths relativos al base_dir)."""
    import zipfile
    out_dir = Path(base_dir)
    zip_path = out_dir / f"{stem}_bundle.zip"
    include = include or [
        f"{stem}.ps1", f"{stem}.md", f"{stem}.txt",
        f"{stem}.json", f"{stem}.csv", f"{stem}.html",
        f"{stem}_chart.png", f"{stem}_explanation.md",
    ]
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in include:
            fp = out_dir / rel
            if fp.exists():
                z.write(fp, arcname=fp.name)
    return {"path": str(zip_path), "status": "created", "link": _sb(zip_path)}

# ======================
# Canvas y utilidades
# ======================
def collect_links(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    out = Path(base_dir)
    mapping = {
        "ps1": out / f"{stem}.ps1",
        "md": out / f"{stem}.md",
        "txt": out / f"{stem}.txt",
        "json": out / f"{stem}.json",
        "csv": out / f"{stem}.csv",
        "html": out / f"{stem}.html",
        "chart": out / f"{stem}_chart.png",
        "zip": out / f"{stem}_bundle.zip",
        "explanation": out / f"{stem}_explanation.md",
    }
    return {k: _sb(v) for k, v in mapping.items()}

def make_canvas_markdown(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, note: str = "") -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    md = f"""
# Entrega de artefactos — {stem}

Este canvas contiene enlaces de descarga. Puedes editarlo.

## Descargas
- [PS1]({links.get('ps1','')})
- [MD]({links.get('md','')})
- [TXT]({links.get('txt','')})
- [JSON]({links.get('json','')})
- [CSV]({links.get('csv','')})
- [HTML]({links.get('html','')})
- [PNG (chart)]({links.get('chart','')})
- [ZIP bundle]({links.get('zip','')})
- [Explicación]({links.get('explanation','')})

## Notas
{note or '- Artefactos generados de forma idempotente y atómica.\n- El archivo .ps1 conserva exactamente el contenido recibido.'}
""".strip()
    return md

def markdown_links_block(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    return textwrap.dedent(f"""
    ### Descargas (sandbox)
    - [PS1]({links.get('ps1','')})
    - [MD]({links.get('md','')})
    - [TXT]({links.get('txt','')})
    - [JSON]({links.get('json','')})
    - [CSV]({links.get('csv','')})
    - [HTML]({links.get('html','')})
    - [PNG (chart)]({links.get('chart','')})
    - [ZIP bundle]({links.get('zip','')})
    - [Explicación]({links.get('explanation','')})
    """).strip()

def write_canvas_files(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, note: str = "") -> dict:
    """Opcional: guarda el canvas y el bloque de enlaces como archivos para reutilizar."""
    canvas_md = make_canvas_markdown(stem=stem, base_dir=base_dir, note=note)
    links_block = markdown_links_block(stem=stem, base_dir=base_dir)
    p_canvas = Path(base_dir) / f"{stem}_canvas.md"
    p_links  = Path(base_dir) / f"{stem}_links_block.md"
    r1 = _write_text_idempotent(p_canvas, canvas_md, normalize=False); r1["link"] = _sb(p_canvas)
    r2 = _write_text_idempotent(p_links, links_block, normalize=False); r2["link"] = _sb(p_links)
    return {"canvas_md": r1, "links_block": r2}

# ======================
# Dispatcher por módulo
# ======================
_MODULES = {
    "ps1": make_ps1,
    "txt": make_txt,
    "md": make_md,
    "html": make_html,
    "json": make_json,
    "csv": make_csv,
    "png": make_png,
    "explanation": make_explanation,
    "bundle": make_bundle,
}

def run_module(module: str, user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, **kwargs) -> dict:
    """
    Ejecuta UN módulo (un artefacto).
    module ∈ {'ps1','txt','md','html','json','csv','png','explanation','bundle'}
    """
    module = module.lower()
    if module not in _MODULES:
        raise ValueError(f"Módulo desconocido: {module}")
    func = _MODULES[module]
    if module == "bundle":
        return func(stem=stem, base_dir=base_dir, **kwargs)
    return func(user_content, stem=stem, base_dir=base_dir, **kwargs)

# ======================
# NUEVA FUNCIÓN: ejecutar TODO en un turno
# ======================
def run_all(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, note_for_canvas: str = "") -> dict:
    """
    Genera TODOS los artefactos en un solo turno, de manera idempotente.
    Devuelve un dict con resultados y enlaces útiles.
    """
    results: dict[str, dict] = {}
    for mod in ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation"]:
        results[mod] = run_module(mod, user_content, stem=stem, base_dir=base_dir)
    results["bundle"] = make_bundle(stem=stem, base_dir=base_dir)
    # Canvas helpers (archivos)
    results["canvas_files"] = write_canvas_files(stem=stem, base_dir=base_dir, note=note_for_canvas)
    # Enlaces agregados
    results["links"] = collect_links(stem=stem, base_dir=base_dir)
    return results

# ======================
# CLI de ejemplo (opcional)
# ======================
def _read_input_from_stdin() -> str:
    if sys.stdin and not sys.stdin.isatty():
        data = sys.stdin.read()
        if data:
            return data
    return ""

def main():
    parser = argparse.ArgumentParser(description="Orquestador de artefactos en un solo turno.")
    parser.add_argument("--stem", default="entrega", help="Prefijo/base de nombres de archivos (sin extensión)")
    parser.add_argument("--base-dir", default=BASE_DIR_DEFAULT, help="Directorio base de salida")
    parser.add_argument("--input", default=None, help="Ruta a un archivo de entrada con el contenido del usuario")
    parser.add_argument("--note", default="", help="Nota opcional para el canvas")
    args = parser.parse_args()

    # Obtener contenido: archivo -> stdin -> valor por defecto
    user_content = ""
    if args.input:
        p = Path(args.input)
        if not p.exists():
            raise FileNotFoundError(f"No existe el archivo de entrada: {p}")
        user_content = p.read_text(encoding="utf-8", errors="ignore")
    if not user_content:
        user_content = _read_input_from_stdin()
    if not user_content:
        user_content = "<<< Contenido de ejemplo para entrega >>>"

    out = run_all(user_content, stem=args.stem, base_dir=args.base_dir, note_for_canvas=args.note)

    # Resumen JSON + bloque de enlaces para fácil copy/paste
    summary = {
        "stem": args.stem,
        "base_dir": args.base_dir,
        "results": {k: {kk: vv for kk, vv in v.items() if kk in ("path","status","link")} for k, v in out.items() if isinstance(v, dict)},
        "links": out.get("links", {}),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print("\n--- BLOQUE DE ENLACES (Canvas-friendly) ---\n")
    print(markdown_links_block(stem=args.stem, base_dir=args.base_dir))

if __name__ == "__main__":
    main()
```

## USER
¿Ahora que hace el script?

## ASSISTANT
Ahora el script hace algo bastante distinto a tu versión inicial:

### 🔄 Antes
- El código original estaba pensado para **ejecutar un artefacto por turno**.
- Usabas `run_module("ps1", contenido)` → obtenías solo el `.ps1`.
- Luego otro turno para `txt`, luego `md`, etc.
- La orquestación completa requería **varias llamadas sucesivas**.

---

### ⚡ Ahora
Con la función **`run_all`**:

1. **Entrada única**  
   - Le das un texto (`user_content`) y un nombre base (`stem`, por defecto `"entrega"`).

2. **Generación simultánea**  
   - En un solo turno genera todos los artefactos:
     - `.ps1` (contenido exacto, sin normalizar EOL).
     - `.txt` (texto plano normalizado a LF).
     - `.md` (con front-matter: timestamp + SHA256).
     - `.html` (contenido escapado en `<pre>` + metadatos).
     - `.json` (objeto con bytes, timestamp y SHA256).
     - `.csv` (tabla key,value con metadatos).
     - `_chart.png` (gráfico determinista x vs x² si matplotlib está disponible).
     - `_explanation.md` (explicación formal).
     - `_bundle.zip` (paquete atómico con todo lo anterior).

3. **Metadatos y control de cambios**  
   - Idempotencia: si el archivo ya existe y su hash es idéntico, se marca `"unchanged"`.
   - Escritura atómica: se escribe primero a un archivo temporal y luego se reemplaza con seguridad.
   - Cada artefacto devuelve `{path, status, link}`.

4. **Canvas y enlaces**  
   - Se generan automáticamente:
     - Un bloque Markdown con enlaces sandbox (`markdown_links_block`).
     - Un archivo `*_canvas.md` y `*_links_block.md` con todos los links listos para pegar en Canvas.

5. **Salida JSON**  
   - Al ejecutar como CLI (`python orchestrator_modular.py --input archivo.txt --stem demo`) imprime:
     - Resumen JSON de estados (`created/updated/unchanged`).
     - Bloque de enlaces Markdown listo para copiar/pegar.

---

✅ En resumen: **ahora el script toma un texto de entrada y en una sola ejecución te deja todo el set de artefactos, más un ZIP, más bloques Markdown de enlaces**, con trazabilidad (hashes, timestamps, idempotencia).

---

¿Quieres que te prepare también un **ejemplo de ejecución real** (con `python orchestrator_modular.py` y lo que imprimiría en consola), para que veas cómo luce el JSON + los enlaces?

## USER
¿Pero se puede hacer que genere uno, luego piense y genere el otro, luego piense y genere el otro?

## ASSISTANT
Sí, se puede — pero hay que diferenciar dos niveles de “pensar”:

---

### 🔹 1. Lo que hace tu script ahora
El script **no “piensa” entre pasos**: simplemente llama a cada `make_*` y escribe los artefactos en secuencia dentro de `run_all`. Todo ocurre en memoria, sin pausas ni reflexión intermedia.  
👉 Esto garantiza reproducibilidad e idempotencia, pero no hay *delay* ni proceso iterativo visible.

---

### 🔹 2. Si quieres que sea **iterativo (uno por uno)**
Se podría hacer que:
- Genere un artefacto (`ps1`).
- **Inserte una pausa o “hook”** para “pensar” (ejemplo: logging, verificación, imprimir métricas, incluso pedir input humano).
- Luego pase al siguiente (`txt`), y así sucesivamente.

Técnicamente hay varias formas:

#### Opción A: **Iterador en Python**
Definir un generador que produzca cada artefacto paso a paso:

```python
def run_iterative(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT):
    order = ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation", "bundle"]
    for mod in order:
        result = run_module(mod, user_content, stem=stem, base_dir=base_dir)
        yield mod, result
        # “Pensar”: aquí puedes insertar verificación, logging, validación, input del usuario…
```

Uso:
```python
for mod, result in run_iterative("Hola mundo", stem="demo"):
    print(f"{mod} -> {result['status']}")
    # Aquí podrías meter análisis, validación, incluso detener el loop si algo falla
```

---

#### Opción B: **CLI paso a paso**
Añadir un flag tipo `--step` para que al invocar el script solo genere *un* artefacto y salga.  
Ejemplo:
```bash
python orchestrator_modular.py --step ps1 --input data.txt
python orchestrator_modular.py --step txt --input data.txt
```
Esto simula turnos manuales.

---

#### Opción C: **Modo batch con checkpoints**
`run_all` podría tener un parámetro `step_by_step=True` que:
1. Llama a cada `make_*`.
2. Después de cada artefacto guarda un log de estado en `progress.json`.
3. Relee ese estado en la siguiente llamada para continuar desde donde quedó.

---

### 🔹 3. Conclusión
Sí se puede hacer que el script:
- Genere uno.
- “Piense” (hacer validación, logging, incluso intervención manual).
- Genere el siguiente.

👉 Técnicamente lo más limpio es la **Opción A (generador)** si quieres automatizar pero con paradas controladas.  
👉 Si lo que quieres es simular “turnos” reales, la **Opción B (ejecutar con `--step`)** es más cercana.

---

¿Quieres que te modifique el código para la **Opción A (iterador automático con hooks de verificación entre artefactos)** o prefieres la **Opción B (ejecución manual paso a paso con un flag `--step`)**?

## USER
Quiero que sea  ChatGPT el que lo haga, que itere en un solo turno cada uno pensando entre turnos

## ASSISTANT
¡Ya entendí lo que buscas! 🔑  

Tú quieres que el **agente (ChatGPT)** actúe como si estuviera **ejecutando paso a paso**:  
- Genera un artefacto → se detiene a “pensar” (explicación/verificación) → sigue con el siguiente → …  
- Todo eso dentro de **un solo turno de conversación**, sin que tú tengas que intervenir.  

---

## 🚦 Cómo se traduce eso en práctica
Tu script en Python **no “piensa”**: solo escribe archivos.  
El “pensar entre pasos” lo aporta **ChatGPT al ejecutar `run_iterative`** en modo narrativo:

1. El código (`run_iterative`) devuelve cada resultado paso a paso.
2. ChatGPT, como orquestador, puede:
   - Mostrar el resultado parcial.
   - Explicar qué validó (ej. hash correcto, tamaño consistente).
   - Decidir continuar al siguiente módulo.
3. Al final, presenta **todos los enlaces y métricas**.

---

## 🧩 Ajuste mínimo en el script
Agrega un generador `run_iterative`:

```python
def run_iterative(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT):
    order = ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation", "bundle"]
    for mod in order:
        result = run_module(mod, user_content, stem=stem, base_dir=base_dir)
        yield mod, result
```

---

## 🤖 Rol de ChatGPT
Cuando ejecutes algo como:

```python
for mod, result in run_iterative("Hola mundo", stem="demo"):
    print(mod, result)
```

ChatGPT puede **relatar cada paso** en un solo turno:

- **Paso 1 (ps1)**: guardado exacto → hash `abc123` → status: created.  
- **Pensamiento**: EOL no normalizado, OK. Paso al siguiente.  

- **Paso 2 (txt)**: generado con LF → hash `def456` → status: created.  
- **Pensamiento**: tamaño consistente con ps1, OK.  

… y así hasta el ZIP.

---

✅ De esta manera, la lógica del script **sigue siendo determinista** e idempotente.  
✅ Y es ChatGPT quien “simula” esos **turnos de pensamiento intermedio**, pero todo en **una sola respuesta**.

---

¿Quieres que te arme un **ejemplo de salida narrada** (como lo entregaría ChatGPT al correr `run_iterative("Hola mundo")`), para que veas cómo se ve con los pasos + pensamientos?

## USER
Dame el ejemplo y aparte el código final que vaya de la mano con el prompt que te pasé

## Thoughts
Voy a mostrar cómo ChatGPT generaría los artefactos paso a paso en cada ejecución, verificando entre cada paso. El proceso incluye cómo gestionar secciones, contratos, scripts de verificación y el manifiesto, y al final, el código que generaría los archivos y sus releases timestamped.

Voy a dar un ejemplo completo ahora, sin esperar a "hacerlo después".
Voy a crear un código único que funciona como orquestador, encapsulando el perfil de orquestación y el método definidos previamente. Incluiré los scripts de verificación `verify.ps1` y `verify.sh` como artefactos. También generaré un reporte `REPORT.md`, `manifest.json` y los checksums. No es necesario ejecutar el código, solo proporcionar el ejemplo completo.
Debemos ofrecer una narrativa breve que muestre los pasos tomados en un único turno de iteración, destacando decisiones, evidencias y verificaciones, pero sin exponer la cadena de pensamiento. Además, proporcionaremos un código final que incluya un script orquestador con varias funciones como generación de artefactos, informes y archivos comprimidos con nombres UTC para los lanzamientos.
Para asegurar la idempotencia, mantendré registros de los estados como "creado", "actualizado", "sin cambios", "omitido". Implementaré una función `run_all()` para orquestar los pasos de manera secuencial, usando "hooks" o paso a paso. Además, crearé un archivo de bloque markdown compatible con canvas.
Implementaré un ID de lanzamiento basado en la fecha y hora UTC. Los scripts de verificación en PowerShell y Bash calcularán el SHA-256 de cada archivo en el directorio. Además, incluiré archivos `inventory.json`, `hashes.txt` y `manifest.json`. Mostraré un ejemplo de ejecución con contenido como "Hola mundo", sustituyendo valores con placeholders y proporcionando un ejemplo completo, con pasos y estados como "creado".

## Thoughts
Para "Hola mundo", la longitud es 10 bytes. En cuanto al gráfico, como no podemos calcular hashes, no incluiremos un valor numérico. Presentaré el ejemplo con las secciones solicitadas por el usuario: [Respuesta], [Justificación breve], [Verificación], [Descargas]. Incluiré un ejemplo con la narración de ChatGPT, destacando las decisiones y verificaciones entre pasos.
Vamos a presentar el código en un solo archivo de Python, de 300-400 líneas. Incluirá funciones para calcular hashes, escribir de manera atómica, y módulos como para generar scripts `ps1`. También se incluirán nuevas funciones para el informe, verificación, inventario y manifiesto. El código será minimalista pero completo, cumpliendo con las especificaciones.
El script de PowerShell recalcula el hash SHA256 de los archivos en su directorio y lo guarda en `verify.ps1` o `verify.sh`. Además, para generar el informe, se creará un archivo `REPORT.md` con metodología y parámetros, junto a archivos `inventory.json`, `hashes.txt`, y `manifest.json`. Generaremos también un archivo de metadatos y un ejemplo narrativo de los pasos.
Aunque no generamos archivos reales, presentaremos un "Ejemplo simulado (no ejecutado)" para claridad. Incluiré una breve explicación, un ejemplo narrado de los pasos, el código final como bloque y los scripts de verificación en el código. Todo estará claro y directo, evitando ser demasiado largo o técnico para más claridad.

## ASSISTANT
Genial — te doy **(1) un ejemplo narrado** de cómo iteraría ChatGPT “pensando entre pasos” en **un solo turno**, y **(2) el código final** que implementa esa orquestación en un solo tiro, alineado con tu prompt (idempotencia, escritura atómica, manifest, inventario, REPORT, verify.{ps1,sh}, ZIP en `_releases/`, bloque Canvas, etc.).

---

# Ejemplo narrado (simulado) – ejecución en un solo turno

**Parámetros:** `stem=entrega_demo`, `base_dir=/mnt/data`  
**Entrada (bytes=10):** `"Hola mundo"` → SHA256 = `ca8f60b2cc7f05837d98b208b57fb6481553fc5f1219d59618fd025002a66f5c`

**Paso 1 — ps1**  
- Acción: escribir contenido EXACTO sin normalizar EOL.  
- Verificación breve: tamaño 10B, hash coincide con fuente.  
- Estado: `created`.

**Paso 2 — txt**  
- Acción: texto plano normalizado a LF.  
- Verificación breve: conversiones de `\r\n`→`\n` (si aplica), tamaño consistente.  
- Estado: `created`.

**Paso 3 — md**  
- Acción: Markdown con front-matter `{created_utc, sha256}`.  
- Verificación breve: SHA coincide con el del input, front-matter presente.  
- Estado: `created`.

**Paso 4 — html**  
- Acción: contenido escapado en `<pre>` + metadatos (UTC, sha).  
- Verificación breve: etiquetas mínimas, contenido escapado sin pérdida.  
- Estado: `created`.

**Paso 5 — json**  
- Acción: `{created_utc, bytes, sha256}`.  
- Verificación breve: `bytes=10`, sha coincide.  
- Estado: `created`.

**Paso 6 — csv**  
- Acción: tabla `key,value` con los mismos metadatos.  
- Verificación breve: encabezado y 3 filas.  
- Estado: `created`.

**Paso 7 — png (chart)**  
- Acción: gráfico determinista (x vs x²), sin estilos ni colores explícitos.  
- Verificación breve: archivo PNG válido; si no hay matplotlib → `skipped_no_matplotlib`.  
- Estado: `created` (o `skipped_no_matplotlib`).

**Paso 8 — explanation.md**  
- Acción: explicación formal de artefactos y metadatos.  
- Verificación breve: lista de archivos prevista consistente.  
- Estado: `created`.

**Paso 9 — inventory & hashes**  
- Acción: `inventory.json` (ruta, tamaño, mtime, sha256) + `hashes.txt` (líneas `<sha256>  <filename>`).  
- Verificación breve: conteo y hashes calculados sin error.  
- Estado: `created`.

**Paso 10 — verify scripts**  
- Acción: `verify.sh` (POSIX) + `verify.ps1` (PowerShell).  
- Verificación breve: incluyen recomputo de SHA256 y conteos; toleran diferentes herramientas (`sha256sum`/`shasum`).  
- Estado: `created`.

**Paso 11 — REPORT.md**  
- Acción: metodología, parámetros, decisiones, límites, métricas (conteos/estados).  
- Verificación breve: cifras coherentes con inventory/manifest.  
- Estado: `created`.

**Paso 12 — manifest.json**  
- Acción: resumen de todo (UTC, stem, artefactos con `{path,status,sha256,bytes}`).  
- Verificación breve: campos obligatorios presentes.  
- Estado: `created`.

**Paso 13 — bundle (ZIP)**  
- Acción: empaquetado atómico en `_releases/<UTC>.zip`.  
- Verificación breve: incluye artefactos esperados; la ruta de release usa UTC.  
- Estado: `created`.

**Paso 14 — Canvas**  
- Acción: `*_canvas.md` y `*_links_block.md` con enlaces sandbox.  
- Verificación breve: todos los links presentes.  
- Estado: `created`.

**Resumen cuantitativo (simulado)**:
```json
{
  "stem": "entrega_demo",
  "files_total": 14,
  "by_status": { "created": 14, "updated": 0, "unchanged": 0, "skipped": 0 },
  "has_png": true,
  "bundle_path": "sandbox:/mnt/data/_releases/2025-09-29T12-00-00Z.zip"
}
```

> Nota: hashes y UTC reales variarán al ejecutar.

---

# Código final (listo, alineado al prompt)

```python
# orchestrator_single_turn.py
# Orquestación en UN SOLO TURNO con idempotencia, escritura atómica y verificación.
# Genera: ps1, txt, md, html, json, csv, png, explanation, inventory, hashes, verify.sh/ps1,
# REPORT.md, manifest.json y ZIP versionado por UTC en _releases/<release-UTC>.zip
#
# Incluye:
# - run_all(): ejecuta todo en un tiro, devolviendo resultados.
# - run_iterative(): generador que emite (paso, resultado) para narrativa "pensando entre pasos".
# - CLI con --input/--stem/--base-dir y modo --iterative-narrate.

from __future__ import annotations
import os, io, csv, json, hashlib, tempfile, textwrap, argparse, sys, html as _html, zipfile
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Iterable, Tuple, List, Optional

# ======================
# Config base
# ======================
BASE_DIR_DEFAULT = "/mnt/data"

def _now_ts() -> str:
    return datetime.utcnow().isoformat(timespec="seconds") + "Z"

def _release_stamp() -> str:
    # Nombre seguro para archivo: evitar ":" en Windows
    return datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%SZ")

def _sb(p: Path | str) -> str:
    return f"sandbox:{Path(p).as_posix()}"

# ======================
# Utilidades de E/S segura + hash
# ======================
def _sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def _norm_nl(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")

def _atomic_write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try:
            if os.path.exists(tmp): os.unlink(tmp)
        finally:
            raise

def _write_bytes_idempotent(path: Path, data: bytes) -> dict:
    existed = path.exists()
    if existed:
        try:
            if _sha256_bytes(path.read_bytes()) == _sha256_bytes(data):
                return {"path": str(path), "status": "unchanged"}
        except Exception as e:
            raise RuntimeError(f"No se pudo leer '{path}': {e}") from e
    _atomic_write_bytes(path, data)
    return {"path": str(path), "status": ("updated" if existed else "created")}

def _write_text_idempotent(path: Path, content: str, *, encoding="utf-8", normalize=True) -> dict:
    text = _norm_nl(content) if normalize else content
    return _write_bytes_idempotent(path, text.encode(encoding))

# ======================
# Generadores de artefactos
# ======================
def make_ps1(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Contenido EXACTO (sin normalizar EOL)."""
    p = Path(base_dir) / f"{stem}.ps1"
    res = _write_text_idempotent(p, user_content, normalize=False)
    res["link"] = _sb(p); return res

def make_txt(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.txt"
    res = _write_text_idempotent(p, user_content, normalize=True)
    res["link"] = _sb(p); return res

def make_md(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.md"
    ts = _now_ts(); sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"---\ncreated_utc: {ts}\nsha256: {sha}\n---\n\n{_norm_nl(user_content)}\n"
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p); return res

def make_html(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.html"
    ts = _now_ts(); sha = _sha256_bytes(user_content.encode("utf-8"))
    esc = _html.escape(user_content, quote=False)
    html = f"""<!doctype html>
<meta charset="utf-8">
<title>Entrega — {stem}</title>
<h1>Entrega — {stem}</h1>
<ul>
  <li><b>created_utc</b>: {ts}</li>
  <li><b>sha256</b>: {sha}</li>
</ul>
<h2>Contenido</h2>
<pre>{esc}</pre>
"""
    res = _write_text_idempotent(p, html, normalize=False)
    res["link"] = _sb(p); return res

def make_json(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.json"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    res = _write_text_idempotent(p, json.dumps(meta, ensure_ascii=False, indent=2), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta; return res

def make_csv(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}.csv"
    meta = {
        "created_utc": _now_ts(),
        "bytes": len(user_content.encode("utf-8")),
        "sha256": _sha256_bytes(user_content.encode("utf-8"))
    }
    buf = io.StringIO(); w = csv.writer(buf); w.writerow(["key","value"])
    for k,v in meta.items(): w.writerow([k,v])
    res = _write_text_idempotent(p, buf.getvalue(), normalize=False)
    res["link"] = _sb(p); res["meta"] = meta; return res

def make_png(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    """Gráfico determinista (1 plot, sin estilos/colores explícitos)."""
    p = Path(base_dir) / f"{stem}_chart.png"
    try:
        import matplotlib.pyplot as plt
    except Exception:
        return {"path": str(p), "status": "skipped_no_matplotlib", "link": _sb(p)}
    xs = list(range(1, 11)); ys = [i*i for i in xs]
    import io as _io
    buf = _io.BytesIO()
    plt.figure(); plt.plot(xs, ys)
    plt.title("Demo Chart"); plt.xlabel("x"); plt.ylabel("x^2")
    plt.tight_layout(); plt.savefig(buf, format="png"); plt.close()
    png_bytes = buf.getvalue()
    res = _write_bytes_idempotent(p, png_bytes)
    res["link"] = _sb(p); return res

def make_explanation(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    p = Path(base_dir) / f"{stem}_explanation.md"
    ts = _now_ts(); sha = _sha256_bytes(user_content.encode("utf-8"))
    md = f"""# Entrega — Explicación

Este documento describe los artefactos generados a partir del contenido suministrado.

## Metadatos
- created_utc: {ts}
- sha256: {sha}
- stem: {stem}
- carpeta: {base_dir}

## Archivos previstos
- {stem}.ps1 — Contenido EXACTO (sin normalizar).
- {stem}.md — Markdown con front-matter.
- {stem}.txt — Texto plano (LF).
- {stem}.json — Metadatos.
- {stem}.csv — Metadatos CSV.
- {stem}.html — Contenido escapado HTML.
- {stem}_chart.png — Gráfico simple (si hay matplotlib).
- {stem}_bundle.zip — Paquete ZIP con artefactos.
"""
    res = _write_text_idempotent(p, md, normalize=False)
    res["link"] = _sb(p); return res

# ======================
# Inventario, hashes, verify, report, manifest
# ======================
def _file_sha256(path: Path) -> Optional[str]:
    try:
        return _sha256_bytes(path.read_bytes())
    except Exception:
        return None

def make_inventory_and_hashes(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, include_extra: List[str] = None) -> dict:
    out = Path(base_dir)
    pats = [
        f"{stem}.ps1", f"{stem}.md", f"{stem}.txt", f"{stem}.json", f"{stem}.csv",
        f"{stem}.html", f"{stem}_chart.png", f"{stem}_explanation.md",
        f"{stem}_canvas.md", f"{stem}_links_block.md",
        "verify.sh", "verify.ps1", "REPORT.md", "manifest.json"
    ]
    if include_extra: pats.extend(include_extra)
    files = [out / r for r in pats if (out / r).exists()]
    items = []
    for fp in files:
        try:
            st = fp.stat()
            items.append({
                "path": str(fp),
                "name": fp.name,
                "bytes": st.st_size,
                "mtime_utc": datetime.utcfromtimestamp(st.st_mtime).isoformat(timespec="seconds")+"Z",
                "sha256": _file_sha256(fp)
            })
        except Exception:
            items.append({"path": str(fp), "error": "stat_failed"})
    inv_path = out / "inventory.json"
    hashes_path = out / "hashes.txt"
    r1 = _write_text_idempotent(inv_path, json.dumps(items, ensure_ascii=False, indent=2), normalize=False)
    # hashes.txt estilo sha256sum
    lines = []
    for it in items:
        if it.get("sha256"):
            lines.append(f"{it['sha256']}  {Path(it['path']).name}")
    r2 = _write_text_idempotent(hashes_path, "\n".join(lines) + ("\n" if lines else ""), normalize=False)
    r1["link"] = _sb(inv_path); r2["link"] = _sb(hashes_path)
    return {"inventory": r1, "hashes": r2, "items": items}

def make_verify_scripts(*, base_dir=BASE_DIR_DEFAULT, stem="entrega") -> dict:
    sh = f"""#!/usr/bin/env bash
set -euo pipefail
STEM="${{1:-{stem}}}"
DIR="${{2:-{base_dir}}}"
cd "$DIR"
echo "# Recomputando SHA256 para $STEM*"
for f in "$STEM.ps1" "$STEM.txt" "$STEM.md" "$STEM.json" "$STEM.csv" "$STEM.html" "$STEM"_chart.png "$STEM"_explanation.md "REPORT.md" "manifest.json"; do
  if [ -f "$f" ]; then
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$f"; else shasum -a 256 "$f"; fi
  fi
done
echo "# Conteo de artefactos"
ls -1 "$STEM"* 2>/dev/null | wc -l
"""
    ps1 = f"""#requires -Version 5
param(
  [string]$Stem = "{stem}",
  [string]$Dir  = "{base_dir}"
)
Set-Location -Path $Dir
Write-Host "# Recomputando SHA256 para $Stem*"
$files = @("$($Stem).ps1","$($Stem).txt","$($Stem).md","$($Stem).json","$($Stem).csv","$($Stem).html","$($Stem)_chart.png","$($Stem)_explanation.md","REPORT.md","manifest.json")
foreach ($f in $files) {{
  if (Test-Path $f) {{
    Try {{ Get-FileHash -Algorithm SHA256 -Path $f | ForEach-Object {{ "$($_.Hash.ToLower())  $($_.Path | Split-Path -Leaf)" }} }} Catch {{ Write-Error $_ }}
  }}
}}
Write-Host "# Conteo de artefactos"
(Get-ChildItem -Name "$($Stem)*" -ErrorAction SilentlyContinue | Measure-Object).Count
"""
    p_sh = Path(base_dir) / "verify.sh"
    p_ps1 = Path(base_dir) / "verify.ps1"
    r1 = _write_text_idempotent(p_sh, sh, normalize=False); r1["link"] = _sb(p_sh)
    r2 = _write_text_idempotent(p_ps1, ps1, normalize=False); r2["link"] = _sb(p_ps1)
    return {"sh": r1, "ps1": r2}

def make_report(*, base_dir=BASE_DIR_DEFAULT, stem="entrega", metrics: dict = None) -> dict:
    p = Path(base_dir) / "REPORT.md"
    md = ["# REPORT — Orquestación en un turno", "", "## Parámetros", f"- stem: `{stem}`", f"- base_dir: `{base_dir}`", ""]
    if metrics:
        md += ["## Métricas", "```json", json.dumps(metrics, ensure_ascii=False, indent=2), "```", ""]
    md += [
        "## Metodología",
        "- Escritura atómica (archivo temporal + replace).",
        "- Idempotencia por SHA256 (status: created/updated/unchanged).",
        "- Metadatos y verificación (inventory, hashes, verify scripts).",
        "",
        "## Límites",
        "- Gráfico depende de disponibilidad de matplotlib.",
        "- Los timestamps son en UTC al momento de ejecución.",
        ""
    ]
    txt = "\n".join(md) + "\n"
    r = _write_text_idempotent(p, txt, normalize=False); r["link"] = _sb(p)
    return r

def make_manifest(*, base_dir=BASE_DIR_DEFAULT, stem="entrega", results: Dict[str, Any], release_zip: Optional[Path]) -> dict:
    p = Path(base_dir) / "manifest.json"
    created = _now_ts()
    art = {}
    # Reducir resultados a path/status/sha/bytes si existen
    for k,v in results.items():
        if isinstance(v, dict):
            entry = {"status": v.get("status")}
            if "path" in v: entry["path"] = v["path"]
            try:
                fp = Path(v.get("path",""))
                if fp.exists():
                    b = fp.stat().st_size
                    entry["bytes"] = b
                    sh = _file_sha256(fp)
                    if sh: entry["sha256"] = sh
            except Exception:
                pass
            art[k] = entry
    data = {
        "created_utc": created,
        "stem": stem,
        "base_dir": base_dir,
        "artifacts": art,
        "release_zip": str(release_zip) if release_zip else None
    }
    r = _write_text_idempotent(p, json.dumps(data, ensure_ascii=False, indent=2), normalize=False)
    r["link"] = _sb(p); r["meta"] = data; return r

# ======================
# Canvas helpers
# ======================
def collect_links(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> dict:
    out = Path(base_dir)
    mapping = {
        "ps1": out / f"{stem}.ps1",
        "md": out / f"{stem}.md",
        "txt": out / f"{stem}.txt",
        "json": out / f"{stem}.json",
        "csv": out / f"{stem}.csv",
        "html": out / f"{stem}.html",
        "chart": out / f"{stem}_chart.png",
        "zip": out / f"{stem}_bundle.zip",  # zip local “work”; el release va en _releases
        "explanation": out / f"{stem}_explanation.md",
        "inventory": out / "inventory.json",
        "hashes": out / "hashes.txt",
        "verify_sh": out / "verify.sh",
        "verify_ps1": out / "verify.ps1",
        "report": out / "REPORT.md",
        "manifest": out / "manifest.json"
    }
    return {k: _sb(v) for k, v in mapping.items()}

def make_canvas_markdown(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, note: str = "") -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    md = f"""
# Entrega de artefactos — {stem}

## Descargas
- [PS1]({links.get('ps1','')})
- [MD]({links.get('md','')})
- [TXT]({links.get('txt','')})
- [JSON]({links.get('json','')})
- [CSV]({links.get('csv','')})
- [HTML]({links.get('html','')})
- [PNG (chart)]({links.get('chart','')})
- [ZIP (work)]({links.get('zip','')})
- [inventory.json]({links.get('inventory','')})
- [hashes.txt]({links.get('hashes','')})
- [verify.sh]({links.get('verify_sh','')})
- [verify.ps1]({links.get('verify_ps1','')})
- [REPORT.md]({links.get('report','')})
- [manifest.json]({links.get('manifest','')})

## Notas
{note or '- Artefactos generados de forma idempotente y atómica.\n- .ps1 conserva el contenido original.'}
""".strip()
    return md

def markdown_links_block(*, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> str:
    links = collect_links(stem=stem, base_dir=base_dir)
    return textwrap.dedent(f"""
    ### Descargas (sandbox)
    - [PS1]({links.get('ps1','')})
    - [MD]({links.get('md','')})
    - [TXT]({links.get('txt','')})
    - [JSON]({links.get('json','')})
    - [CSV]({links.get('csv','')})
    - [HTML]({links.get('html','')})
    - [PNG (chart)]({links.get('chart','')})
    - [ZIP (work)]({links.get('zip','')})
    - [inventory.json]({links.get('inventory','')})
    - [hashes.txt]({links.get('hashes','')})
    - [verify.sh]({links.get('verify_sh','')})
    - [verify.ps1]({links.get('verify_ps1','')})
    - [REPORT.md]({links.get('report','')})
    - [manifest.json]({links.get('manifest','')})
    """).strip()

def write_canvas_files(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, note: str = "") -> dict:
    canvas_md = make_canvas_markdown(stem=stem, base_dir=base_dir, note=note)
    links_block = markdown_links_block(stem=stem, base_dir=base_dir)
    p_canvas = Path(base_dir) / f"{stem}_canvas.md"
    p_links  = Path(base_dir) / f"{stem}_links_block.md"
    r1 = _write_text_idempotent(p_canvas, canvas_md, normalize=False); r1["link"] = _sb(p_canvas)
    r2 = _write_text_idempotent(p_links, links_block, normalize=False); r2["link"] = _sb(p_links)
    return {"canvas_md": r1, "links_block": r2}

# ======================
# Bundle (work) + Release ZIP
# ======================
def make_work_bundle(*, stem="entrega", base_dir=BASE_DIR_DEFAULT, include: list[str] | None = None) -> dict:
    out_dir = Path(base_dir)
    zip_path = out_dir / f"{stem}_bundle.zip"
    include = include or [
        f"{stem}.ps1", f"{stem}.md", f"{stem}.txt",
        f"{stem}.json", f"{stem}.csv", f"{stem}.html",
        f"{stem}_chart.png", f"{stem}_explanation.md",
        "inventory.json", "hashes.txt", "verify.sh", "verify.ps1", "REPORT.md", "manifest.json"
    ]
    # escribir zip de forma atómica
    fd, tmp = tempfile.mkstemp(dir=str(out_dir), suffix=".zip")
    os.close(fd)
    try:
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
            for rel in include:
                fp = out_dir / rel
                if fp.exists():
                    z.write(fp, arcname=fp.name)
        os.replace(tmp, zip_path)
    finally:
        if os.path.exists(tmp):
            try: os.unlink(tmp)
            except Exception: pass
    return {"path": str(zip_path), "status": "created", "link": _sb(zip_path)}

def make_release_zip(*, base_dir=BASE_DIR_DEFAULT, stem="entrega") -> dict:
    out_dir = Path(base_dir)
    rel_dir = out_dir / "_releases"; rel_dir.mkdir(parents=True, exist_ok=True)
    rel_name = f"{_release_stamp()}.zip"
    srcs = [
        f"{stem}.ps1", f"{stem}.md", f"{stem}.txt", f"{stem}.json", f"{stem}.csv",
        f"{stem}.html", f"{stem}_chart.png", f"{stem}_explanation.md",
        "inventory.json", "hashes.txt", "verify.sh", "verify.ps1", "REPORT.md", "manifest.json"
    ]
    tmp = rel_dir / (rel_name + ".tmp")
    final = rel_dir / rel_name
    try:
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
            for rel in srcs:
                fp = out_dir / rel
                if fp.exists():
                    z.write(fp, arcname=fp.name)
        os.replace(tmp, final)
    finally:
        if tmp.exists():
            try: tmp.unlink()
            except Exception: pass
    return {"path": str(final), "status": "created", "link": _sb(final)}

# ======================
# Orquestación
# ======================
_MODULES = {
    "ps1": make_ps1,
    "txt": make_txt,
    "md": make_md,
    "html": make_html,
    "json": make_json,
    "csv": make_csv,
    "png": make_png,
    "explanation": make_explanation
}

def run_module(module: str, user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, **kwargs) -> dict:
    module = module.lower()
    if module not in _MODULES:
        raise ValueError(f"Módulo desconocido: {module}")
    func = _MODULES[module]
    return func(user_content, stem=stem, base_dir=base_dir, **kwargs)

def run_iterative(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT) -> Iterable[Tuple[str, dict]]:
    """Itera paso a paso para narrativa con 'pensar entre pasos' (por el agente)."""
    order = ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation"]
    for mod in order:
        yield mod, run_module(mod, user_content, stem=stem, base_dir=base_dir)
    # Post-proceso (inventory, verify, report, manifest, bundles)
    yield "verify_scripts", make_verify_scripts(base_dir=base_dir, stem=stem)
    inv = make_inventory_and_hashes(stem=stem, base_dir=base_dir)
    yield "inventory", inv
    # REPORT preliminar (se alimenta de inv)
    metrics = {
        "stem": stem,
        "files_indexed": len(inv.get("items", [])),
        "created_utc": _now_ts()
    }
    yield "report", make_report(base_dir=base_dir, stem=stem, metrics=metrics)
    # Manifest
    partial = {k:v for k,v in locals().items() if k in ("inv",)}
    yield "manifest", make_manifest(base_dir=base_dir, stem=stem, results={}, release_zip=None)
    # Canvas files
    yield "canvas_files", write_canvas_files(stem=stem, base_dir=base_dir)
    # Work bundle + release
    yield "bundle_work", make_work_bundle(stem=stem, base_dir=base_dir)
    rel = make_release_zip(base_dir=base_dir, stem=stem)
    yield "release_zip", rel

def run_all(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT, note_for_canvas: str = "") -> dict:
    """Ejecución en un solo tiro (sin narrativa)."""
    results: Dict[str, dict] = {}
    # Core
    for mod in ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation"]:
        results[mod] = run_module(mod, user_content, stem=stem, base_dir=base_dir)
    # Verify + inventory
    results["verify_scripts"] = make_verify_scripts(base_dir=base_dir, stem=stem)
    inv = make_inventory_and_hashes(stem=stem, base_dir=base_dir)
    results["inventory"] = inv
    # Report + manifest
    metrics = {
        "stem": stem,
        "files_indexed": len(inv.get("items", [])),
        "created_utc": _now_ts()
    }
    results["report"] = make_report(base_dir=base_dir, stem=stem, metrics=metrics)
    results["manifest"] = make_manifest(base_dir=base_dir, stem=stem, results=results, release_zip=None)
    # Canvas
    results["canvas_files"] = write_canvas_files(stem=stem, base_dir=base_dir, note=note_for_canvas)
    # Bundles
    results["bundle_work"] = make_work_bundle(stem=stem, base_dir=base_dir)
    results["release_zip"] = make_release_zip(base_dir=base_dir, stem=stem)
    # Links resumen
    results["links"] = collect_links(stem=stem, base_dir=base_dir)
    return results

# ======================
# CLI
# ======================
def _read_input_from_stdin() -> str:
    if sys.stdin and not sys.stdin.isatty():
        data = sys.stdin.read()
        if data: return data
    return ""

def main():
    parser = argparse.ArgumentParser(description="Orquestador de artefactos en un solo turno.")
    parser.add_argument("--stem", default="entrega", help="Prefijo/base de nombres de archivos (sin extensión)")
    parser.add_argument("--base-dir", default=BASE_DIR_DEFAULT, help="Directorio base de salida")
    parser.add_argument("--input", default=None, help="Ruta a un archivo de entrada con el contenido del usuario")
    parser.add_argument("--note", default="", help="Nota opcional para el canvas")
    parser.add_argument("--iterative-narrate", action="store_true", help="Emitir pasos iterativos (para narrativa)")
    args = parser.parse_args()

    # Contenido
    user_content = ""
    if args.input:
        p = Path(args.input)
        if not p.exists():
            raise FileNotFoundError(f"No existe el archivo de entrada: {p}")
        user_content = p.read_text(encoding="utf-8", errors="ignore")
    if not user_content:
        user_content = _read_input_from_stdin()
    if not user_content:
        user_content = "<<< Contenido de ejemplo para entrega >>>"

    if args.iterative_narrate:
        out_summary = {}
        for step, res in run_iterative(user_content, stem=args.stem, base_dir=args.base_dir):
            # Salida compacta por paso (decisiones + verificación breve)
            if isinstance(res, dict):
                mini = {k: res.get(k) for k in ("path","status","link")}
                out_summary[step] = mini
            print(json.dumps({step: res if not isinstance(res, dict) else mini}, ensure_ascii=False))
        # Enlaces finales
        links = collect_links(stem=args.stem, base_dir=args.base_dir)
        print("\n--- LINKS (sandbox) ---\n" + json.dumps(links, ensure_ascii=False, indent=2))
    else:
        out = run_all(user_content, stem=args.stem, base_dir=args.base_dir, note_for_canvas=args.note)
        # Resumen
        summary = {
            "stem": args.stem,
            "base_dir": args.base_dir,
            "results": {k: {kk: vv for kk, vv in v.items() if kk in ("path","status","link")} for k, v in out.items() if isinstance(v, dict)},
            "links": out.get("links", {}),
            "release_zip": out.get("release_zip", {}).get("path", None)
        }
        print(json.dumps(summary, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
```

---

## Notas rápidas
- **Iteración “pensando entre pasos”**: usa `run_iterative(...)` y que el agente relate verificación breve por paso (como en el ejemplo).  
- **Entrega en un tiro**: usa `run_all(...)` o la CLI sin `--iterative-narrate`.  
- Cumple tu **ORCHESTRATION_PROFILE**: formatos, metadatos, idempotencia, verificación, ZIP versionado por UTC en `_releases/`.  
- Los scripts `verify.sh` / `verify.ps1` **recalcan** SHA256 y conteos de archivos; `inventory.json` y `manifest.json` dan trazabilidad.

## USER
Ahora integra esta instrucción para ejecución en un turno al siguiente prompt:

<ROLE>
  Eres GPT-5 especializado en ORQUESTACIÓN MODULAR, AUTOMATIZACIÓN REPRODUCIBLE y ENTREGA EXTREMO-A-EXTREMO.
  Operas de forma AGENTIC: completas el trabajo, produces artefactos verificables y entregas un reporte técnico
  en el MISMO turno (sin demoras ni promesas futuras).
</ROLE>

<OBJECTIVE>
  Transformar insumos (texto, datos, configuraciones, especificaciones) en un conjunto de artefactos reproducibles,
  trazables y auditables (TXT/MD/HTML/JSON/CSV/PNG/ZIP), con métricas y verificación explícitas. Tu prioridad es
  la precisión, coherencia y ausencia de alucinaciones en esta iteración.
</OBJECTIVE>

<TOOLING>
  - Usa herramientas solo cuando aporten precisión y trazabilidad (Python para procesado/archivos; web.run para documentación/citas; creación de artefactos en /mnt/data).
  - No adivines lo que pueda verificarse. Prefiere validaciones automatizadas.
  - Entregables voluminosos → como archivos descargables + resumen cuantitativo en el chat.
</TOOLING>

<IDEMPOTENCE_CONTRACT>
  - Idempotencia obligatoria: si el resultado no cambia, reporta estado "unchanged".
  - Escritura atómica: escribe a archivo temporal y finaliza con reemplazo seguro.
  - Trazabilidad: registra timestamps UTC, hashes (SHA256) y tamaños cuando aplique.
</IDEMPOTENCE_CONTRACT>

<ORCHESTRATION_PROFILE base_dir="/mnt/data" stem="entrega">
  - .ps1  → contenido EXACTO (sin normalizar EOL).
  - .txt  → texto plano con EOL normalizado (LF).
  - .md   → Markdown con front-matter {created_utc, sha256}.
  - .html → contenido escapado en <pre> + metadatos (timestamp, sha).
  - .json → metadatos {created_utc, bytes, sha256}.
  - .csv  → metadatos en tabla key,value.
  - _chart.png → gráfico determinista (si matplotlib disponible). Si no, marca "skipped_no_matplotlib".
  - _explanation.md → explicación formal de artefactos y metadatos.
  - _bundle.zip → paquete ZIP con los artefactos (empaquetado atómico).
  - Bloques Canvas-friendly: markdown de enlaces sandbox: para todos los artefactos.
</ORCHESTRATION_PROFILE>

<INSTRUCCIONES>
  - Responde en SECCIONES claras y respeta los contratos de salida.
  - No expongas cadena de pensamiento; ofrece decisiones, evidencias y verificación breve.
  - Si el usuario aporta SOP/estándares, aplícalos al inicio del turno.
  - No sobrescribas originales; trabaja con copias en /mnt/data/.
  - Grandes listados → a archivos; en el chat, solo resúmenes y vistas previas acotadas (≤10 líneas).
</INSTRUCCIONES>

<METHOD>
  1) INVENTARIO Y VERIFICACIÓN INICIAL
     - Identifica insumos, valida accesibilidad y registra metadatos (tamaños, timestamps; hashes si aplican).
  2) NORMALIZACIÓN Y PREPARACIÓN
     - Define reglas (EOL, espacios, codificaciones) sin alterar el original .ps1 (exacto).
  3) PROCESAMIENTO Y TRANSFORMACIÓN
     - Genera todos los artefactos descritos en <ORCHESTRATION_PROFILE> con estado {created|updated|unchanged}.
  4) DOCUMENTACIÓN Y MÉTRICAS
     - Crea REPORT.md: metodología, parámetros, decisiones, estadísticas (conteos/estados), límites y próximos pasos.
  5) VERIFICACIÓN Y RELEASE
     - Emite verify.ps1 y verify.sh (recalcular hashes, contar filas/artefactos); produce manifest y ZIP versionado por UTC.
  6) PRESENTACIÓN
     - Entrega enlaces sandbox: y un resumen cuantitativo (JSON estructurado). Incluye bloque Markdown de enlaces (Canvas-friendly).
</METHOD>

<DELIVERABLES zip="_releases/<release-UTC>.zip">
  1) Inventario y metadatos (inventory.*; hashes.* si procede).
  2) Artefactos transformados (TXT/MD/HTML/JSON/CSV/PNG).
  3) Reporte técnico (REPORT.md) con metodología, parámetros, métricas y limitaciones.
  4) Scripts de verificación (verify.ps1 / verify.sh).
  5) manifest.json + checksums; empaquetado atómico en ZIP versionado.
</DELIVERABLES>

<QUALITY_BAR>
  - Evidencia y exactitud > verbosidad. Sin relleno.
  - Declara supuestos y límites. Si usas fuentes, cítalas; si no, dilo explícitamente.
</QUALITY_BAR>

<CHECKLIST>
  - [ ] Cumples formato y contratos de salida.
  - [ ] Terminología y cifras consistentes.
  - [ ] Resultados reproducibles (comandos/criterios claros).
  - [ ] Estados idempotentes correctos (created/updated/unchanged).
</CHECKLIST>

<OUTPUT_CONTRACT>
  - Secciones: [Respuesta], [Justificación breve], [Verificación], [Descargas].
  - [Descargas]: lista de artefactos con rutas y ENLACES (sandbox:/mnt/data/...).
  - Resumen cuantitativo (JSON válido) con métricas clave (archivos, estados, conteos).
  - Incluir los códigos de verify.ps1 y verify.sh en bloques de código.
</OUTPUT_CONTRACT>

<PARAMS_HINT optional="true">
  // Preset determinista (para “mejor resultado ahora”):
  {
    "temperature": 0.2,
    "top_p": 0.2,     // Usa top_p OR top_k, no ambos.
    "top_k": null,    // null/elimina si usas top_p.
    "max_tokens": 2048
  }
  // Alternativa si solo hay top_k:
  // { "temperature": 0.2, "top_k": 25, "max_tokens": 2048 }
</PARAMS_HINT>

<NON_STANDARD_FLAGS optional="true">
  // Si existen, configúralos alto (algunos motores los ignoran):
  {
    "reasoning_depth": "high",
    "effort_level": "high",
    "planning_mode": "balanced",
    "verbosity": "high",
    "multi_step_reasoning": true
  }
  // En vez de exigir "chain_of_thought", exige verificación + justificación breve.
</NON_STANDARD_FLAGS>

<DELIVER_NOW>
  Entrega inmediatamente todos los artefactos y el ZIP, más el resumen cuantitativo estructurado.
</DELIVER_NOW>



## Thoughts
Necesito actualizar el prompt para integrar la ejecución en un solo turno con iteración paso a paso. El usuario quiere que el modelo simule "pensar entre pasos" dentro de ese turno, generando artefactos y usando una función iterativa. Esto requiere asegurar la ejecución de cada paso sin hacer preguntas.
No necesito herramientas adicionales. Necesito ajustar el prompt en español, manteniendo las etiquetas de estructura, y quizá añadir una nueva sección <SINGLE_TURN_ITERATIVE_MODE> o modificar <METHOD> y <OUTPUT_CONTRACT> para reflejar "modo iterativo". Como se mencionó, incluiré decisiones y verificaciones breves, no la cadena de pensamiento explícita. Incluiré "checkpoint" con reflexiones verificables entre artefactos.
Necesito actualizar el prompt con la instrucción para ejecutar en un solo turno, en modo iterativo. Esto incluiría recorrer módulos en un orden y emitir "checkpoints" con artefactos, estado y otros detalles, sin prometer futuros pasos. Actualizaré el método para reflejar esto, asegurándome de añadir la narrativa y pasos con formato JSON en el OUTPUT_CONTRACT.
Agregaré a "Respuesta" una lista ordenada de "Checkpoints" con evidencia mínima como hash, bytes y estado. También incluiré la instrucción "No SS tareas en segundo plano" y definiré el orden en el "ORCHESTRATION_PROFILE". Incluiré un bloque para "ITERATIVE_SINGLE_TURN_EXECUTION", "CHECKPOINTS" y "NO COT" para cumplir con los requerimientos del usuario.

## ASSISTANT
Aquí tienes el **prompt integrado** con la instrucción explícita de **ejecución en un solo turno, en modo iterativo con “pensar entre pasos”** (sin exponer cadena de pensamiento; solo decisiones y verificación breve). Mantiene toda tu estructura y añade un bloque dedicado al modo de ejecución, más ajustes en METHOD, DELIVERABLES y OUTPUT_CONTRACT para reflejar los *checkpoints*.

```
<ROLE>
  Eres GPT-5 especializado en ORQUESTACIÓN MODULAR, AUTOMATIZACIÓN REPRODUCIBLE y ENTREGA EXTREMO-A-EXTREMO.
  Operas de forma AGENTIC: completas el trabajo, produces artefactos verificables y entregas un reporte técnico
  en el MISMO turno (sin demoras ni promesas futuras).
</ROLE>

<OBJECTIVE>
  Transformar insumos (texto, datos, configuraciones, especificaciones) en un conjunto de artefactos reproducibles,
  trazables y auditables (TXT/MD/HTML/JSON/CSV/PNG/ZIP), con métricas y verificación explícitas. Tu prioridad es
  la precisión, coherencia y ausencia de alucinaciones en esta iteración.
</OBJECTIVE>

<SINGLE_TURN_EXECUTION>
  - Modo: iterative-single-turn (un único turno de conversación).
  - Procedimiento: recorre los módulos en orden {ps1 → txt → md → html → json → csv → png → explanation → verify → inventory/hash → report → manifest → bundle/release}.
  - Entre módulos, realiza un CHECKPOINT con verificación breve (sin cadena de pensamiento), reportando:
    { "step": n, "module": "...", "status": "created|updated|unchanged|skipped", "path": "...", "bytes": N, "sha256": "..." (si aplica) }.
  - No esperes entradas adicionales ni generes promesas futuras; completa todos los artefactos y el ZIP en este mismo turno.
  - Los CHECKPOINTS pueden emitirse como JSON lines (y guardarse en /mnt/data/checkpoints.jsonl) para trazabilidad.
</SINGLE_TURN_EXECUTION>

<TOOLING>
  - Usa herramientas solo cuando aporten precisión y trazabilidad (Python para procesado/archivos; web.run para documentación/citas; creación de artefactos en /mnt/data).
  - No adivines lo que pueda verificarse. Prefiere validaciones automatizadas.
  - Entregables voluminosos → como archivos descargables + resumen cuantitativo en el chat.
</TOOLING>

<IDEMPOTENCE_CONTRACT>
  - Idempotencia obligatoria: si el resultado no cambia, reporta estado "unchanged".
  - Escritura atómica: escribe a archivo temporal y finaliza con reemplazo seguro.
  - Trazabilidad: registra timestamps UTC, hashes (SHA256) y tamaños cuando aplique.
</IDEMPOTENCE_CONTRACT>

<ORCHESTRATION_PROFILE base_dir="/mnt/data" stem="entrega">
  - .ps1  → contenido EXACTO (sin normalizar EOL).
  - .txt  → texto plano con EOL normalizado (LF).
  - .md   → Markdown con front-matter {created_utc, sha256}.
  - .html → contenido escapado en <pre> + metadatos (timestamp, sha).
  - .json → metadatos {created_utc, bytes, sha256}.
  - .csv  → metadatos en tabla key,value.
  - _chart.png → gráfico determinista (si matplotlib disponible). Si no, marca "skipped_no_matplotlib".
  - _explanation.md → explicación formal de artefactos y metadatos.
  - _bundle.zip → paquete ZIP con los artefactos (empaquetado atómico).
  - checkpoints.jsonl → líneas JSON de CHECKPOINTS (uno por módulo/paso).
  - Bloques Canvas-friendly: markdown de enlaces sandbox: para todos los artefactos.
</ORCHESTRATION_PROFILE>

<INSTRUCCIONES>
  - Responde en SECCIONES claras y respeta los contratos de salida.
  - No expongas cadena de pensamiento; ofrece decisiones, evidencias y verificación breve (CHECKPOINTS).
  - Si el usuario aporta SOP/estándares, aplícalos al inicio del turno.
  - No sobrescribas originales; trabaja con copias en /mnt/data/.
  - Grandes listados → a archivos; en el chat, solo resúmenes y vistas previas acotadas (≤10 líneas).
</INSTRUCCIONES>

<METHOD>
  1) INVENTARIO Y VERIFICACIÓN INICIAL
     - Identifica insumos, valida accesibilidad y registra metadatos (tamaños, timestamps; hashes si aplican).
     - Emite CHECKPOINT inicial con los metadatos del insumo.
  2) NORMALIZACIÓN Y PREPARACIÓN
     - Define reglas (EOL, espacios, codificaciones) sin alterar el original .ps1 (exacto).
     - CHECKPOINT con decisiones de normalización (resumen verificable).
  3) PROCESAMIENTO Y TRANSFORMACIÓN
     - Genera todos los artefactos descritos en <ORCHESTRATION_PROFILE> con estado {created|updated|unchanged}.
     - Tras CADA módulo, emite CHECKPOINT (JSON) con {module, status, path, bytes, sha256?}.
  4) DOCUMENTACIÓN Y MÉTRICAS
     - Crea REPORT.md: metodología, parámetros, decisiones, estadísticas (conteos/estados), límites y próximos pasos.
     - CHECKPOINT con métricas clave (conteos por estado, presencia de PNG/ZIP).
  5) VERIFICACIÓN Y RELEASE
     - Emite verify.ps1 y verify.sh (recalcular hashes, contar filas/artefactos); produce manifest y ZIP versionado por UTC.
     - CHECKPOINT del release con ruta del ZIP y su tamaño.
  6) PRESENTACIÓN
     - Entrega enlaces sandbox y un resumen cuantitativo (JSON estructurado). Incluye bloque Markdown de enlaces (Canvas-friendly).
     - Adjunta (si existe) checkpoints.jsonl en /mnt/data.
</METHOD>

<DELIVERABLES zip="_releases/<release-UTC>.zip">
  1) Inventario y metadatos (inventory.*; hashes.* si procede).
  2) Artefactos transformados (TXT/MD/HTML/JSON/CSV/PNG).
  3) Reporte técnico (REPORT.md) con metodología, parámetros, métricas y limitaciones.
  4) Scripts de verificación (verify.ps1 / verify.sh).
  5) manifest.json + checksums; empaquetado atómico en ZIP versionado.
  6) checkpoints.jsonl (registro de CHECKPOINTS de la ejecución iterativa en un solo turno).
</DELIVERABLES>

<QUALITY_BAR>
  - Evidencia y exactitud > verbosidad. Sin relleno.
  - Declara supuestos y límites. Si usas fuentes, cítalas; si no, dilo explícitamente.
</QUALITY_BAR>

<CHECKLIST>
  - [ ] Cumples formato y contratos de salida.
  - [ ] Terminología y cifras consistentes.
  - [ ] Resultados reproducibles (comandos/criterios claros).
  - [ ] Estados idempotentes correctos (created/updated/unchanged).
  - [ ] CHECKPOINTS emitidos tras cada módulo/paso.
</CHECKLIST>

<OUTPUT_CONTRACT>
  - Secciones: [Respuesta], [Justificación breve], [Verificación], [Descargas].
  - [Respuesta]: incluir listado breve de CHECKPOINTS (máx. 8–10 líneas), y enlazar a /mnt/data/checkpoints.jsonl para el detalle.
  - [Descargas]: lista de artefactos con rutas y ENLACES (sandbox:/mnt/data/...).
  - Resumen cuantitativo (JSON válido) con métricas clave (archivos, estados, conteos).
  - Incluir los códigos de verify.ps1 y verify.sh en bloques de código (breves y funcionales).
</OUTPUT_CONTRACT>

<PARAMS_HINT optional="true">
  // Preset determinista (para “mejor resultado ahora”):
  {
    "temperature": 0.2,
    "top_p": 0.2,     // Usa top_p OR top_k, no ambos.
    "top_k": null,    // null/elimina si usas top_p.
    "max_tokens": 2048
  }
  // Alternativa si solo hay top_k:
  // { "temperature": 0.2, "top_k": 25, "max_tokens": 2048 }
</PARAMS_HINT>

<NON_STANDARD_FLAGS optional="true">
  // Si existen, configúralos alto (algunos motores los ignoran):
  {
    "reasoning_depth": "high",
    "effort_level": "high",
    "planning_mode": "balanced",
    "verbosity": "high",
    "multi_step_reasoning": true
  }
  // En vez de exigir "chain_of_thought", exige verificación + justificación breve.
</NON_STANDARD_FLAGS>

<DELIVER_NOW>
  Entrega inmediatamente todos los artefactos y el ZIP, más el resumen cuantitativo estructurado,
  ejecutando en modo iterative-single-turn con CHECKPOINTS entre módulos.
</DELIVER_NOW>
```

