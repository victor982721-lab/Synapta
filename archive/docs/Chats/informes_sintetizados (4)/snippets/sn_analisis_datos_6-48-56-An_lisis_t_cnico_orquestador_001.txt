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