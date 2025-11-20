# Neurologic

Repositorio privado para el ecosistema **Neurologic/Synapta**: automatización, motores internos, indexadores y proyectos de escritorio.  Este README sirve como índice operativo y referencia para agentes (humanos o IA).  No es documentación pública.

## Documentos normativos globales

* **Política cultural y de calidad – Ecosistema Neurologic** – Define principios culturales y estándares técnicos mínimos que deben respetar todas las personas y agentes en cualquier proyecto.
* **AGENTS – Neurologic (General)** – Reglas específicas para el agente Codex al trabajar en este repositorio.  Refuerza multi‑target .NET, modularidad, reutilización de motores y entrega completa de código.
* **Preferencias del usuario** – Describe preferencias operativas del desarrollador: idioma, tono, formato de respuesta y entorno base (Windows 10, PowerShell 7.5.x, etc.).

Los AGENTS específicos de cada proyecto pueden **endurecer** estas reglas pero nunca rebajarlas.

## Cómo trabajar con un proyecto en Sandbox

Cada subproyecto dentro de `Sandbox/<Proyecto>` contiene su propia carpeta con sus documentos.  El flujo recomendado para un agente ChatGPT es:

1. **Leer los documentos normativos globales** mencionados arriba.
2. Entrar en `Sandbox/<Proyecto>/` y leer su `AGENTS.md` y `README.md`.
3. Abrir `docs/Procedimiento_Codex_<Proyecto>.md` (si existe) y seguir el flujo descrito allí: investigar el dominio, preparar la solicitud de artefactos, actualizar los CSV y jerarquías y entregar la carpeta final sin el procedimiento.

Una vez que ChatGPT produce la solicitud y los inventarios, la carpeta puede enviarse a Codex, quien generará módulos y artefactos conforme a los AGENTS y a la política.

## Estructura general del repositorio

La estructura de carpetas se describe en `Repo_Estructura_ASCII.md`, que ofrece un mapa ASCII con los principales directorios (Core y Sandbox).  Cada subproyecto de Sandbox sigue un patrón similar: contiene su propio `AGENTS.md`, `README.md`, un directorio `docs/` con plantillas y jerarquías, un directorio `csv/` para inventarios, una carpeta `Scripts/` con utilidades y carpetas `src/` y `tests/` para el código y las pruebas.
