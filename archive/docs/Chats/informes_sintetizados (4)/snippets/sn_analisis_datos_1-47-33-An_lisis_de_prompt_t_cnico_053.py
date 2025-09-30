for mod, result in run_iterative("Hola mundo", stem="demo"):
    print(f"{mod} -> {result['status']}")
    # Aquí podrías meter análisis, validación, incluso detener el loop si algo falla