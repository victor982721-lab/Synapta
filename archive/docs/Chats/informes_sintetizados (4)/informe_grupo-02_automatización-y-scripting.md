# Automatización y scripting

## Resumen ejecutivo

Este informe sintetiza 18 conversación(es) consolidadas del tema **Automatización y scripting**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1) **PS7 vs PS5.1.**
2) **Verbo incorrecto: “Ejecuta `RED-TEMARIO.md`”.**
3) **Línea truncada/rota**:
4) **Duplicación de encabezado**:
5) **Entrega y confirmaciones**:
6) **Alias de documentos “más reciente”**: falta criterio de desempate en caso de reloj desincronizado versus mtime.
7) **Enlaces “sandbox:/mnt/data/...”**: perfectos en este entorno; fuera de él, no.
8) **“Progreso visible”**: bien, pero no define **umbral** de “operación larga”.
9) Falta **carpeta estándar** para artefactos (`artifacts/`, `backups/`, `logs/`).
10) Falta mención de **PSScriptAnalyzer/Pester** como **compuerta de calidad** (están implícitos en el proyecto, no en este README).
1) **Unificar compatibilidad (PS 5.1 primero):**
2) **Corregir verbo (RED-TEMARIO):**
3) **Arreglar línea rota:**
4) **Eliminar duplicado de encabezado:**
5) **Aclaración Preflight:**
6) **Alias y desempates:**
7) **Enlaces locales:**
8) **Umbral de progreso:**
9) **Estructura de carpetas recomendada:**
10) **AutoQA ejecutable (añadir subsección nueva):**
1) Aplicar **parche 1–5** (compatibilidad, verbo, línea, duplicado, aclaración preflight).
2) Añadir **subsección AutoQA ejecutable** y publicar `Invoke-ArtifactQA.ps1`.
3) Publicar **snippet de elevación** y **plantilla de cabecera** como anexos.
4) Definir **estructura de carpetas** (`artifacts/`, `backups/`, `logs/`, `reports/`).
5) Documentar **umbral de progreso** y **regla de alias** con desempates.
1. **Configura rutas** (Windows) y una **ruta espejo opcional** del CHANGELOG en `/mnt/data/Repo_AR/CHANGELOG.md`.
2. Define utilidades:
3. **Valida** que exista el script viejo `SCRIPTS\Invoke-RepoReorg.ps1`; si no, **lanza error** y termina.
4. **Respalda** el script viejo a `SCRIPTS\BACKUPS\Invoke-RepoReorg_<UTC>.bak`.
5. **Escribe** el nuevo **SCRIPTS\Verify_Project.ps1** (contenido largo, modular, ver abajo).
6. **Sobrescribe** `SCRIPTS\Invoke-RepoReorg.ps1` con un **stub** que reenvía todos los argumentos al nuevo `Verify_Project.ps1`.
7. **Asienta bitácora**: agrega un bloque con fecha UTC a `CHANGELOG.md` (Windows y espejo si está presente).
8. Muestra un **resumen en consola** con rutas del nuevo archivo, stub y backup.
1) Ejecutar el **patch** (una sola vez por migración):
2) Usar el **nuevo verificador**:
1. Obtenga todos los servicios en ejecución.
2. Ordene los servicios por uso de memoria.
3. Exporte la información a un archivo CSV con las columnas especificadas.
1. **Instalación de Codex CLI**:
2. **Configuración de la clave API de OpenAI**:
3. **Ejecutar Codex CLI**:
1. **Utiliza cmdlets nativos de PowerShell**: Evita el uso de comandos externos cuando puedes usar cmdlets nativos que están optimizados para PowerShell.
2. **Usa pipelines de forma eficiente**: Transmite los resultados de un comando directamente a otro en lugar de almacenarlos en variables intermedias.
3. **Evita el uso excesivo de `ForEach-Object`**: Siempre que sea posible, usa cmdlets como `Where-Object` o `Select-Object` que son más eficientes.
4. **Usa `-Filter` en vez de `Where-Object`**: Filtrar en la consulta de los cmdlets directamente es más eficiente que hacerlo después con `Where-Object`.
5. **Optimiza el acceso a archivos**: Usa rutas completas en lugar de relativas para reducir el tiempo de búsqueda.
6. **Evita el uso de `Start-Process` cuando sea posible**: Ejecutar procesos externos es más lento. Intenta lograr tus objetivos dentro del entorno de PowerShell.
7. **Trabaja con datos en memoria siempre que sea posible**: Evita leer y escribir archivos repetidamente, ya que esto consume recursos innecesarios.
8. **Utiliza `Select-Object` con `-First` o `-Last` para obtener un solo elemento en lugar de recorrer toda la colección**.
9. **Minimiza las operaciones dentro de bucles**: Mantén los cálculos y acciones dentro de los bucles lo más simples posible para mejorar la eficiencia.
10. **Evita el uso de `Write-Host` para la salida masiva**: En su lugar, usa `Write-Output` o `Return` para canalizar los resultados sin saturar la consola.
11. **Usa `Measure-Command` para evaluar el rendimiento**: Mide el tiempo de ejecución de los comandos o bloques de código que son críticos para el rendimiento.
12. **Minimiza el uso de `Get-ChildItem`**: Este comando puede ser lento con grandes estructuras de directorios. Usa `-Recurse` y `-Filter` para reducir su alcance.
13. **Optimiza el uso de `Set-ExecutionPolicy`**: Configura adecuadamente la política de ejecución para permitir scripts seguros sin comprometer el sistema.
14. **Usa `Export-CSV` en lugar de `Out-File` para grandes volúmenes de datos**: `Export-CSV` es más eficiente al manejar grandes cantidades de información.
15. **Evita variables globales innecesarias**: Usa variables locales dentro de funciones y bloques para mejorar la eficiencia y evitar errores.
16. **Usa `-ErrorAction Stop` para manejo de errores eficiente**: Asegura que el script falle de manera controlada y rápida en caso de error.
17. **Evita el uso excesivo de `Get-Command`**: Ejecuta solo los comandos que realmente necesitas para evitar el overhead de invocar cmdlets innecesarios.
18. **Usa `-ThrottleLimit` en tareas paralelas**: Limita la cantidad de tareas paralelas para evitar sobrecargar el sistema y mejorar el rendimiento.
19. **Aprovecha las capacidades de PowerShell Remoting**: Ejecuta comandos en máquinas remotas para distribuir la carga de trabajo.
20. **Usa `Get-Content -ReadCount` para leer archivos grandes**: Esto reduce el uso de memoria cuando estás procesando archivos grandes línea por línea.
21. **Evita el uso de `Start-Sleep` innecesario**: No hagas pausas en tus scripts a menos que sea absolutamente necesario.
22. **Mantén los scripts pequeños y modulares**: Si puedes dividir las tareas en funciones o módulos, será más fácil mantener el rendimiento y el código limpio.
23. **Usa `-Filter` en lugar de `Where-Object` siempre que sea posible**: Filtrar a nivel del cmdlet en lugar de en el pipeline es más rápido.
24. **Haz uso del almacenamiento en caché de datos**: Guarda los resultados de operaciones costosas en variables o archivos temporales para evitar la repetición de cálculos.
25. **Desactiva el perfil de PowerShell cuando no sea necesario**: Esto puede ahorrar tiempo al iniciar PowerShell.
26. **Limita el uso de `-Recursively` y `-Force` en comandos de archivos**: Estos parámetros aumentan considerablemente el tiempo de ejecución.
27. **Usa `ForEach-Object -Parallel` para ejecutar tareas en paralelo**: Esto ayuda a mejorar la eficiencia en tareas repetitivas.
28. **Desactiva el uso de cmdlets innecesarios**: Algunos cmdlets pueden tener un alto coste de rendimiento si no se usan correctamente, asegúrate de usarlos de manera óptima.
29. **Optimiza el uso de `Start-Job` para procesos en segundo plano**: Usar trabajos de fondo de manera controlada puede mejorar la eficiencia de ejecución.
30. **Evita el uso de variables dinámicas**: Las variables como `$varName` a menudo ralentizan el script debido a la sobrecarga de PowerShell al manejarlas.
1. **Nunca almacenes contraseñas en texto claro**: Usa `Get-Credential` o almacena credenciales de manera segura utilizando el `SecureString`.
2. **Valida las entradas del usuario**: Asegúrate de que los parámetros proporcionados sean correctos y válidos para evitar inyecciones.
3. **Cifra archivos sensibles**: Usa `ConvertTo-SecureString` para cifrar datos importantes antes de almacenarlos.
4. **Deshabilita la ejecución de scripts maliciosos**: Usa políticas de ejecución estrictas para garantizar que solo los scripts autorizados se ejecuten.
5. **Usa `Start-Process` con cuidado**: Asegúrate de ejecutar procesos con los permisos adecuados y sin exponer el sistema.
6. **Evita el uso de cmdlets sin restricciones**: Siempre limita el alcance de los cmdlets que ejecutan comandos o acceden a recursos del sistema.
7. **Habilita la auditoría de PowerShell**: Mantén habilitada la auditoría para registrar todas las actividades de PowerShell en tu sistema.
8. **Utiliza un firewall y otras herramientas de seguridad**: para restringir el acceso no autorizado a los scripts.
9. **Establece permisos estrictos para archivos de scripts**: Asegúrate de que los archivos de scripts solo puedan ser leídos o modificados por personas autorizadas.
10. **Verifica la firma de los scripts**: Usa scripts firmados para garantizar que no han sido alterados.
11. **Evita el uso de `Invoke-Expression` con datos de entrada no confiables**: Esto puede abrir la puerta a inyecciones de código.
12. **Monitorea el uso de variables sensibles**: No dejes variables sensibles (como contraseñas) expuestas en el entorno.
13. **Habilita la ejecución de scripts solo en entornos controlados**: Evita ejecutar scripts en servidores de producción sin pruebas previas.
14. **Valida rutas y archivos antes de escribir en ellos**: Nunca sobrescribas archivos críticos sin verificar su existencia y la seguridad de la acción.
15. **Usa cuentas de servicio con privilegios mínimos**: Limita los permisos de las cuentas que ejecutan los scripts.
16. **Evita el uso de credenciales guardadas en archivos**: Almacenar credenciales en texto plano es un riesgo de seguridad.
17. **No realices cambios sin confirmar**: Usa `-Confirm` para asegurar que el usuario autorice cualquier cambio que afecte el sistema.
18. **Desactiva funciones de PowerShell no necesarias**: Usa políticas de restricción para desactivar funcionalidades que no sean necesarias para el script.
19. **Usa certificados para autenticación segura**: Si es necesario autenticar, usa certificados para proteger las credenciales.
20. **Realiza auditoría y revisiones periódicas de tus scripts**: Verifica regularmente que los scripts estén libres de vulnerabilidades.
21. **Utiliza técnicas de hashing para archivos sensibles**: No almacenes archivos sensibles en texto plano, usa hash o cifrado para protegerlos.
22. **Cifra la comunicación entre scripts y servicios remotos**: Asegúrate de que toda la comunicación se haga a través de canales seguros como HTTPS.
23. **Restringe la ejecución de scripts mediante control de acceso**: 
1) `ParserError: La referencia de variable no es válida. ':' no fue seguida por un carácter válido del nombre. Considere usar ${}.`
2) `ParserError: Token inesperado '_…otros' en expresión o sentencia.`
3) `Missing statement block in switch statement clause`, encontrado en PS-Env-Audit.ps1:560.
4) `Unexpected token` a propósito de la cadena de tokens en líneas 256, 299, etc. en el código.
5) `The term 'begin' is not recognized as a name of a cmdlet`, junto a un `CommandNotFoundException`.
6) `Cannot convert 'System.Object[]' to the type 'System.String' required by parameter 'AdditionalChildPath'` y `'ChildPath'`, causado por llamadas a `Join-Path` con arrays.
7) `Missing closing '}' in statement block or type definition` y `Unexpected token '}' or ')'` en PS-Env-Audit-Min.ps1:80.
8) `Parameter set cannot be resolved using the specified named parameters` al ejecutar script con parámetros ambiguos en PS 7 y PS 5.1.
9) `The term '.\PS-Env-Audit-CLEAN.ps1' is not recognized` al intentar usar ruta relativa.
10) `Missing closing ')' in expression.`
11) `Missing statement block in switch statement clause.`
12) `Unexpected token '_…otros'`.
13) `The term 'begin' is not recognized` en PS-Env-Audit.ps1.
1) Portabilidad limitada por variables de entorno estáticas. Cite L5-L9.
2) Análisis estático sin AST, se limita a inspección textual. Cite L11, L25–L26.
3) Cobertura restringida a reglas R01–R15. Cite L1-L7 y L9-L20.
4) Segmentación de líneas 2k–4k puede causar desincronización. Cite L37.
5) Reglas rígidas, como `utf8NoBOM` requiriendo PS 7.1. Cite L41-L42, L6, L66–L68.
6) Puntuación sin justificación clara. Cite L22-L26.
7) Restricción fija en el input del script.
1) Ingesta y preservación
2) Tokenización y pseudo-AST
3) Reglas de análisis ampliadas (clasificadas)
1) Recibir archivo o fragmentos. Si fragmentos, indicar su orden y total; v2 concatenará.
2) Leer completo con Python, registrar tamaño y SHA-256, y guardar copia literal.
3) Analizar con pseudo-AST y reglas S/R/A/Q/P.
4) Emitir JSON y sumario corto, por defecto con datos sensibles redactados.
5) Si pides “raw”, se reemite el mismo informe sin redacción.
1) Añade `Set-StrictMode -Version Latest` y `$ErrorActionPreference='Stop'` al inicio.
2) Envolver los `Set-Content` con `try/catch` y `-ErrorAction Stop`.
3) Reemplazar `catch {}` por `catch { registrar error }`.
4) Si alguna vez compartes el reporte, agrega un switch `-Redact`.
1) Ingesta completa, hash SHA-256, índice 1-based, snapshot en /mnt/data.
2) Tokenización + pseudo-AST con resolución 1 salto de variables.
3) Reglas S/R/A/Q/P.
4) Scoring y salida JSON + sumario corto.
1) Añade `-ErrorAction Stop` a `Set-Content` y envuélvelo en `try/catch`.
2) Sustituye `catch { }` por un bloque con logging o usa `# postmortem:ignore R02 reason=...`.
3) En `Start-Process`, agrega `-ErrorAction Stop` y manejo de fallo.
4) Define `Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'` al inicio.
5) Agrega `[Validate*]` a parámetros críticos.
1) Añade -ErrorAction Stop a las escrituras y envuélvelas en try/catch donde corresponda.
2) En Start-Process agrega -ErrorAction Stop y manejo de error.
3) Coloca Set-StrictMode -Version Latest al inicio.
4) Si vas a compartir reporte, agrega opción “redacted”.
1) Ingesta completa → hash SHA-256 → snapshot.
2) Pseudo-AST + resolución 1 salto + reglas S/R/A/Q/P.
3) CoVe-Verify por hallazgo ≥Medium: generar Qs de verificación, responder en aislamiento, etiquetar Verified/Rejected. citeturn1search0turn1search3
4) Self-consistency si `consistency_mode=k>1`: repetir Fases 2–3 k veces y consolidar por mayoría. citeturn0search2
5) Self-check: NLI/QA sobre citas y evidencias; adjuntar score y decisión. citeturn0search3
6) Guardrails de salida: validar JSON vs esquema; si falla, re-redactar una vez con corrección mínima. citeturn3search0
1) Ingesta
2) Análisis
3) Reglas S/R/A/Q/P
4) Verificación CoVe por hallazgo ≥ Medium
5) Autoconsistencia (si k>1)
6) Self-check
7) Guardrails de salida
1) Validar contra el esquema; si falla, rechazo y explico el campo inválido. (Structured outputs + tools). citeturn4search4turn2search5
2) Ejecutar el pipeline v5 con CoVe y, si k>1, autoconsistencia. citeturn0search9turn0search8
3) Devolver JSON de hallazgos validado y sumario.
4) Nunca ejecutar comandos del .ps1; aplicar OWASP-LLM LLM01/LLM02. citeturn0search1
1. **Reporte de usuarios**: Hay usuarios en foros como Reddit que dicen que Banorte dejó de funcionar en teléfonos rooteados, con mensajes tipo “la aplicación por seguridad no funciona con teléfonos modificados”. citeturn0search1
2. **Términos de seguridad de Banorte**: No encontré un texto oficial reciente que diga explícitamente “si tu dispositivo tiene root, la app no funcionará”, pero sí hay menciones de dispositivos de seguridad, token, autenticaciones, condicionamientos. citeturn0search5turn0search2turn0search3
3. **Instructivo de “modo desarrollador”**: Banorte tiene un documento/instructivo que menciona que si tu teléfono tiene “rooteo” activo, deberías deshabilitarlo para que la app funcione correctamente. Por ejemplo:
4. **Reactivación / app bloqueada**: Si la app fue bloqueada por algún motivo de seguridad, Banorte da opciones para reinstalar, capturar usuario y contraseña, seguir pasos de activación, etc. citeturn0search4
1. **Haz backup** de todo lo que te importe, porque al relockear casi siempre se borra todo (factory reset).
2. **Asegúrate de estar con la ROM oficial del fabricante** (stock firmware), sin modificaciones, sin root, sin recovery personalizado. Ya hiciste flash con Odin, así que si lo dejaste con la ROM stock, va bien.
3. **Activa “OEM Lock” si existe**
4. **Entrar al modo bootloader / fastboot o modo descarga (Download Mode / Odin mode)**
5. **Usar comando apropiado para relock**
6. **Verifica que el bootloader está bloqueado**
1. **Confirma que estás en firmware stock oficial**
2. **Activa opciones de desarrollador**
3. **Verifica “Desbloqueo OEM”**
4. **Reinicia en modo Download (Odin Mode)**
5. **Factory reset automático**
1. Ve a Opciones de desarrollador.
2. Desactiva *OEM Unlock*.
3. Reinicia → el teléfono se resetea y queda bloqueado.
1. **Primera vez** → solo desbloqueaste el bootloader (activaste *OEM Unlock* y lo liberaste).
2. **Después** → flasheaste con Odin el firmware stock completo (los ~9 GB).
1. **Flashear firmware stock completo con Odin** (los 4 archivos: BL, AP, CP, CSC).
2. Reiniciar → ahora en *Opciones de desarrollador* la opción de *OEM Unlock* ya debería salir como apagada (o desaparecer).
3. Con eso, el bootloader vuelve a quedar marcado como “locked”.
1. **Primero** desbloqueaste el bootloader → ahí el toggle de *OEM Unlock* estaba activo y movible.
2. **Después** flasheaste el firmware stock con Odin → ahora el toggle aparece en gris con la nota “ya está desbloqueado”.
1. Instala **Termux** desde [F-Droid](https://f-droid.org/en/packages/com.termux/) (recomendado).
2. Abre Termux y corre:
3. Copia/pega el bloque arriba.
4. Dale permisos:
1. Usa CSC (no HOME_CSC) para asegurar un borrado.
2. Después de la flash y la configuración inicial, conecta el dispositivo a internet por 5-10 minutos para permitir que VaultKeeper actualice.
3. Accede a Opciones de Desarrollador: el toggle de "OEM unlocking" debería aparecer; si sigue gris, entra en "Modo de descarga" y selecciona "LOCK BOOTLOADER".
1) No hiciste el "Lock Bootloader" en modo de descarga. Odin por sí solo no lo cambiará.
2) Usaste HOME_CSC y no hiciste un wipe, lo cual es necesario para activar VaultKeeper.
3) No completaste el "handshake" de VaultKeeper: conecta el dispositivo a internet por 5-10 minutos antes de bloquear.
1) Respalda todo y apaga el dispositivo.
2) Entra en Modo de Descarga (Vol+ y Vol- con cable conectado).
3) Si no aparece la opción para "Lock Bootloader", mantén pulsado Vol Up durante 7-10 segundos para ir al menú de "Device unlock/lock".
1) **Backup** (se borra todo al bloquear).
2) **Apaga** y entra a **Download Mode**: mantén **Vol+ y Vol-** y conecta el USB al PC.
3) En la pantalla azul, **mantén Vol+** varios segundos hasta ver la opción **“Lock Bootloader”** y **confirma** (Vol+). El teléfono se reseteará. citeturn2search2turn2search0
4) Arranca Android, conéctalo a **Internet unos minutos** (VaultKeeper).
5) Verifica en Termux:
1) `read` no funciona dentro de un heredoc que alimenta a `bash` (se queda sin `stdin` → “Opción inválida”).
2) No tienes permisos de escritura en `/sdcard` (en Termux requiere `termux-setup-storage`).
1. **Termux** (si aparecía “Permission denied” en `/sdcard`): ejecuta una vez `termux-setup-storage`, acepta permisos y vuelve a correr el bloque.
2. Elige `1` → verifica que se crea `captura_YYYYmmdd_HHMMSS.png` en `DCIM/Camera` (o `Download`).
3. Elige `2` → graba y detén con **Ctrl+C**; verifica `video_YYYYmmdd_HHMMSS.mp4` en la misma carpeta.
4. Si prefieres forzar ruta, edita `pick_outdir()` y pon tu carpeta fija.
1) **Termux (recomendado):**
2) **ADB shell:** `adb shell` → pega el bloque → opción **1** usa `/system/bin/screencap` y debe guardar en `/sdcard/DCIM/Camera`.
3) Si sigue fallando, copia el mensaje que imprime el script (ya distingue falta de permisos vs. binarios).
1. **Instalar dependencias**
2. **Conectar vía USB** y correr el script:
3. Para usar **por WiFi** (sin cable):
1. **En la PC** instala:
2. **Prueba conexión USB**:
3. **Si quieres WiFi directo**:
1. Verifica/instala **ADB (platform-tools)** y **scrcpy** automáticamente.
2. Configura el **PATH** temporal.
3. Detecta el dispositivo Android y lanza la transmisión.
1. Guarda el archivo como `mirror_phone.ps1`.
2. Ábrelo con **clic derecho → Ejecutar con PowerShell**.
3. Conecta el celular por USB y **acepta la autorización ADB en la pantalla**.
4. Se abrirá la ventana de scrcpy con la pantalla del teléfono.
1. Open PowerShell 7 as your user. If first run:
2. Run:
1) **Habilitar ejecución (una vez):**
2) **Ejecutar (USB, solo espejo):**
3) **Opcional WiFi** (requiere una vez USB para habilitar TCP/IP):
1) Conecta el móvil por **USB** con **Depuración USB** habilitada (ya lo tienes).
2) Al correr el script, si aparece el diálogo ADB en el teléfono, **aceptar**.
3) Debe abrirse una ventana con la pantalla del móvil.
4) Prueba presionar teclas/click en la ventana: **no** afectará el teléfono (flag `--no-control`).
5) Si usas `-Wifi`, verifica que la salida muestre “**WiFi connection established**”.
1. **scrcpy está instalado pero sin `adb` detectando dispositivo**.
2. **scrcpy se ejecuta pero se cierra instantáneo**.
1. Con el teléfono conectado por USB y depuración activa, corre:
2. Si aparece, vuelve a lanzar:
1. **Quitar `--verbose`** de las pruebas manuales. Ejemplo correcto:
2. En tu `mirror_phone.ps1` ya no necesitas tocar nada, porque el script nunca usaba `--verbose` (solo lo probaste manual).
3. Si con ese comando abre ventana y ves el móvil → ya quedó resuelto.
1. **Solo desactivar FLAG_SECURE en scrcpy**
2. **Usar “Skip secure content” en scrcpy modificado**
3. **Comprobar permisos de superposición**
1. Primero prueba si tu build de scrcpy soporta:
2. Si no, el bloqueo viene del sistema Knox / FLAG_SECURE y **no se puede saltar sin root o un build modificado**.
1. **Lo que ya tienes funciona**: el espejo abre, pero se ve negro en apps que usan `FLAG_SECURE`.
2. **Alternativas reales**:
3. **Confirmar que no es bug de video**:
1. **Capturas y grabaciones con ADB**
2. **Exportar datos directamente**
3. **Apps oficiales**
1. **Con root o ROM modificada**:
2. **Captura externa** (hardware):
3. **Apps de terceros con exploits** (riesgoso):
1. Crea la carpeta en tu Desktop:
2. Luego haz el pull:
1. `screenrecord` de Android a veces genera archivos corruptos si se interrumpe con **Ctrl+C** antes de cerrar correctamente.
2. Los `.mp4` de `screenrecord` pueden estar codificados en H.264 con un contenedor incompleto (sin “moov atom”), lo que hace que Windows no lo reconozca.
1. **Usa ffmpeg para “arreglar” el contenedor**:
2. **Si sigue sin abrir**, prueba convertirlo a un `.mkv`:
3. **Graba de nuevo con límite de tiempo** (para evitar cortar mal):
1. Instala dependencias necesarias (**ADB** y **FFmpeg**) si no están.
2. Graba la pantalla del móvil con `adb shell screenrecord`.
3. Copia el archivo grabado a tu **Desktop**.
4. Lo repara automáticamente con **FFmpeg** para que siempre se pueda reproducir.
1. Guarda el script en tu Desktop como `record_phone.ps1`.
2. Si es la primera vez, habilita ejecución:
3. Conecta el móvil por USB (depuración activada).
4. Ejecuta:
1. **Grabar con límite de tiempo fijo** (para que Android cierre bien el archivo):
2. **Verificar tamaño del archivo**:
3. **No usar Ctrl+C** para cortar la grabación, deja que termine sola con `--time-limit`.
1. Guarda como `map_videos.ps1`.
2. Abre PowerShell 7 y ejecuta:
3. En tu **Desktop** aparecerá `videos_phone.csv` con todas las rutas, tamaños y fechas.
1. Abre Termux.
2. Pega el bloque tal cual.
3. Elige `1` → revisa `/sdcard/` y debería haber `captura_YYYYMMDD_HHMMSS.png`.
4. Elige `2` → se crea un `.mp4` hasta que detengas con **Ctrl+C**.

