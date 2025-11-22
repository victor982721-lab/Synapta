# Análisis de las Herramientas en Neurologic/Tools

## Diagnóstico del funcionamiento actual

Los scripts en la carpeta Neurologic/Tools están diseñados para analizar código fuente de otros
scripts (principalmente PowerShell y Python) de forma automatizada. El núcleo es el script
Analyze-Scripts.ps1, acompañado por un módulo auxiliar FunctionSpecHelper.psm1 y su documentación. A
continuación se detalla su funcionamiento:

Recorrido de archivos con concurrencia: Analyze-Scripts.ps1 recorre recursivamente un directorio
raíz dado (-RootPath) en busca de archivos de script (*.ps1, *.psm1 de PowerShell y *.py de Python),
ignorando carpetas como "packages". Utiliza procesamiento paralelo (ForEach-Object -Parallel con
ThrottleLimit=6) para analizar múltiples archivos simultáneamente, aprovechando varios núcleos de
CPU[1]. Esto permite streaming de resultados: cada archivo se analiza en un runspace separado y los
resultados se van enviando a la consola conforme se obtienen, sin cargar todo en memoria de una
vez[1].

Análisis de scripts PowerShell: Para cada archivo PowerShell (.ps1/.psm1), el script emplea el
parser de PowerShell nativo para obtener su Árvore de Sintaxis Abstracta (AST) mediante
[System.Management.Automation.Language.Parser]::ParseFile. Si ocurren errores de sintaxis al
parsear, el script intenta una corrección automática: invoca PSScriptAnalyzer con la opción -Fix y
también Invoke-Formatter (si está disponible) sobre el archivo, para formatear o corregir problemas
comunes de estilo, luego reintenta el parseo[2]. (Esta corrección se hace solo una vez por archivo
para evitar bucles). Si tras esto el archivo no puede ser parseado, se registra el error de parseo.
En caso exitoso, con el AST resultante se extrae información clave:

Funciones definidas: lista de nombres de funciones (FunctionCount y nombres concatenados en
Functions).

Llamados a comandos: se recoge la lista de comandos o cmdlets invocados en el script (Commands),
hasta un máximo de 25 distintos por archivo, lo que da una idea de qué acciones realiza.

Comandos “interesantes”: se destaca cualquier uso de comandos considerados sensibles o relevantes
(Interesting), por ejemplo invocaciones a Invoke-WebRequest, Invoke-Expression, Start-Process,
llamadas a git, dotnet, uso de Read-Host, establecer Set-ExecutionPolicy, entre otros[3,4]. Estos se
reportan con su conteo, por ejemplo "Invoke-Expression (x3)" si apareciera 3 veces.

Especificaciones de funciones: gracias al módulo FunctionSpecHelper.psm1, el script transforma cada
función encontrada en el AST en una especificación detallada. Por cada función se documenta su
nombre, parámetros (tipos, valores por defecto, si son obligatorios), comandos usados dentro de la
función, bloques Try/Catch con tipos de excepciones manejadas y contenidos de cada catch, sentencias
return encontradas y una representación estructurada de su AST interno[5]. Esta información se
almacena como un objeto por función en la propiedad FunctionSpecs (además se resume el conteo de
funciones con especificación en FunctionSpecCount y sus nombres en FunctionSpecSummary). La
conversión a “especificación” filtra nodos vacíos para ahorrar espacio (mediante Remove-EmptyNodes).
En esencia, se genera una suerte de documentación técnica del código a partir de la AST de cada
función.

Análisis de scripts Python: Para los archivos .py, el enfoque es similar pero usando Python
internamente. Analyze-Scripts.ps1 incorpora un helper embebido escrito en Python (se define como
cadena multi-línea en la variable $pythonAnalyzer). Este código Python utiliza el módulo estándar
ast de Python para parsear el archivo Python y extraer:

Nombres de funciones definidas en el script Python.

Lista de llamadas a funciones o métodos realizados (por nombre cualificado).

Un listado de llamadas “interesantes” en Python, definido por una lista de patrones relevantes (por
ejemplo uso de subprocess.Popen, llamadas HTTP con requests o httpx, llamadas potencialmente
inseguras como os.system, funciones integradas potencialmente peligrosas como exec/eval, operaciones
de archivo como open/remove, etc.)[6]. Si el script contiene alguna de estas llamadas, se agregan a
Interesting con un conteo, similar al caso PowerShell.

Si el parseo del código Python falla (por error de sintaxis), el helper captura la excepción y
devuelve un JSON indicando el error en ParseErrors para ese archivo.

Nota: El script busca automáticamente una instalación de Python 3 en el sistema – intenta distintas
formas (python, py) – y, si la encuentra, ejecuta el helper con cada archivo. Si no encuentra
intérprete Python, marca un error indicando que no hay Python disponible para analizar archivos .py.
Cada archivo Python se analiza en un proceso separado (llamando al intérprete) y el resultado es
devuelto en formato JSON para ser incorporado al objeto final del análisis.

