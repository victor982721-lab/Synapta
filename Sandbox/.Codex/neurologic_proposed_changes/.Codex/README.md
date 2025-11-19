# `.Codex` – Herramientas auxiliares

La carpeta `.Codex` agrupa scripts y módulos utilizados por los agentes automatizados (como Codex) para preparar el entorno de trabajo. También contiene copias locales de ciertos módulos de PowerShell que normalmente se descargarían desde Internet. Al tenerlos aquí se garantiza reproducibilidad y se reducen dependencias externas.

## Estructura

* **PSScriptAnalyzer/** – Versión completa del módulo `PSScriptAnalyzer` (1.24.0) disponible para importarse sin conexión a Internet. Para utilizarlo, añade la ruta a `$env:PSModulePath` e importa el módulo.
* **Pester/** – Contiene actualmente el manifiesto de la versión 5.7.1. No incluye el código fuente de Pester, por lo que es necesario instalarlo vía `Install-Module Pester` a menos que se añada una copia completa.
* **Script_Config.sh / Script_Mantto.sh** – Scripts de shell que instalan PowerShell 7.5.4 y .NET 8, descargan módulos si no están disponibles y crean enlaces simbólicos. Se recomienda refactorizarlos para usar los módulos locales de `.Codex` antes de ejecutar `Install-Module`.
* **SOP_SPECS.md** – Procedimiento para crear especificaciones técnicas para proyectos nuevos. La versión actualizada se encuentra en `docs/SOP_SPECS_updated.md`.

## Uso

1. **Cargar módulos locales** – En tus scripts de mantenimiento o configuración, comprueba si el módulo requerido está disponible bajo `.Codex` y, de ser así, añade la ruta a `$env:PSModulePath` antes de llamar a `Import-Module`. Ejemplo:

   ```powershell
   $codexMods = Join-Path $PSScriptRoot '..\.Codex'
   $pssaPath  = Join-Path $codexMods 'PSScriptAnalyzer/1.24.0'
   if (Test-Path (Join-Path $pssaPath 'PSScriptAnalyzer.psm1')) {
       $env:PSModulePath = "$pssaPath;$env:PSModulePath"
       Import-Module PSScriptAnalyzer -Force
   }
   ```

2. **Actualizar los módulos** – Si deseas mantener copias de Pester o de otras versiones de PSScriptAnalyzer, coloca la carpeta completa dentro de `.Codex` y actualiza la documentación.

3. **Refactorizar scripts** – Ajusta `Script_Config.sh` y `Script_Mantto.sh` para que utilicen primero los módulos locales y sólo ejecuten instalaciones externas cuando falten.

Mantener esta carpeta ordenada y documentada ayuda a reducir tiempos de instalación y garantiza que los agentes puedan reproducir exactamente el mismo entorno en cada ejecución.