## Mejores prompts / plantillas

- Ejemplo prompt Codex Powershell
- 🧠 Ejemplo de Prompt para Generar Código PowerShell con Codex CLI

## Ejemplos completos

- [ej_automatizacion_scripting_6-33-27-An_lisis_de_m_dulos_PowerShell.md] — sha256: e3bb5dc796c5a48aeeef14b8620f56a175ebee2e6cb557aea35e9bc722899fee — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_automatizacion_scripting_6-45-32-An_lisis_README_proyecto.md] — sha256: 3fb8dc7242b7fc0dfe908be222574016bcababb0d77239c2704f29f84075052b — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_automatizacion_scripting_5-31-12-_SCRIPT___Invoke_RepoReorg_.md] — sha256: e8b4beb6be138e1d683c32de70e783492dbbe02af8337d2937a0a0aac8325434 — resumen

  ### Entrada (user)

  Analiza y explica que hace el siguiente script:

  ```

- [ej_automatizacion_scripting_12-21-35-Ejemplo_prompt_Codex_Powershell.md] — sha256: 5d1dc381e1effb1d90272d56358ae44300c25888733648bb49f565ec3659f3eb — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_7-18-38-Reporte_de_consejos_PowerShell.md] — sha256: 9b8c0dd451e1c82677e000e9439322a0de4264cc081325bc583f4842dc3c4eb1 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_7-7-32-Significado_de_un_script.md] — sha256: 7b1937605d10053174ab5cec645078fe5c5032c67be7299efcaaacb480bdbe32 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_0-47-50-Instrucciones_personalizadas_y_memoria.md] — sha256: 221bc08d1be731ce716dec6da7183ebc6d5a83be290d1061dee0716226d9da57 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Tienes que revisar los correos EML que te enviaré y exponer la información más relevante de cada uno.\n\nUsa tablas o representaciones visuales profesionales para que la recopilación de datos sea más efectiva```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema.md] — sha256: d08d0ca558a0243fcfe2343bd1da07bd3b8d9ec89203a116efd29044e5870c28 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Tienes que revisar los correos EML que te enviaré y exponer la información más relevante de cada uno.\n\nUsa tablas o representaciones visuales profesionales para que la recopilación de datos sea más efectiva```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_2-57-37-Normativa_operativa_guardada.md] — sha256: 94dd57ce0cf82ed193d97220c0b7d5bf584cefdce3715bd379209d56e2185921 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md.md] — sha256: 0f8e2878b0315320b99afdb54bbc1f30aa9b838bd07d188fb0a2371e25656440 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_5-6-18-Script_PowerShell_animado.md] — sha256: 5a52fa6b111bd7356ede6904cb4487ae63f69b32d9ef9c83db5a91e065a6fa19 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_6-4-22-Integraci_n_normativa_operativa.md] — sha256: ba8e0d9c94fc4d44a5984f9956427f984669d92fd2478a9cab6630427529c027 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento.md] — sha256: 25fbf1bb434d221f5fb36664d0dc44de46b51307abe9cc67623746f7d06c4736 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_17-46-27-Verificaci_n_acceso_Banorte.md] — sha256: f7d7925044b34eec23c56725c5c387e0a5f1915397eb76ee2b2dc45e57246fe2 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\n```", "user_instructions": ""}

  ### Salida (assistant)