Consolidación de resultados: A medida que cada archivo es analizado (ya sea por PowerShell o
Python), el resultado es un objeto PSCustomObject con campos: Script (ruta del archivo),
FunctionCount, FunctionSpecCount, FunctionSpecSummary, Functions, Interesting, Commands y
ParseErrors (y FunctionSpecs en estructuras JSON si es PowerShell con funciones). El script
principal acumula todos esos objetos en una colección ($cachedResults) mientras simultáneamente
muestra una tabla formateada en la consola con los campos principales[7]. La tabla se ajusta a ancho
200 para mostrar columnas como Functions, Interesting, etc., truncando si es necesario. Si no se
encontró ningún archivo de script en la ruta dada, avisa con un warning.

Exportación de reporte: Si el usuario proporciona -OutputPath, el script puede volcar los resultados
a un archivo CSV o JSON. Si la extensión del OutputPath es “.json”, serializa la colección completa
(incluyendo los arrays de FunctionSpecs) a JSON; en caso contrario exporta a CSV (omitiendo los
campos complejos no representables). Informa con un mensaje en verde dónde guardó el resultado[8].
De este modo se puede conservar el análisis para inspección más detallada o procesamiento posterior.

En resumen, el funcionamiento actual de estas herramientas es recorrer el código fuente de scripts
PowerShell y Python, parsearlos a profundidad (incluso intentando correcciones automáticas en
PowerShell) y extraer métricas e información clave de forma concurrente, entregando un resumen
tabular inmediato y permitiendo exportar datos detallados (incluyendo la estructura interna de las
funciones en formato JSON). Esto cumple el propósito principal de auditar otros scripts y ofrecer
insights sobre su contenido de forma automatizada.

## Fortalezas de la implementación actual

La solución implementada en Neurologic/Tools presenta varias virtudes importantes:

Análisis basado en AST (estructura del código): A diferencia de enfoques simples de búsqueda de
texto, aquí se utiliza el parseo formal del código (AST) tanto para PowerShell como para Python.
Esto brinda robustez en la detección de elementos sintácticos reales (funciones, comandos, llamadas)
sin verse engañado por comentarios, strings u otras falsas coincidencias. Por ejemplo, identificar
todas las funciones o comandos invocados es preciso gracias al uso del parser nativo de PowerShell y
del módulo ast de Python, en lugar de meras expresiones regulares.

Paralelismo y eficiencia en el recorrido: El uso de ForEach-Object -Parallel con un límite de hilos
permite aprovechar múltiples núcleos para procesar varios archivos a la vez, reduciendo
significativamente el tiempo total en analizar un árbol grande de scripts[1]. Además, la
arquitectura de streaming evita cargar todo en memoria: los resultados se formatean y muestran
conforme llegan, manteniendo un consumo de memoria moderado incluso con muchos archivos.

Cobertura multi-lenguaje (PowerShell + Python): La herramienta no se limita a un solo lenguaje de
scripting; integra dos de los lenguajes de scripting más usados en proyectos (PowerShell para
automatización en entornos Windows, Python ampliamente usado en múltiples contextos). Esto aumenta
su alcance y utilidad, pudiendo auditar repositorios híbridos. La implementación detecta
automáticamente la disponibilidad de Python 3 en el sistema y es tolerante a su ausencia (reportando
un error claro en lugar de fallar completamente en esos casos).

Auto-corrección de errores de sintaxis en PowerShell: Una característica notable es el intento de
reparar problemas de sintaxis/estilo automáticamente cuando un script PowerShell no puede ser
parseado inicialmente. Al invocar PSScriptAnalyzer con reglas de formateo (Invoke-ScriptAnalyzer
-Fix y Invoke-Formatter), se corrigen cosas como sangrías, cierres de bloques, etc., que pudieran
estar impidiendo el parseo[2]. Si la corrección tiene éxito, el script se vuelve a parsear. Esto
agrega resiliencia: el analizador logra procesar incluso scripts con pequeños defectos de estilo o
formateo, en lugar de omitirlos por completo. (Cabe destacar que el script controla que solo se
intente una vez por archivo para evitar bucles infinitos de corrección).

Información rica y detallada por función (PowerShell): Gracias al módulo auxiliar, la herramienta
genera una especificación rica de cada función PowerShell encontrada. Esto equivale a una
documentación interna del código: conocemos la firma de la función (parámetros y tipos), qué
comandos invoca, cómo maneja excepciones (bloques catch y tipos capturados), qué valores retorna,
etc. Tener estructurado el AST de cada función en JSON facilita eventualmente inspeccionar la lógica
o incluso realizar transformaciones o análisis adicionales. Pocas herramientas de análisis estático
ofrecen esta granularidad de detalles por función de forma automática.

Resaltado de llamadas importantes o potencialmente riesgosas: Tanto en PowerShell como en Python, el
resumen incluye un campo Interesting que actúa como alerta de posibles focos de atención. En
PowerShell señala usos de cmdlets y comandos que pueden ser fuente de problemas o requieren revisión
especial (ej. uso de Invoke-Expression, ejecución de procesos externos, cambios de políticas de
ejecución, etc.), y en Python lista funciones de sistema, llamadas a shell, operaciones de I/O y
funciones peligrosas como eval[6,4]. Esta selección actúa similar a una pequeña verificación de
buenas prácticas de seguridad: por ejemplo, Invoke-Expression es conocido por ser potencialmente
inseguro, y la herramienta lo sacaría a relucir. Esto ayuda a que un revisor se enfoque rápidamente
en qué partes del script podrían ser problemáticas o merecen auditoría más profunda.

