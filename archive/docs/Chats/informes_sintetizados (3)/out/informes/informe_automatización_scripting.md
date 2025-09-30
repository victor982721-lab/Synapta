# automatización/scripting

## Resumen ejecutivo

- Conversaciones canónicas: 4.
- Tópicos frecuentes: script, window, windows, system, termux, powershell, entorno, mensaje, string, replace.
- Justificación de agrupamiento: reglas deterministas por palabras clave.

## Alcance y supuestos

- Se consolidan conversaciones (MD/JSON) relativas al grupo mediante reglas de palabras clave.
- Se preservan bloques de código, prompts, tablas, comandos y pares I/O.

## Procedimiento paso a paso

- (C0044) 1. **Configura rutas** (Windows) y una **ruta espejo opcional** del CHANGELOG en `/mnt/data/Repo_AR/CHANGELOG.md`.
- (C0044) 2. Define utilidades:
- (C0044) 3. **Valida** que exista el script viejo `SCRIPTS\Invoke-RepoReorg.ps1`; si no, **lanza error** y termina.
- (C0044) 4. **Respalda** el script viejo a `SCRIPTS\BACKUPS\Invoke-RepoReorg_<UTC>.bak`.
- (C0044) 5. **Escribe** el nuevo **SCRIPTS\Verify_Project.ps1** (contenido largo, modular, ver abajo).
- (C0044) 6. **Sobrescribe** `SCRIPTS\Invoke-RepoReorg.ps1` con un **stub** que reenvía todos los argumentos al nuevo `Verify_Project.ps1`.
- (C0044) 7. **Asienta bitácora**: agrega un bloque con fecha UTC a `CHANGELOG.md` (Windows y espejo si está presente).
- (C0044) 8. Muestra un **resumen en consola** con rutas del nuevo archivo, stub y backup.
- (C0081) 1. **Termux** (si aparecía “Permission denied” en `/sdcard`): ejecuta una vez `termux-setup-storage`, acepta permisos y vuelve a correr el bloque.
- (C0081) 2. Elige `1` → verifica que se crea `captura_YYYYmmdd_HHMMSS.png` en `DCIM/Camera` (o `Download`).
- (C0081) 3. Elige `2` → graba y detén con **Ctrl+C**; verifica `video_YYYYmmdd_HHMMSS.mp4` en la misma carpeta.
- (C0081) 4. Si prefieres forzar ruta, edita `pick_outdir()` y pon tu carpeta fija.

## Mejores prompts / plantillas

- (C0053) Prompt:

```text
# Detectar Escritorio del usuario actual y ubicar Entorno.ps1
$desktop = [Environment]::GetFolderPath('Desktop')
$script  = Join-Path $desktop 'Entorno.ps1'
Set-Location -Path $desktop

if (-not (Test-Path -LiteralPath $script)) {
    Write-Warning "No se encontró: $script"
    return
}

# Intentar primero pwsh (PS7), luego powershell (PS5), sin ruido si uno falla
$ran = $false

try {
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        & $pwshCmd.Source -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
        $ran = $true
    }
}
catch { }

if (-not $ran) {
    try {
        $ps5Cmd = Get-Command powershell -ErrorAction SilentlyContinue
        if ($ps5Cmd) {
            & $ps5Cmd.Source -NoProfile -ExecutionPolicy Bypass -File $script @args 2>$null
            $ran = $true
        }
    }
    catch { }
}

if (-not $ran) {
    Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)."
}
```
- (C0053) Prompt:

```text
$desktop = [Environment]::GetFolderPath('Desktop')
$script  = Join-Path $desktop 'Entorno.ps1'
Set-Location $desktop
if (-not (Test-Path -LiteralPath $script)) { Write-Warning "No se encontró: $script"; return }

# Asegurar -Stay por defecto
$paramList = @($args)
if (-not ($paramList -contains '-Stay')) { $paramList += '-Stay' }

$ran = $false
try {
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($pwsh) {
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null
    if ($LASTEXITCODE -eq 0) { $ran = $true }
  }
} catch { }

if (-not $ran) {
  try {
    $ps5 = Get-Command powershell -ErrorAction SilentlyContinue
    if ($ps5) {
      & $ps5.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null
      $ran = $true
    }
  } catch { }
}

if (-not $ran) { Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)." }
```
- (C0053) Prompt:

