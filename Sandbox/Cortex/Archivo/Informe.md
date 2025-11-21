# Informe Técnico: Mejoras Propuestas para el Script Monolítico RepoMaster.ps1

El script RepoMaster.ps1 es una herramienta monolítica para la administración de repositorios
Neurologic/Synapta. Integra múltiples funciones (creación de estructura Sandbox, sincronización Git
ascendiente/descendiente, merges de ramas Codex diarias, descarga de artifacts vía GitHub CLI,
análisis estático de código, validación de estructura de proyectos, entre otras). A continuación se
presenta un análisis de mejoras técnicas recomendadas para robustecer y modernizar el script,
manteniendo un solo archivo .ps1 (no se migrará a módulo) y asegurando compatibilidad con PowerShell
5.1+ en Windows 7, 8, 10 y 11. Las mejoras se dividen en secciones clave y posteriormente se propone
un plan de implementación por fases con prioridades.

## 1. Refactorización de Funciones – Separar Lógica de Negocio e Interfaz CLI

Actualmente, varias funciones en RepoMaster.ps1 mezclan la lógica interna con la interacción de
usuario mediante Read-Host[1]. Por ejemplo, funciones como Invoke-StructureCreator, Invoke-SyncUp,
Invoke-SyncDown o Invoke-ArtifactDownload realizan cálculos y operaciones al mismo tiempo que piden
datos al usuario o muestran menús. Esto dificulta la reutilización en otros contextos (por ejemplo,
llamar esas funciones desde scripts de automatización o pipelines CI/CD sin intervención humana),
complica las pruebas unitarias, y obliga a duplicar lógica si se quieren añadir nuevas interfaces o
automatizaciones[2,3].

Mejora propuesta: Mantener el archivo como monolito, pero refactorizar cada funcionalidad en dos
funciones separadas – una función “core” con la lógica pura y parámetros bien definidos, y una
función “UI” encargada de la interacción por consola[4].

La función core realizará toda la tarea (e.g. operaciones Git, manipulación de archivos, cálculo de
datos) sin ninguna llamada a Read-Host ni salidas interactivas. Recibirá por parámetro todo lo
necesario (paths, mensajes, banderas de confirmación, etc.) y retornará resultados o códigos de
estado.

La función UI asociada será la que use Read-Host o presente menús. Esta reunirá la información
solicitando entrada al usuario (proyecto, branch, confirmaciones Yes/No, etc.), llamará internamente
a la función core y luego mostrará el resultado al usuario.

Por ejemplo, se puede crear Invoke-SyncUpCore con parámetros $RepoPath, $Branch, $CommitMessage,
$ConfirmPush, que ejecute la lógica de git add/commit/pull/push sin interacción[5]. En paralelo
habría un Invoke-SyncUp (interactivo) que quizás solo tome $RepoPath y $Branch, pregunte al usuario
por el mensaje de commit y confirmación, y entonces invoque a Invoke-SyncUpCore con esos datos[6].

Beneficios:

* Reutilización y automatización: Separar lógica de la CLI permite invocar las operaciones desde otros scripts o procesos automatizados sin necesidad de entrada manual[2,3]. Por ejemplo, un pipeline CI podría llamar a Invoke-SyncUpCore -RepoPath X -Branch main -CommitMessage "CI commit" -ConfirmPush $true para subir cambios automáticamente.

* Testabilidad: La lógica en funciones core es más fácil de probar unitariamente, alimentándola con parámetros controlados y verificando su salida, sin tener que simular entradas de consola. Esto mejora la confiabilidad y facilita depuración de cada pieza de funcionalidad.

* Mantenibilidad: Se evita código duplicado y se aísla la complejidad. Si en el futuro se agrega una nueva interfaz (por ejemplo, un menú adicional o nuevos parámetros), la lógica central permanece en un solo lugar. Esto reduce errores y hace el código más claro, incluso manteniéndolo todo en un solo archivo.

* Conserva la experiencia actual: Los usuarios finales que prefieren el menú interactivo no verán diferencia, pues las funciones UI seguirán ofreciendo prompts similares. Solo que internamente estarán más ordenadas.

Cabe destacar que esta refactorización no implica convertir el script en módulo ni cambiar su modo
de despliegue; simplemente organiza mejor el código dentro del mismo archivo monolítico.

## 2. Soporte de Ejecución No Interactiva (Parámetros vs. Prompts)

Relacionado con lo anterior, conviene ampliar las funciones para aceptar parámetros opcionales en
lugar de depender estrictamente de Read-Host. Actualmente el script tiene algunos parámetros
globales (-InitialRepo y -AutoOption) para seleccionar opciones 1–6 automáticamente, pero dentro de
muchas funciones críticas aún se realizan preguntas interactivas forzosas[7]. Por ejemplo: -
Invoke-StructureCreator siempre pide por consola el nombre del nuevo proyecto (y confirmaciones
sobre reuso de carpetas). - Invoke-SyncUp siempre pide un mensaje de commit al usuario. -
Invoke-SyncDown infiere la fecha o nombre de la rama Codex del día, o la pide manualmente. -
Invoke-ArtifactDownload solicita por consola el ID de run de GitHub Actions y el nombre del artifact
a descargar, etc.

Mejora propuesta: Agregar parámetros opcionales a estas funciones (o a sus nuevas versiones core)
para todos esos datos que hoy requieren interacción[8]. Por ejemplo: - Invoke-StructureCreatorCore
-ProjectName "MiProyecto" -ForceReuse $true donde -ProjectName y una bandera -ForceReuse (para
omitir confirmaciones) permitan crear la estructura sin preguntar. - Invoke-SyncUpCore
-CommitMessage "Actualización" -Force $true para pasar el mensaje de commit y confirmar push
automáticamente. - Invoke-SyncDownCore -CodexBranch "codex_2025-11-19" o -CodexDate "2025-11-19"
para especificar qué rama Codex fusionar, en lugar de solo la fecha del día. -
Invoke-ArtifactDownloadCore -RunId 123456 -ArtifactName "build.zip" -TargetDir "C:\Temp" para
descargar un artifact concreto sin interacción.