Salida flexible y exportable: La herramienta proporciona una vista rápida en consola (tabla
resumida), muy útil para inspección interactiva, y permite exportar los resultados completos a
formatos CSV o JSON para procesamiento posterior. En particular, la opción JSON preserva la
estructura de datos compleja (incluyendo la lista completa de FunctionSpecs por archivo)[9,10]. Esto
es valioso para integrar el análisis con otras herramientas; por ejemplo, se podría indexar ese JSON
o generar reportes avanzados a partir de él. La documentación misma sugiere la posibilidad futura de
convertir las especificaciones en tablas Markdown o un dashboard estático[11], gracias a contar con
esos datos estructurados.

Compatibilidad y modernidad: Requiere PowerShell 7+, lo cual permite usar las características
modernas del lenguaje (como el paralelismo en runspaces) y asegura compatibilidad con sistemas
operativos actuales. También se integra con py launcher de Windows para localizar diferentes
instalaciones de Python, mostrando atención a portabilidad en distintos entornos. Adicionalmente, es
idempotente en cierto sentido: tras correr, limpia el archivo temporal del helper Python del
sistema, dejando el entorno como estaba.

En conjunto, estas fortalezas hacen que la implementación actual sea robusta para análisis estático
básico, adaptable a diferentes escenarios y con un nivel de detalle que sienta las bases para usos
más avanzados (documentación de código, refactorizaciones, etc.). La herramienta ya encapsula muchas
buenas prácticas, como apoyarse en AST en vez de texto plano, y aprovechar herramientas existentes
(el módulo PSScriptAnalyzer) para mejorar resultados.

## Limitaciones de la implementación actual

Pese a sus virtudes, la solución presenta también algunas limitaciones y áreas de mejora
importantes:

Alcance limitado de lenguajes: Actualmente el análisis solo cubre scripts PowerShell y Python. Si en
el repositorio existen otros tipos de scripts (por ejemplo, Bash/sh, JavaScript/TypeScript, etc.),
la herramienta no los analiza. Esto reduce su robustez frente a “otros scripts” en un sentido
amplio. Ampliar el soporte a más lenguajes requeriría agregar lógicas adicionales o integrar parsers
externos para esos lenguajes, algo no contemplado todavía.

Foco en metadatos estructurales, no en calidad/corrección del código: La herramienta extrae
información estructural (qué funciones hay, cuántas, qué comandos usan, etc.) pero no evalúa la
calidad ni detecta defectos lógicos del código en sí. Por ejemplo, no reporta si una función viola
guías de estilo (más allá de haber o no Set-StrictMode en PowerShell), si hay variables sin usar,
problemas de nombrado, posibles bugs comunes, etc. En PowerShell existe PSScriptAnalyzer con muchas
reglas de buenas prácticas, pero el script actual solo lo usa para formateo, no para obtener
advertencias/errores. Igualmente, en Python no se aplican linters como Pylint/Flake8 que detectarían
code smells o errores estáticos. En resumen, la salida nos dice qué hay en cada script, pero no qué
está bien o mal según estándares de calidad. Falta esa capa de análisis cualitativo.

Análisis de seguridad superficial: Aunque el campo Interesting destaca ciertas llamadas
potencialmente peligrosas, no es equivalente a un escaneo de seguridad completo. Por ejemplo, Bandit
(herramienta SAST para Python) tiene decenas de reglas para identificar vulnerabilidades (SQL
injection, uso inseguro de yaml.load, etc.), las cuales no están cubiertas por simplemente listar
llamadas interesantes. En PowerShell, no se están aplicando reglas específicas de seguridad (más
allá de marcar Invoke-Expression, etc.). Esto significa que la capacidad para analizar con precisión
aspectos de seguridad es limitada en la implementación actual.

Dependencia de intérpretes externos: Para analizar Python se invoca un intérprete Python externo
para cada archivo. Esto implica que el rendimiento del análisis Python puede degradarse si hay
muchísimos archivos .py, pues cada uno lanza un proceso Python separado. No se reutiliza un mismo
proceso para analizar múltiples archivos, ni se integra un parser Python en el propio PowerShell. Si
bien el paralelismo mitiga algo (varios Python pueden correr en paralelo), el overhead de lanzar
procesos repetidamente existe. En entornos con cientos de scripts Python, esta aproximación podría
ser menos eficiente que usar una biblioteca embebida o procesar múltiples archivos por lanzamiento.

Posible impacto en los archivos originales (efecto colateral): La función de auto-fix con
PSScriptAnalyzer modifica directamente el archivo PowerShell en disco (aplicando formato y fixes)
durante el análisis. Si bien esto permite parsearlo luego, también significa que el script original
sufre cambios de estilo (p. ej. indentación ajustada, etc.) sin intervención del usuario. En
contextos de solo análisis, modificar los artefactos podría ser indeseable. La documentación sugiere
tener cuidado con esto y quizá limitar esa auto-corrección a ciertos casos[12]. En la implementación
actual no hay opción para hacerlo en modo “sólo lectura” salvo deshabilitar PSScriptAnalyzer. Esto
puede ser visto como una limitación (aunque menor), especialmente si el análisis se ejecuta sobre un
repositorio y uno no desea que se reformatee código automáticamente en ese momento.

