# orquestador.py
if __name__ == "__main__":
    import argparse, sys, pathlib
    ap = argparse.ArgumentParser()
    ap.add_argument("--stem", required=True)
    ap.add_argument("--input-file", help="Ruta con contenido a procesar; usa - para STDIN")
    ap.add_argument("--note", default="")
    ap.add_argument("--no-release", action="store_true")
    args = ap.parse_args()

    content = sys.stdin.read() if args.input_file == "-" else pathlib.Path(args.input_file).read_text(encoding="utf-8")
    preflight()
    # Orquestación mínima
    for _step, _ in run_iterative(content, stem=args.stem, base_dir=str(pathlib.Path(__file__).parent)):
        pass
    if not args.no_release:
        # Si tu ‘run_iterative’ ya libera, omite o convierte a flag interno
        ...