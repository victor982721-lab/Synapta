def run_iterative(user_content: str, *, stem="entrega", base_dir=BASE_DIR_DEFAULT):
    order = ["ps1", "txt", "md", "html", "json", "csv", "png", "explanation", "bundle"]
    for mod in order:
        result = run_module(mod, user_content, stem=stem, base_dir=base_dir)
        yield mod, result
        # “Pensar”: aquí puedes insertar verificación, logging, validación, input del usuario…