Ausencia de métricas de complejidad o tamaño del código: El reporte no incluye mediciones
cuantitativas de la complejidad de los scripts más allá del conteo de funciones. Por ejemplo, no
informa el número de líneas de código de cada script ni la complejidad ciclomatica de las funciones.
Herramientas como Radon para Python o análisis de complejidad para PowerShell podrían aportar un
índice de qué tan complejo o mantenible es cada script, pero actualmente no está considerado. Esto
limita la “precisión” del análisis en términos de señalar código potencialmente difícil de mantener.

Sin detección de duplicación de código: Si hubiera bloques de código copiados entre scripts (código
duplicado), la herramienta no lo detectaría, ya que analiza archivo por archivo de forma aislada. En
proyectos grandes, identificar duplicación es útil para refactorización, pero no está soportado en
la implementación actual.

Configurabilidad y extensibilidad reducidas: Por el momento, la lista de comandos “interesantes”
está embebida y fija en el código (tanto para PS como Python). El usuario no puede fácilmente
ampliar o ajustar qué considera “interesante” sin editar el script. Tampoco hay opciones para
ajustar la profundidad del análisis (por ejemplo, excluir la generación del AST completo en
FunctionSpecs si solo se quiere un resumen, etc.). Esto podría considerarse una limitación en
términos de flexibilidad. Asimismo, aunque el script produce datos JSON detallados, aún no hay un
mecanismo implementado para indexarlos incrementalmente ni para generar reportes más amigables (esto
está mencionado como idea futura[11] pero no realizado).

Integración manual en flujos CI/CD: Actualmente, para usar esta herramienta hay que ejecutarla
manualmente y luego revisar la consola o abrir el CSV/JSON. No existe una integración directa con un
sistema de CI que pudiera, por ejemplo, hacer fallar un pipeline si se encuentran ciertos problemas.
La herramienta tampoco define umbrales (por ejemplo, “más de X funciones sin StrictMode es fallo”).
En otras palabras, sirve de diagnóstico pero no impone automáticamente políticas de calidad.
Incorporarla en un flujo automatizado requeriría trabajo adicional del usuario (interpretar el JSON
en un script CI, etc.). Esto no es un defecto del script per se, pero limita su efectividad práctica
a la hora de asegurar robustez si no se automatiza su uso.

Consideraciones de rendimiento no ajustables: El valor de ThrottleLimit=6 es fijo; en máquinas con
muchos núcleos podría infrautilizar recursos, y en máquinas con pocos quizás saturar. No hay un
parámetro para configurarlo dinámicamente según CPU disponibles. Además, la utilización de
Format-Table -AutoSize para la salida en pantalla implica que posiblemente el comando espere a tener
todos los resultados para ajustar columnas, lo cual podría demorar la impresión incremental. Aunque
el impacto es pequeño, son detalles que podrían optimizarse.

En síntesis, la implementación actual se concentra en qué hay en el código pero no en qué tan bueno
o seguro es ese código. Carece de integración de reglas robustas de estática que detecten malas
prácticas o vulnerabilidades de forma exhaustiva. También podría mejorar en rendimiento al escalar a
muchos archivos y en flexibilidad para soportar más lenguajes o métricas. Estas limitaciones abren
la oportunidad para varias mejoras, descritas a continuación.

## Recomendaciones de mejora

Con base en el diagnóstico anterior, se proponen varias mejoras concretas empleando técnicas,
herramientas y patrones modernos, para potenciar la robustez, eficiencia y precisión del análisis de
scripts:

### 1. Integrar analizadores estáticos y linters para evaluación de calidad

Una mejora sustancial sería complementar el análisis estructural existente con herramientas
estáticas de linteo que verifiquen adherencia a buenas prácticas y posibles errores. En PowerShell,
esto significa explotar al máximo PSScriptAnalyzer, y en Python, incorporar linters como
Pylint/Flake8 y analizadores de seguridad como Bandit:

Uso completo de PSScriptAnalyzer (PowerShell): Actualmente se usa PSScriptAnalyzer solo para
formatear, pero esta herramienta contiene decenas de reglas de calidad definidas por la comunidad
PowerShell. Se recomienda ejecutar Invoke-ScriptAnalyzer sobre cada script PS para recolectar
DiagnosticResults de sus reglas (p. ej., detectar variables no inicializadas, uso inapropiado de
Write-Host, ausencia de comentarios, etc.). PSScriptAnalyzer está diseñado justo para chequear
código PowerShell contra buenas prácticas reconocidas[13]. Es un módulo altamente configurable: se
pueden habilitar o deshabilitar reglas según convenga, e incluso crear reglas personalizadas en caso
de necesidades específicas[14]. Por ejemplo, se podría escribir una regla personalizada para
asegurar que todos los scripts establezcan Set-StrictMode -Latest al inicio (si no existe ya una
regla estándar para ello). Al integrar PSScriptAnalyzer de esta manera, el informe podría incluir un
resumen de hallazgos estáticos por script (cantidad de warnings/errores o los mensajes principales).
Esto aportaría precisión en la detección de defectos: por ejemplo, PSScriptAnalyzer alertaría de
inmediato sobre código dead code, funciones sin usar, prácticas de seguridad pobre, etc., que
actualmente pasarían inadvertidas[13]. Vale mencionar que PSScriptAnalyzer también permite incluir
módulos de reglas de seguridad, como InjectionHunter, para encontrar patrones de inyección en
scripts PowerShell[15,16]. Incorporar ese tipo de reglas fortalecería la dimensión de seguridad en
el análisis.

