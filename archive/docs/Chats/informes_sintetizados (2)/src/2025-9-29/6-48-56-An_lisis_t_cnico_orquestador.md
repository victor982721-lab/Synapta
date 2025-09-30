# Análisis técnico orquestador

https://chat.openai.com/c/68da8036-9d28-8331-800c-addf7274479d

## USER
Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~
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
~~~~~

## Thoughts
Estoy pensando que el escritor de CSV usa los valores predeterminados del módulo csv para el dialecto Excel, lo que afecta los saltos de línea. De forma predeterminada, csv usa '\r\n' en Windows y parece que eso se mantiene incluso en Linux si se configura `normalize=False`. StringIO, en cambio, usa '\n'. Sin ejecutar código, solo analizo el comportamiento esperado.
El script `verify.sh` usa `sha256sum` o `shasum` como alternativa, y cuenta los archivos con `ls -1 "$STEM"*`. Podría contar más de la cuenta si incluye archivos como ps1/ps1, pero aún así es aceptable. En cuanto a `verify.ps1`, usa `Write-Host`, lo cual no es óptimo según algunas guías, pero está bien como mejora opcional.
El script `verify.ps1` usa `Write-Host`, cuyo uso no se recomienda siempre, pero en este caso está bien a modo de mejora opcional. El archivo `REPORT.md` genera métricas correctamente. Además, `make_manifest` itera sobre el diccionario de resultados mientras maneja `bytes` y `sha256` con `fp.exists`, lo cual es adecuado. En general, todo parece estar bien implementado.
El uso de `Write-Host` en `verify.ps1` no es ideal, pero aquí no es un problema grave, aunque podría ser mejor evitarlo. El archivo `REPORT.md` genera métricas de manera correcta. Hay varios detalles en la implementación de los scripts como `make_manifest`, `make_work_bundle`, y `make_release_zip`, todo parece estar bien. Sin embargo, hay un posible error en el manifiesto que podría generar problemas debido a variables no utilizadas.
El código tiene varios aspectos positivos, como el uso de hashing eficiente y la seguridad en la manipulación de archivos. Sin embargo, hay algunas omisiones y posibles mejores prácticas que se podrían aplicar, como actualizar el manifiesto después de la creación del `release_zip` o mejorar la recopilación de enlaces. También se podrían incluir verificaciones adicionales y manejar algunos casos borde, como los archivos grandes.

Se proponen parches pequeños a la implementación, como la mejora de la función de generación del manifiesto y la integración más eficiente de elementos como la URL del `release_zip`.

## ASSISTANT
# Análisis técnico detallado — `orchestrator_single_turn.py`

A continuación desgloso la finalidad, el flujo, los artefactos que genera, garantías (idempotencia, atomicidad), portabilidad, casos borde y **hallazgos con parches propuestos**.

---

## 1) Propósito y alcance

Script de **orquestación “one-shot”** que, a partir de un `user_content` (texto arbitrario, p.ej. un bloque PowerShell), produce un **conjunto completo de artefactos** en `/mnt/data` (por defecto), con **escritura atómica**, **idempotencia por SHA-256**, **inventario y hashes**, **scripts de verificación**, **reporte**, **manifest**, **bundle ZIP de trabajo** y **release ZIP** con sello UTC seguro para Windows.

Arquitectura limpia y modular: funciones `make_*` para cada salida, una capa de utilidades de E/S segura, y dos modos de ejecución (`run_all` y `run_iterative`) además de un **CLI**.

---

## 2) Flujo de ejecución

### `run_all(user_content, stem, base_dir, note_for_canvas)`
1. Genera en orden: `ps1`, `txt`, `md`, `html`, `json`, `csv`, `png` (si hay matplotlib), `*_explanation.md`.
2. Crea `verify.sh` y `verify.ps1`.
3. Genera `inventory.json` + `hashes.txt`.
4. Construye `REPORT.md` con métricas simples.
5. Genera `manifest.json` **(sin incluir el release ZIP, porque aún no existe en este punto)**.
6. Crea archivos para “canvas” (`*_canvas.md`, `*_links_block.md`).
7. Empaqueta **work bundle** (`*_bundle.zip`).
8. Crea **release ZIP** en `_releases/<UTC>.zip`.
9. Devuelve un diccionario con resultados y bloque de **links** sandbox.

### `run_iterative(...)`
Emite pares `(paso, resultado)` en secuencia similar y, al final, imprime links. **Ojo**: crea `manifest.json` **con `results={}` y `release_zip=None`**; el manifest queda “vacío” (véase hallazgos).

---

## 3) Artefactos generados

