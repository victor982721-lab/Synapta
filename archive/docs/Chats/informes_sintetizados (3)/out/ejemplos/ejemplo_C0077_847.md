```python
import zipfile, sys, json, importlib.util, pathlib, shutil

ZIP = r"C:\ruta\al\zip\TU_ARCHIVO.zip"  # <-- AJUSTA
BASE_DIR = pathlib.Path.home()/ "Desktop" / "workspace_wizard_out"
EXTRACT  = BASE_DIR / "zip_extract"
ARTI     = BASE_DIR / "artifacts"
STEM     = "workspace-wizard-ps5-7"

for p in (EXTRACT, ARTI):
    if p.exists(): shutil.rmtree(p)
    p.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(ZIP, "r") as zf:
    zf.extractall(EXTRACT)

modpath = None
for name in ("orquestador.py","orchestrator_modular.py","orchestrator.py","orquestador_modular.py"):
    hit = next(EXTRACT.rglob(name), None)
    if hit: modpath = hit; break
if not modpath:
    raise SystemExit("No se encontró orquestador.py/orchestrator_modular.py dentro del ZIP")

spec = importlib.util.spec_from_file_location(modpath.stem, str(modpath))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

USER_CONTENT = r"""<PEGA AQUÍ EL MISMO BLOQUE PowerShell COMPLETO QUE TE DI>"""

preflight_ok = False
try:
    preflight_ok = bool(mod.preflight())
except Exception:
    preflight_ok = False

err = ""
try:
    mod.run_all(user_content=USER_CONTENT, stem=STEM, base_dir=str(ARTI),
                note_for_canvas="", link_check=True, no_release=False)
except Exception as e:
    err = str(e)

(ARTI/"summary.json").write_text(json.dumps({
    "stem": STEM, "status_link_check":"", "preflight_ok": preflight_ok,
    "run_all_err": err, "base_dir": str(ARTI)
}, indent=2, ensure_ascii=False), encoding="utf-8")

print("OK ->", ARTI)
```