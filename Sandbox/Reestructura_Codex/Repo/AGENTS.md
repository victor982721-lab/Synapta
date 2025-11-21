# AGENTS – Neurologic propuesto

Prioridad de reglas:
1. Política cultural y de calidad (este repositorio).
2. AGENTS específicos de cada subcarpeta.
3. Instrucciones del README correspondiente.

Lineamientos rápidos:
- Trabajar en Windows 10/11 con PowerShell 7.x; mantener compatibilidad con Windows PowerShell 5.1 cuando aplique.
- Prefiere C# y PowerShell; proyectos .NET siempre en multi-target `net8.0;net7.0;net6.0` (o `-windows` para WPF).
- Mantén `namespace = ruta de carpeta` y evita duplicar motores ya existentes en `Core/`.
- Entrega artefactos completos (código + documentación mínima); corre PSSA y `dotnet test` al modificar código ejecutable.
- Actualiza `Repo_Estructura_ASCII.md` y los README cuando cambie la estructura.
