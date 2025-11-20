# AGENTS – Core

Este documento define las reglas específicas para el desarrollo de módulos en la carpeta **Core** del repositorio Neurologic. Se complementa con la Política cultural y de calidad y el AGENTS general, y en ningún caso puede contradecirlas.

## Entorno

* **Sistema operativo:** Windows 10 o superior.
* **Shell:** PowerShell 7.5.4 o superior (no usar Windows PowerShell 5.1 ni WSL por defecto).
* **Lenguajes:** C# para librerías .NET; PowerShell para scripts de soporte. Python sólo cuando esté justificado y se acuerde explícitamente.
* **Proyectos .NET:** se deben crear como **bibliotecas multi‑target** con `<TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>`. No se permite degradar a single‑target salvo justificación documentada.

## Principios de desarrollo

1. **Modularidad y reutilización** – Los componentes de Core se diseñan para ser reutilizables por múltiples proyectos. No mezcles lógica de UI ni dependencias específicas de un subproyecto.
2. **Firmas claras** – Cada módulo (por ejemplo, `FileSystem`, `Indexing`, `Search`) debe exponer API pública clara (métodos, clases, interfaces) y ocultar los detalles internos. Documenta el uso mínimo en XML-docs y en un `README.md` dentro de su carpeta.
3. **Pruebas automáticas** – Cada módulo debe ir acompañado de un proyecto de pruebas (`<nombre>.Tests.csproj`) dirigido a los mismos frameworks. Las pruebas deben ejecutarse mediante `dotnet test` en el pipeline CI.
4. **Compatibilidad hacia atrás** – Cambios que rompan la compatibilidad deben documentarse y planificarse mediante versiones. Evita modificar firmas públicas sin un plan de migración.
5. **No duplicación** – Antes de crear un módulo nuevo, busca en `Core` si ya existe algo equivalente. Extiende o adapta lo existente conforme a la política de reutilización.

## Estructura recomendada

Para cada módulo bajo `Core` se recomienda la siguiente estructura:

```
Core/
  NombreModulo/
    NombreModulo.csproj
    README.md
    src/
      (clases, interfaces)
    tests/
      NombreModulo.Tests.csproj
      (pruebas)
```

* `NombreModulo.csproj` debe definir las frameworks de destino y, si es necesario, paquetes NuGet de terceros.
* `README.md` explicará el propósito del módulo, cómo instalarlo en otros proyectos y dará ejemplos de uso.
* `src/` contendrá la implementación. No mezclar código de varias responsabilidades en un mismo archivo.
* `tests/` contendrá las pruebas unitarias usando Pester (para PowerShell) o xUnit/NUnit (para C#).

## Cumplimiento

Los cambios en `Core` se revisarán según la lista de verificación de calidad de la política global【240671532981222†L160-L176】. Cualquier omisión (por ejemplo, falta de multi‑targeting, ausencia de pruebas o documentación) hará que se considere el trabajo como borrador hasta su corrección.