- `stem.ps1` — **contenido exacto** (EOL sin normalizar).
- `stem.txt` — texto normalizado a LF.
- `stem.md` — Markdown con *front-matter* `created_utc` y `sha256` del **user_content**.
- `stem.html` — HTML minimal escapando el contenido.
- `stem.json` — metadatos `{created_utc, bytes, sha256}` (del user_content).
- `stem.csv` — los mismos metadatos en CSV.
- `stem_chart.png` — gráfico simple determinista (si `matplotlib` disponible).
- `stem_explanation.md` — explicación resumida de qué se generó.
- `verify.sh` / `verify.ps1` — recomputan SHA-256 y cuentan artefactos.
- `inventory.json` — listado con `{path, name, bytes, mtime_utc, sha256}`.
- `hashes.txt` — estilo `sha256sum`.
- `REPORT.md` — parámetros, métricas y metodología.
- `manifest.json` — metadatos agregados (ver hallazgos).
- `*_bundle.zip` — ZIP “work”.
- `_releases/<AAAA-MM-DDTHH-MM-SSZ>.zip` — ZIP “release” con timestamp **safe**.

---

## 4) Garantías de E/S

- **Escritura atómica**: `_atomic_write_bytes()` usa `mkstemp` + `os.replace()`.
- **Idempotencia**: `_write_*_idempotent` compara **SHA-256** de bytes existentes vs nuevos:
  - Si iguales → `status: "unchanged"`.
  - Si difieren → `"updated"`; si no existía → `"created"`.

**Normalización de EOL**:
- `ps1` → **no normaliza** (conserva bytes tal cual).
- `txt` → normaliza a LF.
- `md` → normaliza el cuerpo del user_content (LF) pero no el archivo resultante (ya armado).
- `csv` → no fuerza normalización (ver observación sobre `\r\n` más abajo).

---

## 5) Verificación, inventario y trazabilidad

- `inventory.json` y `hashes.txt` permiten **reproducir y verificar** el set generado.
- `verify.sh` usa `sha256sum` o `shasum -a 256`; `verify.ps1` usa `Get-FileHash`.
- `REPORT.md` documenta parámetros, contadores y metodología.
- `manifest.json` agrega snapshot con **sha256 y bytes por artefacto** (si se pasó un `results` completo).

---

## 6) Portabilidad y compatibilidad

- Paths y nombres: `release` usa `YYYY-MM-DDTHH-MM-SSZ` (sin `:`) → **compatible Windows**.
- `verify.sh`: Linux/macOS; `verify.ps1`: **PowerShell 5+** (tiene `#requires -Version 5`).
- Gráfico: condicional a `matplotlib` (si no, status `skipped_no_matplotlib`).
- Codificación: escritura en **UTF-8 (sin BOM)**. En Windows, algunos editores PS históricos predeterminaban UTF-16LE/BOM; hoy PS 5.1/7 manejan UTF-8 sin problema, pero es un **cambio cultural** a tener presente.

---

## 7) Calidad de diseño

- **Buena separación de responsabilidades** (`make_*` por tipo).
- **Determinismo razonable** (mismo input → mismos artefactos), salvo los que incluyen timestamps.
- **Sólida higiene de errores** en E/S (intentos de limpiar temporales; manejo de fallas de lectura).

---

## 8) Casos borde / consideraciones

- **Idempotencia “parcial”** por timestamps:
  - `md`, `html`, `json`, `csv` **siempre** cambiarán entre corridas por `created_utc`, aunque el contenido sea idéntico → se marcarán `"updated"`.
  - El **PNG** podría diferir entre corridas si `matplotlib` incrusta metadatos/tiempos; el código pretende ser determinista, pero no lo garantiza al 100% según backend.
- **CSV y finales de línea**: `csv.writer` sobre `StringIO` suele usar `\r\n`; al no normalizar, el archivo puede mezclar convenciones si se procesa en otros sistemas.
- **`ps1` en UTF-8 sin BOM**: perfecto hoy, pero puede sorprender a herramientas legadas en Windows.
- **Enlace a PNG cuando no existe**: en `skipped_no_matplotlib` se devuelve un link a una ruta que **no estará presente**; no rompe nada, pero el link 404 en sandbox puede confundir.
- **Conteo de artefactos** en `verify.*`: se hace con glob `"$STEM*"`; incluye también `*_bundle.zip`, `*_canvas.md`, etc. (intencional, pero acláralo en doc si buscas una métrica más estricta).

---

## 9) Hallazgos (con severidad) y parches sugeridos

### A. `manifest.json` incompleto en `run_iterative` (Crítico)
- **Qué pasa**: en `run_iterative`, se llama a:
  ```python
  yield "manifest", make_manifest(..., results={}, release_zip=None)
  ```
  y se crea una variable `partial = {k:v for k,v in locals().items() if k in ("inv",)}` que **no se usa**.
