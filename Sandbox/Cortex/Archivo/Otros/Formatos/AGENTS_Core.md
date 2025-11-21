# AGENTS – Core

Este documento define las reglas específicas para el desarrollo de módulos en la carpeta **Core** del repositorio Neurologic.  Se complementa con la **Política cultural y de calidad** y el **AGENTS general**, y en ningún caso puede contradecirlos.

## Entorno y herramientas

* **Sistema operativo principal:** Windows 10 (compatibilidad con Windows 7–11).
* **Shell principal:** PowerShell 7.5.x (se admite compatibilidad con PowerShell 5 en adelante).  No usar WSL/WSL2 por defecto.
* **Lenguajes:** C# para librerías .NET; PowerShell para scripts de soporte.  Python solo cuando esté justificado y se acuerde explícitamente.
* **Proyectos .NET:** se deben crear como bibliotecas multi‑target desarrolladas para **.NET 8** con compatibilidad para **.NET 7** y **.NET 6** (`<TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>`).  No se permite degradar a single‑target salvo justificación documentada.  Se prioriza el funcionamiento en el entorno real del usuario y se deja abierta la adaptación a futuras versiones.

## Principios de desarrollo

1. **Modularidad y reutilización** – Los componentes de Core se diseñan para ser reutilizables por múltiples proyectos.  No mezcles lógica de UI ni dependencias específicas de un subproyecto.
2. **Firmas claras** – Cada módulo (por ejemplo, `FileSystem`, `Indexing`, `Search`) debe exponer APIs públicas claras (clases, métodos, interfaces) y ocultar los detalles internos.  Documenta el uso mínimo con XML‑docs y un `README.md` en su carpeta.
3. **Pruebas automáticas** – Cada módulo debe ir acompañado de un proyecto de pruebas (`NombreModulo.Tests.csproj`) dirigido a los mismos frameworks.  Las pruebas se ejecutan mediante `dotnet test` en CI.
4. **Compatibilidad hacia atrás** – Cambios que rompan la compatibilidad deben documentarse y planificarse mediante versiones.  Evita modificar firmas públicas sin un plan de migración.
5. **No duplicación** – Antes de crear un módulo nuevo, busca en `Core` si ya existe algo equivalente.  Extiende o adapta lo existente conforme a la política de reutilización.

## Estructura recomendada

Para cada módulo bajo `Core` se recomienda la siguiente estructura:

```
Core/
  NombreModulo/
    NombreModulo.csproj
    README.md
    src/
      ...       # Clases, interfaces, impl.
    tests/
      NombreModulo.Tests.csproj
      ...       # Pruebas unitarias
```

* `NombreModulo.csproj` debe definir los frameworks de destino y, si es necesario, paquetes NuGet de terceros.
* `README.md` explicará el propósito del módulo, cómo instalarlo en otros proyectos y dará ejemplos de uso.
* `src/` contendrá la implementación.  No mezclar código de varias responsabilidades en un mismo archivo.
* `tests/` contendrá las pruebas unitarias usando xUnit/NUnit para C# o Pester para PowerShell.

## Cumplimiento

Los cambios en Core se revisan según la lista de verificación de calidad definida en la Política global.  Cualquier omisión (por ejemplo, falta de multi‑targeting, ausencia de pruebas o de documentación) hará que el trabajo se considere un borrador hasta su corrección.