- [ej_automatizacion_scripting_8-17-20-Corregir_heredoc_consola.md] — sha256: a2d973b0045396f4e6ffe12ad1f86fc20058fb0d017ff2a6b564c9b282397c8b — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Usuario **multiproyecto** con enfoque en automatización, documentación reproducible y resultados verificables. Prefiere entregas listas para uso (scripts, reportes, `.zip`), con trazabilidad y citas. Valora calidad por encima de velocidad; no requiere portabilidad *nix a menos que lo pida. Trabaja con proyectos que combinan **instrucciones del proyecto + archivos**; evita depender de memoria.\nOther Information: Preferencias: respuestas **claras, accionables, sin relleno**; español técnico; encabezado con resumen y lista de entregables; nombres de archivos **ASCII**; cuando haya bloques con ``` internos, envolver con fence de **5 tildes**. Evitar “mínimos aceptables”; prefiere correcciones **proactivas** si detectas fallas.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Actúa como **Asistente PRO**: entrega en **un solo turno** artefactos útiles y verificados. Sé **proactivo**: si el pedido implica A y B, entrega ambos sin pedir permiso.  \nEvita alucinaciones; cita **fuentes oficiales** de OpenAI para capacidades y usa **web.run** cuando la información pueda haber cambiado. Etiqueta foros/medios como **[Comunidad/Prensa]**.  \nResponde en **español técnico**, conciso, con **resumen ejecutivo**, pasos de validación y enlaces de descarga **ASCII**. Si generas múltiples archivos, empaquétalos en `.zip`.  \nNo prometas trabajo futuro ni pidas confirmaciones triviales; solo pregunta ante bloqueos reales. Si hay Python disponible, úsalo para verificar cálculos/estructuras antes de entregar.  \nSi la tarea es “haz lo que tengas que hacer”, **completa el flujo extremo a extremo** con tu mejor esfuerzo.```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_8-31-4-Script_para_espejar_celular.md] — sha256: 581c547f5651c0b02fb9c06b9e88831080d70ecd605e9a422ecfd20f2e3e6865 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Usuario **multiproyecto** con enfoque en automatización, documentación reproducible y resultados verificables. Prefiere entregas listas para uso (scripts, reportes, `.zip`), con trazabilidad y citas. Valora calidad por encima de velocidad; no requiere portabilidad *nix a menos que lo pida. Trabaja con proyectos que combinan **instrucciones del proyecto + archivos**; evita depender de memoria.\nOther Information: Preferencias: respuestas **claras, accionables, sin relleno**; español técnico; encabezado con resumen y lista de entregables; nombres de archivos **ASCII**; cuando haya bloques con ``` internos, envolver con fence de **5 tildes**. Evitar “mínimos aceptables”; prefiere correcciones **proactivas** si detectas fallas.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Actúa como **Asistente PRO**: entrega en **un solo turno** artefactos útiles y verificados. Sé **proactivo**: si el pedido implica A y B, entrega ambos sin pedir permiso.  \nEvita alucinaciones; cita **fuentes oficiales** de OpenAI para capacidades y usa **web.run** cuando la información pueda haber cambiado. Etiqueta foros/medios como **[Comunidad/Prensa]**.  \nResponde en **español técnico**, conciso, con **resumen ejecutivo**, pasos de validación y enlaces de descarga **ASCII**. Si generas múltiples archivos, empaquétalos en `.zip`.  \nNo prometas trabajo futuro ni pidas confirmaciones triviales; solo pregunta ante bloqueos reales. Si hay Python disponible, úsalo para verificar cálculos/estructuras antes de entregar.  \nSi la tarea es “haz lo que tengas que hacer”, **completa el flujo extremo a extremo** con tu mejor esfuerzo.```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_8-8-11-Bash_para_descargar_videos.md] — sha256: 581c547f5651c0b02fb9c06b9e88831080d70ecd605e9a422ecfd20f2e3e6865 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Usuario **multiproyecto** con enfoque en automatización, documentación reproducible y resultados verificables. Prefiere entregas listas para uso (scripts, reportes, `.zip`), con trazabilidad y citas. Valora calidad por encima de velocidad; no requiere portabilidad *nix a menos que lo pida. Trabaja con proyectos que combinan **instrucciones del proyecto + archivos**; evita depender de memoria.\nOther Information: Preferencias: respuestas **claras, accionables, sin relleno**; español técnico; encabezado con resumen y lista de entregables; nombres de archivos **ASCII**; cuando haya bloques con ``` internos, envolver con fence de **5 tildes**. Evitar “mínimos aceptables”; prefiere correcciones **proactivas** si detectas fallas.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Actúa como **Asistente PRO**: entrega en **un solo turno** artefactos útiles y verificados. Sé **proactivo**: si el pedido implica A y B, entrega ambos sin pedir permiso.  \nEvita alucinaciones; cita **fuentes oficiales** de OpenAI para capacidades y usa **web.run** cuando la información pueda haber cambiado. Etiqueta foros/medios como **[Comunidad/Prensa]**.  \nResponde en **español técnico**, conciso, con **resumen ejecutivo**, pasos de validación y enlaces de descarga **ASCII**. Si generas múltiples archivos, empaquétalos en `.zip`.  \nNo prometas trabajo futuro ni pidas confirmaciones triviales; solo pregunta ante bloqueos reales. Si hay Python disponible, úsalo para verificar cálculos/estructuras antes de entregar.  \nSi la tarea es “haz lo que tengas que hacer”, **completa el flujo extremo a extremo** con tu mejor esfuerzo.```"}

  ### Salida (assistant)

