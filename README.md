# Neurologic

Repositorio personal para el ecosistema **Neurologic / Synapta**:
automatización, motores internos, indexadores y proyectos de escritorio
(WPF/.NET), orientados a uso propio.

Este README no está pensado como documentación pública, sino como índice
operativo para los documentos de reglas internas.

---

## Documentos normativos

- **Política cultural y de calidad – Ecosistema Neurologic**  
  Estándar global de cultura, calidad y criterios mínimos de aceptación.
  Aplica a personas y agentes (humanos y IA).

- **AGENTS – Neurologic (General para Codex)**  
  Reglas específicas para el agente **Codex** al trabajar en este
  repositorio (multi-framework .NET, organización de módulos, reutilización
  de motores, etc.).

- **AGENTS específicos de proyecto**  
  Cada subproyecto puede definir sus propias reglas adicionales:
  - `Neurologic/Ws_Insights/AGENTS.md`
  - (futuros proyectos irán añadiendo sus propios `AGENTS.md`)

Los AGENTS específicos solo pueden **endurecer** el estándar cultural y
técnico global, nunca rebajarlo.

---

## Tipos de agentes y alcance

En este repositorio se usan varios “agentes” sobre el mismo código:

- **Codex en CLI (GPT-5 Codex)**  
  - Agente de generación automática de código y proyectos.  
  - Debe obedecer:
    - Política cultural y de calidad – Ecosistema Neurologic.
    - AGENTS – Neurologic (General para Codex).
    - AGENTS específicos del subproyecto donde trabaje.

- **Codex / asistentes de código en la web**  
  - Mismo rol que Codex en CLI, pero ejecutado desde la plataforma web.  
  - Mismas reglas que el punto anterior.

- **ChatGPT (web o CLI)**  
  - Agente conversacional y de apoyo técnico (análisis, explicación,
    diseño, refactors guiados, etc.).  
  - Debe respetar la **Política cultural y de calidad**, pero no está obligado
    a seguir al pie de la letra las reglas operativas pensadas
    específicamente para Codex (por ejemplo, multi-target automático al
    crear proyectos, reglas de creación de archivos en lote, etc.).  
  - Cuando ChatGPT actúe como “Codex” (generando código A→Z), se
    recomienda alinearse voluntariamente con los AGENTS de Codex para
    mantener coherencia.

---

## Prioridad de reglas

Cuando haya dudas sobre qué seguir, el orden es:

1. **Política cultural y de calidad – Ecosistema Neurologic.**
2. **AGENTS específicos del proyecto** (si existen).
3. **AGENTS – Neurologic (General para Codex)** para trabajos de generación
   de código automatizada.
4. Criterio puntual en esta sesión (instrucciones ad hoc que no violen los
   puntos anteriores).

---
