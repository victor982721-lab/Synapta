<#
.SYNOPSIS   
Herramienta interactiva para administrar repositorios del ecosistema Synapta/Neurologic desde una sola consola.

DESCRIPTION
RepoMaster automatiza tareas frecuentes sobre repositorios Git alojados bajo una ruta base (por defecto, `Documents\GitHub`) y se adapta al entorno de trabajo del usuario (Windows 7–11 con compatibilidad desde PowerShell 5 en adelante, priorizando Windows 10 y PowerShell 7.5.x).  Entre sus funciones destacan:

* Alta de subproyectos en `Sandbox/<Proyecto>` con estructura estándar (carpetas `docs`, `csv`, `Scripts`, `src`, `tests`).
* Generación de archivos base (`AGENTS.md`, `README.md`, `.csproj`, mapas ASCII, jerarquía JSON, CSV, procedimientos).
* Inicialización de la estructura base del repositorio (documentos globales y sandbox vacío) cuando no existe.
* Creación de copias de seguridad comprimidas (7z) de proyectos en Sandbox hacia la carpeta de documentos del usuario.
* Eliminación de proyectos en Sandbox de forma segura, sin requerir permisos especiales fuera del script.
* Sincronización de cambios locales hacia `origin` (pull + commit + push) y fusión de ramas `Codex_YYYY-MM-DD` generadas por agentes en la rama principal indicada.
* Análisis estático con PSScriptAnalyzer sobre proyectos creados.
* Descarga de artifacts publicados por GitHub Actions (vía GitHub CLI).
* Operaciones en lote sobre todos los repositorios Git detectados bajo la ruta base.
* Función “Doctor” para validar la estructura mínima esperada de cada proyecto.

El script está pensado como monolito interactivo: muestra menús, pregunta confirmaciones y guía al usuario en cada paso.
También admite un modo no interactivo básico mediante -InitialRepo y -AutoOption.

.PARAMETER BasePath
Ruta base donde se buscarán repositorios Git y se mostrará el menú de selección.
Por defecto: "$env:USERPROFILE\Documents\GitHub".

.PARAMETER DefaultBranch
Nombre de la rama principal sobre la que operan las funciones de sincronización y fusión (por ejemplo, main o master).
Puede ser sobreescrita por -InitialBranch.

.PARAMETER InitialRepo
Ruta a un repositorio concreto para ejecutar directamente una opción automática, sin pasar por el menú de selección.
Se usa en combinación con -AutoOption.

.PARAMETER AutoOption
Código de opción a ejecutar en modo automático sobre -InitialRepo.
Valores actuales:
  '1' = Crear estructura Sandbox en el repositorio indicado.
  '2' = Crear la estructura base del repositorio (documentos globales + sandbox vacío).
  '3' = Sincronizar cambios locales → origin/DefaultBranch.
  '4' = Fusionar la rama Codex_YYYY-MM-DD → DefaultBranch.
  '5' = Descargar artifacts de GitHub Actions.
  '6' = Crear una copia de seguridad comprimida (7z) de un proyecto del Sandbox.
  '7' = Eliminar un proyecto existente en Sandbox.
  '8' = Atrás (seleccionar otro repositorio; solo tiene efecto en modo interactivo).
Cualquier otro valor se considera no soportado y dispara una advertencia.

.PARAMETER InitialBranch
Permite sobreescribir la rama por defecto (-DefaultBranch) al inicio de la ejecución.
Si se indica, todas las operaciones que usan la rama principal trabajarán sobre este valor.

.NOTES
Autor:    ChatGPT (generado para el usuario).
Contexto: Ecosistema Synapta / Neurologic – administración de repos locales y flujos con Codex / GitHub.
Fecha:    19 de noviembre de 2025.

REQUISITOS:
- Git instalado y accesible en PATH (para Ensure-GitAvailable / Ensure-GitRepo / operaciones de sync).
- .NET SDK (para dotnet build / dotnet test en operaciones en lote).
- PSScriptAnalyzer instalado si se desea usar Invoke-PSSAAnalysis:
    Install-Module -Name PSScriptAnalyzer
- GitHub CLI (gh) configurado con autenticación válida para descargar artifacts:
    https://cli.github.com/  +  gh auth login

.LINK
(Interno) Documentación de estándares de proyecto Neurologic / Synapta, si aplica.

.EXAMPLE
# Uso interactivo normal sobre la ruta base por defecto
.\RepoMaster.ps1

.EXAMPLE
# Ejecutar directamente la creación de estructura Sandbox sobre un repo concreto
.\RepoMaster.ps1 -InitialRepo 'C:\Code\MyRepo' -AutoOption '1'

.EXAMPLE
# Trabajar sobre una rama principal distinta a main (por ejemplo, develop)
.\RepoMaster.ps1 -DefaultBranch 'develop'

#>