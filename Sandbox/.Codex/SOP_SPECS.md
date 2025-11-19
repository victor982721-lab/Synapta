# Procedimiento para solicitar especificaciones técnicas a los agentes (ChatGPT / Codex)

Este documento define **cómo deben formularse las solicitudes de especificación técnica** para que los agentes (ChatGPT, Codex u otros) generen documentos **normativos, completos y útiles**, sin respuestas "blandas" ni ambiguas.

La idea es que, siguiendo este procedimiento, cada especificación que pidas funcione como un **plano de ingeniería**: dice qué se quiere, cómo se quiere y en qué forma, sin hablar de capacidades del modelo ni tiempos de ejecución.

---

## 1. Alcance

Este procedimiento aplica a:

- Especificaciones para **Codex** (CLI o web).  
- Especificaciones para **ChatGPT** cuando se le pide diseñar artefactos técnicos (scripts, módulos, CLIs, servicios, estructuras de proyectos, etc.).  
- Especificaciones neutrales que luego consumirá cualquier agente.

No aplica a:

- Preguntas casuales.  
- Consultas exploratorias o de aprendizaje sin intención de generar artefactos.

---

## 2. Principios generales

1. La especificación **debe describir solo el artefacto**, no las capacidades del modelo.  
2. Toda instrucción se redacta en modo **normativo** usando verbos como:  
   - "debe", "no debe", "tiene que", "está prohibido".  
3. Se evita el lenguaje vago:  
   - No usar "podría", "en lo posible", "idealmente" salvo que realmente se quiera dejar algo opcional.  
4. El documento debe poder entenderse como si fuera a ejecutarse por un equipo humano de ingeniería sin conocer nada de IA.

---

## 3. Estructura mínima de una solicitud de especificación

Cuando pidas una especificación a un agente, la solicitud debe contener explícitamente los siguientes bloques (pueden ir como secciones o como lista estructurada):

### 3.1 Bloque [AGENTE_DESTINO]

Indica para quién está pensada la especificación:

- `AGENTE_DESTINO: Codex`  
- `AGENTE_DESTINO: ChatGPT`  
- `AGENTE_DESTINO: Codex y ChatGPT`  

Reglas:

- Si el destino incluye **Codex**, la especificación se redacta pensando en que Codex la usará como plano para generar código sin deducir cosas "implícitas".
- Si es solo para ChatGPT, se puede ser un poco más descriptivo, pero manteniendo el formato normativo.


### 3.2 Bloque [MODO]

Define el tipo de especificación que se desea:

- `MODO: Normativo_Estricto` → el agente debe producir una especificación de ingeniería dura (como planos), sin recomendaciones blandas ni opciones opcionales no pedidas.
- `MODO: Exploratorio` → el agente puede proponer alternativas, hablar de pros/contras, etc.

Reglas:

- Por defecto, si no se indica, se asume `MODO: Normativo_Estricto`.
- En modo normativo estricto el agente **no debe**:
  - Introducir frases del tipo "podría", "si se quiere" sin que la solicitud lo permita.  
  - Explicar capacidades del modelo o limitarse por tiempo.


### 3.3 Bloque [CONTEXTO]

Describe el entorno donde vivirá el artefacto:

- Repositorio y ruta base (ej. `Neurologic/Tools/...`).  
- SO, shell, versión de PowerShell/.NET.  
- Restricciones globales (no WSL, no PS 5.1, no venv, etc.).

Ejemplo de formato:

```text
CONTEXTO:
- Repo: Neurologic
- Ruta sugerida: Neurologic/Tools/RuntimeAnalyzerCLI/
- Entorno: Windows 10, PowerShell 7+
- Restricciones: sin WPF, sin WSL, sin PS 5.1
```


### 3.4 Bloque [OBJETIVO_TECNICO]

Debe responder claramente a: **¿qué artefacto final se quiere obtener?**

Ejemplos:

- "Una herramienta CLI que…"  
- "Un módulo reutilizable que…"  
- "Una librería .NET que…"  
- "Un conjunto de scripts PowerShell que…"  

Reglas:

- Debe quedar claro si es **CLI**, **servicio**, **lib**, **módulo**, etc.  
- Indicar explícitamente si **no debe** haber UI, WPF, web, etc.


### 3.5 Bloque [ALCANCE_FUNCIONAL]

Lista de capacidades **obligatorias** y, si aplica, cosas explícitamente fuera de alcance.

Formato recomendado:

```text
ALCANCE_FUNCIONAL:
- Debe hacer A, B, C.
- Debe soportar X, Y, Z.
- No debe hacer/soportar: …
```

Ejemplos de puntos típicos:

- Qué tipo de análisis debe hacer (estático, dinámico, ambos).  
- Qué entradas acepta (scripts, módulos, directorios).  
- Qué salidas debe producir (JSON, logs, archivos, etc.).  
- Si debe integrarse con Pester, indexadores, motores, etc.


### 3.6 Bloque [INTERFAZ]

Especifica cómo se usa el artefacto desde fuera.

Para CLIs:

- Nombre del comando/script principal.  
- Parámetros obligatorios y opcionales.  
- Tipos y comportamiento esperado (valores por defecto, validaciones).  
- Manejo del código de salida (`$LASTEXITCODE`).

Para módulos/librerías:

- Funciones públicas y sus firmas.  
- Tipos de parámetros y retorno.  
- Contratos básicos (qué se garantiza).


### 3.7 Bloque [ESTRUCTURA_ARCHIVOS]

Si el artefacto implica múltiples archivos/proyectos, incluir:

- Árbol ASCII del directorio propuesto.  
- Nombres exactos de scripts, módulos y carpetas.  
- Relación entre componentes (qué referencia a qué).

Reglas:

- Si se define una estructura, el agente **no debe inventar carpetas adicionales** salvo que la especificación se lo permita.
- Para estructuras complejas, usar un árbol como:

```text
<Raiz>/
├── ScriptPrincipal.ps1
├── Modules/
│   └── MiModulo.Core.psm1
└── Tests/
    └── Generated/
```


### 3.8 Bloque [RESTRICCIONES_TECNOLOGICAS]

Lista de "sí" y "no" tecnológicos:

- Lenguajes permitidos.  
- Versiones mínimas.  
- Librerías/módulos obligatorios.  
- Tecnologías prohibidas.

Ejemplo:

```text
RESTRICCIONES_TECNOLOGICAS:
- PowerShell 7+ obligatorio.
- Pester v5 obligatorio.
- Prohibido: Windows PowerShell 5.1, WSL, UI gráfica, WPF.
```


### 3.9 Bloque [CRITERIOS_ACEPTACION]

Define cuándo se considera que la especificación está cumplida (para artefactos que genere Codex):

- El artefacto compila/se ejecuta sin errores básicos.  
- Cumple la interfaz descrita.  
- Produce el tipo de salida especificado.  
- Implementa todas las secciones de estructura de carpetas y módulos.  
- Respeta las políticas globales (Política cultural y de calidad, AGENTS general, AGENTS de proyecto).

Formato sugerido:

```text
CRITERIOS_ACEPTACION:
- Debe generar un script CLI ejecutable con el contrato de parámetros indicado.
- Debe crear la estructura de carpetas y módulos descrita.
- Debe integrar Pester con las reglas X, Y, Z.
- Debe producir reporte JSON/NDJSON con el formato definido.
```

---

## 4. Reglas que el agente debe seguir al generar la especificación

Cuando proporciones una solicitud que siga este procedimiento, el agente (ChatGPT/Codex) debe:

1. Responder en modo **normativo**:
   - Usar "debe", "no debe", "tiene que", "está prohibido".  
   - Evitar referencias a tiempos de ejecución del modelo, límites de tokens o "lo haré en X minutos".

2. No hablar de capacidades del modelo:
   - No mencionar "si Codex puede" o "si el modelo soporta".  
   - La especificación siempre se redacta como si fuera a ser leída por un equipo humano de ingeniería.

3. No introducir opciones blandas no pedidas:
   - No decir "se puede" o "idealmente" a menos que la solicitud indique explícitamente que algo es opcional.  
   - Cualquier cosa opcional debe marcarse en una sección clara (por ejemplo, "Características opcionales").

4. No inventar estructura fuera de lo pedido:
   - No añadir carpetas como `Scripts/`, `src/` o similares si no están en el bloque [ESTRUCTURA_ARCHIVOS] o en reglas globales conocidas.  
   - Si el agente considera necesaria una carpeta adicional, debe mencionarla como propuesta explícita dentro de la especificación, no como hecho consumado.

5. Alinear la especificación con las políticas globales de Neurologic/Synapta:
   - Recordar que, por encima de cualquier especificación puntual, aplican:
     - Política cultural y de calidad – Ecosistema Neurologic.  
     - AGENTS – Neurologic (general).  
     - AGENTS específicos del proyecto (si existen).

---

## 5. Plantilla de solicitud de especificación

Cuando quieras pedir una especificación, puedes usar esta plantilla mínima:

```text
Quiero una especificación técnica en modo normativo para el siguiente artefacto.

AGENTE_DESTINO: Codex
MODO: Normativo_Estricto

CONTEXTO:
- Repo: Neurologic
- Ruta sugerida: Neurologic/Tools/RuntimeAnalyzerCLI/
- Entorno: Windows 10, PowerShell 7+
- Restricciones: sin WSL, sin PS 5.1, sin UI

OBJETIVO_TECNICO:
- Una herramienta CLI que analice dinámicamente scripts PowerShell usando Pester.

ALCANCE_FUNCIONAL:
- Debe hacer A, B, C…
- No debe hacer X, Y, Z…

INTERFAZ:
- Comando principal: .\Invoke-RuntimeAnalyzer.ps1
- Parámetros: TargetPath (obligatorio), Mode, RuleSet, etc.

ESTRUCTURA_ARCHIVOS:
- [Tree ASCII aquí]

RESTRICCIONES_TECNOLOGICAS:
- PowerShell 7+, Pester v5 obligatorio.
- Prohibido WPF, GUI, WSL.

CRITERIOS_ACEPTACION:
- Debe generar X archivos.
- Debe integrarse con Y.
- Debe producir salida JSON/NDJSON con el formato Z.
```

Con algo de este estilo, el agente ya no "interpreta" ni "suaviza" la respuesta: solo rellena el plano con el detalle técnico.

---

## 6. Uso práctico

1. Antes de pedir una especificación, redactar la solicitud siguiendo esta estructura (aunque sea en corto).  
2. Pegar la solicitud al agente (ChatGPT).  
3. Verificar que la respuesta:
   - Es normativa.  
   - No introduce carpetas ni conceptos no descritos.  
   - No habla de capacidades del modelo.
4. Si la respuesta es demasiado blanda, reforzar indicando explícitamente:  
   - "Reescribe en modo normativo estricto según el procedimiento de especificaciones".

Una vez que tengas la especificación, puedes usarla tal cual como entrada para Codex o como documento de diseño dentro de Neurologic.

