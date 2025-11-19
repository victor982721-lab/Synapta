# AGENTS – NombreDelProyecto

Este documento complementa el AGENTS general de Neurologic y la Política cultural y de calidad. Define reglas específicas para el subproyecto **NombreDelProyecto**. Recuerda que no puedes rebajar las normas globales; sólo puedes endurecerlas o añadir detalles particulares.

## Entorno

* **Sistema operativo:** Windows 10 o superior.
* **Shell predeterminado:** PowerShell 7.5.x (`pwsh`). Evitar WSL y Windows PowerShell 5.1 salvo indicación contraria.
* **Target frameworks (si aplica):** `net8.0-windows;net7.0-windows;net6.0-windows` para aplicaciones WPF, o `net8.0;net7.0;net6.0` para bibliotecas/CLI.

## Responsabilidades del proyecto

Describe brevemente la función de este proyecto en el ecosistema. Señala si es una biblioteca de soporte, una herramienta de línea de comandos, una interfaz gráfica o una combinación.

## Principios específicos

1. **Reutilización interna** – Este proyecto debe reutilizar los motores de `Core` en lugar de copiar su lógica. Si requiere funcionalidad que no existe, deberá añadirla a `Core` antes de implementarla aquí.
2. **Determinismo** – Las mismas entradas deben producir las mismas salidas; documenta cualquier excepción necesaria.
3. **Arquitectura limpia** – Mantén una separación clara entre lógica de negocio, acceso a datos y presentación. Para CLI/GUI, usa patrones MVVM o similares.
4. **Documentación y tablas** – Este proyecto debe generar en `docs/` un mapa ASCII (`filemap_ascii.txt`), un JSON de jerarquía (`table_hierarchy.json`), la especificación (`spec.md`) y un plan de trabajo (`plan.md`). También debe mantener tablas CSV descriptivas en `csv/`.
5. **Pruebas** – Debe incluir pruebas unitarias (Pester para PowerShell, xUnit para C#, etc.) que cubran los casos críticos.

## Excepciones autorizadas

Lista aquí cualquier excepción autorizada respecto al AGENTS general (por ejemplo, si solo necesita compilar para `net6.0` porque depende de una API no disponible en versiones superiores). Debe incluir la justificación detallada y ser aprobada antes de implementarse.