En las funciones UI correspondientes, la lógica sería: si el parámetro fue proporcionado, usarlo
directamente; si no, entonces hacer Read-Host como de costumbre[9]. De este modo, el comportamiento
interactivo actual se mantiene, pero se añade la alternativa de ejecutar de forma no asistida.

Beneficios:

El script podrá ejecutarse de forma 100% no interactiva cuando sea necesario[10]. Por ejemplo, un
programador podría automatizar la descarga de artifacts nightly pasando los parámetros adecuados, o
un pipeline podría crear estructuras sandbox sin intervención.

* Integración CI/CD: Estas mejoras permiten usar RepoMaster.ps1 como parte de pipelines de integración continua (Quality Gates, despliegues, etc.). Se podría invocar con distintos parámetros en un ambiente de servidor sin nadie para responder prompts.

* Evitación de duplicación: Si más adelante se quieren exponer estas operaciones vía otra interfaz (por ejemplo, un GUI, una tarea programada, o integrarlas en otro script mayor), no será necesario reimplementar la lógica ni hacer workarounds para proveer la entrada simulada; simplemente se llamarán las funciones core con parámetros.

* Experiencia uniforme: Los usuarios interactivos siguen teniendo el menú y prompts tradicionales, mientras que los usuarios avanzados o procesos automatizados ganan flexibilidad. Todo dentro del mismo monolito.

## 3. Mejoras en el “Wizard” de Línea de Comandos (Menú Interactivo)

El flujo de menú CLI actual puede optimizarse para ser más intuitivo, seguro y visualmente claro.
Actualmente, el script presenta opciones numeradas y utiliza Read-Host para leer la opción deseada,
junto con múltiples confirmaciones manuales (“¿Está seguro? (S/N)”) dispersas. Esto funciona, pero
se puede hacer más robusto y agradable al usuario.

Mejora propuesta – Menús y selección interactiva: Emplear mecanismos integrados de PowerShell para
presentar opciones y capturar elecciones válidas en vez de procesar texto libre. Por ejemplo, usar
$Host.UI.PromptForChoice() con objetos ChoiceDescription permite mostrar un menú con varias opciones
predefinidas y obligar al usuario a escoger una de ellas (vía número o tecla de atajo)[11,12].
PowerShell por defecto usa este método para ciertos prompts (como confirmaciones de cmdlets) – se
pueden replicar esos diálogos en nuestro script.

Con PromptForChoice, el menú podría listar las operaciones (1. Crear Sandbox, 2. Subir cambios, 3.
Bajar cambios Codex, etc.) y el usuario solo presiona el número o la letra indicada. Esto elimina
entradas inválidas y simplifica el flujo (no hay que hacer validaciones manuales del input, el API
solo devuelve índices 0..N). Además, se pueden incluir descripciones de ayuda para cada opción que
el usuario vea escribiendo ?[13].

Para menús más avanzados, se puede explorar la captura de teclas para navegación con flechas (como
han implementado algunos scripts comunitarios[14]). Esto permitiría moverse por las opciones con ↑/↓
y Enter, haciendo la experiencia más parecida a un instalador interactivo. Si bien requiere manejar
entradas con [System.Console]::ReadKey() manualmente, es una mejora “visual” opcional para flujos
ágiles.

Mejora propuesta – Confirmaciones robustas: Reemplazar los simples Read-Host para “¿Seguro? (S/N)”
por métodos más seguros: - Utilizar nuevamente $Host.UI.PromptForChoice() con una pregunta de Sí/No.
Por ejemplo, presentar Sí y No como ChoiceDescription (con &S y &N como teclas aceleradoras) de modo
que el usuario deba oprimir S o N y Enter, y solo esos valores son aceptados automáticamente[12].
Esto evita casos donde el usuario ingrese cualquier otra cosa por error. - Alternativamente, marcar
las funciones críticas con the [CmdletBinding(SupportsShouldProcess)] y usar -Confirm. Dado que es
un script, quizás es más sencillo manualmente preguntar. Aun así, conviene centralizar estas
confirmaciones en funciones comunes para no repetir lógica. Por ejemplo, una función Confirm-Action
"Descripción de la acción" que devuelva $true/$false según la respuesta (internamente podría usar
PromptForChoice como se describió).

Mejora propuesta – Flujo más claro y feedback visual: - Limpieza de pantalla y formato: Considerar
limpiar la consola (Clear-Host) al iniciar el menú o ciertas fases, para reducir “ruido” de mensajes
anteriores. Además, usar colores en la salida con Write-Host -ForegroundColor para resaltar
resultados (ej. verde para “Éxito”, rojo para “Error/Conflicto”, amarillo para advertencias). Esto
guía al usuario a identificar rápidamente el estado de cada operación. - Indicadores de progreso:
Para operaciones que toman tiempo (por ejemplo, clonaciones, descargas de artifacts grandes,
ejecución de builds/tests en múltiples repos), usar Write-Progress para mostrar una barra de
progreso o al menos el estado actual (e.g. “Descargando artifact 20%…”). Esto hace el script más
“visual” en CLI y mejora la percepción de agilidad. - Resúmenes al finalizar tareas múltiples: Si el
script realiza acciones en lote (por ejemplo, la opción de Multi-repo que construye y prueba varios
proyectos), sería útil presentar un resumen final de resultados[15]. Por ejemplo, listar en una
tabla qué repos/proyectos fueron procesados con éxito y cuáles tuvieron fallos, en lugar de esperar
que el usuario lea toda la salida mezclada. Un resumen compacto de “✔ Repo1 (build OK), ✔ Repo2
(tests OK), ✘ Repo3 (falló build)” permite ubicar problemas más rápidamente.

Mejora propuesta – Consistencia de opciones automáticas: Actualmente, el script acepta -AutoOption
1..6 para elegir tareas automáticamente, pero internamente la función Execute-Option solo implementa
1..4; las opciones 5 y 6 no hacen nada (retornan “Opción no reconocida”)[16]. Esto debe corregirse
para coherencia: o bien implementar también la lógica para 5 (descarga de artifact) y 6 (análisis
estático) en modo no interactivo, o limitar el ValidateSet del parámetro para no aceptar 5/6[17].
Cualquiera de las dos soluciones evitará confusión al usar -AutoOption (que actualmente permite
invocar algo que no se ejecutará realmente). Se recomienda implementar dichas opciones
automáticamente si es posible, ya que con las mejoras de parámetros antes mencionadas, sería
sencillo pasar por ejemplo -AutoOption 5 -RunId X -ArtifactName Y para que también la descarga de
artifact pueda correr sin menú.

