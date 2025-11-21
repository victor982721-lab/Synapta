# Política cultural y de calidad – Neurologic (resumen)

1. **Respeto y reutilización**: estudiar y extender motores existentes antes de crear nuevos; evitar duplicaciones y reescrituras innecesarias.
2. **Determinismo y modularidad**: mismos inputs producen mismos outputs; separar lógica de negocio de UI; publicar APIs claras reutilizables.
3. **Multi-target .NET y compatibilidad**: proyectos nuevos deben dirigirse a `net8.0/net7.0/net6.0` (o `-windows` para WPF); scripts PowerShell compatibles con Windows PowerShell 5.1 y PowerShell 7+.
4. **Calidad y pruebas**: entregar artefactos completos con validaciones (PSSA, análisis de compilador, `dotnet test` cuando aplique) y salidas estructuradas.
5. **Trazabilidad**: documentar decisiones en README/AGENTS/bitácoras y mantener inventarios coherentes con la estructura declarada.