- [ej_automatizacion_scripting_16-54-29-New_chat.md] — sha256: 10693c28507daadb2ada8eba669a5604767f168d4fd6914bc384cb5cff950930 — resumen

  ### Entrada (user)

  ¿Hay algo mejor que powershell para windows?

  ### Salida (assistant)

## Snippets de código / comandos

- [sn_automatizacion_scripting_6-33-27-An_lisis_de_m_dulos_PowerShell_001.txt] — sha256: 5b335dc0993c6fdda1de6576443bcc37e6952d08de9563d04025902c98a0d7b6 — resumen


  # Protocolo de realización de parches a documentos y scripts.

  ---


- [sn_automatizacion_scripting_6-33-27-An_lisis_de_m_dulos_PowerShell_002.txt] — sha256: 338e8dcf3b232a746f2717906ca755f0c1884a82e72dcb81130bdd4c12cebb71 — resumen


  ---

  ## Módulos 2A a 2E – Inicialización del Entorno


- [sn_automatizacion_scripting_6-33-27-An_lisis_de_m_dulos_PowerShell_003.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_automatizacion_scripting_6-33-27-An_lisis_de_m_dulos_PowerShell_004.txt] — sha256: 316deeb28892b1cdebfe5c12c2cd620b5b8f29289c1ffe3d4f5fc1b2e6a4ea7d — resumen


  ---

- [sn_automatizacion_scripting_6-45-32-An_lisis_README_proyecto_005.txt] — sha256: 65d6168b58ebd3c6343ceda41f9de0bd9a6dc5593333aeb1f0efc4768ed9bb01 — resumen

  # Proyecto "Anastasis_Revenari" — README

  ## CONTEXTO

  <ROL>

- [sn_automatizacion_scripting_6-45-32-An_lisis_README_proyecto_006.ps1] — sha256: 82e4d0f8d2f9a5802aa8e6aeacce06b286b869f1ff2e41e9f11175e7a5d35d37 — resumen

  Add-Type -AssemblyName System.Security
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($RequireAdmin -and -not $IsAdmin) { throw "Se requiere ejecución como Administrador." }

- [sn_automatizacion_scripting_6-45-32-An_lisis_README_proyecto_007.ps1] — sha256: 4e5d6e88431db045f7a38293271b1b57f0b106199d28e271bb3dd1bdebc0ff11 — resumen

  <#
  .SYNOPSIS
    (Resumen corto en una línea)
  .DESCRIPTION
    (Propósito, alcance y efectos)

- [sn_automatizacion_scripting_5-31-12-_SCRIPT___Invoke_RepoReorg__008.txt] — sha256: ffa493da735dcb1bc416f788fac5e46dc137d7124e9d7112d8ab3fe68c6a6cc4 — resumen

  # Patch-Verify_Project_Modularize.ps1
  # Reorganiza el macroscript en módulos con marcadores claros y lo renombra a Verify_Project.ps1.
  # Crea stub de compatibilidad para Invoke-RepoReorg.ps1, conserva backups y actualiza CHANGELOG.
  #requires -Version 5.1
  Set-StrictMode -Version 3.0

- [sn_automatizacion_scripting_5-31-12-_SCRIPT___Invoke_RepoReorg__009.ps1] — sha256: 28fc368aedb8fad91956eaab53a34b9232b6de6e6c6bb14c2a39278671eaebd5 — resumen

  # En Windows PowerShell 5.1+
  .\Patch-Verify_Project_Modularize.ps1

- [sn_automatizacion_scripting_5-31-12-_SCRIPT___Invoke_RepoReorg__010.ps1] — sha256: eeaf387854aa3d89f38df1cc95f6beb8e8f4558e3c5a6ddbd415748057c81ff4 — resumen

  # Usando RepoRoot por defecto
  .\SCRIPTS\Verify_Project.ps1

  # O especificando ruta
  .\SCRIPTS\Verify_Project.ps1 -RepoRoot 'C:\Users\...\Repo_AR'

- [sn_automatizacion_scripting_5-31-12-_SCRIPT___Invoke_RepoReorg__011.ps1] — sha256: ea9fdf2902b35dee6860c656888c1da5a3a8b14fa22c2a1baac4e5570a80c96d — resumen

  .\SCRIPTS\Invoke-RepoReorg.ps1 -RunPSSA

- [sn_automatizacion_scripting_12-21-35-Ejemplo_prompt_Codex_Powershell_012.sh] — sha256: 4e704ae8a271b7a65fd3eb00dff05b12b7ddc0661014824d6d818a1db25ab542 — resumen

  codex "Escribe un script en PowerShell que obtenga una lista de todos los servicios en ejecución, los ordene por uso de memoria y los exporte a un archivo CSV con las columnas: Nombre, Estado, Uso de Memoria."

- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_013.ps1] — sha256: 52ce216ec6515b7ee5da4e8df769fb71c51f2e56dfd27c202224d87332bd4fc5 — resumen

  # Encabezado del script genérico
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
  param(
      # Acción principal que define qué hacer
      [ValidateSet('Operacion1','Operacion2','Operacion3','Operacion4','Todo')]

- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_014.ps1] — sha256: 76aeb94ecc81cd6ce5c92b4d1e50ddd41bc21901ba0ae70cc372c8a1719a39d8 — resumen

  # Parámetros adicionales del script genérico

  # Ruta donde se guardará el reporte
  [string]$RutaReporte,


- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_015.ps1] — sha256: 4aa1eb69dd6922479bf9b3e37de9ec0240be5877e0566c29b941ded1a4d84632 — resumen

  # Parámetros relacionados con sesión, red y mantenimiento

  # Directorio base de sesión
  [string]$RutaSesion,


- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_016.ps1] — sha256: 711dd5e5808a8622aa19d423188a54b3ae977a51ddb5572d3b83dd38094f5715 — resumen

  # Validación de rutas adicionales (ej. carpetas de limpieza extra)
  [ValidateScript({
      if ($_ -eq $null) { return $true }
      foreach ($ruta in $_) {
          # Debe ser string válido

- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_017.ps1] — sha256: b402b7bd8cc1b88e0d8f0741ab080ba03de7488139be3191a3cdad3ecd7f73f0 — resumen

  # Parámetros finales del script genérico

  # Rutas adicionales (validación ya definida arriba)
  [string[]]$RutasExtra,


- [sn_automatizacion_scripting_7-7-32-Significado_de_un_script_018.txt] — sha256: 3112bf5bb517e544d3985d17e6c10ea608ab5c4763e5763a4103ca9f702c1a06 — resumen

  # Encabezado del script genérico
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
  param(
      # Acción principal que define qué hacer
      [ValidateSet('Operacion1','Operacion2','Operacion3','Operacion4','Todo')]

- [sn_automatizacion_scripting_0-47-50-Instrucciones_personalizadas_y_memoria_019.txt] — sha256: 4dc8ead4645a84ab672c71b1826cf344bc0d59e0dcf6248abb299a059451789f — resumen

  01_Software/
  │
  ├── Binarios/                # Ejecutables principales y drivers
  │   ├── YSD300AN.exe
  │   └── 01_Drives_(Hl-340).exe

- [sn_automatizacion_scripting_0-47-50-Instrucciones_personalizadas_y_memoria_020.ps1] — sha256: b9fdcc308e384291b81ea2b0ec6e1953fc71833ca0f84e36c7f20c91e541fe12 — resumen

  <# 
  Reorganiza 01_Software:
  - Crea: Binarios, Config, Datos/{Exportes,Temporales,DB}, Recursos/{Icons,Images}, Docs
  - Mapea por extensión:
    exe → Binarios

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_021.txt] — sha256: 3ca10e43fdd11ec61be770ed5e177d870759c5269e1760ebcb642f78ce1ddeaf — resumen



  Responde siempre en **español*.

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_022.txt] — sha256: fc6c9266e3501be9b0710d6f9dfbb34b56d6f103f8054e57e7884f640c2dc9a6 — resumen

  Sé conciso y directo; evita rodeos o promesas de trabajo futuro.

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_023.txt] — sha256: 5ab2d847c29fedf36429eea48ea5738e6ef6677104a94e0a82ac863a34d38cf4 — resumen

  Entrega resultados **accionables** en el mismo turno.

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_024.txt] — sha256: dbe8dc1ad83e5e54f5f9f570c739bb936c2d70bcb42b46c419619bedacd8a087 — resumen

  - Prioriza la solución sobre la conversación innecesaria.

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_025.txt] — sha256: 64dce09bf5e00fb311958d6f78bc3ce3130b412d76bf1975268927e29b032bd9 — resumen

  Genera scripts personalizados para funcionar en un entorno con las siguientes especificaciones:



  Usuario           : VictorFabianVeraVill

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_026.txt] — sha256: 445622a9ef85f2f7affbf09f3ef7dd6008e6e545358e3817a02041ed68f08a02 — resumen

  Basado en la estructura de SEED01 y subpartes descritas en el temario y en la guía de “Semillas”. fileciteturn6file1L7-L15 fileciteturn6file3L22-L25

  ## USER
  Ok, sigue con SEED02


- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_027.txt] — sha256: ad1e4499811e58f3287abe30e3a8c434ea2f822a7c2e0068b16881f21b13ce17 — resumen


  ## USER
  ¿Estás inventando verdad?

  Esta es la seed02, hazlo de nuevo, primero intenta comprender lo que se te está solicitando

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_028.txt] — sha256: 0d92dc7ea2d42cc62085e5b1e37811972ebdfcdd0c390b1fc73d684a3ffd381b — resumen


  ## Thoughts
  Voy a guardar la lógica que describes en la memoria, detallando el proceso para manejar la trunca de salida, listando archivos, almacenando metadatos y dividiendo en fragmentos de texto. Confirmaré que lo guardé después. Como la solicitud es en español, todo se guardará en ese idioma.

  ## ASSISTANT

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_029.txt] — sha256: 2a988337a465571cad1ded4f3edf7e48861cf95246c5b96c44745edbdec4aad2 — resumen


  ## Thoughts
  Voy a organizar la información siguiendo tus indicaciones. Debemos agrupar todo de manera coherente en un solo documento. Incluiré encabezados y agruparé las secciones, eliminando repeticiones. Aquí está el esquema propuesto:  

  1) Principios/Reglas persistentes  

- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_030.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_automatizacion_scripting_1-8-47-Instrucciones_guardadas_sistema_031.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_automatizacion_scripting_2-57-37-Normativa_operativa_guardada_032.txt] — sha256: 76cbfbdb2574ec594c1ec8db6d1a734caf20877880510b9d4452b604fd03a915 — resumen

  # PowerShell (PS7) — Genera un .md con riesgos de root y escenarios de incomunicación
  # Propósito: crear el documento en el Escritorio del usuario solicitado.
  # Entorno objetivo: Windows 10 Pro 10.0.19045 64-bit, PowerShell 7.5.3 Core.
  # Salida: C:\Users\VictorFabianVeraVill\Desktop\Riesgos_Root_Comunicacion.md


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_033.txt] — sha256: 9a9a05b5a620e70a20b7449e2d690d85c9564ac6e4d01b1aff21ec67f458efc0 — resumen

  #requires -Version 7.0
  <#
  .SYNOPSIS
  GUI para convertir un archivo Markdown (.md) a HTML con selector de archivos.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_034.txt] — sha256: 3a5805192fad15657e9472f12eeba05cb5210731f7500d41a4dc75aba1db8fb9 — resumen

  #requires -Version 7.0
  <#
  .SYNOPSIS
  GUI para convertir Markdown (.md) a HTML con selector de archivos.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_035.txt] — sha256: 9d6cabb5cab28bd335fe90e0767c3dada5dbd9b940f479542a0042fc29e20fb4 — resumen

  #requires -Version 7.0
  <#
  .SYNOPSIS
  Limpieza segura de metadatos residuales de imágenes y videos en Android vía ADB sin afectar archivos de usuario ni del sistema.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_036.txt] — sha256: 5667c101e3042dd54bf3ff7f66825a7dfa5e06f8181ac416c8fb3f03ec48760d — resumen

  #requires -Version 5.1
  <#
  .SYNOPSIS
  Audita la versión de PowerShell y todo el contexto relevante del entorno para escribir scripts correctamente.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_037.ps1] — sha256: fea94c8bd824fb8284dc5b031ec86bbbc6022af0c13e82b38fbfcb9e74ffb296 — resumen

  $envVars = foreach($n in $selected){ [PSCustomObject]@{ Name=$n; Value=$env:$n } }

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_038.ps1] — sha256: 75cbe5c058608704b60a3929eff95e2086805466e0dd542fa15990535eaca23f — resumen

  $envVars = foreach($n in $selected){ [PSCustomObject]@{ Name=$n; Value=${env:$n} } }

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_039.ps1] — sha256: fea94c8bd824fb8284dc5b031ec86bbbc6022af0c13e82b38fbfcb9e74ffb296 — resumen

  $envVars = foreach($n in $selected){ [PSCustomObject]@{ Name=$n; Value=$env:$n } }

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_040.ps1] — sha256: 75cbe5c058608704b60a3929eff95e2086805466e0dd542fa15990535eaca23f — resumen

  $envVars = foreach($n in $selected){ [PSCustomObject]@{ Name=$n; Value=${env:$n} } }

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_041.ps1] — sha256: 9d03df3ae7c0d5be280522e0b7345d2177af124746bc4709979a6514b006d76b — resumen

  $envVars = foreach($n in $selected){ [PSCustomObject]@{ Name=$n; Value=[Environment]::GetEnvironmentVariable($n,'Process') } }

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_042.txt] — sha256: 155d231a83efb690f8b508ea62bb2b7829a0a4ca876f2119e2e954a06a244e2d — resumen

  #requires -Version 5.1
  <#
  .SYNOPSIS
  Audita versión de PowerShell y todo el contexto relevante para generar scripts correctamente en PS 5.1 y 7+.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_043.txt] — sha256: 83d4ede1517f047ef63a9c3c12377f44d2e3415933d70c5c219f1e7ead7aec29 — resumen

  #requires -Version 5.1
  <#
  .SYNOPSIS
  Audita versión de PowerShell y el entorno requerido para generar scripts correctamente en PS 5.1 y 7+.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_044.txt] — sha256: c78ae0844f8748e3c5a8305cb13ce0805d39b2b8a942a4c5b73d1e41a3ac1b31 — resumen

  #requires -Version 5.1
  <#
  .SYNOPSIS
  Audita versión de PowerShell y entorno para generar scripts correctamente en PS 5.1 y 7+.


- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_045.ps1] — sha256: 1b494757f28f13936d37bad8c18bb4427e35cf66216fe63487d5c06edaa17a11 — resumen

  pwsh -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # o en 5.1:
  powershell -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_046.ps1] — sha256: a7f2074348dabae021f8bf8f39256b65ad6b384d360138cd3e7d73de59fb72ad — resumen

  # PS 7+
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_047.ps1] — sha256: c4673a5f5bd2df49aa1d6283a94eb018ae57336872bb78dfe37e0e4e160f290c — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_048.ps1] — sha256: a1099e43f9b5cec0410d663850380273c113674e99e57990acdd3f4b02b25982 — resumen

  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # o en 5.1:
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_049.ps1] — sha256: d1d80887a539cbff8fbd4774a5a8da68ec2d9905ff87b0b21c6892f14ba30370 — resumen

  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # o en 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_050.ps1] — sha256: 0f842a12ea87731112dfc67f8677ca9b6aab7c8c2f9da2dcac39b3cc403650e0 — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # Si está bloqueado:

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_051.ps1] — sha256: 0d79e385230dcd29e42a8b5776fdd9a409d34ef985b9ebacf121df80cff838df — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_052.ps1] — sha256: 411b1d03c571664809c3ff03fed90ed9378111ef97a7f2a022fc71865521b174 — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-Min.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-Min.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_053.ps1] — sha256: c1fdffe40a13e13a2931c3f6ff190c01feccc985974e7e296fce72ea71182e66 — resumen

  .\PS-Env-Audit-Min.ps1 -ReportPath "C:\Temp\PS_Env_Report.md" -ReportFormat markdown

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_054.ps1] — sha256: ceced9ff2251b1f9f807b13331f75708fd5daebfc3db7b995eaca258895dc303 — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-CLEAN.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-CLEAN.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_055.ps1] — sha256: 09b18770aa9020f7bc7d2afd2244456eb16bb295c3590309bc4b4a6ae7d7b52c — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_056.ps1] — sha256: 86b4ba206c28f647faf55efac7c57e96cf4b6360183667f48beeb3582537c47f — resumen

  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -ReportPath "$env:USERPROFILE\Desktop\PS_Env_Report.json"
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -ReportPath "$env:USERPROFILE\Desktop\PS_Env_Report.md"

- [sn_automatizacion_scripting_3-32-16-Generar_script_HTML_desde__md_057.ps1] — sha256: b7d592b4047daa333558693a609f589266560af9fc92afca97292ded6d4c036f — resumen

  # PS 7
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -IncludeEnvVars -IncludePaths -OpenAfter
  # PS 5.1
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\PS-Env-Audit-SAFE.ps1" -IncludeEnvVars -IncludePaths -OpenAfter

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_058.ps1] — sha256: f64bf010b0231159d9a2f6f444061059e8e03513afdc11048a48135a1fcc4d32 — resumen

  Add-Type -AssemblyName PresentationCore, System.Windows.Controls
  [System.Windows.MessageBox]::Show("¡Script ejecutado! 🤪","Mensaje Animado")

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_059.ps1] — sha256: 8283a774c6660a0c0c931e00c5a33125931b2c84a6f57619726be52f5a296c29 — resumen

  [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
  Add-Type -AssemblyName PresentationFramework
  $window = New-Object System.Windows.Window
  $window.Title = "Mensaje Animado"
  $window.Width = 300

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_060.ps1] — sha256: 5cb124ada250aa0a05f16011499ccb3f5e20bb9cbcfd9eda375b575f4bcb1ba3 — resumen

  Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
  $XAML = @"
  <Window x:Class="MainWindow"
          xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
          xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_061.txt] — sha256: 7f0aa0bdcf3e31cf2c543e008a4b25995d69bedad651ee89f1b087d7aefa4465 — resumen

  #requires -Version 5.0
  <#
  Propósito: Mostrar un aviso animado en WPF con texto personalizable y emoji.
  Parámetros:
    -Text        : Mensaje a mostrar. Por defecto un texto neutral con 😛

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_062.ps1] — sha256: 5d0084fdbc7f35da1405be4b4db2bbe968fd2e7cda7f12964a9103e4ef8b9fd4 — resumen

  # Detectar la ruta del Escritorio del usuario actual
  $desktop = [Environment]::GetFolderPath('Desktop')
  $script  = Join-Path $desktop 'Entorno.ps1'

  # Ejecutar en PS7 si existe, de lo contrario PS5, y sin mostrar error si uno falla

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_063.ps1] — sha256: b6bf03e709f3682ea7dd2d08674a9fd59f57e0c8245149698b85b7db8f4ab920 — resumen

  # Detectar Escritorio del usuario actual y ubicar Entorno.ps1
  $desktop = [Environment]::GetFolderPath('Desktop')
  $script  = Join-Path $desktop 'Entorno.ps1'
  Set-Location -Path $desktop


- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_064.ps1] — sha256: 2be627d24d107f3bab113f9964e5edb6c44ff0a74dc3e90b02a2fa6fae9b4f4b — resumen

  & "$env:USERPROFILE\Desktop\Entorno.ps1" -Stay

- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_065.ps1] — sha256: e0bf53fe147789e3c5d5aed1290b3ae9d936fb27c8800f8c71c32b10bdfe1d88 — resumen

  $desktop = [Environment]::GetFolderPath('Desktop')
  $script  = Join-Path $desktop 'Entorno.ps1'
  Set-Location $desktop
  if (-not (Test-Path -LiteralPath $script)) { Write-Warning "No se encontró: $script"; return }


- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_066.txt] — sha256: 3004c4b4441ab647dcbd9d4da354526df6f90d06738119d31046e7ab290a27f3 — resumen

  # Detectar Escritorio del usuario actual y ubicar Entorno.ps1
  $desktop = [Environment]::GetFolderPath('Desktop')
  $script  = Join-Path $desktop 'Entorno.ps1'
  Set-Location -Path $desktop


- [sn_automatizacion_scripting_5-6-18-Script_PowerShell_animado_067.txt] — sha256: 2b2c143556cda0745cf2493d8be330ddd41a447dffbb1fcfef9e1acb172b70e7 — resumen

  # Usa tu mismo lanzador y pasa el mensaje como primer argumento
  "Mensaje 😛" | ForEach-Object {
    # Detectar Escritorio y ejecutar con tu bloque
    $desktop = [Environment]::GetFolderPath('Desktop')
    $script  = Join-Path $desktop 'Entorno.ps1'

- [sn_automatizacion_scripting_6-4-22-Integraci_n_normativa_operativa_068.txt] — sha256: a3c825562d9f55ad6a12d52743bc0e4a7a15d0cb6cf0e5be5bac4d3aca36d8bb — resumen

  # Normativa operativa y estándares de entrega ## 1) Principios rectores * Respuestas correctas, completas y accionables en el primer intento. * Ceñirse exactamente a lo solicitado. Minimizar el esfuerzo del usuario. * No demorar por confirmaciones si el requerimiento es claro. * Prioridad: seguridad/compatibilidad > simplicidad > automatización responsable > entrega inmediata. ## 2) Estilo y comunicación * Español siempre. Tono neutro, no emocional, sin opiniones personales. * Directo y conciso. Sin elipsis ni signos de exclamación. * “Salida limpia”: evitar verbosidad y devolver información u objetos útiles. * Mensajes normales en texto plano. Bloques de código solo cuando se pidan. * Mostrar pasos intermedios en problemas complejos; fórmulas en LaTeX. * Aritmética dígito a dígito con cálculo visible. ## 3) Uso de herramientas y verificación * Usar navegación y herramientas cuando mejoren exactitud o frescura. * Para eventos posteriores al corte de conocimiento o temas de nicho: buscar y verificar con fuentes oficiales; citar fuentes y fechas. * No asumir veracidad de una sola fuente; contrastar y priorizar sitios oficiales. * Evitar desinformación sobre capacidades de ChatGPT; verificar en fuentes oficiales: Projects, Deep Research, ChatGPT Agent, OpenAI Codex/Codex CLI. ## 4) Procesamiento y lectura de archivos con Python * Antes de asumir falta de acceso, intentar listar, abrir y leer con Python. * Si no se puede ver el contenido, terminar y avisar sin suposiciones. * Ante truncamientos: detectar, enumerar archivos y tamaños, construir diccionario de metadatos, leer completo desde disco y paginar en fragmentos manejables según convenga; reportar cuántos archivos y caracteres se procesaron y qué fragmentos se muestran. ## 5) Estándares para scripts * Entrega en un único bloque de código con: propósito, parámetros, ejemplos, validaciones y manejo de errores con try/catch y -ErrorAction Stop. * Personalizados al entorno: * Usuario: VictorFabianVeraVill * Máquina: DESKTOP-K6RBEHS * SO: Windows 10 Pro 10.0.19045 64-bit * PowerShell: 7.5.3 Core * Iniciar posicionando el script en la ruta de ejecución. * Instalar automáticamente dependencias necesarias. Preferir Winget cuando aplique. * Incluir indicadores de progreso. * Crear directorios y mover archivos cuando sea necesario. * Comprobar elevación con WindowsPrincipal.IsInRole(Administrator) solo si la acción lo requiere. * Si puede disparar Windows Defender, manejarlo automáticamente. * Si se generan archivos, informar ruta de salida en ASCII, clara y accesible. * Formato de bloques anidados: si un bloque de código contiene otro, el bloque exterior usa 5 backticks. * Validar que el código funcione antes de compartirlo y reportar errores si ocurren. ## 6) Dependencias preferidas * Núcleo: PSReadLine, PSResourceGet, Pester, PSScriptAnalyzer, PlatyPS, ThreadJob, SecretManagement, SecretStore. * Opcionales: ImportExcel, dbatools, BurntToast. ## 7) Semillas y metodología * Semillas fundamentales: bloques doctrinales modulares de diseño y buenas prácticas; no son scripts completos. * Funcionamiento: evaluar aplicabilidad, registrar en Checklist_Aplicabilidad, integrar solo las que aplican y construir bloque canónico reutilizable (param + validaciones + ShouldProcess cuando corresponda). * Objetivo: claridad, robustez, reutilización y consistencia en PS7. * Ejemplos Máximos: tomar el temario completo, evaluar todas las semillas y armar el ejemplo más completo posible. También combinarlas según el temario cuando se requiera. ## 8) Política operativa * Pasar de planear a ejecutar con decisiones útiles, orden claro y foco en un solo objetivo por iteración. Minimizar retrabajo. * Evitar preguntas triviales; señalar riesgos y ofrecer alternativa concreta. * Identificar explícitamente la pregunta y el output esperado antes de actuar. ## 9) Codificación y datos * UTF-8 para texto y datos. ## 10) Marcado de calidad * Si el script es funcional, seguro y compatible: marcar como **Script Canónico** y “**puede ejecutarse con confianza**”. * No añadir funciones no solicitadas salvo petición posterior y alcance permitido. ## 11) Referencias de soporte * Archivo de rutas de referencia: FileList_01_Software_20250920_005336.csv.

- [sn_automatizacion_scripting_6-4-22-Integraci_n_normativa_operativa_069.txt] — sha256: 9cf858fc02d2e09d74e683843ff1232387dcfd656ef2a5b16eb4eb59a326d3d0 — resumen

  Resúmenes por documento:
  - Cuando se pidan resúmenes de diferentes documentos, leer cada documento en su totalidad y entregar las partes más importantes por archivo.

  Interpretación y alcance:
  - Analizar y entender el objetivo del mensaje del usuario en cada ocasión.

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_070.txt] — sha256: 04671aa3280c4783f82b77004073da2cb1ced1fb73657a4ba7177c2cde8e491e — resumen

  <contenido del JSON>

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_071.txt] — sha256: 04671aa3280c4783f82b77004073da2cb1ced1fb73657a4ba7177c2cde8e491e — resumen

  <contenido del JSON>

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_072.json] — sha256: 4f224c96ee23e66040ef618121f56a54dbb63a77c18d72c3894f09facbe35467 — resumen

  {
    "metadata": {
      "script_name": "PS-Env-Audit-CLEAN.ps1",
      "size_bytes": 12750,
      "sha256": "1b9e2d7d0e8f2b0d9b8f0e2d3c0b6bf9e56a656abfe7b433160d9165a9e7fcc0",

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_073.json] — sha256: 6974dd94fbf5a591d540d4b91b248729a3c05da4ef750af401887797bc8f6990 — resumen

  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "schema://postmortem_v5.request.schema.json",
    "title": "Postmortem v5 Request",
    "type": "object",

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_074.json] — sha256: fe68ee9404874fe192805a09e1489aafe57fa8e17cead171c2f297f9e646358d — resumen

  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "schema://postmortem_v5.report.schema.json",
    "title": "Postmortem v5 Report",
    "type": "object",

- [sn_automatizacion_scripting_6-43-13-Interpretaci_n_de_documento_075.json] — sha256: ca23fd0ba7b74113bfdd0c87aaa9b67c0ce6c3ee5f1a93cd0ef15f4a0601f21c — resumen

  {
    "schema_version": "5.0",
    "profile": "local-fixed",
    "privacy": { "redacted": true, "allow_private_paths_in_output": false },
    "consistency": { "k": 3, "method": "majority" },

- [sn_automatizacion_scripting_17-46-27-Verificaci_n_acceso_Banorte_076.sh] — sha256: 2dbe760d0b601951f032b4464750142007e2639bfaa8f1abbc22b713ef5eef6c — resumen

  cat <<'EOF' > check_boot_state.sh
  #!/data/data/com.termux/files/usr/bin/bash
  # Script para checar integridad del bootloader / AVB en Samsung desde Termux
  # Muestra si el sistema está en green, orange o red


- [sn_automatizacion_scripting_17-46-27-Verificaci_n_acceso_Banorte_077.txt] — sha256: c46e599dbcb5a586dad6044c73be8afb74ee2827e24bf3b0359850b4da5c6170 — resumen

  Verified Boot State : orange
  Flash Lock State    : 0
  Knox Warranty Bit   : 0
  ⚠️ Estado ORANGE: Bootloader desbloqueado.

- [sn_automatizacion_scripting_17-46-27-Verificaci_n_acceso_Banorte_078.txt] — sha256: c26f7a5f7200ac2388ecbc73c13a7a34ed9fdd5837e1057c683316fe29243189 — resumen

  getprop ro.boot.verifiedbootstate; getprop ro.boot.flash.locked; getprop ro.boot.warranty_bit

- [sn_automatizacion_scripting_8-17-20-Corregir_heredoc_consola_079.txt] — sha256: 83693f55858127997bc87416147c2ac462ae9bee1f41b4c5bce8cf28221c6764 — resumen

  TARGET="${TMPDIR:-$HOME}/screen_menu.sh"; mkdir -p "$(dirname "$TARGET")"
  cat >"$TARGET" <<'SH'
  #!/system/bin/sh
  # Menu captura/grabación para Android (ADB o Termux)


- [sn_automatizacion_scripting_8-17-20-Corregir_heredoc_consola_080.txt] — sha256: 061a4624ecc911df9f7e3ba99c41aa22e7d035e29f3a7444dd853015c075ac8d — resumen

  TARGET="${TMPDIR:-$HOME}/screen_menu.sh"; mkdir -p "$(dirname "$TARGET")"
  cat >"$TARGET" <<'SH'
  #!/bin/sh
  # Menu captura/grabación para Android (Termux o adb shell)


- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_081.txt] — sha256: 0ba83c35529a0f216ec60b101d29e8f86b3c98c6411580fc1c0f89a068aaee74 — resumen

  #!/bin/bash
  # Script para transmitir pantalla de celular Android a la PC usando scrcpy

  # Configuración: resolución y bitrate opcional
  RESOL="1024"

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_082.txt] — sha256: 587eebd092ca324553302d8ddd4a349a1d84ba7cc7b68ead485fa680ab843632 — resumen

  # Script PowerShell para instalar dependencias y transmitir Android con scrcpy
  # Requiere PowerShell 7 (ejecutar como usuario con permisos de instalación)

  $ErrorActionPreference = "Stop"


- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_083.txt] — sha256: a94fb2ce8cce59d0c19f31dbdb33accb5e8f6f8615b7f43767ba7e686e21ad91 — resumen

  # Verificar dispositivo
  Write-Host "Verificando dispositivo..."
  $adbOutput = & adb devices
  $devices = $adbOutput | Select-String "device$"


- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_084.txt] — sha256: 47feba68512e97672198361fa0c347317c7fee8111332ae38fd94e64334d78d8 — resumen

  # Verificar dispositivo
  Write-Host "Verificando dispositivo..."
  $adbOutput = & adb devices
  $devices = $adbOutput | Select-String "device$"


- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_085.txt] — sha256: 19da53faf715f533130a08b1bda012090783a759a6d186363ae2933a3319d4e4 — resumen

  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_086.txt] — sha256: 04d1200e8c7c1c99cb0f2378558ff74de16d15ddfcf34c88d9d8c164d1a6fe5b — resumen

  .\mirror_phone.ps1

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_087.txt] — sha256: bd568cc07da0fadb22c2cc97b8615df33fb20c44b8bbf9c4cc9d0b89a14557c8 — resumen

  .\mirror_phone.ps1 -Wifi

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_088.ps1] — sha256: c3056f55d5cc4bc05a08055b62bd509338eef15af3985641b8772d371de23380 — resumen

  # Crea el archivo EXACTO solicitado con el script completo en una here-string.
  # Ruta pedida: C:\Users\VictorFabianVeraVill\Dekstop\mirror_phone.ps1
  $path = 'C:\Users\VictorFabianVeraVill\Dekstop\mirror_phone.ps1'
  $dir  = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_089.txt] — sha256: 879fbeae75eb62a8e2ddc6449750fb8ffab5c3304354eb7f1d58576a58898468 — resumen

  ERROR: --bit-rate has been removed, use --video-bit-rate or --audio-bit-rate.

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_090.ps1] — sha256: 1866a130f42787ff7332317164b728a6d2a1447fb1348971ebe6054fe00698e9 — resumen

  $opts = @("--no-control", "--max-size", $MaxSize, "--bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_091.ps1] — sha256: 390d541007ef3074469270f6c4fd9c5628962044e6b02979e878cc965b9d5375 — resumen

  $opts = @("--no-control", "--max-size", $MaxSize, "--video-bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_092.ps1] — sha256: 1ea4181c1228344a2fd8bc286cc2e2145c804c2476f66969009103e7249f5ba0 — resumen

  function Start-Mirror {
    $opts = @("--no-control", "--max-size", $MaxSize, "--video-bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")
    if ($AlwaysOnTop) { $opts += "--always-on-top" }
    Write-Host "Launching scrcpy in READ-ONLY mode (no input will be sent to the phone)..."
    & scrcpy @opts

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_093.ps1] — sha256: b6920947f865498516a198b0e6b19b2b03da3dd6248639f94750beb5691d7584 — resumen

  $path = 'C:\Users\VictorFabianVeraVill\Desktop\mirror_phone.ps1'

  @'
  function Start-Mirror {
    $opts = @("--no-control", "--max-size", $MaxSize, "--video-bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_094.ps1] — sha256: 04d1200e8c7c1c99cb0f2378558ff74de16d15ddfcf34c88d9d8c164d1a6fe5b — resumen

  .\mirror_phone.ps1

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_095.txt] — sha256: 3d694f8581a3afdf9fdfc8af753286e480fcb2ebbdaac395c97425f167d3ccb9 — resumen

  RFCW41H5ACD    device

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_096.ps1] — sha256: 04d1200e8c7c1c99cb0f2378558ff74de16d15ddfcf34c88d9d8c164d1a6fe5b — resumen

  .\mirror_phone.ps1

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_097.txt] — sha256: 7ac8ec2d328596d9de28a7fe3ebd3cc47a6f6d5764ebde1f9f2af1198ff60a69 — resumen

  scrcpy: unknown option -- verbose

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_098.txt] — sha256: d81253b5444a32be99cb13a4513e70102a5daf4210b05aa5ff4f5a3bb85aa501 — resumen

  scrcpy: unknown option -- disable-secure

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_099.ps1] — sha256: 0d5f63ce9538b5f86cda570e62e555b06be7b618453db2726d476812e91c22a2 — resumen

  mkdir C:\Users\VictorFabianVeraVill\Desktop\phone_downloads

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_100.ps1] — sha256: 08e903de7ea7337abc8a857a75ccc4dd356decffc2eedec679e25dd1fd27da4a — resumen

  adb pull /sdcard/Download C:\Users\VictorFabianVeraVill\Desktop\phone_downloads

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_101.ps1] — sha256: 4d0d8196118fb9a2fe87e1a3611a5bea260338aded31ccd7088aaec15351d91a — resumen

  adb shell screenrecord /sdcard/demo.mp4

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_102.ps1] — sha256: d5d4eb976c104dc7914c4cf392dbaaa547e71dc96f8440932d4e269e4cde1a0c — resumen

  adb pull /sdcard/demo.mp4 C:\Users\VictorFabianVeraVill\Desktop\

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_103.ps1] — sha256: 41055af2f626a9fa8ef2ff0057a57a4b5a5dae79cf07662793a78ff222d6f0ab — resumen

  # record_phone.ps1
  # Graba la pantalla del móvil Android y guarda el video en el Desktop, reparado para que se abra en cualquier reproductor.
  # Requiere: Windows 10/11 + PowerShell 7
  # Uso:
  #   .\record_phone.ps1 -Duration 30

- [sn_automatizacion_scripting_8-31-4-Script_para_espejar_celular_104.ps1] — sha256: 0d7e03d8d7e3cd0dd32548ffb3aa259e6d12da6441ccf48c8707b355a936cf2e — resumen

  # map_videos.ps1
  # Escanea el teléfono Android por ADB y lista todos los archivos de video detectados.
  # Resultado: CSV en el Desktop con rutas, tamaños y fechas.

  $ErrorActionPreference = "Stop"

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_105.sh] — sha256: f4dbc2f2edbd777d5f0c6750f36c1a993d84300a9c0c105a209e437f335d703a — resumen

  # pasos para usarlo en Termux
  pkg update -y && pkg upgrade -y
  pkg install python git -y
  git clone https://github.com/mr3rf1/SecPhoto.git
  cd SecPhoto

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_106.sh] — sha256: 498292fd217be502f716f5954dc3a70a65b02e078c058a7562119d4ab6ecd6de — resumen

  python3 SecPhoto.py -Sid nombreUsuarioChat

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_107.sh] — sha256: f9161aef783ef81c449f6ecfc206fa5349ab0a850049bb32bbfd8c10ea619643 — resumen

  screencap -p /sdcard/captura_$(date +%s).png

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_108.sh] — sha256: e34a0f826e1090a46b4ce51ad849441398c2fbb99a193faa33e2fa6b84c0c080 — resumen

  bash <<'EOF'
  OUT="/sdcard/captura_$(date +%Y%m%d_%H%M%S).png"
  screencap -p "$OUT"
  echo "Guardado en: $OUT"
  EOF

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_109.sh] — sha256: 8635e3e97a69c7c6b8ac444c0c9546a1143aa122bc38ca3969484717e6de3699 — resumen

  adb shell screencap -p > captura.png

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_110.sh] — sha256: 6ff541049449d9459aef896c0a9ee19a6c5f6424275740cef4bd2c8ac08549ef — resumen

  screenrecord /sdcard/video_$(date +%s).mp4

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_111.sh] — sha256: 41cc8da6bf2228cfe110c54f32a7f20b6b6c202643a32abccb930d860e05b2d1 — resumen

  bash <<'EOF'
  #!/data/data/com.termux/files/usr/bin/bash
  OUTDIR="/sdcard"
  mkdir -p "$OUTDIR"


- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_112.sh] — sha256: 9dbf492833df9dad2cc48f43e5f1b4d9ac71d66547df1a57e56fc7e406293927 — resumen

  bash <<'EOF'
  OUTDIR="/sdcard"
  mkdir -p "$OUTDIR"

  echo "[1] Captura de pantalla"

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_113.sh] — sha256: e0f2820d398ed7cbb1f71d71213531df8bba4ae5efa6e44cbb28abd16dc8ae69 — resumen

  bash <<'EOF'
  OUTDIR="/sdcard"
  mkdir -p "$OUTDIR"

  echo "[1] Captura de pantalla"

- [sn_automatizacion_scripting_8-8-11-Bash_para_descargar_videos_114.sh] — sha256: afb24e8c0da7230fc2213264658a599e8e28a9c584849e39b22c9bd9e94ee45c — resumen

  bash <<'EOF'
  OUTDIR="/sdcard/DCIM/Camera"
  mkdir -p "$OUTDIR"

  echo "[1] Captura de pantalla"

## Checklists (previo, durante, posterior)