Beneficios: Estas mejoras en la interfaz CLI incrementan la usabilidad: - El usuario comete menos
errores al elegir opciones (menú guiado en lugar de tipeo libre). - Las acciones destructivas o
delicadas cuentan con confirmaciones más claras y a prueba de inputs inesperados. - Una interfaz
consistente (valida las mismas opciones tanto en modo automático como interactivo) genera confianza
en la herramienta[18]. - Con feedback visual (colores, progreso, resúmenes), el usuario obtiene
información inmediata del estado de las operaciones, mejorando la experiencia y eficacia al usar el
script.

## 4. Robustez y Validaciones Integradas (Errores, Análisis Estático y Conflictos)

Para hacer el script más robusto en entornos de producción, es fundamental incluir validaciones y
controles de calidad directamente en él, de forma que detecte condiciones anómalas o malas prácticas
sin depender de herramientas externas instaladas.

Mejora propuesta – Modo estricto y control de errores: Habilitar al inicio del script un modo
estricto de PowerShell para evitar que errores pasen silenciosamente. Específicamente: - Usar
Set-StrictMode -Version Latest nada más empezar (después de param(...)). Esto hará que usos de
variables no inicializadas, referencias a propiedades que no existen, o llamadas a funciones con
sintaxis incorrecta lancen errores inmediatos en vez de devolver valores nulos o vacíos[19,20]. En
otras palabras, similares a “Option Explicit” en VBScript, se fuerza a que el código sea más
correcto. - Forzar $ErrorActionPreference = 'Stop' de modo global[21]. Así, cualquier error no
manejado (no atrapado en try/catch) detendrá la ejecución del script en lugar de seguir adelante.
Esto previene que una falla en, por ejemplo, un comando externo (git que falle, o gh CLI que no
encuentre un artifact) pase desapercibida. Con 'Stop', si ocurre un error no contemplado, el script
abortará inmediatamente evitando continuar en un estado inconsistente.

Además, se recomienda revisar los bloques try/catch existentes: asegurarse de capturar
$_.Exception.Message o la información del error y loguearla al usuario o a un log, en lugar de
ignorarla[22]. De esa forma, si algo falla, habrá trazabilidad de qué y por qué falló.

Beneficios: Activar Strict Mode y ErrorActionPreference='Stop' eleva la robustez: - Se detectan
errores de programación sutiles (typos en nombres de variables, suposiciones incorrectas) durante el
desarrollo y pruebas, en lugar de producir comportamientos inesperados en producción[23]. Por
ejemplo, sin strict mode una variable $pathRepositorio mal escrita como $pathRepositori podría
evaluarse como $null y seguir adelante; con strict mode lanzará error inmediatamente identificando
la variable no establecida. - Evita continuar ejecuciones peligrosas tras un error crítico,
reduciendo el riesgo de “efectos colaterales”. Por ejemplo, si falla un git merge y no se detiene el
script, podría intentar hacer push con un merge incompleto; con ErrorActionPreference='Stop' eso no
sucederá[24]. - Facilita depurar y corregir: los errores no quedan ocultos, por lo que el
desarrollador del script sabrá que algo salió mal y podrá corregirlo en vez de tener un éxito
silencioso que en realidad no hizo nada.

* Mejora propuesta – Análisis estático PSSA integrado: El script ya cuenta con una función de análisis estático (posiblemente Invoke-PSSAAnalysis) que invoca PowerShell Script Analyzer (PSSA) para revisar la calidad del código. Sin embargo, según el análisis, actualmente se llama a Invoke-ScriptAnalyzer -Fix y se descarta la salida (| Out-Null), mostrando solo un mensaje genérico de “Análisis PSSA completado”[25]. Esto priva al usuario de conocer qué problemas halló la herramienta. Adicionalmente, PSSA está disponible como módulo externo, lo que implica que el análisis podría fallar si el módulo no está instalado en la máquina.

* Las mejoras propuestas son: - Incluir resultados resumidos de PSSA: En lugar de descartar la salida, capturarla en una variable y procesarla. Por ejemplo, contar cuántos warnings y errors retornó la herramienta, y luego imprimir un resumen: “PSSA: X errores, Y advertencias encontrados.”[26]. Incluso se puede listar brevemente las reglas más importantes violadas o los archivos afectados, si se desea detalle. - Fail-fast opcional: Ofrecer un modo estricto de calidad (quizá un parámetro -QualityGate o usar el mismo -AutoOption para que en CI falle) donde si PSSA detecta errores (o cierto número de warnings), el script termina con código de salida de error. Esto serviría en entornos de integración continua para bloquear merges si el código no pasa estándares. En modo interactivo normal, se podría simplemente advertir pero permitir continuar. - No depender de instalación externa: Para no requerir que el usuario instale el módulo PSScriptAnalyzer manualmente, se pueden tomar dos caminos: - Opción A: Integrar el módulo en el propio repositorio (por ejemplo, incluir los archivos de PSScriptAnalyzer en una subcarpeta del repo) y luego hacer Import-Module por ruta relativa. De esta manera, Invoke-ScriptAnalyzer estaría disponible aunque no esté instalado globalmente. Habría que manejar la versión (usar una compatible con PS 5.1). - Opción B: Si no se quiere incluir todo el módulo, usar .NET/AST para análisis básico. PowerShell expone su motor de parsing a través de [System.Management.Automation.Language.Parser]. Se podría invocar Parser.ParseFile() sobre los propios scripts .ps1 o .psm1 a revisar, obteniendo una lista de errores de sintaxis si los hubiera[27]. Incluso sin las reglas de estilo de PSSA, al menos detectaríamos si hay errores de sintaxis o tokens inesperados. De hecho, hay implementaciones de ejemplo que autochequean un script con AST cada vez que se ejecuta para garantizar que no contiene errores de sintaxis[28]. - Adicionalmente, ciertas validaciones simples de estilo se pueden codificar manualmente si es crítico (por ejemplo, asegurar que no haya comandos Write-Host directos en código de módulo, etc.), pero probablemente integrar PSSA ya cubre la mayoría de las reglas estándar.

