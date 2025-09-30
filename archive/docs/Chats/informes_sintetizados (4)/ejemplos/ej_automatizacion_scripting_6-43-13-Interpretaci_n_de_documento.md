### Entrada (user)

{"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

### Salida (assistant)

Es un protocolo de auditoría estática para scripts de PowerShell 7 en Windows 10 que entrega, en un solo turno, un JSON de hallazgos con puntaje y una lista de correcciones priorizadas S1–S4, sin ejecutar nada en el host. Define entradas, salidas, orden y formato deterministas. fileciteturn0file0

Puntos clave:
- Contexto fijo del entorno y alcance: Win10 Pro 22H2 + PS 7.5.3, rutas e indicadores locales. fileciteturn0file0
- Flujo en 6 fases: normalización, chequeo de sintaxis/versión, reglas duras R01–R06, robustez R07–R12, exactitud R13–R15, y scoring. fileciteturn0file0
- Reglas típicas: operadores C# inválidos, parseo de `manage-bde`/`netsh`, `Get-NetFirewallProfile` sin try/catch, `utf8NoBOM` sin `#requires 7.1`, `Start-Process` sin comillas, uso de `-ErrorAction Stop`, `ShouldProcess`, limpieza de temporales, “primer elemento” en colecciones. fileciteturn0file0
- Esquema JSON y orden de reporte estrictos, con severidad y línea 1-based o `null`. fileciteturn0file0
- Plantillas de corrección incluidas y prompt listo para pegar con el script a auditar. fileciteturn0file0
- Prohibido navegar o ejecutar; sólo inspección textual con heurísticos definidos. fileciteturn0file0
