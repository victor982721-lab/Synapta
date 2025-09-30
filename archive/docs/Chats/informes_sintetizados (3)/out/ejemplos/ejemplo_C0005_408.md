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