Integrar PSSA de manera visible aporta transparencia al proceso de calidad. En entornos
colaborativos, los linters como PSSA ayudan a mantener consistencia[29,30]. Con estas mejoras, el
script no solo “arreglaría” potencialmente el código (si usaba -Fix), sino que informaría claramente
qué hallazgos hizo.

* Beneficios: - Conciencia de calidad: Los desarrolladores ven inmediatamente las advertencias/errores de estilo o mejores prácticas que existen en el código, en lugar de que el script los corrija silenciosamente o los omita[31]. Esto educa sobre las convenciones adoptadas y facilita limpiar el código manualmente. - Integración en flujos CI: El script puede actuar como un quality gate automatizado – por ejemplo, ejecutándose en un pipeline para asegurar que nadie hace push de código que viole ciertas reglas de calidad[32]. Si configuramos que “PSSA errores -> code exit 1”, entonces una tarea automatizada podría fallar y notificar a los desarrolladores antes de mergear. - No dependencia del entorno: Al no requerir que el usuario tenga instalado PSScriptAnalyzer globalmente (o al detectar y manejar su ausencia), aumentamos la portabilidad del script. Cualquier miembro del equipo, incluso en Windows 7 limpio, podría ejecutar el análisis ya que el propio script proveería la herramienta o al menos avisaría claramente su falta. - Detección temprana de errores de sintaxis: Con el uso de Parser.ParseFile u otro método AST, se podrían atrapar errores de sintaxis en scripts de proyecto antes de intentar ejecutarlos. Por ejemplo, si parte del pipeline es correr scripts en Scripts\*.ps1, se podría validar que todos estén sintácticamente correctos, evitando sorpresas en runtime.

* Mejora propuesta – Manejo seguro de merges y conflictos: Dado que una función central de RepoMaster es fusionar ramas Codex (ramas diarias), es crítico robustecer este proceso para no comprometer el repositorio principal: - Actualmente Invoke-SyncDown realiza git fetch, luego checkout/merge de la rama Codex (nombrada Codex_YYYY-MM-DD o similar) y después ejecuta un git status buscando conflictos marcados UU[33]. Si detecta “UU” en la salida, asume conflicto y probablemente aborta el push. - Se propone verificar explícitamente códigos de salida y estado de la rama tras merge. Es decir, inmediatamente después de git merge, comprobar $LASTEXITCODE. Si el merge devuelve código distinto de 0 (indicando conflictos no resueltos), no continuar con push y notificar al usuario claramente que hubo conflictos[34]. Adicionalmente, en lugar de buscar solo “UU”, conviene revisar la salida de git status --porcelain en busca de cualquier indicio de cambio sin resolver (archivos no fusionados, marcadores de conflicto, etc.)[35]. Si el status no está “clean”, debe evitarse el git push. - Incluir un mensaje de ayuda: en caso de conflicto, indicar al usuario qué hacer, por ejemplo: "Conflictos detectados. Por favor resuélvalos manualmente ejecutando git status y git mergetool, luego confirme los cambios y ejecute git push manualmente." Esto orienta al usuario menos experto en Git sobre los pasos siguientes, en lugar de un fallo genérico. - También se podría ofrecer (como idea futura) integrar una llamada a git mergetool o similar, pero eso ya sale del alcance normal del script automatizado. Mejor es detenerse y dejar que el usuario resuelva con las herramientas apropiadas.

Con esto, el script no intentará hacer push de merges incompletos o con conflictos. Es una mejora de
integridad de datos de alta prioridad, ya que evita ensuciar la rama principal con un commit
problemático[36].

* Mejora propuesta – Manejo de remotos Git y repos no estándar: Otra validación importante es sobre supuestos de la configuración Git: - El script asume que el remoto Git relevante se llama origin y que apunta a GitHub.com[37] (esto probablemente para derivar la URL de GitHub y usar gh CLI en la descarga de artifacts). Si alguien tiene un remoto distinto (ej. upstream en lugar de origin, o está usando Azure DevOps, etc.), podría fallar de forma no intuitiva. - Se propone mejorar la función que obtiene el slug del repo (Get-RepoSlug) para aceptar un parámetro -RemoteName con valor por defecto 'origin'[38]. Así, si un usuario tiene un remoto diferente, puede indicarlo al script. - Además, validar la URL: si la URL del remoto seleccionado no contiene “github.com”, mostrar un mensaje claro de que las funcionalidades de artifacts solo funcionan con repos alojados en GitHub[39]. Esto en lugar de arrojar un error genérico al ejecutar gh CLI. Si en un futuro se quisiera soportar otro hosting, habría que implementarlo explícitamente; por ahora, una advertencia ayuda al usuario a entender la limitación. - Por último, si no se encuentra el remoto esperado (origin por defecto), capturar ese caso y listar los remotos disponibles (git remote -v) para que el usuario sepa qué nombres existen. Se puede incluso recomendar: “Remoto 'origin' no encontrado. Use git remote rename <existente> origin o ejecute el script con -RemoteName <nombre> para especificar otro.”

* Beneficios: Estas validaciones de entorno de Git hacen al script más robusto frente a configuraciones distintas[40]. En vez de “fallar misteriosamente”, dará mensajes de error claros y accionables, ahorrando tiempo de diagnóstico. El usuario sabrá inmediatamente si el problema es que apuntó a un repo no GitHub, o que su remoto se llama diferente, etc., y podrá corregirlo. Esto mejora la confiabilidad percibida de la herramienta.

En resumen, todas estas mejoras de robustez (modo estricto, controles de error, análisis de código
embebido, chequeos de conflictos y entorno) apuntan a que RepoMaster.ps1 se comporte de forma más
segura y predecible incluso en escenarios adversos, facilitando tanto la corrección de problemas
como la prevención de daños.

## 5. Uso de .NET Embebido para Funcionalidades Avanzadas

Aunque PowerShell provee muchísima funcionalidad de alto nivel, a veces aprovechar clases .NET
directamente puede brindar capacidades adicionales o mayor eficiencia, especialmente manteniendo
compatibilidad con PS 5.1 (basado en .NET Framework). Se sugiere evaluar puntos del script donde
invocar métodos .NET in situ aporte valor:

