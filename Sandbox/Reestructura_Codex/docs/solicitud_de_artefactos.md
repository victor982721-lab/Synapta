# Solicitud de artefactos para Codex Web

## Agente destino
- Codex Web (entorno Windows 10/11, PowerShell 7.x; compatibilidad con PS 5.1 cuando aplique).

## Antecedentes
- Informe base: `Reestructuración Integral del Repositorio.docx` (raíz de este proyecto).
- Árbol propuesto en `Repo/` con módulos reutilizables (`Core/`), ejemplos (`Sandbox/ProyectoEjemplo`) y utilidades (`Scripts/New-RepoReport.ps1`).
- Normativa: `AGENTS.md` global + específicos y `Politica_Cultural_y_Calidad.md`.

## Objetivo técnico
- Mantener y evolucionar el árbol `Repo/` como plantilla reutilizable para nuevos proyectos .NET/PowerShell multi-target.
- Asegurar que cada solicitud a Codex tenga inventario actualizado (CSV), mapa ASCII y jerarquía JSON coherentes.

## Alcance de la solicitud
- Crear o ajustar artefactos en `Repo/` respetando `Repo_Estructura_ASCII.md`.
- Extender módulos existentes antes de proponer nuevos motores.
- Actualizar documentación e inventarios cuando cambie la arquitectura.

## Interfaces y formatos esperados
- Proyectos .NET: `*.csproj` multi-target `net8.0;net7.0;net6.0` (o `-windows` si corresponde).
- Scripts: PowerShell con compatibilidad PS 5.1+ y PSSA limpio.
- Inventario: `csv/modules.csv`, `csv/artefacts.csv`, `docs/table_hierarchy.json`, `docs/filemap_ascii.txt`.

## Dependencias
- .NET SDK 8/7/6 instalados.
- PowerShell 7.x (con fallback a Windows PowerShell 5.1 si se indica en AGENTS).

## Criterios de aceptación
- Estructura respetada según `Repo_Estructura_ASCII.md`.
- Documentación y CSV reflejan la misma arquitectura que el código.
- Pruebas (`dotnet test`) y PSSA ejecutadas cuando se modifique código ejecutable, con resultados documentados.
- No se introducen motores duplicados; se extienden los existentes en `Core/`.