Linters de Python (Pylint/Flake8/Ruff): Del lado de Python, se sugiere complementar el parser AST
básico con herramientas como Pylint o Flake8. Pylint, por ejemplo, comprobará estilo PEP8, detectará
código huérfano, complejidad excesiva, malas prácticas comunes y generará una calificación del
script, además de mensajes detallados[17,18]. Flake8 combina PyFlakes (errores lógicos), pycodestyle
(estilo PEP8) y McCabe (complejidad ciclomatica)[19,20]. Incluso una opción muy interesante y de
alto rendimiento es Ruff, un linter moderno en Rust que implementa multitud de reglas de PEP8,
seguridad y mejores prácticas a una velocidad muy superior a Pylint (Ruff ya está siendo adoptado en
2025 en múltiples proyectos). Estas herramientas pueden ser invocadas desde PowerShell (por ejemplo,
ejecutando flake8 o ruff via llamada al intérprete) y parseando su salida. Otra alternativa es usar
Prospector, que actúa como un agregador de varios linters (Pylint, pycodestyle, McCabe, Bandit,
etc.) y proporciona una visión holística de la calidad de código Python[21,22]. Integrar Prospector
significaría con un solo comando obtener reportes unificados de estilo, errores y seguridad para
cada archivo Python.

Análisis de seguridad con Bandit (Python): Para la vertiente de seguridad en Python, Bandit es la
herramienta estándar. Bandit examina el AST de cada archivo Python y aplica plugins que detectan
patrones de vulnerabilidades comunes[23] (SQL injection, uso de funciones de hashing inseguras,
contraseñas hardcodeadas, etc.). Actualmente el script marca algunas llamadas peligrosas, pero
Bandit llevaría esto a otro nivel con decenas de comprobaciones. Se puede ejecutar bandit -r
<directorio> y obtener un informe de hallazgos de seguridad para todos los scripts Python. Incluir
en el reporte un conteo de issues de Bandit por archivo o incluso listar brevemente los más
importantes con sus niveles (alto/medio/bajo) haría el análisis mucho más robusto en precisión,
cubriendo huecos que el listado manual de llamadas no alcanza. Por ejemplo, Bandit detectará si se
usa yaml.load sin especificar SafeLoader (riesgo de deserialización insegura), cosa que un simple
scan de llamadas no sabría evaluar.

Resumen integrable de calidad: Los datos extra de estas herramientas podrían integrarse al JSON
final. Ejemplo: añadir campos como PSStyleIssues o PyLintScore o SecurityFindings. Al hacerlo, se
podría implementar un “quality gate” sencillo – por ejemplo, marcar un script como problemático si
PSScriptAnalyzer arrojó errores de severidad alta o si Bandit encontró vulnerabilidades de nivel
alto. Esto prepara el camino para automatizar decisiones (ej. fallar un pipeline de CI si un script
nuevo viola ciertas reglas).

Incorporar estos linters y analizadores estáticos alineará la herramienta con las mejores prácticas
de la industria, donde el código se revisa no solo por su estructura sino por su calidad.
Herramientas de análisis de código comerciales e integraciones CI (Codacy, SonarQube, etc.) ya
combinan multiples analizadores: por ejemplo, Codacy al analizar un proyecto utiliza
PSScriptAnalyzer para PowerShell y Bandit/Pylint/Ruff para Python entre otros[24], precisamente para
obtener una imagen completa. Seguir este patrón reforzará la utilidad de Neurologic/Tools.

### 2. Incorporar métricas de complejidad y mantenibilidad del código

Para mejorar la profundidad del análisis, sería valioso agregar mediciones cuantitativas que
permitan evaluar qué tan complejo o riesgoso es el código de cada script:

Complejidad ciclomatica (CC): Calcular la complejidad ciclomatica de cada función o script ofrece
una medida objetiva de la dificultad de entendimiento/pruebas. En Python esto se puede lograr
integrando la librería Radon, que parsea el AST y calcula la CC por función y asigna una
calificación de mantenibilidad. Radon, por ejemplo, puede indicar que una función tiene CC=15 (un
poco alta) y asignar una nota como "B" o "C" en mantenibilidad[25,26]. En PowerShell no hay una
herramienta tan estándar como radon, pero se podría implementar una función que a partir del AST
cuente decisiones (if/loops) para estimar la complejidad, o buscar alguna librería .NET existente.
Agregar un campo CyclomaticComplexity por función en las FunctionSpecs o un promedio por script
permitiría identificar código extremadamente complejo que podría necesitar refactorización.

Tamaño y longitud del código: Aunque trivial, incluir el número de líneas de cada script y quizás el
número de líneas por función complementaría la interpretación. Un script con 10k líneas merece mayor
escrutinio que uno de 50, y actualmente eso no se ve directamente. Se podría calcular con una simple
cuenta de líneas no vacías/ comentario. Esto es útil también para normalizar otras métricas.