Análisis y manipulación de archivos: Para inspeccionar o modificar ciertos archivos de proyecto, las
clases .NET pueden ser útiles. Por ejemplo, si se necesita leer un .csproj o .json de configuración,
usar [xml] o System.Xml.XmlDocument para XML, o System.Text.Json (en PS7) / Newtonsoft.Json (se
puede cargar DLL en PS5) para JSON, permite un control más fino que hacer parsing manual con regex.
Del mismo modo, operaciones de I/O masivo (copiar/mover muchos archivos, calcular hashes, etc.)
pueden beneficiarse de métodos nativos de System.IO que suelen ser más rápidos que loops en
PowerShell puro.

Descarga y descompresión de artifacts: Actualmente se utiliza la CLI de GitHub (gh.exe) para
descargar artifacts, y luego posiblemente se extraen manualmente. Una alternativa (no necesariamente
para ya, pero a considerar) es usar directamente la API REST de GitHub mediante .NET (clase
System.Net.Http.HttpClient) para descargar el artifact zip, y luego descomprimirlo con clases .NET.
.NET Framework 4.5+ incluye System.IO.Compression.ZipFile que permite crear y extraer archivos ZIP
fácilmente[41,42]. De hecho, muchos prefieren usar las APIs .NET nativas en lugar de instalar
herramientas externas o módulos adicionales[42]. En este caso, el script podría detectar: si no está
gh instalado, intentar con HttpClient + autenticación (aunque eso implica manejar token de GitHub).
Si gh está presente, perfecto. Pero de cualquier forma, una vez obtenido el .zip, en lugar de
requerir que el usuario lo extraiga manualmente, el script podría llamar a
[System.IO.Compression.ZipFile]::ExtractToDirectory(archivo, destino) para dejar listo el contenido
en la carpeta objetivo.

