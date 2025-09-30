# &lt;WsW_Contexto&gt;

https://chat.openai.com/c/68da6bf4-ead8-8327-867b-89caeb296cc3

## USER
Analiza y explica que entiendes con lo siguiente:

```
Contexto de workspace
- root = C:\Users\VictorFabianVeraVill\mnt
- Abreviaturas: "docs/chatgpt" = <root>\docs\chatgpt
- Nuevo proyecto "X": crear en <root>\data\proyectos\X con subcarpetas {docs, src, config, results}
- No escribes en disco: solo dame comandos/archivos listos para copiar/pegar

Preferencias de salida
- Sistema: Windows 10/11, PowerShell 7 preferido (acepto PS5 si aplica)
- Formato: SOLO bloques de código con los comandos, sin prosa
- Encoding: UTF-8
- Evita rutas relativas fuera de <root>

Límites de seguridad (duros)
- Máx. profundidad: 8 niveles
- Máx. nodos a crear por operación: 200
- No proponer cambios fuera de <root>
- Validar nombres Windows (sin <>:"/\|?*, sin punto/espacio final; sin nombres reservados)

Convenciones
- Nombres proyecto: kebab-case (ej. proyecto-ejemplo)
- Fechas en archivos: YYYY-MM-DD (ej. 2025-09-28)
- Logs en <root>\logs cuando aplique

Plantilla por defecto (si no digo lo contrario)
- Para “nuevo proyecto X”: crear {docs/, src/, config/, results/} y README.md con título y fecha
```

## Thoughts
El usuario pide análisis y explicación, pero incluye "Formato: SOLO bloques de código con los comandos, sin prosa" como parte de sus preferencias. Esto parece ser para futuras respuestas, no para la nuestra. Así que probablemente deba ofrecer una explicación detallada y casual, sin seguir esa preferencia en este caso.
Parece que debemos proporcionar una explicación en español, destacando puntos clave como la raíz del espacio de trabajo, abreviaciones, y convenciones de seguridad. Aunque el usuario solicitó "solo bloques de código... sin prosa", también pide análisis y explicación, lo que implica incluir texto explicativo. Mostrar comandos y validaciones en PowerShell podría ser útil.
Las "Preferencias de salida" parecen ser parte del contenido que debemos analizar, no instrucciones estrictas a seguir. Aunque el usuario suele pedir respuestas con solo comandos, esta vez ha solicitado un análisis y explicación, lo que implica usar prosa. Dado el estilo casual, una explicación breve en español será suficiente, sin herramientas extras.
La especificación del workspace define el camino raíz, abreviaturas, estructura del proyecto, sin escribir en disco y solo proporcionando comandos y archivos listos para copiar. Se prefiere PowerShell 7, con solo bloques de código. También debe evitarse usar rutas relativas fuera de la raíz, con límites de profundidad y nodos. Además, se validan nombres en Windows, emplea convenciones para fechas y registros, con un modelo estándar para nuevos proyectos.

## ASSISTANT
Esto define un “contrato de trabajo” para cómo debo operar en tu PC (Windows) dentro de un workspace controlado.

# Lo esencial que entiendo

- **Ámbito**: Todo vive bajo `C:\Users\VictorFabianVeraVill\mnt` (**<root>**). Puedo usar la abreviatura `"docs/chatgpt"` para referirme a `<root>\docs\chatgpt`. No debo proponer ni tocar nada fuera de `<root>`.
- **Creación de proyectos**: Un proyecto “X” se crea en `<root>\data\proyectos\X` con subcarpetas `{docs, src, config, results}`. Los nombres de proyecto van en **kebab-case**.
- **Salida/entregables**: No debo escribir en disco; te doy **comandos o archivos listos para copiar/pegar**. Prefieres **PowerShell 7** (vale PS5 si aplica). La salida debe ser **solo bloques de código con comandos**, sin prosa, en **UTF-8**. Evitaré rutas relativas que salgan de `<root>`.
- **Límites duros**: 
  - Profundidad máxima de estructura: **8 niveles**.
  - Máximo de **200 nodos** (archivos+carpetas) por operación.
  - Validación de nombres Windows: sin `<>:"/\|?*`, sin punto/espacio al final, y sin nombres reservados (p.ej. `CON`, `PRN`, `AUX`, `NUL`, `COM1–9`, `LPT1–9`).
- **Convenciones**:
  - Fechas en archivos: `YYYY-MM-DD` (ej. `2025-09-28`).
  - **Logs** van en `<root>\logs` cuando corresponda.
- **Plantilla por defecto** (“nuevo proyecto X”):
  - Crear `{docs/, src/, config/, results/}`.
  - Generar `README.md` con **título** y **fecha** (formato arriba).

# Implicaciones prácticas de mi actuación

- Cuando pidas “nuevo proyecto X”, te devolveré **solo** un bloque PS que:
  - Cree la estructura bajo `<root>\data\proyectos\X`.
  - Cumpla profundidad ≤ 8, ≤ 200 nodos.
  - Use rutas absolutas dentro de `<root>`.
  - Genere `README.md` con fecha `YYYY-MM-DD` en UTF-8.
  - (Si aplica) añada comandos para loguear en `<root>\logs`.

- Si requieres archivos de contenido, te los entregaré como **bloques de archivo** listos para pegar (UTF-8), nunca escribiendo yo en disco.

Si quieres, ya puedo devolverte el bloque de PowerShell para “nuevo proyecto *proyecto-ejemplo*” siguiendo exactamente estas reglas.