Detección de duplicación de código: Considerar integrar una herramienta como PMD CPD (Copy/Paste
Detector) u otras similares para encontrar bloques duplicados entre scripts[27,28]. Dado que el
objetivo es auditar repos, a veces es importante saber si el mismo fragmento inseguro aparece en
múltiples lugares. CPD soporta muchos lenguajes (incluyendo Python) y podría señalar “el bloque X
aparece en el script A y B”, indicando posible refactorización o riesgo replicado. Quizá su
integración directa sea compleja, pero alternativamente, dado que ya se tiene el texto de cada
función (el AST incluye extents de código), se podría hash de contenido de funciones para ver
duplicados exactos.

Índice de mantenibilidad: Algunas herramientas (Radon la calcula para Python) combinan métricas de
complejidad, longitud y comentarios en un índice compuesto. Implementar algo así para cada script
(ej. “Maintainability Index” estándar) daría una visión rápida de qué tan difícil de mantener es un
archivo en general. Un índice bajo podría disparar alarmas.

Añadiendo estas métricas al reporte, se gana precisión en la evaluación: no se limita a listar
componentes, sino que cuantifica la salud del código. En la práctica, estos números ayudan a
priorizar: por ejemplo, funciones con CC muy alta o scripts enormes se podrían marcar para revisión.
Esto coincide con tendencias en análisis estático moderno, donde además de reglas de estilo, se
monitorean complejidad y duplicación para evitar deuda técnica.

### 3. Optimización del rendimiento y escalabilidad del análisis

Para hacer la herramienta más eficiente, especialmente en repositorios grandes o uso repetitivo, se
proponen varias optimizaciones:

Reutilización de intérprete Python: En lugar de lanzar un proceso Python por archivo .py, considerar
agrupar análisis de Python. Por ejemplo, se podría modificar el helper Python para que acepte
múltiples archivos en una sola ejecución y devuelva un JSON con la lista de resultados. Así, cada
runspace PowerShell podría procesar un lote de archivos Python de golpe, reduciendo la sobrecarga de
iniciar procesos. Incluso se podría tener un enfoque híbrido: usar un hilo dedicado que corra un
script Python que lea de un pipeline los nombres de archivo y emita resultados (similar a un
servicio). Dado que Python es rápido parseando, el cuello de botella actual es más el overhead de
invocación repetida. Otra opción más ambiciosa sería integrar un parser Python embebido. Por
ejemplo, usar IronPython (implementación de Python sobre .NET) para parsear internamente, o invocar
directamente desde PowerShell a una librería .NET como Python.Runtime (Python.NET) si existiese. No
obstante, simplemente agrupar llamados puede ser suficiente para un gran boost de rendimiento si hay
miles de archivos Python.

Paralelismo adaptable: Convertir ThrottleLimit en un parámetro configurable o incluso autodetectarlo
según el entorno. Por ejemplo, usar [Environment]::ProcessorCount para establecer un límite dinámico
de hilos (quizá CPU count - 1 por seguridad). Esto haría el script más eficiente en máquinas con 8+
cores (podría subir de 6 a 8 hilos, etc.) y más seguro en máquinas dual-core (bajar a 2 para no
saturar). Además, se podría implementar un pool de runspaces persistente si se planea ejecutar el
análisis muchas veces (aunque en la mayoría de casos correrá una vez, así que crear runspaces sobre
la marcha está bien).

Análisis incremental/persistente: Actualmente cada ejecución analiza todo desde cero. Una mejora
para eficiencia en el tiempo sería aprovechar los resultados previos cuando se corra frecuentemente
sobre el mismo proyecto. Por ejemplo, la herramienta podría guardar archivos .spec.json por cada
script (como mencionó la documentación, emulando el antiguo Analizador_Funciones)[11]. En una
siguiente ejecución, podría saltar análisis de archivos que no cambiaron (comparando timestamp o un
hash) y reutilizar sus resultados guardados, analizando solo archivos nuevos o modificados. Esto es
especialmente útil en integración continua: si en un commit solo cambian 2 scripts de 50, no es
necesario reprocesar los 50 siempre. Implementar esta caché persistente reduciría drásticamente el
tiempo de análisis en ciclos repetitivos, haciendo la herramienta más escalable en proyectos grandes
a largo plazo.

Modo sin efectos colaterales: Ofrecer una opción (ej. -ReadOnly o -NoFix) para no alterar archivos
durante el análisis. Con esta bandera, se saltaría la llamada a Invoke-ScriptAnalyzer -Fix y solo se
reportarían errores de parseo en lugar de intentar corregirlos. Esto garantizaría que el proceso de
análisis no cambia el repo, lo cual es preferible en ciertos entornos (por ejemplo, un pipeline de
CI que solo quiere analizar pero no tocar el código). El usuario podría decidir según el contexto:
en local quizás quiere autoformato, en CI no.

Mejor manejo de la salida concurrente: Si se desea que la tabla en consola se vaya actualizando en
tiempo real, se podría evitar Format-Table -AutoSize (que espera a formatear completo) y usar en su
lugar quizá Out-Host o formatos de ancho fijo predefinido, aunque con columnas variables es
complejo. Otra alternativa es imprimir cada resultado en una línea formateada simple (CSV-like) a
medida que llega. Esto sacrifica la bonita alineación pero da feedback inmediato. Es un trade-off a
evaluar: actualmente se priorizó estética sobre inmediatez. Documentar esta consideración o permitir
un modo -LiveOutput podría ser útil.

