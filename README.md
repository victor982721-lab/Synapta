# Neurologic

Repositorio personal para el ecosistema **Neurologic / Synapta**: automatización, motores internos, indexadores y proyectos de escritorio (WPF/.NET), orientados a uso propio. Este README funciona como índice operativo de las reglas internas. Para documentación específica de cada proyecto (p. ej. Ws_Insights, Cortex) consulta los README ubicados en sus carpetas (`Neurologic/Sandbox/<Proyecto>/README.md`).

---

## Documentos normativos

- **Política cultural y de calidad – Ecosistema Neurologic**: estándar global de cultura, calidad y criterios mínimos.
- **AGENTS – Neurologic (General para Codex)**: reglas específicas para el agente Codex.
- **AGENTS específicos por proyecto**: cada subproyecto define reglas adicionales (ej. `Sandbox/Cortex/AGENTS.md`, `Sandbox/Ws_Insights/AGENTS.md`). Estos solo pueden endurecer el estándar global, nunca rebajarlo.

---

## Tipos de agentes

- **Codex CLI / Web**: generación automática de código. Debe seguir la política cultural, el AGENTS general y el AGENTS específico del subproyecto.
- **ChatGPT (web o CLI)**: agente conversacional/apoyo técnico. Sigue la política cultural; cuando actúe como Codex se recomienda alinearlo con los AGENTS para mantener coherencia.

---

## Prioridad de reglas

1. Política cultural y de calidad.
2. AGENTS del subproyecto.
3. AGENTS – Neurologic (General para Codex).
4. Instrucciones específicas de la sesión (sin violar los puntos anteriores).

---

## Estructura y carpetas

- `Core/`: librerías reutilizables (C# / PowerShell) disponibles para todo el ecosistema.
- `Sandbox/`: proyectos en desarrollo o experimentales (Cortex, Ws_Insights, etc.).
- `Scripts/`: utilidades compartidas (diagnósticos, migraciones, etc.).
- Documentos globales relevantes: `AGENTS.md`, `Politica_Cultural_y_Calidad.md`, `Preferencias_del_Usuario.md`, `Repo_Estructura_ASCII.md`.

---

## Convenciones rápidas

- Multi-target obligado para proyectos .NET nuevos (`net8/net7/net6`).
- `namespace = ruta de carpeta` para C#.
- Evitar crear carpetas arbitrarias; sigue la estructura declarada en Repo_Estructura_ASCII.
- Reutilizar motores/indexadores existentes antes de crear uno nuevo.
- Scripts deben entregarse completos, listos para ejecutar.

---

## Recursos adicionales

- `Neurologic/Repo_Estructura_ASCII.md`: mapa ASCII de carpetas.
- `Neurologic/Preferencias_del_Usuario.md`: estilo de respuesta, lenguajes preferidos y restricciones.
- `Neurologic/Sandbox/Cortex/docs/Informe.md`: análisis de mejoras para el script maestro.
- `Neurologic/Sandbox/Ws_Insights/README.md`: documentación detallada de Ws_Insights.

Este documento se actualiza conforme evolucionan las reglas globales del ecosistema.