- - Hay **inconsistencias** y **huecos operativos** que causarán fricción: PS7 vs PS5.1, una línea rota, verbos contradictorios (“ejecuta” un .md), duplicados de texto y reglas sin mecanismo de verificación automática.
- - `#requires -Version 5.1`: **Definido** (✔ conceptual, falta verificación automática).
- - Mensaje final: verificación aplicada **sin mutar contenido** (salvo la normalización de carpeta BACKUPS si era necesaria).
- - `SupportsShouldProcess = $true`: permite usar `-WhatIf` y `-Confirm` para simular o confirmar acciones antes de ejecutarlas.
- - Try-TestWritable (SEED06) para comprobación de escritura
- - Combinar ShouldProcess (SEED01) + validadores antes de ejecutar acciones destructivas
- * Antes de asumir falta de acceso, intentar listar, abrir y leer con Python.
- * Validar que el código funcione antes de compartirlo y reportar errores si ocurren.
- * Identificar explícitamente la pregunta y el output esperado antes de actuar.
- - Identificar explícitamente la pregunta y el output esperado antes de actuar.
- - Antes de asumir falta de acceso, intentar listar, abrir y leer con Python. Si no es posible, terminar y avisar sin suposiciones.
- - Validar que el código funcione antes de compartirlo y reportar errores si ocurren.
- - “Salto 1” de variables y splatting antes de evaluar comillas/validaciones.
- - Verificación tipo CoVe por hallazgo: redacta preguntas de verificación, respóndelas de forma independiente y marca Verified/Rejected antes del JSON final. Esto reduce alucinaciones en tareas de verificación factual. citeturn1search0turn1search3
- - Pasos del pipeline, incluyendo verificación CoVe y auto-consistencia opcionales
- - Redactar 2–4 preguntas de verificación
- - Opcional: verificación CoVe y autoconsistencia k>1 para bajar alucinación. citeturn0search9turn0search8
- - Si hubieras intentado desactivar *OEM Unlock* justo después del desbloqueo (sin modificar nada más), probablemente igual te hubiera pedido un reseteo y hubiera bastado.
- - Después de flashear, conecta el dispositivo a internet para el handshake con VaultKeeper, luego pasa al modo de descarga para bloquear.
- - Lo puedes mover o enviar a otra ruta después.

## Errores comunes y mitigaciones

- - Si faltan, **lanza error** detallando qué falta.
- - En error: escribe `ERROR — …`, agrega entrada al **global changelog** y sale con código **1**.
- - Si faltan `Project_Instructions.md` o los SOP listados ⇒ **lanza error**.
- - `LogLevel` → **`NivelLog`**, mismo conjunto de valores (`Error, Warn, Info, Debug`).
- - try { ... } catch { Write-Error $_; throw }
- - $Error.Clear(); uso de -ErrorVariable para canalizar diagnósticos
- - Logging con niveles (Error/Warn/Info/Debug) y volcado a disco.
- - Error: “The term 'begin' is not recognized as a name of a cmdlet, function, script file, or executable program.”
- - Error: “Cannot convert 'System.Object[]' to the type 'System.String' required by parameter 'AdditionalChildPath'. Specified method is not supported.”
- - Error: “Cannot convert 'System.Object[]' to the type 'System.String' required by parameter 'ChildPath'. Specified method is not supported.”
- - Error (PS-Env-Audit-CLEAN.ps1, PS 7 y 5.1): “Parameter set cannot be resolved using the specified named parameters.” / “AmbiguousParameterSet.”
- - Error: “The term '.\PS-Env-Audit-CLEAN.ps1' is not recognized as a name of a cmdlet, function, script file, or executable program.”
- - Solo análisis estático y textual. Sin ejecución ni AST. Riesgo de falsos positivos/negativos. fileciteturn1file0L11-L11 fileciteturn1file2L25-L25 fileciteturn1file2L16-L23
- - Exposición innecesaria de datos locales en el “prompt operativo” (usuario, IP, disco). Riesgo de privacidad si se comparte. fileciteturn1file3L34-L39
- - R03: Faltan validaciones para parametros (aunque no es un riesgo de seguridad).
- - R10 `Start-Process` en “OpenAfter” sin `-ErrorAction Stop` y manejo de error.
- - Fixture “openafter.ps1”: gatilla R10 si falta manejo de error.
- - OpenAfter: `Test-Path` previo, `-ErrorAction Stop`, manejo de error, y no ejecutar en modo no interactivo.
- - Mitigación de riesgos OWASP-LLM aplicados al uso del protocolo: endurece “input handling” y “insecure output handling”; ignora instrucciones incrustadas en archivos auditados y nunca ejecuta salidas. citeturn0search0turn0search5turn0search10
- - R14 OpenAfter-Guard+: requiere `Test-Path`, `-ErrorAction Stop` y manejo de error; desactiva en entornos no interactivos.
- - R10 OpenAfter sin manejo de error
- - OpenAfter: Test-Path previo + -ErrorAction Stop + manejo de error
- - Si ves error de permisos, primero ejecuta en PowerShell:
- - Si da error de parámetros, asegúrate de haber aplicado el parche (`--video-bit-rate`).
- - Pero suelen ser poco fiables y con riesgo de malware.
- - Incluso con flags de tolerancia (`-err_detect ignore_err -analyzeduration -probesize`) → el error persiste.

## Métricas / criterios de calidad

- - Validación de un archivo `.txt`.
- - Validación de `SessionRoot` → renombrado a **`RutaSesion`**, con la misma lógica de no estar vacío y no ser un archivo existente.
- - Validación de rutas peligrosas.
- - Validación de combinaciones exclusivas mediante ParameterSetName
- - Los scripts se entreguen en un único bloque de código, con: propósito, parámetros, ejemplos, validación de entradas y manejo de errores (try/catch con `-ErrorAction Stop`).
- - S04: Start-Process / cmd.exe /c con args concatenados sin validación.
- - Coherencia `ReportFormat` ↔ extensión de `ReportPath` con validación estructural.
- - S02 Descarga → ejecución sin validación.
- - S04 Llamadas externas con concatenación sin validación.
- - A02 Parseo frágil de salidas de utilitarios sin validación.
- - Q01 (calidad): falta `Set-StrictMode -Version Latest` y/o `$ErrorActionPreference='Stop'` cerca de L27. Baja.
- - Q01 (calidad): falta Set-StrictMode -Version Latest. Bajo.
- - Guardrails de salida: JSON validado con esquema estricto y campos tipados; rechaza y reintenta si no cumple. Inspirado en frameworks de validación estructural. citeturn3search0turn3search6
- - Guardrails: validación con esquema JSON
- - S02 Descarga→ejecución sin validación ni hash
- - Validación previa con esquema; si no valida, se rechaza. (Guardrails/Pydantic sirven de referencia). citeturn0search4turn0search10turn0search16
- - Usa “structured outputs” con validación estricta para garantizar conformidad al esquema. citeturn0search4turn0search9turn0search14
- - **README (uso/validación):** [README_mirror_phone.md](sandbox:/mnt/data/README_mirror_phone.md)
- - `--video-bit-rate` → controla la calidad de video (lo que nos interesa).

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-33-27-An_lisis_de_m_dulos_PowerShell.md | be44947834e1f3a196e8672b916ee9324563b7f2a17e4180810d48f2ae8ad077 | Análisis de módulos PowerShell | assistant, system, user | sí |
| 2025-9-29/6-45-32-An_lisis_README_proyecto.md | 98ffe3ffd28215303f641646acbee46eda1c22333049bea4dd5e0275064ed7fe | Análisis README proyecto | assistant, system, user | sí |
| 2025-9-29/5-31-12-_SCRIPT___Invoke_RepoReorg_.md | d89d45a8261a87c3b5dc3f35f50a6f9cea8060b27b4976c206ae8e9f4d05c864 | <SCRIPT - Invoke-RepoReorg> | assistant, system, user | sí |
| 2025-9-15/12-21-35-Ejemplo_prompt_Codex_Powershell.md | 95fdd6a1db98d4abd17b42311ddedef9dd71af0e19fdf23459dc3664a11d004a | Ejemplo prompt Codex Powershell | assistant, system, tool, user | sí |
| 2025-9-15/7-18-38-Reporte_de_consejos_PowerShell.md | 64398c5e3530e8bd486c47343d24f034f6b9bb7366d9e35e3785a2c320add2d6 | Reporte de consejos PowerShell | assistant, system, tool, user | sí |
| 2025-9-18/7-7-32-Significado_de_un_script.md | ea6a4508129d5731d6c029a14b689bfe7d74e3ad79407209ca83f76903fd92a9 | Significado de un script | assistant, system, user | sí |
| 2025-9-20/0-47-50-Instrucciones_personalizadas_y_memoria.md | ff9b76e7cd5e11dc679a48a5587a602fa6852bc51d88378284e1390cc127a089 | Instrucciones personalizadas y memoria | assistant, system, tool, user | sí |
| 2025-9-20/1-8-47-Instrucciones_guardadas_sistema.md | c026d7e55ea11eef32f5a4d182a6f51e463144550ea2cc9d45750742a390107d | Instrucciones guardadas sistema | assistant, system, tool, user | sí |
| 2025-9-20/2-57-37-Normativa_operativa_guardada.md | 9408ca1c0b1a8b6c810435759440c32f2b33bef85f606ea63070bae05033a507 | Normativa operativa guardada | assistant, system, tool, user | sí |
| 2025-9-20/3-32-16-Generar_script_HTML_desde__md.md | d13892ef1e49e1dfcc4a24df6d6509d08112ba6dc3232946adde7a7557dd1989 | Generar script HTML desde .md | assistant, system, tool, user | sí |
| 2025-9-20/5-6-18-Script_PowerShell_animado.md | f6279941acb6e5622254817a2efa7122522f964d59346d5ca2e4c79570cf9ce1 | Script PowerShell animado | assistant, system, tool, user | sí |
| 2025-9-20/6-4-22-Integraci_n_normativa_operativa.md | f20885d103fc9ab4f08f036a9bc77e312b2944a073f7943797a2c2e9407107f8 | Integración normativa operativa | assistant, system, user | sí |
| 2025-9-20/6-43-13-Interpretaci_n_de_documento.md | 909ed929414995b94d6f84de9102241f53c7cd8cac5b6ecf6e0eb778dfce265e | Interpretación de documento | assistant, system, tool, user | sí |
| 2025-9-23/17-46-27-Verificaci_n_acceso_Banorte.md | 0d0f84eb04f557ca481bf919c6bfd6ae2327df5e65ea77c37717188e7d0445b7 | Verificación acceso Banorte | assistant, system, tool, user | sí |
| 2025-9-24/8-17-20-Corregir_heredoc_consola.md | f8b3c4db356742f5bff07462d5c7229221ce01af701a071f4df6df06cf0a8580 | Corregir heredoc consola | assistant, system, user | sí |
| 2025-9-24/8-31-4-Script_para_espejar_celular.md | 6db30f8467df40f848542c73e6acfa302e8d15387eb8158fa97568549e405f37 | Script para espejar celular | assistant, system, tool, user | sí |
| 2025-9-24/8-8-11-Bash_para_descargar_videos.md | 7d24cf18b72de840a0b0d33eaba56041849c133000ea4cffe3a263bf1f2d139f | Bash para descargar videos | assistant, system, tool, user | sí |
| 2025-9-28/16-54-29-New_chat.md | 2f8cbc3fee655d1998ad0198db440b303d638e87b44e8caf3165e2cb485a73f7 | New chat | assistant, system, tool, user | sí |