En general, estas optimizaciones apuntan a que la herramienta pueda manejar volúmenes mayores de
código de forma más rápida y con más control. Especialmente la idea de análisis incremental (que el
propio autor de la doc insinuó) la hará más apta para integrarse en ciclos continuos sin incurrir en
tiempos largos innecesarios.

### 4. Extender el soporte e interoperabilidad a más lenguajes y herramientas

Para hacer el análisis más robusto y general, se puede planificar soporte a otros tipos de scripts y
aprovechar frameworks multi-lenguaje:

Soporte para scripts Bash/Batch/Otros: Si el repositorio tiene scripts de shell (extensión .sh) o
archivos por lotes (.bat/.cmd), actualmente se ignoran. Se podría integrar al menos una detección
básica para estos. Por ejemplo, para Bash existen parsers AST como shfmt (que tiene modo parser
JSON) o se podría usar Tree-sitter, una biblioteca genérica de parseo. Tree-sitter permite obtener
árboles de sintaxis para decenas de lenguajes de forma unificada[29]. De hecho, proyectos modernos
de análisis de código usan Tree-sitter para soportar múltiples lenguajes con un solo motor de
consultas. Una idea sería invocar un parser Tree-sitter CLI (hay bindings para Node, Python, Rust)
para archivos que no sean PS ni Python, y extraer funciones o comandos de shell script, por ejemplo.
Esto ampliaría la cobertura significativamente, haciendo la herramienta aplicable a prácticamente
cualquier repositorio con scripts heterogéneos.

Reglas de búsqueda de patrones con Semgrep o Tree-sitter queries: Otra vía es integrarse con
Semgrep, un analizador estático ligero que soporta muchos lenguajes mediante patrones semánticos.
Semgrep permite escribir reglas en YAML que buscan patrones en el AST de distintos lenguajes
(ejemplo: "buscar cualquier ejecución de sistema con argumentos sin sanitizar"). Es ampliamente
usado en la industria por su flexibilidad multi-lenguaje. Slack, por ejemplo, lo utiliza para
escanear 6 lenguajes diferentes con un solo motor de reglas[30], y recientemente lograron extenderlo
para soportar su propio lenguaje (Hack) mediante la generación de gramáticas Tree-sitter[31,32]. Si
nuestra herramienta exporta los datos o si queremos agregar detecciones más complejas de patrones,
podríamos apalancar Semgrep en segundo plano para ciertos checks. Por ejemplo: ejecutar reglas
Semgrep de seguridad en los archivos Python (Semgrep soporta Python y muchos otros). Semgrep ya
tiene rulesets existentes (para OWASP, mejores prácticas, etc.) que podríamos reutilizar.

Interoperabilidad con formatos estándar: Para facilitar la integración con otros sistemas,
considerar soportar salida en formatos estándar de reporte estático, como SARIF (Static Analysis
Results Interchange Format) que es un JSON común que muchas herramientas de devops reconocen. O
incluso generar Markdown directamente para proyectos GitHub (e.g., un informe Markdown con tablas de
hallazgos). Esto haría más sencilla la adopción de los resultados por otras plataformas.

En resumen, ampliar horizontes hacia más lenguajes y adoptar herramientas genéricas (Tree-sitter,
Semgrep) haría la solución más robusta en el sentido de ser aplicable a diferentes tecnologías y
adaptable a futuros lenguajes sin empezar de cero. Dado que el foco actual eran PS y Python, esto
puede ser una segunda fase, pero vale la pena considerarlo si “analizar otros scripts” eventualmente
abarca más que esos dos.

### 5. Mejores prácticas de la industria y ejemplos a imitar

Finalmente, es útil mirar cómo proyectos open-source y empresas abordan análisis de scripts para
inspirar mejoras:

Integración de múltiples análisis en plataformas CI: Ya mencionado, servicios como Codacy o
SonarQube analizan código combinando una serie de linters y analizadores especializados por
lenguaje. Codacy, por ejemplo, al escanear un proyecto PowerShell emplea PSScriptAnalyzer para
revisar el código[24]. Para Python, corre herramientas como Bandit (seguridad), Prospector/Pylint
(estilo y errores) e incluso Ruff y Semgrep para abarcar performance y patrones complejos[24]. Esta
combinación garantiza que el código se evalúa desde varias perspectivas (formato, errores lógicos,
complejidad, seguridad). Nuestra herramienta debería aspirar a algo similar en su dominio:
aprovechar los mejores analizadores disponibles en lugar de reimplementarlo todo. La buena práctica
aquí es no reinventar la rueda donde ya existe una solución probada (por ejemplo, confiar en
PSScriptAnalyzer para rules de PowerShell en vez de codificar manualmente decenas de checks).

Uso de AST para documentación y refactorización: Algunos proyectos open source generan documentación
automática de funciones a partir del AST o comentarios en el código. Por ejemplo, herramientas como
JSDoc para JS o Doxygen para C++ analizan la estructura del código para producir docs. En nuestro
caso, ya extraemos muchos datos; una buena práctica sería presentarlos de forma útil. La
documentación interna sugiere hacer tablas Markdown o dashboards[11]: implementar eso seguiría la
tendencia de proyectos que entregan artifacts de análisis legibles para humanos (p. ej., un informe
HTML/Markdown adjunto en una Pull Request mostrando los hallazgos). Un ejemplo a emular: un proyecto
podría, tras correr Analyze-Scripts, publicar un informe “Reporte de Análisis de Código” donde se
destaquen scripts problemáticos. Esto crea visibilidad y cultura de calidad en el equipo.

