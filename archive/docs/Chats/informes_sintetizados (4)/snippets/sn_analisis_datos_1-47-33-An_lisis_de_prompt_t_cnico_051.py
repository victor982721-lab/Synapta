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