Operaciones concurrentes: Si en el futuro se quisiera acelerar alguna tarea (por ejemplo, ejecutar
análisis o pruebas en varios repositorios en paralelo), se podría utilizar programación .NET de
múltiples hilos o jobs de PowerShell. PowerShell 5.1 permite usar Start-Job (que crea procesos
aparte) o para algo más ligero, crear runspaces vía .NET. Si bien esto añade complejidad, es una
posibilidad: el script podría, por ejemplo, lanzar múltiples tareas en paralelo y luego recopilar
resultados, en lugar de secuencial, aprovechando múltiples núcleos. Esto estaría respaldado por .NET
(clases de System.Management.Automation para runspaces o TPL en C#). Es una mejora avanzada y
opcional, mencionada como horizonte a explorar.

Funciones del sistema operativo: Usando .NET se puede acceder a funcionalidades de Windows no
expuestas directamente en cmdlets de PS 5.1. Por ejemplo, para manipular el registro de Windows
(PS6+ no trae Microsoft.PowerShell.Management por defecto, pero en PS5.1 sí existe via .NET), o para
usar GUI simples (via Windows Forms/WPF) si alguna vez se quisiera una ventana de selección de
archivo o similar, se puede invocar [System.Windows.Forms.OpenFileDialog] etc. Dado que buscamos
permanecer en CLI, esto último no es prioridad ahora, pero es bueno tener presente que el monolito
puede hacer “casi cualquier cosa” si aprovechamos la plataforma .NET subyacente.

Análisis del código fuente: Como ya se mencionó, el uso de clases .NET como
System.Management.Automation.Language.Parser nos dio la capacidad de analizar la sintaxis de scripts
PowerShell internamente[27]. De forma similar, si quisiéramos inspeccionar código C# en los repos
(por ejemplo, para verificar versiones de paquete, frameworks objetivos, etc.), podríamos usar
bibliotecas .NET (como Microsoft.Build APIs o Roslyn) directamente dentro del script. Un caso
sencillo: verificar que todos los proyectos utilizan ciertos TargetFrameworks. En lugar de buscar
texto, podemos cargar cada .csproj como XML (ya que MSBuild projects son XML) y consultar los nodes
<TargetFramework>...</TargetFramework>; esto es más confiable que una búsqueda de string y aprovecha
.NET.

Mejor manejo de errores y excepciones: Llamar métodos .NET nos da excepciones ricas de .NET que
podemos capturar en try/catch y procesar. Por ejemplo, si utilizamos [System.IO.File]::ReadAllText()
y falla, podemos detectar si fue por FileNotFound, acceso denegado, etc., mediante la excepción
específica. Esto podría alimentar mensajes de error más detallados al usuario (traducir “Acceso
denegado al leer X, verifique permisos” en lugar de un genérico).

En resumen, aprovechar .NET embebido hace al script más potente sin perder su forma (monolítica).
Ciertas operaciones pueden simplificarse o acelerarse significativamente usando llamadas directas a
clases de .NET Framework en vez de reinventar la rueda en PowerShell. Un punto importante: dado que
apuntamos a compatibilidad con Windows PowerShell 5.1, debemos atenernos a .NET Framework 4.x. Esto
significa que no se deberían usar APIs que solo existen en .NET Core/5/6 a menos que se compruebe la
versión de PS en runtime. Por suerte, .NET Framework 4.8 (última en Win10/11) es bastante completa;
por ejemplo, todas las clases mencionadas (System.IO, System.Xml, System.Net.Http, etc.) están
disponibles allí.

Beneficios: Incorporar .NET de forma estratégica ofrece: - Menos dependencias externas: se pueden
lograr cosas con las clases base sin requerir módulos de terceros ni utilidades externas,
manteniendo el entorno del servidor más limpio[42]. - Mejor rendimiento en algunos casos: Por
ejemplo, procesar archivos binarios o grandes volúmenes de texto puede ser más rápido con métodos
.NET que con loops de PowerShell. - Capacidades ampliadas: Permite al script hacer prácticamente
cualquier cosa que una aplicación .NET haría, dando flexibilidad para futuras expansiones (ej:
enviar peticiones web, manipular zip, acceder a APIs de Windows, etc.) más allá de lo que PowerShell
ofrece por defecto. - Uso eficiente de recursos: PowerShell es potente pero a veces verboso; un
llamado estático de .NET puede reemplazar decenas de líneas de script. Menos código, menos potencial
de bug humano, aprovechando implementación ya probada de .NET.

Naturalmente, cada adición de .NET debe evaluarse para no complejizar innecesariamente el script. La
recomendación es usarlo cuando aporte claridad, velocidad o funcionalidad que justifiquen su
inclusión.

## 6. Compatibilidad con PowerShell 5.1+ y Windows 7–11

Es crucial que todas estas mejoras mantengan la compatibilidad hacia atrás con entornos legados
donde corra Windows PowerShell 5.1 (por ejemplo, algunos equipos con Windows 7, Windows Server 2012
R2, etc.), a la vez que funcionen correctamente en PowerShell 7.x en sistemas más nuevos. Tomaremos
en cuenta las siguientes consideraciones de compatibilidad:

Lenguaje y Cmdlets: PowerShell 5.1 (Windows PowerShell) y PowerShell 7+ (PowerShell Core) tienen un
alto grado de compatibilidad en lenguaje, pero existen diferencias en algunos cmdlets y módulos
disponibles[43]. Por ejemplo, cmdlets relacionados con tecnologías Windows (Registro, WMI, etc.)
vienen de base en PS5.1 pero en PS7 requieren importar módulos de compatibilidad. Para nuestro caso
(repos, git, files) no hay mucha diferencia, pero evitaremos usar características de sintaxis muy
nuevas (p.ej. el operador &&/|| encadenado, el operador ternario ? :, etc. introducidos en PS7) o,
si se usan, asegurarse de encapsularlos para no ejecutarlos en PS5.1.

Versión de .NET: PS5.1 se basa en .NET Framework 4.5/4.8, mientras PS7 se basa en .NET Core/ .NET
6/7/etc. Esto impacta en llamadas .NET directas – algunas APIs disponibles en .NET Framework no
existen en .NET Core (por ejemplo, clases de GUI de Windows), y viceversa algunas mejoras de .NET
Core no están en Framework[44,45]. Dado que apuntamos principalmente a Windows, si usamos clases del
Framework clásico (e.g. System.Windows.Forms), funcionarán en PS5.1 y también en PS7 en Windows
gracias a la compatibilidad con .NET Standard 2.0[46], pero no en Linux/macOS (lo cual no es
requisito aquí). En síntesis, probaremos cualquier función .NET añadida tanto en 5.1 como en 7.x
sobre Windows para garantizar que los métodos invocados existen en ambos runtimes.

Disponibilidad de utilidades externas: Verificar que herramientas externas necesarias estén
presentes en todos los entornos objetivo. Por ejemplo, Git obviamente debe estar instalado en la
máquina. GitHub CLI (gh): en Windows 7 podría requerir una versión específica (si la más nueva no
soporta Win7, habría que documentar la última compatible). Sería conveniente que el script al inicio
hiciera una comprobación rápida de prerequisitos: git, gh, dotnet SDK (si se usa dotnet build/test),
etc., y si falta algo, advertir claramente. Esto evita fallos más adelante con mensajes crípticos.
En caso de que alguna herramienta no esté, se puede abortar graciosamente indicando “Instale X para
usar la opción Y”.

Pruebas en entornos reales: Planificar pruebas en un Windows 7 con PowerShell 5.1, en un Windows
10/11 con PowerShell 5.1, y en Windows 10/11 con PowerShell 7.x. Esto cubrirá la mayoría de
variaciones. Windows 7 tiene ciertas limitaciones (no tiene .NET 4.8 de fábrica, pero se puede
actualizar; también el TLS 1.2 no estaba habilitado por defecto en .NET 4.5, lo cual podría afectar
descargas HTTPS con .NET – se puede forzar via [Net.ServicePointManager]::SecurityProtocol si fuera
necesario).

Manejo de diferencias de comandos externos: En PS7, los comandos externos (git, gh, etc.) se invocan
igual que en PS5.1, pero hay un matiz: en PS7, $LASTEXITCODE se actualiza, pero también existe $?
que indica solo si el proceso pudo ser lanzado. En general, usar $LASTEXITCODE es la forma correcta
de detectar si git devolvió error, y eso funciona en ambas versiones, así que estamos bien. Sin
embargo, aseguraremos de no usar construcciones obsoletas. Por ejemplo, en PS7 conviene usar
$env:VARIABLE en vez de %VARIABLE% para variables de entorno. Mantendremos sintaxis compatible.

Encoding y Consola: Windows PowerShell 5.1 por defecto usa encoding OEM (ej. CP850) en la consola,
mientras PS7 usa UTF-8. Dado que nuestro script puede imprimir textos en español (acentos) y
símbolos (✔✘ para resultados quizá), sería bueno asegurarse de la codificación. Podemos
explícitamente setear [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8 al inicio para uniformar
(esto en Win7/PS5.1 asegurará que caracteres especiales se muestren correctamente). Es un detalle
menor, pero mejora la experiencia en entornos con configuración regional distinta.

Política de ejecución: En sistemas antiguos podría estar restringida. Aunque no es directamente una
mejora de código, mencionar en la documentación que el script debe ejecutarse con ExecutionPolicy
permisivo (RemoteSigned, Bypass, etc.) en aquellos entornos, o firmar digitalmente el script si es
viable, para que en Windows 7/10 no bloquee su ejecución.

En síntesis, la meta es que RepoMaster.ps1 continúe funcionando sin problemas en PowerShell 5.1 en
Windows 7/8.1 (plataformas legacy que la empresa pudiera tener), a la vez que aproveche las mejoras
disponibles al correr en PowerShell 7 en Windows 10/11. Esto implica probar y condicionar el código
donde haya discrepancias. Por suerte, muchas de las mejoras propuestas (separación de funciones,
manejo de errores, mejoras de menú) son agnósticas de la versión de PowerShell, por lo que la
compatibilidad se mantiene si se implementan correctamente.

No se espera que sea necesario mantener versiones separadas del script; uno solo debe adaptarse
dinámicamente si requiere algo especial en PS7 (aunque la filosofía será codificarlo de forma
compatible desde el inicio). Documentaremos cualquier requerimiento especial en el encabezado del
script para los usuarios.

## 7. Otras Mejoras Adicionales Propuestas

Además de los ejes principales descritos arriba, se identificaron otros ajustes importantes para
mejorar la mantenibilidad y consistencia del script monolítico:

Centralización de constantes y configuración: Actualmente, ciertos valores “constantes” se repiten
en múltiples lugares del código – por ejemplo el nombre de la carpeta Sandbox ("Sandbox"), la lista
de frameworks de .NET soportados ("net8.0;net7.0;net6.0"), la estructura estándar de subdirectorios
(docs/, src/, tests/, etc.), prefijos de nombres de rama Codex ("Codex_" vs "codex_")[47]. Conviene
declarar estas como variables globales o constantes al inicio del script (por ejemplo, using
$Global: or script-scoped constants) y luego referenciarlas en las funciones[48]. De ese modo, si
mañana cambia el nombre de “Sandbox” o se agrega un nuevo framework, se actualiza en un solo lugar y
todo el script lo toma. Esto reduce errores y facilita configuraciones personalizadas.

Logs o salida a archivo (opcional): Para entornos donde se ejecuta el script en tareas programadas o
CI, podría ser útil que ciertas operaciones registren un log en archivo (especialmente errores o
resúmenes). Se puede implementar de forma sencilla, escribiendo en un archivo de texto append en
$env:TEMP o junto al script, cada vez que ocurre algo notable (e.g. “Repo X – merge conflict on Y”).
Esto complementa la salida en pantalla y ayuda a depurar después de ejecuciones no interactivas.

Ayuda integrada y documentación: Ya que seguimos en un monolito, es viable aprovechar los
comentarios en formato help (comentarios <# .SYNOPSIS ... .PARAMETER ... #> antes de funciones) para
documentar su uso. Incluir o actualizar la sección de ayuda hace que los usuarios puedan ejecutar
Get-Help .\RepoMaster.ps1 o Get-Help Invoke-SyncUp y obtener información de cómo usarlo. Tras las
mejoras de parámetros, esta documentación debe reflejar las nuevas opciones no interactivas, etc.

Validación de entorno de build/test: Dado que el script ejecuta dotnet build y dotnet test en
proyectos, se podría mejorar la detección de errores de build. Por ejemplo, capturar el código de
salida de dotnet y también escanear la salida en busca de las palabras “FAILED” o similar, para
identificar cuáles proyectos fallaron. Parte de esto se cubriría con el resumen de multi-repo ya
mencionado (se sabrá qué repo falló). Adicionalmente, si un build falla, quizás el script podría
proponer: “¿Desea abrir el log de errores? (S/N)” y si dice S, abrir el .trx o .log de test en
notepad. Aunque esto es más interactivo; en CI simplemente se tendría el log de consola.

Modo verbose/depuración: Incluir un parámetro global -Verbose o usar el sistema de Verbose nativo
(Write-Verbose) para que, si el usuario lo solicita, el script imprima información adicional (p.
ej., comandos git ejecutados, paths internos, etc.). Esto ayuda a diagnósticos cuando algo no va
bien, sin abrumar la salida normal en modo silencioso. PowerShell soporta -Verbose automáticamente
en funciones avanzadas; al convertir funciones con [CmdletBinding()], se puede aprovechar este
mecanismo.

Manejo de códigos de salida del script: Al final del script (en la parte que evalúa la opción
seleccionada), sería útil devolver un código de salida al sistema operativo distinto de 0 si algo
importante falló. Por ejemplo, si se ejecuta con -AutoOption en un pipeline, un error podría hacer
exit 1. Actualmente puede que el script siempre termine con 0 aunque falle una operación (a menos
que un throw no atrapado salga). Definir claramente los exit codes (0 = ok, 1 = error general, 2 =
error en análisis PSSA, etc.) haría más integrable la herramienta en otros procesos.

Estas sugerencias adicionales persiguen mejorar la mantenibilidad, información y profesionalismo del
script. Aunque individuales, en conjunto pulen la experiencia y la facilidad de mantenimiento a
largo plazo.

## 8. Plan de Trabajo por Fases y Prioridades

Para implementar las mejoras propuestas de forma organizada, se sugiere abordarlas en fases,
priorizando primero las de mayor impacto en robustez y funcionalidad básica, y luego las mejoras de
experiencia de usuario y mantenibilidad. A continuación, un plan esquemático por fases:

Fase 1 – Mejoras de Alta Prioridad (Robustez y Base Técnica):

Robustez de Ejecución: Implementar Set-StrictMode -Version Latest y $ErrorActionPreference = 'Stop'
al inicio del script, y ajustar try/catch para loguear errores. Prioridad: Alta[49].

Refactorización Lógica/UI: Separar las funciones principales en pares core/UI, y agregar parámetros
opcionales para inputs (proyecto, mensaje commit, etc.) según lo descrito en sección 1 y 2[50,8].
Asegurar que el modo existente del menú sigue funcionando con las nuevas funciones. Prioridad: Alta
(habilita bases para automatización)[51].

Soporte No Interactivo Completo: Tras la separación, verificar que con los nuevos parámetros se
pueden realizar las 5–6 operaciones principales sin intervención. Ajustar la lógica de
-AutoOption/Execute-Option para que las opciones 5 y 6 funcionen correctamente o restringirlas[16].
Prioridad: Alta (evita comportamientos inesperados).

Manejo de Merges y Conflictos: Mejorar Invoke-SyncDown para abortar en caso de conflicto, chequeando
$LASTEXITCODE y estado de repo limpio antes de push[34]. Añadir mensajes aclaratorios al usuario.
Prioridad: Alta (protege integridad de repos)[36].

Comprobaciones de entorno iniciales: (Rápido de hacer) Añadir validación de existencia de Git,
dotnet SDK, GitHub CLI, etc., con mensajes amigables si falta algo. Esto puede prevenir errores más
adelante. Prioridad: Alta (evita fallos tempranos).

Manejo básico de remotos: Implementar la opción de -RemoteName en las funciones que asumen origin
(e.g. Get-RepoSlug) y mensajes de advertencia si no es GitHub[52]. Prioridad: Media-Alta (no bloquea
funcionamiento normal, pero mejora robustez).

Resultado esperado de Fase 1: El script será mucho más confiable en su ejecución fundamental. Podrá
correrse automatizadamente con parámetros, no se romperá silenciosamente por variables mal escritas,
y evitará cometer errores graves en Git. Estas bases también facilitan las siguientes mejoras de
interfaz.

Fase 2 – Mejoras de Interfaz y Calidad (Prioridad Media):

Wizard CLI Mejorado: Incorporar $Host.UI.PromptForChoice en los menús principales para selección de
opciones y en confirmaciones críticas (Sí/No), sustituyendo Read-Host donde aplique[11,12].
Implementar colores en la salida y barras de progreso en operaciones largas para un feedback visual.
Prioridad: Media (mejora UX, no funcionalidad pura).

Integración de PSSA y Análisis Estático: Modificar Invoke-PSSAAnalysis para capturar resultados y
mostrar resumen (X warnings/ Y errors)[26]. Considerar incluir el módulo PSScriptAnalyzer en el repo
o al menos detectarlo y auto-instalarlo si falta (si hay internet), o utilizar Parser AST como
fallback. Opcional: añadir parámetro -QualityGate para fallar si hay errores PSSA. Prioridad:
Media[31].

Resumen en Multi-repo: Mejorar Invoke-MultiRepoMenu (u opción equivalente) para acumular los
resultados de build/test de cada proyecto y al final listar un resumen con qué repos tuvieron éxito
y cuáles fallaron[15]. Prioridad: Media (comodidad para el usuario).

Centralizar Constantes: Implementar sección de constantes globales al inicio (p. ej.
$NlgSandboxName="Sandbox", etc.) y reemplazar literales múltiples en el código por referencias a
estas constantes[48]. Prioridad: Media (evita inconsistencias futuras).

Otras Refactorizaciones Menores: Aplicar las mejoras adicionales de sección 7: actualizar la ayuda
en comentarios, añadir logging opcional si es sencillo, ajustar encoding de consola si se presentan
problemas de caracteres, etc. Prioridad: Media-Baja (no crítico pero útil para pulir).

Pruebas exhaustivas en distintos entornos: Durante esta fase, realizar pruebas funcionales completas
en PowerShell 5.1 (idealmente en Win7 y Win10) y PowerShell 7 (Win10/11) para confirmar que los
cambios de fase 1 y 2 no rompieron compatibilidad. Corregir cualquier issue específico detectado.

Fase 3 – Futuras Mejoras (a considerar):

Tras completar las anteriores, el script estaría bastante sólido. Como fase 3 (a implementar según
necesidad/prioridad futura) se pueden contemplar: - Paralelismo en operaciones batch: Si el
escenario de múltiples repos simultáneos crece, evaluar ejecutar builds/tests en paralelo usando
jobs o runspaces. - Integración con APIs o otras herramientas: Por ejemplo, posibilidad de crear
automáticamente un Pull Request en GitHub después de un SyncDown exitoso, usando la API REST via
Invoke-RestMethod o gh CLI. Esto ya sería una funcionalidad nueva, no tanto refactor. - Soporte
multiplataforma (PowerShell Core en Linux/Mac): Si alguna vez se quisiera usar este script en otros
OS (dado que PS7 es cross-platform), habría que abstraer las partes dependientes de Windows (ej.
dotnet sí corre en Linux, pero gh CLI también existe multiplataforma). No es un objetivo inmediato,
pero mantener el código lo más general posible ayuda si se decide dar ese paso.

En conclusión, aplicando este plan por fases se lograrán mejoras significativas manteniendo el
script monolítico: primero garantizando robustez y capacidad de automatización (fase 1), luego
optimizando la experiencia de usuario y calidad del código (fase 2). Las prioridades altas incluyen
todo lo que impacta estabilidad e integridad (strict mode, separación lógica, manejo de errores y
conflictos)[53], mientras que las prioridades medias abarcan mejoras de usabilidad y mantenimiento
que, si bien importantes, pueden implementarse en segundo término[54].

Con estas mejoras, RepoMaster.ps1 se mantendrá como un único script autoincluido, pero mucho más
sólido, flexible y cómodo de usar tanto en modo interactivo como en automatizaciones. Se evitarán
sorpresas por errores silenciosos, se agilizarán los flujos CLI y se incorporarán prácticas modernas
de PowerShell sin requerir reestructurar el proyecto por completo. En resumen, el script seguirá
sirviendo de herramienta central para la gestión de los repositorios Neurologic/Synapta, ahora con
mayor robustez y funcionalidad adaptada a las necesidades actuales y futuras.

Fuentes:

Análisis preliminar de mejoras (canvas interno) para RepoMaster.ps1[1,34]

Documentación de buenas prácticas de PowerShell (StrictMode, manejo de errores)[19,20]

Blogs técnicos sobre creación de menús interactivos en PowerShell[11,12]

Recomendaciones de uso de .NET en scripts para evitar dependencias externas (ejemplo: compresión
ZIP)[42,41]

Microsoft Docs – diferencias entre Windows PowerShell 5.1 y PowerShell 7 (consideraciones de
compatibilidad)[43,44]

[1,2,3,4,5,6,7,8,9,10,15,16,17,18,21,22,23,24,25,26,31,32,33,34,35,36,37,38,39,40,47,48,49,50,51,52,53,54]
canvas_mejoras_repo_master.md

[11,12,13] More Choices in PowerShell - Petri IT Knowledgebase

https://petri.com/more-choices-powershell/

[14] A better PowerShell Console Menu - Caroline Chiari

https://blog.carolinechiari.com/a-better-powershell-console-menu

[19,20] Enforce Better Script Practices by Using Set-StrictMode - Scripting Blog [archived]

https://devblogs.microsoft.com/scripting/enforce-better-script-practices-by-using-set-strictmode/

[27,28] How to avoid stupid mistakes in your powershell scripts (self-test your scripts) - How-to -
Duplicacy Forum

https://forum.duplicacy.com/t/how-to-avoid-stupid-mistakes-in-your-powershell-scripts-self-test-your-scripts/2008

[29,30] PowerShell Tools for the Advanced Use Cases, part 1

https://powershellmagazine.com/2015/10/12/powershell-tools-for-the-advanced-use-cases-part-1/

[41,42] compression - Powershell Script to Zip Files - Server Fault

https://serverfault.com/questions/527398/powershell-script-to-zip-files

[43,44,45,46] Differences between Windows PowerShell 5.1 and PowerShell 7.x - PowerShell | Microsoft
Learn

https://learn.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell?view=powershell-7.5
