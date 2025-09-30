from pathlib import Path

def verify_sandbox_links(links: dict) -> list[str]:
    errs = []
    for k, v in links.items():
        if not v or not v.startswith("sandbox:"):
            errs.append(f"{k}: enlace inválido '{v}'")
            continue
        p = Path(v.replace("sandbox:",""))
        if not p.exists():
            errs.append(f"{k}: no existe {p}")
        elif p.is_file() and p.stat().st_size == 0:
            errs.append(f"{k}: tamaño 0 bytes {p}")
    return errs

# Al final:
errs = verify_sandbox_links(collect_links(stem=stem, base_dir=base_dir))
if errs:
    raise RuntimeError("Link check FAILED:\n- " + "\n- ".join(errs))