Enfoque incremental en análisis de seguridad (caso Slack): El blog de ingeniería de Slack compartió
cómo expandieron su análisis estático para seguridad. Su clave fue no empezar de cero, sino extender
una herramienta existente (Semgrep) y alimentarla con un parser (Tree-sitter) específico para su
caso[30,31]. La lección aquí es valiosa: cuando falta soporte para algo (en su caso, un lenguaje
propietario; en el nuestro, podrían ser ciertos patrones de nuestros scripts), conviene considerar
extender frameworks abiertos con reglas propias. Por ejemplo, podríamos escribir reglas Semgrep
específicas para PowerShell si quisiéramos detectar algo complejo que PSScriptAnalyzer no cubra. O
podríamos contribuir una gramática de PowerShell a Tree-sitter (si no existe ya) para usar sus
consultas. Slack logró parsear 5 millones de líneas de código con 99.999% de éxito gracias a
Tree-sitter[33], demostrando que las tecnologías modernas de parseo son altamente efectivas y
podrían ser incorporadas para robustez.

Automatización de quality gates: En entornos profesionales, es común establecer umbrales de calidad
(“quality gates”) que el código debe pasar antes de considerarse aceptable. SonarQube, por ejemplo,
permite configurar que la compilación falle si la cobertura baja de X% o si hay issues de cierto
nivel. En nuestro contexto, podríamos definir criterios como “ningún script debe tener errores de
parseo ni violaciones críticas de PSScriptAnalyzer; cada script Python debe tener 0 vulnerabilidades
HIGH de Bandit, complejidad ciclomatica < 10 en cada función”, etc. Implementar estas comprobaciones
(aunque sea manualmente interpretando el JSON de resultados) sería una buena práctica para mantener
la calidad a largo plazo. Podemos inspirarnos en herramientas CI existentes o incluso en la
documentación de calidad de Codacy que menciona cómo ajustar quality gates y métricas
objetivo【64†(find)】. La idea es que las mejoras técnicas propuestas no queden aisladas, sino que se
usen para enforzar estándares continuamente.

En conclusión, adoptar buenas prácticas de proyectos líderes significa: apoyarse en herramientas
especializadas (en vez de soluciones caseras frágiles), proporcionar visualizaciones e informes
accionables de los datos obtenidos, y usar el análisis estático de forma proactiva (integrado en el
ciclo de desarrollo, evitando que código deficiente llegue a producción). Siguiendo estas
recomendaciones, la herramienta Neurologic/Tools puede evolucionar de un analizador básico a una
suite de análisis estático poderosa y de amplio espectro, elevando significativamente la robustez,
eficiencia y precisión con la que analiza otros scripts.

Referencias

PowerShell PSScriptAnalyzer – Static code checker oficial con reglas de mejores prácticas[13,14].
Permite detectar defectos y formatear código automáticamente.

Snyk.io – 10 dimensiones del análisis estático en Python, incluyendo linters (Pylint, Flake8) y
detección de vulnerabilidades con Bandit[17,23].

Codacy Blog – Herramientas de análisis estático para Python, discute Radon (complejidad
ciclomatica), Bandit, Ruff, etc., y destaca su uso combinado para mejorar calidad de código[34,24].

Slack Engineering – Análisis estático a escala con Semgrep y Tree-sitter, ejemplo de extensión a
nuevos lenguajes y uso de patrones AST para encontrar vulnerabilidades[31,32].

Documentación Analyze-Scripts.md – descripción de características y posibles extensiones de la
herramienta actual[1,35], base sobre la cual se plantearon las mejoras aquí descritas.

[1,2,5,9,10,11,12,35] Analyze-Scripts.md

https://github.com/victor982721-lab/Neurologic/blob/acabfcf56cada2fb60231dbc75d973649c1dcabe/Tools/Analyze-Scripts.md

[3,4,6,7,8] Analyze-Scripts.ps1

https://github.com/victor982721-lab/Neurologic/blob/acabfcf56cada2fb60231dbc75d973649c1dcabe/Tools/Analyze-Scripts.ps1

[13] PSScriptAnalyzer module - PowerShell | Microsoft Learn

https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview?view=ps-modules

[14,15,16] PSScriptAnalyzer: SAST Tool for PowerShell Script | by Vaibhav Kumar Srivastava | Medium

https://codewithvamp.medium.com/psscriptanalyzer-sast-tool-for-powershell-script-f2317e51e6e0

[17,18,19,23] 10 dimensions of Python static analysis | Snyk

https://snyk.io/blog/10-dimensions-of-python-static-analysis/

[20,21,22,25,26,27,28,34] Which Python static analysis tools should I use? - Codacy | Blog

https://blog.codacy.com/python-static-analysis-tools

[24] Supported languages and tools - Codacy docs

https://docs.codacy.com/getting-started/supported-languages-and-tools/

[29] Tips for using tree sitter queries - Cycode

https://cycode.com/blog/tips-for-using-tree-sitter-queries/

[30,31,32,33] How Two Interns Are Helping Secure Millions of Lines of Code | Engineering at Slack

https://slack.engineering/how-two-interns-are-helping-secure-millions-of-lines-of-code/