```text
# Usa tu mismo lanzador y pasa el mensaje como primer argumento
"Mensaje 😛" | ForEach-Object {
  # Detectar Escritorio y ejecutar con tu bloque
  $desktop = [Environment]::GetFolderPath('Desktop')
  $script  = Join-Path $desktop 'Entorno.ps1'
  Set-Location -Path $desktop
  if (-not (Test-Path -LiteralPath $script)) { Write-Warning "No se encontró: $script"; return }
  $paramList = @('-Text', $_, '-Stay', '-Full')
  $ran = $false
  try { $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue; if ($pwsh) { & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null; $ran = $true } } catch {}
  if (-not $ran) { try { $ps5 = Get-Command powershell -ErrorAction SilentlyContinue; if ($ps5) { & $ps5.Source -NoProfile -ExecutionPolicy Bypass -File $script @paramList 2>$null; $ran = $true } } catch {} }
  if (-not $ran) { Write-Warning "No se encontró ni pwsh (PS7) ni powershell (PS5)." }
}
```

## Ejemplos completos

- [ejemplo_C0041_8.md] — sha256: f3ff45ba6cd603c1542fcdb46249ea8bdac350b2c12c0a53893bdba0bbfc1a3f — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0044_8.md] — sha256: ccaf1b588a731e0612171578ac13ceafd980a95c9c115662e719ab255ae0089c — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0053_19.md] — sha256: 2041f97c5f4309bf20281287eb6e957eb951a3eed074ce3765b4bed8fe15d863 — Bloque de código largo archivado como ejemplo.

## Snippets de código / comandos

- [snippet_C0044_131.md] — sha256: 5194b0b90f0e2a22e270ae7d807ab639cbb8ef93ac4ca1297e37b234f67e7869 — Snippet de código breve.
- [snippet_C0044_134.md] — sha256: 77226d884ff4c79af90d1d6700bf2a89ff38d138896d98d67c3ebd5e8f352998 — Snippet de código breve.
- [snippet_C0044_137.md] — sha256: faf40c37df803a637c53edfb482ffb96aa3f5c9041a64b61f14af041c50ec26c — Snippet de código breve.
- [snippet_C0053_13.md] — sha256: 3836bc4dc9207ecf57589d5d0de8adf71466b9fefe671e928342c07102d013ba — Snippet de código breve.
- [snippet_C0053_16.md] — sha256: dbdc474b457f3759d147d4254cac4b8ae97f40ed2b60fe352fc4cc36b36010d5 — Snippet de código breve.
- [snippet_C0053_736.md] — sha256: 1d8cf7dd3ba3af022553d1cf3ceab80b6d0eebfb818a23a7f221c8d0041253c4 — Snippet de código breve.
- [snippet_C0053_757.md] — sha256: 23a80e6e5aa2b485316c19191c39d4b84e28c65bea1eeba7205f1fc3919db1ff — Snippet de código breve.
- [snippet_C0053_760.md] — sha256: 3cecb85010cd997a1ecfc03de8a7c0b5b3fbb8f81a2ef0502318d75889cddc39 — Snippet de código breve.
- [snippet_C0053_1001.md] — sha256: 0c1245f9addd599556de4749af6504b1ca0d7abd56c9d5464afe99d95b964f8d — Snippet de código breve.

## Checklists (previo, durante, posterior)

- (N/A) No se detectaron checklists explícitas.

## Errores comunes y mitigaciones