- **Impacto**: `manifest.json` no refleja artefactos ni release.
- **Arreglo mínimo**: acumular `results` como en `run_all` y volver a **actualizar** el manifest tras crear el release.
  
  **Patch (dif resumido):**
  ```diff
  def run_iterative(...):
-   for mod in order:
-       yield mod, run_module(...)
+   results = {}
+   for mod in order:
+       r = run_module(...)
+       results[mod] = r
+       yield mod, r

    yield "verify_scripts", make_verify_scripts(...)
    inv = make_inventory_and_hashes(...)
+   results["inventory"] = inv

    metrics = {...}
-   yield "report", make_report(...)
+   rpt = make_report(...)
+   results["report"] = rpt
-   yield "manifest", make_manifest(..., results={}, release_zip=None)
+   man = make_manifest(..., results=results, release_zip=None)
+   yield "manifest", man

    yield "canvas_files", write_canvas_files(...)
    yield "bundle_work", make_work_bundle(...)
-   rel = make_release_zip(...)
-   yield "release_zip", rel
+   rel = make_release_zip(...)
+   yield "release_zip", rel
+   # actualizar manifest con release
+   man2 = make_manifest(..., results=results, release_zip=Path(rel["path"]))
+   yield "manifest_updated", man2
  ```

### B. `run_all` no refleja `release_zip` en `manifest.json` (Alto)
- **Qué pasa**: el `manifest` se crea **antes** del release; nunca se re-emite.
- **Arreglo**: tras `make_release_zip`, volver a llamar a `make_manifest(..., release_zip=Path(results["release_zip"]["path"]))` y **sobrescribir** el manifest.

### C. Falta incluir el **release ZIP** en `collect_links()` / canvas (Medio)
- **Qué pasa**: los links incluyen sólo el ZIP de **work**. Para UX conviene exponer también el release.
- **Arreglo**: agregar una clave `release_zip`:
  ```diff
  def collect_links(...):
      mapping = {
         ...
-        "zip": out / f"{stem}_bundle.zip",
+        "zip": out / f"{stem}_bundle.zip",
+        "release_zip": out / "_releases" / f"{_release_stamp()}.zip"  # o mejor: leer del manifest
      }
  ```
  **Mejor**: leer la ruta real desde `manifest.json` si ya existe para no adivinar el nombre.

### D. Idempotencia de `md/html/json/csv` afectada por `created_utc` (Medio)
- **Qué pasa**: cada corrida marca `"updated"`.
- **Opciones**:
  1) **Mantenerlo** (válido si “creación” es parte del registro).
  2) Añadir `--freeze-timestamps <ISO>` para usos reproducibles.
  3) Permitir bandera `--no-front-matter`/`--no-meta` para md/html/json/csv.

### E. PNG potencialmente no determinista (Bajo)
- **Mitigación**: fijar `matplotlib` a backend consistente y **desactivar metadatos** (p.ej. `plt.savefig(..., metadata={"Software": ""})`) si aplica.

### F. `verify.ps1` usa `Write-Host` (Bajo)
- Si sigues estándares estrictos (no `Write-Host`), cambia a `Write-Output`.

### G. `make_csv` y finales de línea (Bajo)
- Para consistencia multiplataforma, puedes fijar `lineterminator="\n"`:
  ```diff
  buf = io.StringIO()
- w = csv.writer(buf)
+ w = csv.writer(buf, lineterminator="\n")
  ```

### H. Link a PNG cuando no hay `matplotlib` (Bajo)
- Evita publicar link a un archivo no creado; p.ej., sólo incluirlo en inventario si `status != skipped_no_matplotlib`.

---

## 10) Seguridad y saneamiento

- **HTML** escapa el contenido → evita inyección.
- **MD** incluye el `user_content` tal cual (después de normalizar EOL del cuerpo); correcto para auditoría. Si el contenido pudiera incluir secrets, considera un **modo redactado** (fuera del alcance actual).
- Escritura atómica + checksum → reduce riesgos de corrupción en cortes.

---

## 11) CLI y UX

- `--input` (archivo) o STDIN; si no hay entrada, usa placeholder.
- `--iterative-narrate` imprime pasos con resúmenes `{path,status,link}` + bloque de links final.
- `--note` se inserta en `*_canvas.md`.

**Sugerencia UX**: tras crear el release, imprimir explícitamente el link del release y su SHA-256 (disponible en `hashes.txt` si lo incluyes, o recalcular).

---

## 12) Conclusión

El orquestador está **bien diseñado**: seguro en E/S, claro, y con cobertura completa del ciclo *generar → verificar → empaquetar*. Los puntos a corregir son menores pero **mejoran mucho la trazabilidad**:

- **Corregir `manifest`** en ambos modos para que incluya **todos** los artefactos y el **release ZIP**.
- **Exponer el link del release** en los helpers/canvas.
- Considerar banderas para **congelar timestamps** y mejorar la **determinismo** de PNG/CSV.
- Pequeños ajustes de UX (`Write-Output`, links condicionales al PNG).

Si quieres, te dejo de inmediato un **patch consolidado** con los cambios A–C (o más) listo para aplicar.

