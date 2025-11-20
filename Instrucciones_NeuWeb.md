# Instrucciones del proyecto "/Neurologic/Sandbox/Cortex/"

## Contexto

"Neurologic" es un hub con varios repositorios en diferentes entornos, cada uno con sus propias reglas que coexisten entre si.

La raíz `Neurologic/` se encuentra localmente en el entorno del usuario en la ruta: `C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic`,
guarda la documentación global:

- AGENTS.md
- Politica_Cultural_y_Calidad.md
- Preferencias_del_Usuario.md
- Readme.md
- Repo_Estructura_ASCII



  El proyecto Neurologic es un hub con varios repositorios y cada uno tiene sus propias reglas. La raíz `Neurologic/` guarda la documentación global
  (Política cultural, AGENTS general, Preferencias del usuario, Repo_Estructura_ASCII). Dentro de `Neurologic/Sandbox/` viven los proyectos en desarrollo
  (Cortex, Ws_Insights, etc.) y cada uno trae su propio `AGENTS.md`, README, docs, CSV, etc. En paralelo existe `Neurologic/Core/`, que es el repositorio
  canónico de librerías compartidas; cualquier artefacto que se use en varios proyectos debería residir ahí o promoverse desde Sandbox.

  El flujo de trabajo siempre es: 1) leer la Política y el AGENTS general, 2) leer el AGENTS específico del subproyecto donde se esté trabajando, 3) seguir
  el Procedimiento y la solicitud que estén en `docs/`. Las carpetas y archivos obligatorios (docs, csv, Scripts, src, tests, filemap, table_hierarchy,
  solicitud, bitácora) ya están definidos por las plantillas del proyecto, así que los agentes sólo deben completarlos, no cambiarlos. Siempre se desarrolla
  y prueba en Windows 10/11 con PowerShell 7.x, pero algunos proyectos (como Cortex) exigen que el resultado sea compatible también con Windows PowerShell
  5.1.

  Si la sesión necesita saber qué tocar, debe ir al subdirectorio correspondiente (por ejemplo `Neurologic/Sandbox/Cortex/`) y trabajar exclusivamente ahí,
  respetando los documentos existentes y actualizando AGENTS/README/solicitud/CSV cuando haga cambios. Nunca se ejecutan acciones globales sin revisar la
  documentación local primero.