- (C0041) Devuelve un objeto resumen con conteo de errores.
- (C0044) El script establece el modo estricto, define funciones auxiliares y asegura que existan directorios. Realiza un respaldo del archivo antiguo y escribe un nuevo `Verify_Project.ps1`, además de actualizar el historial en `CHANGELOG.md`. Es idempotente; puede reejecutarse sin problemas. Menciona posibles fallos como la ausencia de rutas o permisos.
- (C0044) 3. **Valida** que exista el script viejo `SCRIPTS\Invoke-RepoReorg.ps1`; si no, **lanza error** y termina.
- (C0044) - Si faltan, **lanza error** detallando qué falta.
- (C0044) - **PSScriptAnalyzer** (`-RunPSSA`): analiza el propio script, muestra tabla de hallazgos y marca fallo del gate si hay errores/ warnings.
- (C0044) - Si hay fallos/errores, **lanza excepción** “Quality Gate falló”.
- (C0044) - En error: escribe `ERROR — …`, agrega entrada al **global changelog** y sale con código **1**.
- (C0044) # Errores y casos borde
- (C0044) - Si **no existe** `SCRIPTS\Invoke-RepoReorg.ps1`, el patch **falla** (no intenta inventarlo; requiere versionar y dejar stub).
- (C0044) - Falta de permisos de escritura ⇒ errores al crear backup, escribir nuevos archivos o CHANGELOG.
- (C0044) - Si faltan `Project_Instructions.md` o los SOP listados ⇒ **lanza error**.
- (C0044) - Solo **falla** el gate si se pidió correrlos y hubo hallazgos/errores.
- (C0053) $ErrorActionPreference = 'Stop'
- (C0053) Write-Error ("Error: " + $_.Exception.Message)
- (C0053) Voy a crear el archivo con un script compatible tanto con PS5 como PS7, incluyendo opciones como -Text, -DurationSec y quizás -Theme o -Position. No es necesario agregar más opciones, pero puedo mantenerlo minimalista. Si las bibliotecas WPF fallan, podemos recurrir a un mensaje de notificación sin animación.
- (C0053) Crearé un script que utilice una ventana HTA con animación CSS y soporte tanto PS5 como PS7, incluyendo parámetros como texto, duración y posición. Usaremos "mshta" para las animaciones e implementaremos una validación de ubicación de ejecución. Si falla, el script utilizará WScript.Shell Popup sin animación como último recurso.
- (C0053) Manejo de errores:
- (C0053) - try/catch con $ErrorActionPreference = 'Stop'.
- (C0053) $ErrorActionPreference = 'Stop'
- (C0053) Write-Error ("Error: {0}" -f $_.Exception.Message)
- (C0053) Compatibilidad PS5 y PS7. WPF con animación y respaldo mshta. Incluye validaciones, errores controlados y progreso.
- (C0053) Por favor el comando para ejecución que funcione para ambos PS, (Si es necesario que pruebe uno, si no funciona, prueba el otro automáticamente, sin marcar error de preferencia)
- (C0053) Usa este bloque para ejecutar **Entorno.ps1** desde cualquier PowerShell (5 o 7) sin marcar error si falla uno u otro. Dirige siempre la ruta al Escritorio del usuario actual:
- (C0053) # Ejecutar en PS7 si existe, de lo contrario PS5, y sin mostrar error si uno falla
- (C0053) if (Get-Command pwsh -ErrorAction SilentlyContinue) {
- (C0053) elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
- (C0053) - Redirige los errores a `null` para que no interrumpan.
- (C0053) El usuario quiere que la ventana emergente permanezca abierta hasta que la cierre manualmente. La solución es agregar un parámetro -Sticky, -WaitForClick o -NoAutoClose. También se puede modificar el script para aceptar -Mode 'Timer' o 'Manual', manteniendo la opción de duración definida y la opción de permanecer hasta un clic o Enter.
- (C0053) Parece que el usuario tuvo problemas con la política de ejecución, probablemente al ejecutar directamente el archivo `.ps1`. Para solucionarlo, deben usar el comando `powershell -ExecutionPolicy Bypass -File path`. Además, necesito ajustar el código para asegurarme de que el parámetro `-Stay` no cierre automáticamente el script y que la variable `keep` se defina correctamente. También corregiré el lanzador para garantizar la ruta y las comillas adecuadas.
- (C0053) El usuario intentó ejecutar el script `.ps1` usando el parámetro `-ExecutionPolicy Bypass`, pero teniendo problemas con la política de ejecución y el error "no reconocido como cmdlet". Debo revisar el uso de `pwsh` y cómo se interpreta este parámetro en sistemas no-Windows. Luego, modificaré el archivo de manera adecuada con las herramientas disponibles.
- (C0053) Si todavía ves el diálogo de error de script, confirma que no tengas políticas de IE/HTA que bloqueen JS.
- (C0053) # Ejecutar en PS7 si existe, de lo contrario PS5, y sin mostrar error si uno falla
- (C0053) if (Get-Command pwsh -ErrorAction SilentlyContinue) {
- (C0053) elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
- (C0053) El usuario quiere una versión robusta del lanzador que maneje problemas comunes, como la política de ejecución. Necesitamos un código para revisar si el archivo existe, establecer el directorio a "Desktop", probar "pwsh" o "powershell", y asegurar compatibilidad entre versiones 5 y 7 usando un fallback. También pasaremos los argumentos correctamente, posiblemente usando "–%". Además, debemos permitir que funcione sin errores incluso con restricciones de la política de ejecución.
- (C0053) Parece que el script no está firmado digitalmente, lo que a menudo es un problema con PS5, que requiere políticas como "AllSigned" o "RemoteSigned". Usar -ExecutionPolicy Bypass puede evitar la política, pero si el archivo tiene la marca Zone.Identifier (por descargarse de internet), aún puede generarse un error. Además, hay que recordar manejar las comillas con rutas que tengan espacios para evitar problemas, y pasar correctamente los argumentos usando "$args".
- (C0053) El usuario prefiere respuestas directas y estilo minimalista. Para el código, debemos asegurar un bloque sin complicaciones, utilizando triple backtick. No es necesario anidar, ya que no hay bloques de código dentro. También, deberíamos asegurar la ruta al escritorio usando [Environment]::GetFolderPath('Desktop') y prevenir fallos con la invocación directa si es necesario.
- (C0053) El usuario ha solicitado mensajes sin bloquear código a menos que se indique lo contrario, así que voy a usar el bloque de código solo para el script, como pidieron. Debemos agregar validación para asegurarnos de que el script existe, suprimir errores, y manejar salidas no deseadas sin hacer ruido, aunque aún avisemos si algo falta, como PowerShell.
- (C0053) Aquí tienes la versión corregida. Prueba PS7 y, si no está o falla, PS5. Dirige la ruta al Escritorio del usuario actual y evita errores visibles.
- (C0053) Parece que el problema es que el script se cierra rápidamente. Es probable que no se esté pasando el argumento -Stay correctamente. Además, si hay una política de ejecución o redirección de errores a null, la ventana se cierra por eso. Necesitamos ajustar el lanzador para que pase -Stay por defecto y se asegure de que el script se ejecute sin problemas.
- (C0053) Solución: ejecuta con `-Stay`. Usa uno de estos.
- (C0053) Bloque con fallback PS7→PS5, sin errores visibles y manteniendo la ventana:
- (C0053) El usuario quiere que la ventana se abra en tamaño completo. La solución más fácil es agregar un parámetro como -Full o -Maximize para ajustar el tamaño de la ventana, maximizando y estableciendo la tarjeta al 90% del ancho con una fuente más grande. Para mshta, usaremos `resizeTo` para hacer que ocupe toda la pantalla.
- (C0053) # Intentar primero pwsh (PS7), luego powershell (PS5), sin ruido si uno falla
- (C0053) $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
- (C0053) $ps5Cmd = Get-Command powershell -ErrorAction SilentlyContinue
- (C0053) El tamaño pequeño apparentemente se debe a la configuración de WPF, donde el uso de `SizeToContent=WidthAndHeight` ignora el borde. Para solucionarlo, debo establecer `SizeToContent=Manual` cuando FullOpt sea verdadero y ajustar el tamaño de la ventana al área de trabajo. Además, el mensaje podría no aparecer debido a un problema con la fuente Segoe UI Emoji.
- (C0053) Parece que el problema podría ser causado por cómo se generan los textos en HTML. Para solucionarlo, aseguro que el mensaje por defecto se muestre si no se pasa uno. Además, agrego un ajuste en el script para verificar y reemplazar mensajes vacíos por "Mensaje listo 😛". También corregiré el lanzador para incluir automáticamente los parámetros -Stay y -Full.
- (C0053) # Intentar PS7, luego PS5, sin ruido si uno falla
- (C0053) $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
- (C0053) $ps5 = Get-Command powershell -ErrorAction SilentlyContinue
- (C0081) El usuario intenta usar un heredoc para ejecutar un sitio en consola, pero se encuentra con errores porque heredoc no puede pasar datos interactivos a `read -p`. En lugar de usar `read -p`, podrían considerar usar argumentos o variables predefinidas para el script, para evitar los problemas con la entrada interactiva.
- (C0081) El problema aquí es que cuando usas `read` dentro de un heredoc, trata de leer de `stdin`, que ya está ocupado alimentando el heredoc. Una solución sería ejecutar el script en un subshell, usando `bash -s`, o bien usar una "aquí cadena" para proporcionar respuestas por adelantado.
- (C0081) El problema es que `read` en un heredoc llega al final de la entrada, lo que deja `opt` vacío y causa el error. Mi sugerencia es escribir el script en un archivo temporal, darle permisos de ejecución y luego ejecutarlo. Esto permitiría usar `read` interactivo, y también se podría solucionar el problema de permisos del directorio `/sdcard`.
- (C0081) Si están usando `adb shell`, deberían tener permisos para escribir en `/sdcard`, pero pueden necesitar activar `WRITE_EXTERNAL_STORAGE` para crear en subdirectorios como `/DCIM/Camera`. En Termux, pueden tener problemas debido a las restricciones de almacenamiento, pero pueden solucionarlo con `termux-setup-storage` para acceder a `$HOME/storage/shared`.
- (C0081) Al usar `adb shell`, deberías asegurarte de tener permisos de escritura para `/sdcard`. Si usas Termux, es necesario ejecutar `termux-setup-storage`. La solución a errores como `Permission denied` y `Opción inválida` implica escribir el script a un archivo temporal y ejecutarlo, asegurando que `read` lea desde TTY. Además, se crea un menú para elegir directorio de salida y captura la pantalla con un timestamp.
- (C0081) Tu heredoc fallaba por dos motivos:
- (C0081) Te dejo un **heredoc de una sola pasada** que crea un script interactivo y lo ejecuta. Detecta automáticamente la carpeta de salida (ADB vs Termux) y maneja errores.
- (C0081) echo "ERROR: crear '$OUTDIR'."
- (C0081) [ -x "$SCREENCAP" ] || { echo "ERROR: no encuentro $SCREENCAP"; exit 1; }
- (C0081) [ -x "$SCREENREC" ] || { echo "ERROR: no encuentro $SCREENREC"; exit 1; }
- (C0081) "$SCREENCAP" -p "$FILE" || { echo "Fallo en screencap"; exit 1; }
- (C0081) # Puedes ajustar bit rate o resolucion si lo necesitas
- (C0081) ¿Quieres que lo adapte para **guardar en otra carpeta** o con **parámetros de `screenrecord`** (bitrate, resolución, límite de tiempo)?
- (C0081) Fallo en screencap
- (C0081) En dispositivos Android más nuevos, *screencap* suele requerir permisos de shell, lo que impide su uso desde aplicaciones como Termux. Como solución, es mejor usar la API de *termux-screenshot*, que requiere instalar Termux:API. Puedes usar el comando `termux-screenshot -o [ruta]` para guardar la captura.
- (C0081) Parece que *termux-screenshot* con opciones como `[ -u ]` y `[ -d ]` podría ser la alternativa más confiable. Cuando se usa *screencap* en un app sin permisos root, falla por falta del permiso `READ_FRAME_BUFFER`. En Termux, la mejor opción es utilizar `termux-screenshot` o `termux-screenrecord`, con un chequeo previo para asegurarse de que sean accesibles.
- (C0081) Para asegurar nos aseguramos de usar el comando correcto de *termux-screenshot*, el script primero verifica con varias sintaxis posibles. Si no funciona, pasa a la opción *screencap*. Impleméntamos el uso de `termux-screenshot -o file` o simplemente `termux-screenshot` según la disponibilidad. Además, garantizamos que las entradas del usuario sean leídas correctamente y se gestionan mensajes de error si no se tienen permisos adecuados.
- (C0081) El fallo `Failed to take screenshot. Status: -1` ocurre porque **/system/bin/screencap** solo funciona con UID *shell* (p. ej., `adb shell`). En **Termux** necesitas usar **termux-screenshot/termux-screenrecord** (requieren Termux:API).
- (C0081) echo "ERROR: crear '$OUTDIR'."
- (C0081) [ -w "$OUTDIR" ] || { echo "ERROR: sin permiso de escritura en '$OUTDIR'"; exit 1; }
- (C0081) # intentar sintaxis directa; si falla, probar -o
- (C0081) echo "ERROR: termux-screenshot falló. ¿Instalaste Termux:API y diste permisos?"; return 1; }
- (C0081) /system/bin/screencap -p "$FILE" || { echo "ERROR: screencap falló (requiere UID shell)"; return 1; }
- (C0081) echo "ERROR: sin permisos para capturar."
- (C0081) echo "ERROR: sin permisos para grabar (usa Termux:API o adb shell)"; return 1
- (C0081) 3) Si sigue fallando, copia el mensaje que imprime el script (ya distingue falta de permisos vs. binarios).

## Métricas / criterios de calidad

- (N/A) No se detectaron métricas explícitas; se recomienda definir KPIs de cobertura, precisión y latencia.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- No hubo fusiones en este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| id_conv | título | fuentes | canónico | miembros |
|---|---|---|---|---|
| C0041 | <WsW_Script> | F0101;F0102 | C0041 | C0041 |
| C0044 | <SCRIPT - Invoke-RepoReorg> | F0107;F0108 | C0044 | C0044 |
| C0053 | Script PowerShell animado | F0047;F0048 | C0053 | C0053 |
| C0081 | Corregir heredoc consola | F0075;F0076 | C0081 | C0081 |