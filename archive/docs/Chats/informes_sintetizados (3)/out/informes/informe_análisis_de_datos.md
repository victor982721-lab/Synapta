# análisis de datos

## Resumen ejecutivo

- Conversaciones canónicas: 26.
- Tópicos frecuentes: archivos, archivo, thoughts, return, contenido, powershell, script, manifest, enlace, usuario.
- Justificación de agrupamiento: reglas deterministas por palabras clave.

## Alcance y supuestos

- Se consolidan conversaciones (MD/JSON) relativas al grupo mediante reglas de palabras clave.
- Se preservan bloques de código, prompts, tablas, comandos y pares I/O.

## Procedimiento paso a paso

- (C0003) 1. Filtrar cadenas útiles del CSV (chino legible).
- (C0003) 2. Traducir (respetando longitud si vas a parchear in-place).
- (C0003) 3. Parchear:
- (C0003) 4. Probar en VM y repetir.
- (C0014) 1. Frija (última release estable):
- (C0014) 2. .NET Core 3.1 Desktop Runtime x86 (requerido por Frija):
- (C0014) 1. Abrir un índice reputado de firmware Samsung (p.ej., SamFW o SamMobile).
- (C0014) 2. Buscar por modelo SM-A546E y CSC MXO.
- (C0014) 3. Si MXO no arroja resultados, probar TCE; si no, TMM; si no, IUS (en ese orden).
- (C0014) 4. Elegir SIEMPRE la ÚLTIMA compilación estable (Android 14/15 según disponibilidad) que sea paquete de 4 archivos.
- (C0014) 5. Extraer:
- (C0014) 1. En la página del firmware elegido, obtener el enlace DIRECTO de descarga (si la plataforma lo ofrece como URL de FUS/CDN).
- (C0014) 2. Validar con una petición HEAD/GET:
- (C0014) 3. Si el enlace directo no es visible:
- (C0014) 4. Si ninguna fuente da enlace directo:
- (C0014) 1. Instalar controladores Samsung y usar un cable USB estable; batería del teléfono ≥50 %.
- (C0014) 2. Iniciar Odin 3.13.x → cargar cada archivo en su campo (BL, AP, CP, CSC o HOME_CSC).
- (C0014) 3. Mantener activadas las opciones **Auto Reboot** y **F. Reset Time**; **Re‑Partition** debe estar desactivada.
- (C0014) 4. Tras flashear: si piensa volver a bloquear el bootloader, recuerde que el bloqueo borra los datos y requiere credenciales Samsung (FRP).
- (C0016) 1. **Permisos adecuados**
- (C0016) 2. **Acceso al API/servicio**
- (C0016) 3. **Filtrado correcto**
- (C0016) 4. **Formato de salida**
- (C0016) 5. **Automatización / integración**
- (C0016) 1. Crear un flujo en **Power Automate** (o Logic Apps) que use la acción “Get events (V4)” o similar.
- (C0016) 2. Configurar el rango de fechas: por ejemplo, desde hace 1 año hasta hoy.
- (C0016) 3. Elegir los campos necesarios (titulo, fecha/hora, duración, organizador).
- (C0016) 4. Exportar los resultados: escribir en Excel, una tabla, una base de datos, etc.
- (C0016) 5. (Opcional) Agregar filtros: reuniones cuyo nombre contenga ciertas palabras, solo reuniones “organizadas por mí”, etc.
- (C0016) 1. **Grabación**
- (C0016) 2. **Transcripción**
- (C0016) 3. **Chat de la reunión**
- (C0016) 4. **Archivos compartidos**
- (C0016) 1. Teams: Calendario → Unirse con ID → Ingrese ID y código → Detalles de la reunión, luego ir a Chat de la reunión para ver resúmenes, grabaciones y transcripciones.
- (C0016) 2. Outlook: Buscar el ID en el correo, ya que las invitaciones contienen el ID y la fecha/hora.
- (C0016) 1. En Teams: Calendario → Unirse con ID → ingresa el ID y código → accede a "Chat" o "Más detalles" para ver resumen/grabaciones/transcripciones.
- (C0016) 2. En Outlook: Busca el número en el calendario o usa el asunto "Microsoft Teams meeting".
- (C0016) 3. Si tienes permisos de administrador, usa Graph Explorer.
- (C0020) 1. Leer los bytes del archivo EXE.
- (C0020) 2. Analizar el encabezado DOS en 0x0: 'MZ', y luego obtener e_lfanew en 0x3C.
- (C0020) 3. Ir a esa posición y buscar 'PE\0\0'.
- (C0020) 4. Leer el encabezado COFF (IMAGE_FILE_HEADER), luego el encabezado opcional y extraer el directorio de recursos.
- (C0020) 5. Necesitamos la tabla de secciones para mapear los RVAs a los desplazamientos de archivo.
- (C0023) 1. **Filter Hardness**: 95 (More Results)
- (C0023) 2. **Word Weighting**: ✅
- (C0023) 3. **Match Similar Words**: ❌
- (C0023) 4. **Can Mix File Kind**: ✅
- (C0023) 5. **Use Regular Expressions When Filtering**: ❌
- (C0023) 6. **Remove Empty Folders on Delete or Move**: ✅
- (C0023) 7. **Ignore Files Smaller Than 100 KB**: ✅
- (C0023) 8. **Ignore Files Larger Than 1000 MB**: ❌
- (C0023) 9. **Partially Hash Files Bigger Than 100 MB**: ✅
- (C0023) 10. **Ignore Duplicates Hardlinking to the Same File**: ✅
- (C0023) 1. **Tamaño de Fondo**: Si el valor actual es **8** y sientes que debe ser más grande, puedes configurarlo en **10** para una visualización más clara.
- (C0023) 2. **Ventana de Detalles**:
- (C0023) 3. **Color de Párrafo Delta**: Esto podría estar relacionado con la visualización de las diferencias entre archivos o la selección de duplicados. Si no estás seguro de qué hace exactamente, **déjalo en su valor predeterminado** a menos que quieras cambiar el esquema de colores.
- (C0023) 1. **Modo de depuración** te da información interna sobre la aplicación (útil solo para depurar errores).
- (C0023) 2. **No necesitas reiniciar el sistema**, solo la aplicación.
- (C0023) 3. **No afecta los resultados** del escaneo, solo la experiencia interna de la aplicación.
- (C0023) 1. **Tipo de Escaneo**: Decide si prefieres un análisis rápido (por nombre) o uno más exhaustivo (por contenido o hash).
- (C0023) 2. **Dureza del Filtro**: El valor de **90-95** es ideal para precisión, pero si prefieres más resultados (más "suaves"), baja el valor a **85**.
- (C0023) 3. **Exclusiones y Opciones Avanzadas**: Desactiva filtros como "Match Similar Words" si prefieres coincidencias exactas. También, activa "Remove Empty Folders" si te interesa limpiar carpetas vacías.
- (C0023) 4. **Archivos Grandes**: Considera excluir archivos grandes si no deseas procesarlos.
- (C0023) 5. **Recreación de Rutas**: Actívalo si planeas mover o eliminar duplicados y quieres mantener la estructura de carpetas original.
- (C0023) ### Paso 1: **Eliminar Archivos Duplicados con dupeGuru**
- (C0023) ### Paso 2: **Revisión de Malware y Seguridad**
- (C0023) 1. **Ejecutar un Escaneo Completo de Malware**:
- (C0023) 2. **Verificar Configuraciones de Seguridad**:
- (C0023) ### Paso 3: **Limpieza de Archivos del Sistema**
- (C0023) 1. **Liberar espacio en disco**:
- (C0023) 2. **Eliminar Archivos Temporales**:
- (C0023) ### Paso 4: **Revisar Documentos y Archivos Importantes**
- (C0023) 1. **Revisión Manual de Carpetas de Documentos**:
- (C0023) 2. **Verificar Archivos en tu "C:\Users"**:
- (C0023) ### Paso 5: **Optimización del Rendimiento**
- (C0023) 1. **Desfragmentar el Disco Duro (HDD)**: Si usas un **HDD** en lugar de un **SSD**, realizar una desfragmentación puede ayudar a mejorar el rendimiento. Puedes hacerlo desde **Inicio > Desfragmentar y Optimizar Unidades**.
- (C0023) 2. **Revisar Programas de Inicio**:
- (C0023) 3. **Revisar el Uso de la Memoria y el CPU**:
- (C0023) ### Paso 6: **Considerar una Recuperación o Restablecimiento del Sistema (Si es Necesario)**
- (C0023) 1. **Escanear y eliminar malware**.
- (C0023) 2. **Liberar espacio en disco** usando el Liberador de espacio de Windows.
- (C0023) 3. **Eliminar archivos temporales** y revisar **Documentos** y **Descargas** manualmente.
- (C0023) 4. **Optimizar el rendimiento** deshabilitando programas innecesarios y desfragmentando discos (si es HDD).
- (C0023) 5. **Recuperación o restablecimiento** (solo si es necesario).
- (C0023) 1. **Eliminar duplicados** con **dupeGuru**.
- (C0023) 2. **Escanear malware** con **Windows Defender** o **Malwarebytes**.
- (C0023) 3. **Limpiar archivos temporales** con **Liberador de espacio** o **CCleaner**.
- (C0023) 4. **Optimizar el sistema**: deshabilitar inicio automático y desfragmentar disco (si es HDD).
- (C0023) 5. **Verificar archivos del sistema** con `sfc /scannow`.
- (C0023) 6. **Respaldar archivos** importantes.
- (C0023) 7. **Recuperar sistema** (si es necesario).
- (C0023) 1. **Seleccionar el Directorio o Carpeta a Escanear**:
- (C0023) 2. **Iniciar el Escaneo**:
- (C0023) 3. **Revisar la Configuración**:
- (C0023) 4. **Ajustes de Vista**:
- (C0023) 5. **Modo Oscuro**:
- (C0023) 1. Desinstala **dupeGuru** desde el **Panel de Control** > **Aplicaciones**.
- (C0023) 2. Descarga la versión más reciente desde el [sitio oficial de dupeGuru](https://dupeguru.voltaicideas.net/).
- (C0023) 3. Vuelve a instalarla y asegúrate de que la instalación se complete correctamente.
- (C0023) 1. Haz clic derecho sobre el ícono de **dupeGuru**.
- (C0023) 2. Selecciona **Ejecutar como administrador**.
- (C0023) 3. Intenta abrir la aplicación nuevamente para ver si eso resuelve el problema.
- (C0023) 1. Abre **dupeGuru**.
- (C0023) 2. En el menú, busca la opción de **"Añadir Carpeta"** o **"Select Folder"** y selecciona un directorio manualmente para escanear.
- (C0023) 3. Si no ves los botones claramente, prueba cambiar el tamaño de la ventana o buscar en los menús de la parte superior.
- (C0023) 1. **Mover la carpeta a "Archivos de Programa"**:
- (C0023) 1. **Desinstalar dupeGuru**:
- (C0023) 2. **Reinstalar en una Ruta Correcta**:
- (C0023) 1. **Mueve la carpeta** de **dupeGuru** a una ubicación más estándar, como **`C:\Program Files\dupeGuru`**.
- (C0023) 2. **Reinstala** **dupeGuru** y selecciona una ruta adecuada para evitar problemas de permisos.
- (C0023) 3. Asegúrate de **ejecutar como administrador** si es necesario.
- (C0023) 4. **Reinicia** la computadora si el problema persiste.
- (C0024) 1. Verificación inicial de hash para .dcy
- (C0024) 2. Comparación a nivel de bloques
- (C0024) 3. Verificación de hashes para .ysd
- (C0024) 4. Mapeo de equivalencias
- (C0024) 5. Análisis de las diferencias: 1118 bloques de 16 bytes
- (C0024) 6. Descripción de los pares: temp0==temp1; temp2==Ejemplo.ysd; 济南.ysd==济南西门子240821.ysd
- (C0024) 7. División en grupos A, B, C
- (C0024) 8. Opcional: generar el CSV con las diferencias
- (C0024) 1. Recepción de archivos: temp0.dcy, temp1.dcy, temp2.dcy, 济南.ysd, 济南西门子240821.ysd, Ejemplo.ysd.
- (C0024) 2. Hashing y tamaño: 29,423 bytes cada uno. Se calcularon MD5, SHA1, SHA256. Incluyo solo MD5 como huella (sha1/sha256 coinciden).
- (C0024) 3. Resultado: temp0.dcy == temp1.dcy (MD5 da5039a2...), temp2.dcy diferente (MD5 dfaf...).
- (C0024) 1. Detectamos 1118 diferencias en bloques de 16 bytes, distribuidas a lo largo del archivo. No mostraremos el contenido en hexadecimal, pero mencionamos los rangos y las diferencias.
- (C0024) 2. Hashes: 济南.ysd == 济南西门子240821.ysd (MD5 c33f4...), Ejemplo.ysd igual a temp2.dcy (MD5 dfaf3...); tamaños coinciden.
- (C0024) 3. Conclusión: los archivos .ysd y .dcy son el mismo contenedor/ formato, solo varía el contenido del conjunto de datos.
- (C0025) 1. **Reporte de usuarios**: Hay usuarios en foros como Reddit que dicen que Banorte dejó de funcionar en teléfonos rooteados, con mensajes tipo “la aplicación por seguridad no funciona con teléfonos modificados”. citeturn0search1
- (C0025) 2. **Términos de seguridad de Banorte**: No encontré un texto oficial reciente que diga explícitamente “si tu dispositivo tiene root, la app no funcionará”, pero sí hay menciones de dispositivos de seguridad, token, autenticaciones, condicionamientos. citeturn0search5turn0search2turn0search3
- (C0025) 3. **Instructivo de “modo desarrollador”**: Banorte tiene un documento/instructivo que menciona que si tu teléfono tiene “rooteo” activo, deberías deshabilitarlo para que la app funcione correctamente. Por ejemplo:
- (C0025) 4. **Reactivación / app bloqueada**: Si la app fue bloqueada por algún motivo de seguridad, Banorte da opciones para reinstalar, capturar usuario y contraseña, seguir pasos de activación, etc. citeturn0search4
- (C0025) 1. **Haz backup** de todo lo que te importe, porque al relockear casi siempre se borra todo (factory reset).
- (C0025) 2. **Asegúrate de estar con la ROM oficial del fabricante** (stock firmware), sin modificaciones, sin root, sin recovery personalizado. Ya hiciste flash con Odin, así que si lo dejaste con la ROM stock, va bien.
- (C0025) 3. **Activa “OEM Lock” si existe**
- (C0025) 4. **Entrar al modo bootloader / fastboot o modo descarga (Download Mode / Odin mode)**
- (C0025) 5. **Usar comando apropiado para relock**
- (C0025) 6. **Verifica que el bootloader está bloqueado**
- (C0025) 1. **Confirma que estás en firmware stock oficial**
- (C0025) 2. **Activa opciones de desarrollador**
- (C0025) 3. **Verifica “Desbloqueo OEM”**
- (C0025) 4. **Reinicia en modo Download (Odin Mode)**
- (C0025) 5. **Factory reset automático**
- (C0025) 1. Ve a Opciones de desarrollador.
- (C0025) 2. Desactiva *OEM Unlock*.
- (C0025) 3. Reinicia → el teléfono se resetea y queda bloqueado.
- (C0025) 1. **Primera vez** → solo desbloqueaste el bootloader (activaste *OEM Unlock* y lo liberaste).
- (C0025) 2. **Después** → flasheaste con Odin el firmware stock completo (los ~9 GB).
- (C0025) 1. **Flashear firmware stock completo con Odin** (los 4 archivos: BL, AP, CP, CSC).
- (C0025) 2. Reiniciar → ahora en *Opciones de desarrollador* la opción de *OEM Unlock* ya debería salir como apagada (o desaparecer).
- (C0025) 3. Con eso, el bootloader vuelve a quedar marcado como “locked”.
- (C0025) 1. **Primero** desbloqueaste el bootloader → ahí el toggle de *OEM Unlock* estaba activo y movible.
- (C0025) 2. **Después** flasheaste el firmware stock con Odin → ahora el toggle aparece en gris con la nota “ya está desbloqueado”.
- (C0025) 1. Instala **Termux** desde [F-Droid](https://f-droid.org/en/packages/com.termux/) (recomendado).
- (C0025) 2. Abre Termux y corre:
- (C0025) 3. Copia/pega el bloque arriba.
- (C0025) 4. Dale permisos:
- (C0025) 1. Usa CSC (no HOME_CSC) para asegurar un borrado.
- (C0025) 2. Después de la flash y la configuración inicial, conecta el dispositivo a internet por 5-10 minutos para permitir que VaultKeeper actualice.
- (C0025) 3. Accede a Opciones de Desarrollador: el toggle de "OEM unlocking" debería aparecer; si sigue gris, entra en "Modo de descarga" y selecciona "LOCK BOOTLOADER".
- (C0025) Repite el flash **completo** con Odin cargando **BL/AP/CP/CSC (no HOME_CSC)** para forzar wipe y, tras el primer arranque con Internet, regresa a **Download Mode** y realiza el **Lock** como en el paso 3. citeturn0search14
- (C0046) 1. **Regex en `Test-FenceSafety` no es multilinea y tiene escape frágil**
- (C0046) 2. **CRLF “portátil”**
- (C0046) 3. **`Out-File -Encoding utf8` en ejemplos**
- (C0046) 4. **Detección de cierre here-string con indentación**
- (C0046) 5. **Regla de 4 backticks en repos con ejemplos**
- (C0046) 6. **Here-string con línea `@` literal en columna 1**
- (C0061) 1. Captura del bloque de entrada y normalización UTF-8.
- (C0061) 2. Cálculo de metadatos (longitud, líneas, SHA-256).
- (C0061) 3. Generación de entregables mínimos viables: TXT, MD, HTML, JSON, CSV (inventario), artefacto gráfico (PNG), scripts de verificación, manifest y empaquetado ZIP.
- (C0061) 4. No se usaron fuentes externas; todo proviene del bloque del usuario.
- (C0065) 1. **Módulo 2A – INIT-ENV** (sin `param()` adentro; se toma de la cabecera unificada)
- (C0065) 2. **Módulo 2B – INIT-LOG**
- (C0065) 3. **Módulo 2D – INIT-PATHS**
- (C0065) 4. **Módulo 2C – INIT-CHECKS** (opcional; utilidades, no muta estado global salvo logs)
- (C0065) 5. **Módulo 2E – INIT-CONFIG**
- (C0072) 1. **Run `SOP_AVCM.md`** (Configuration and Memory Update & Verification) and return its **AVCM summary** in that same turn.
- (C0072) 2. **Use `web.run`** for any information with a probability ≥ 10% of being outdated (APIs, prices, news, policies, laws, software versions, etc.), **citing sources** and **explicitly labeling** them as **[Official]** or **[Community/Press]**.
- (C0072) 3. **One turn, value**: do not promise future work or “background” work. If something is missing, request it explicitly and deliver what can be done **now**.
- (C0072) 1. **Actionable**: executable in console, no extra steps.
- (C0072) 2. **Definitive**: a single artifact per turn.
- (C0072) 3. **Hardened (CBs and fences)**:
- (C0072) 4. **Automated**: integrated handling of parameters, paths, dependencies, and directory creation.
- (C0072) 5. **Validated**: PSSA (JSON and SARIF) and Pester (NUnit) in `VERIFICATION\`.
- (C0072) 6. **Safe**: `.bak` backup beforehand in the same folder (and a mirror in `SCRIPTS\BACKUPS\`).
- (C0072) 7. **Modularized**: sections with `[BEGIN MODULE: X]` / `[END MODULE: X]` for segmented updates.
- (C0072) 8. **Compatible**: Windows 10/11; PowerShell 5/7.
- (C0072) 9. **Traceable**: immutable log in `CHANGELOG.md` with version, date, and description.
- (C0072) 1. Identify the **module(s)** to change or the full document.
- (C0072) 2. Prepare a here-string patch with markers `[BEGIN MODULE: X]` / `[END MODULE: X]`.
- (C0072) 3. Make a `.bak` backup and a mirror in `SCRIPTS\BACKUPS\`.
- (C0072) 4. Apply the patch (targeted replacement).
- (C0072) 5. Run verification (PSSA/Pester/Manifests).
- (C0072) 6. Update `CHANGELOG.md` (version, date, description).
- (C0074) 1. Genera en orden: `ps1`, `txt`, `md`, `html`, `json`, `csv`, `png` (si hay matplotlib), `*_explanation.md`.
- (C0074) 2. Crea `verify.sh` y `verify.ps1`.
- (C0074) 3. Genera `inventory.json` + `hashes.txt`.
- (C0074) 4. Construye `REPORT.md` con métricas simples.
- (C0074) 5. Genera `manifest.json` **(sin incluir el release ZIP, porque aún no existe en este punto)**.
- (C0074) 6. Crea archivos para “canvas” (`*_canvas.md`, `*_links_block.md`).
- (C0074) 7. Empaqueta **work bundle** (`*_bundle.zip`).
- (C0074) 8. Crea **release ZIP** en `_releases/<UTC>.zip`.
- (C0074) 9. Devuelve un diccionario con resultados y bloque de **links** sandbox.
- (C0076) 1. **Gates canónicos**
- (C0076) 2. **Nombres**
- (C0076) 3. **Consistencia CV**
- (C0076) 4. **Críticos**
- (C0076) 5. **Reproducibilidad en gates**
- (C0076) 6. **TTI**
- (C0076) 7. **Audit capabilities**
- (C0076) 1. **Cerrar las brechas de umbrales** (gates y métricas) con los cambios propuestos.
- (C0076) 2. **Definir `set_base_csv` y `metodo_de_scoring`** (esquema, tamaño, fuente de verdad).
- (C0076) 3. **Instrumentar secret scan** (herramienta/regex + reporte en `/05_riesgos/seguridad.md`).
- (C0076) 4. **Completar `audit_capabilities_table` con fuentes** y etiquetas **[Oficial]/[Comunidad]** antes de usarla.
- (C0076) 5. **Probar reproducibilidad** con 3–5 corridas deterministas y registrar `cv`, `repro_pct`, `TTI`.
- (C0082) 1. **Instalar dependencias**
- (C0082) 2. **Conectar vía USB** y correr el script:
- (C0082) 3. Para usar **por WiFi** (sin cable):
- (C0082) 1. **En la PC** instala:
- (C0082) 2. **Prueba conexión USB**:
- (C0082) 3. **Si quieres WiFi directo**:
- (C0082) 1. Verifica/instala **ADB (platform-tools)** y **scrcpy** automáticamente.
- (C0082) 2. Configura el **PATH** temporal.
- (C0082) 3. Detecta el dispositivo Android y lanza la transmisión.
- (C0082) 1. Guarda el archivo como `mirror_phone.ps1`.
- (C0082) 2. Ábrelo con **clic derecho → Ejecutar con PowerShell**.
- (C0082) 3. Conecta el celular por USB y **acepta la autorización ADB en la pantalla**.
- (C0082) 4. Se abrirá la ventana de scrcpy con la pantalla del teléfono.
- (C0082) 1. Open PowerShell 7 as your user. If first run:
- (C0082) 2. Run:
- (C0082) 1. **scrcpy está instalado pero sin `adb` detectando dispositivo**.
- (C0082) 2. **scrcpy se ejecuta pero se cierra instantáneo**.
- (C0082) 1. Con el teléfono conectado por USB y depuración activa, corre:
- (C0082) 2. Si aparece, vuelve a lanzar:
- (C0082) 1. **Quitar `--verbose`** de las pruebas manuales. Ejemplo correcto:
- (C0082) 2. En tu `mirror_phone.ps1` ya no necesitas tocar nada, porque el script nunca usaba `--verbose` (solo lo probaste manual).
- (C0082) 3. Si con ese comando abre ventana y ves el móvil → ya quedó resuelto.
- (C0082) 1. **Solo desactivar FLAG_SECURE en scrcpy**
- (C0082) 2. **Usar “Skip secure content” en scrcpy modificado**
- (C0082) 3. **Comprobar permisos de superposición**
- (C0082) 1. Primero prueba si tu build de scrcpy soporta:
- (C0082) 2. Si no, el bloqueo viene del sistema Knox / FLAG_SECURE y **no se puede saltar sin root o un build modificado**.
- (C0082) 1. **Lo que ya tienes funciona**: el espejo abre, pero se ve negro en apps que usan `FLAG_SECURE`.
- (C0082) 2. **Alternativas reales**:
- (C0082) 3. **Confirmar que no es bug de video**:
- (C0082) 1. **Capturas y grabaciones con ADB**
- (C0082) 2. **Exportar datos directamente**
- (C0082) 3. **Apps oficiales**
- (C0082) 1. **Con root o ROM modificada**:
- (C0082) 2. **Captura externa** (hardware):
- (C0082) 3. **Apps de terceros con exploits** (riesgoso):
- (C0082) 1. Crea la carpeta en tu Desktop:
- (C0082) 2. Luego haz el pull:
- (C0082) 1. `screenrecord` de Android a veces genera archivos corruptos si se interrumpe con **Ctrl+C** antes de cerrar correctamente.
- (C0082) 2. Los `.mp4` de `screenrecord` pueden estar codificados en H.264 con un contenedor incompleto (sin “moov atom”), lo que hace que Windows no lo reconozca.
- (C0082) 1. **Usa ffmpeg para “arreglar” el contenedor**:
- (C0082) 2. **Si sigue sin abrir**, prueba convertirlo a un `.mkv`:
- (C0082) 3. **Graba de nuevo con límite de tiempo** (para evitar cortar mal):
- (C0082) 1. Instala dependencias necesarias (**ADB** y **FFmpeg**) si no están.
- (C0082) 2. Graba la pantalla del móvil con `adb shell screenrecord`.
- (C0082) 3. Copia el archivo grabado a tu **Desktop**.
- (C0082) 4. Lo repara automáticamente con **FFmpeg** para que siempre se pueda reproducir.
- (C0082) 1. Guarda el script en tu Desktop como `record_phone.ps1`.
- (C0082) 2. Si es la primera vez, habilita ejecución:
- (C0082) 3. Conecta el móvil por USB (depuración activada).
- (C0082) 4. Ejecuta:
- (C0082) 1. **Grabar con límite de tiempo fijo** (para que Android cierre bien el archivo):
- (C0082) 2. **Verificar tamaño del archivo**:
- (C0082) 3. **No usar Ctrl+C** para cortar la grabación, deja que termine sola con `--time-limit`.
- (C0082) 1. Guarda como `map_videos.ps1`.
- (C0082) 2. Abre PowerShell 7 y ejecuta:
- (C0082) 3. En tu **Desktop** aparecerá `videos_phone.csv` con todas las rutas, tamaños y fechas.
- (C0084) 1. Abre Termux.
- (C0084) 2. Pega el bloque tal cual.
- (C0084) 3. Elige `1` → revisa `/sdcard/` y debería haber `captura_YYYYMMDD_HHMMSS.png`.
- (C0084) 4. Elige `2` → se crea un `.mp4` hasta que detengas con **Ctrl+C**.

## Mejores prompts / plantillas

- (C0016) Prompt:

```text
# Requiere módulo Microsoft.Graph y permisos Calendars.Read
Connect-MgGraph -Scopes "Calendars.Read"
$from = (Get-Date).AddYears(-1).ToString("o")
$to   = (Get-Date).ToString("o")

# Trae eventos del último año y filtra por el ID en asunto/cuerpo
$events = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me/calendarview?startDateTime=$from&endDateTime=$to&$top=1000"
$hits = $events.value | Where-Object {
  $_.subject -match '254 296 380 195' -or $_.bodyPreview -match '254 296 380 195'
}
$hits | Select-Object subject, @{n='start';e={$_.start.dateTime}}, @{n='end';e={$_.end.dateTime}}, organizer, webLink
```
- (C0020) Prompt:

```text
# Verifica si los archivos del .ini existen junto a cada EXE y en System32
$exes = @(
  'C:\TBEA\01_Software\YSD300AN\YSD300AN.exe',
  'C:\TBEA\01_Software\YSD300AN-P2406\YSD300AN-P2406.exe'
) | Where-Object { Test-Path $_ }

$rows = foreach ($e in $exes) {
  $root = Split-Path -Path $e -Parent
  foreach ($rel in 'dcc.ini','dccsys.ini','data','user') {
    $p = Join-Path $root $rel
    [pscustomobject]@{Exe=(Split-Path $e -Leaf); Item=$rel; Path=$p; Exists=(Test-Path $p)}
  }
}
$rows += [pscustomobject]@{
  Exe='System32'; Item='dcy.ufo'; Path=(Join-Path $env:WINDIR 'System32\dcy.ufo'); Exists=(Test-Path (Join-Path $env:WINDIR 'System32\dcy.ufo'))
}
$rows | Format-Table -Auto
```
- (C0046) Prompt:

```text
$body = @'
# Título
Contenido con `$ variables, ```backticks``` y { llaves } sin expandir.
'@

$footer = @"
© 2025 — Proyecto Anastasis Revenari · Versión: $version · Fecha: $fecha
"@

($body + "`r`n`r`n" + $footer) | Out-File $dest -Encoding utf8
```
- (C0046) Prompt:

```text
'{ "key": "{{value}}" }' -f @()
```
- (C0046) Prompt:

```text
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if ($NoNewLine) {
            [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
        } else {
            [System.IO.File]::WriteAllText($Path, $Content + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        }
        return
    }

    # PS5.1: forzar UTF-8 sin BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8NoBom.GetBytes($(if ($NoNewLine) { $Content } else { $Content + [Environment]::NewLine }))
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}
```
- (C0046) Prompt:

```text
function Write-BacktickSafeFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$BodyLiteral,  # contenido @' ... '@
        [Parameter()]           [string]$FooterExpandable = ''
    )
    Set-StrictMode -Version 3.0

    $sep = "`r`n`r`n"
    $final = if ($FooterExpandable) { $BodyLiteral + $sep + $FooterExpandable } else { $BodyLiteral }

    if ($PSCmdlet.ShouldProcess($Path, "Escribir contenido UTF-8 sin BOM")) {
        Write-Utf8NoBom -Path $Path -Content $final
    }
}
```
- (C0046) Prompt:

```text
function Test-FenceSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path
    )
    begin { Set-StrictMode -Version 3.0 }
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }
            $text = Get-Content -Path $p -Raw

            $issues = @()

            if ($text -match '````') {  # 4 backticks
                $issues += 'Uso prohibido de 4 backticks (````)'
            }
            if ($text -match "^\s+['""]@") { # cierre here-string con indentación
                $issues += "Cierre de here-string con indentación (debe ir en columna 1)"
            }
            if ($text -match '-f\s+.*\{.*\}') {
                $issues += "Uso de -f con llaves {}; duplica llaves o evita -f"
            }

            [PSCustomObject]@{
                Path   = $p
                Issues = if ($issues) { $issues -join '; ' } else { '<OK>' }
            }
        }
    }
}
```
- (C0046) Prompt:

```text
function Test-FenceSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path
    )
    begin { Set-StrictMode -Version 3.0 }
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }
            $text = Get-Content -Path $p -Raw

            $issues = @()

            if ($text -match '````') {  # 4 backticks
                $issues += 'Uso prohibido de 4 backticks (````)'
            }

            # Cierre de here-string con indentación (debe ir en col 1, sin espacios/tabs)
            if ($text -match '(?m)^\s+([\'"])@\s*$') {
                $issues += "Cierre de here-string con indentación o trailing spaces (debe ir en columna 1, sin espacios)"
            }

            # Uso de -f con llaves {}; nota: es heurística
            if ($text -match '-f\s+.*\{.*\}') {
                $issues += "Uso de -f con llaves {}; duplica llaves o evita -f"
            }

            [PSCustomObject]@{
                Path   = $p
                Issues = if ($issues) { $issues -join '; ' } else { '<OK>' }
            }
        }
    }
}
```
- (C0046) Prompt:

```text
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0

    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    # Normaliza a CRLF siempre (norma del proyecto para archivos Windows)
    $crlf = "`r`n"
    $text = if ($NoNewLine) { $Content } else { $Content + $crlf }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}
```
- (C0046) Prompt:

```text
function Write-BacktickSafeFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$BodyLiteral,    # contenido @' ... '@
        [Parameter()]           [string]$FooterExpandable = ''
    )
    Set-StrictMode -Version 3.0

    $sep = "`r`n`r`n"
    $final = if ($FooterExpandable) { $BodyLiteral + $sep + $FooterExpandable } else { $BodyLiteral }

    if ($PSCmdlet.ShouldProcess($Path, "Escribir contenido UTF-8 sin BOM (CRLF)")) {
        Write-Utf8NoBom -Path $Path -Content $final
    }
}
```
- (C0047) Prompt:

```text
{"step":1,"module":"inventory","status":"created","path":"/mnt/data/inventory.json","bytes":742,"sha256":"<...>","created_utc":"2025-09-29T11:36:00Z"}
{"step":2,"module":"ps1","status":"skipped_not_applicable"}
{"step":3,"module":"txt","status":"created","path":"/mnt/data/entrega.txt","bytes":5843,"sha256":"<...>"}
```
- (C0047) Prompt:

```text
#!/usr/bin/env bash
set -euo pipefail
dir="${1:-/mnt/data}"
manifest="$dir/manifest.json"
jq -r '.artifacts[] | [.path, .sha256] | @tsv' "$manifest" | while IFS=$'\t' read -r p h; do
  calc=$(sha256sum "$p" | awk '{print $1}')
  [[ "$calc" == "$h" ]] || { echo "Mismatch: $p"; exit 1; }
done
echo "OK"
```
- (C0047) Prompt:

```text
param([string]$Dir="/mnt/data")
$Manifest = Join-Path $Dir "manifest.json"
$Artifacts = (Get-Content $Manifest -Raw | ConvertFrom-Json).artifacts
$ErrorActionPreference='Stop'
foreach($a in $Artifacts){
  $calc = (Get-FileHash -Algorithm SHA256 -Path $a.path).Hash.ToLower()
  if($calc -ne $a.sha256.ToLower()){ throw "Mismatch: $($a.path)" }
}
"OK"
```
- (C0054) [**prompt_C0054_f758c464.md**] — sha256: f758c464a860fb75cf2cef88a475da33d98e416278fe621bf8c207bc0c0d75ac — resumen: Prompt extenso archivado.
- (C0065) [**prompt_C0065_1b1a7667.md**] — sha256: 1b1a7667c7501744566ea27c03e5ac4b95372b3eb8af293ad1457c5bdaf78995 — resumen: Prompt extenso archivado.
- (C0065) Prompt:

```text
$Global:_HasSimulatedPaths = ($Global:_SimulatedPaths.Count -gt 0)
if ($Global:_HasSimulatedPaths) {
  Write-Log -Level DryRun -Message ("Se simularon {0} rutas." -f $Global:_SimulatedPaths.Count)
}
```

## Ejemplos completos

- [ejemplo_C0002_137.md] — sha256: cd65036278a9a45b551830eebf69e56ddbb2ee0f6a6a5ec8648c08d38b6fc13f — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0010_29.md] — sha256: 7e5352f7d4b5e382c1540c561f5f8afee9239f5042102cde663d785c68556c50 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0010_79.md] — sha256: 980f70da033a5794655feb238adc9210759fa72619fb6a2f088e114394cbcca9 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0010_134.md] — sha256: dcb5c3784d4a9db2fb6325fbaa55da7d2ca061eb7717eb03cc6d3ca7b245dfea — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0010_136.md] — sha256: c997e4e874a37ae98f00c378b62a0e3746c095cf3e2781366398b67239a06719 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0010_269.md] — sha256: d481170bed45194c0724cbdd0ab54b762913ed2d45a6b4d82d553a0c787fad94 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0047_8.md] — sha256: 9878659c35b62cf9bbd132fe8a49deb46b13cb9b45f9b2218f6a24f5d5d9d11c — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0054_8.md] — sha256: f6a910f9bbb5ddc9070f056ca7d0a9560fcb7770ef18aed8f4906e2b4999a276 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0065_608.md] — sha256: 263a6e77dd50839f724d0792d439eb04306776e9afb4a977a198ade0be89b7eb — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0068_8.md] — sha256: 78620c1f1c90b4d151593c5fc6096997da796524b93fd30733542f74bd3c2e94 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0069_10.md] — sha256: 571df3fdf0152a180f0a4bac12a5459b05cbb3914e6e75ea981b97bfeb3ef6d7 — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0069_14.md] — sha256: e11a584f9059c11709418b523aba1013080f165e37f58e3c40e65bc2c39feb1f — Bloque de código largo archivado como ejemplo.
- [ejemplo_C0076_8.md] — sha256: 02353404651bfece2001a922147494e45ee1a5086da9643010d742ba9fab001b — Bloque de código largo archivado como ejemplo.

## Snippets de código / comandos

- [snippet_C0002_109.md] — sha256: 781a4afb5b23e97ba0adf20a7051b7b35657ed1acc53efe5cb1f33a7af7d2d59 — Snippet de código breve.
- [snippet_C0010_8.md] — sha256: dfa6d842a0805c3ddb6ec97d457311b18d20e044bc0c54ee93ec7b05a15039b4 — Snippet de código breve.
- [snippet_C0010_9.md] — sha256: f15889effac3d3d581c691c65268fd6a234e612451ccd1dab00e947c420c4896 — Snippet de código breve.
- [snippet_C0010_10.md] — sha256: ced315ec32933a1080b6d542fb3d0aab3cb3be1ea1dcf2a6a04067d09e6e004c — Snippet de código breve.
- [snippet_C0010_11.md] — sha256: 8da2d2223554dbedbdfc5b5d833e18d0618b8d095c13bfbdf3f68a7b53309db0 — Snippet de código breve.
- [snippet_C0010_271.md] — sha256: be9fee0a93cb20cc7926ef24c91157ad51e233655e52e4a8846d1cc51796148c — Snippet de código breve.
- [snippet_C0010_273.md] — sha256: be9fee0a93cb20cc7926ef24c91157ad51e233655e52e4a8846d1cc51796148c — Snippet de código breve.
- [snippet_C0014_806.md] — sha256: bf0df5904a97cb82862d943051d63d32c9d34fac32d5bd72d4fee218e22e2b61 — Snippet de código breve.
- [snippet_C0016_261.md] — sha256: 2153e67449fdf88ecffc24810d0874237832b17ec65a8360e166d39f2b8ea629 — Snippet de código breve.
- [snippet_C0020_320.md] — sha256: 4e966c2efbfd2d4375dd2e679029f1dec54cc86ee3c94ac2ef173078fe593db6 — Snippet de código breve.
- [snippet_C0023_110.md] — sha256: 2073e83af27af9cbaefd84b5699d11cc32eb70928ee9ebbabb070645a9ecc06e — Snippet de código breve.
- [snippet_C0023_114.md] — sha256: 75d5ba4c6f670ac8479ec1f9a0e444e1e11d154679625c9cd8cca6e17de72da6 — Snippet de código breve.
- [snippet_C0023_118.md] — sha256: 6f2f0073293bd3f14fcd74a0d713ce716ad81627300223686913285ead899425 — Snippet de código breve.
- [snippet_C0025_293.md] — sha256: ac3b86605d7a9df3802cad10e7a5a3851473a58bd9187d847b5fbce1913ec641 — Snippet de código breve.
- [snippet_C0025_354.md] — sha256: de2755d534247776275956099f07c9836b78d6df02092d012daa381585fbb658 — Snippet de código breve.
- [snippet_C0046_33.md] — sha256: 27196cffd04276b878ec78359d3ea41b95d3f04d5a69ff4f03e29ac44988bdf4 — Snippet de código breve.
- [snippet_C0046_52.md] — sha256: 2c6a2d18bd23ddb3a4544d44ae6ddc6687a5faa92d4dd64f3e112afbf490e0e0 — Snippet de código breve.
- [snippet_C0046_57.md] — sha256: 2cf4f52201c66d85afbd2711cf4559f2ca201a2158c1c6ddccb7d04e02653f2f — Snippet de código breve.
- [snippet_C0046_61.md] — sha256: ea0e0473e80c3989661706e238c832f6ac716078aa3cb73e5836713d8ae586ea — Snippet de código breve.
- [snippet_C0046_66.md] — sha256: d53cb8fd515b4494f88465548de27a78953f383ce6d09a5a6e5c61331d233813 — Snippet de código breve.
- [snippet_C0046_71.md] — sha256: 0f1c7730fdf41f4737e8d6ff4a50ae5a61992b2de41ec2158daa4ee225fddca3 — Snippet de código breve.
- [snippet_C0046_121.md] — sha256: a77ce04742e57301ccf99610819df662116045f05912aadf42919e2894b95499 — Snippet de código breve.
- [snippet_C0046_125.md] — sha256: 9b3e37bc8c32e541f6f9a7388529dbcc9c557a235ce6b5a1ac84af4afb32c8ba — Snippet de código breve.
- [snippet_C0046_129.md] — sha256: 2e927a5ee0921f8083b6bfebddfd149c40257d63a89ed2c3874da01df956a693 — Snippet de código breve.
- [snippet_C0046_135.md] — sha256: 87f68d8e650f28399cd9a561b2e1432371dca0e53817d44a86675ebc3757ad19 — Snippet de código breve.
- [snippet_C0046_177.md] — sha256: 7b74ffb06bedd643846d53363c59721a2a4a129bf7af9f07fe983d4bd41622e4 — Snippet de código breve.
- [snippet_C0046_180.md] — sha256: bf0e0e304d28ccb0f368f713ad81e6a14ea77b03e1ae0a103a207898ca216e72 — Snippet de código breve.
- [snippet_C0046_183.md] — sha256: 05622829ef0d93d92a4ef2fd76fa473b2263f8cff8fd6fa3bd50410202f6d863 — Snippet de código breve.
- [snippet_C0047_111.md] — sha256: afdf31de7622461ab309b86d15375358c0dfc5cc748a5aa5f40682c08c9068a3 — Snippet de código breve.
- [snippet_C0047_114.md] — sha256: 0cf096f429181801fc3e9fd243048abecc68b1d768b30242697ed6928a0f501c — Snippet de código breve.
- [snippet_C0047_117.md] — sha256: 72eed350a21027f8d5a6686674cddbd2730eb4048b1a452a69d8a0f596575a30 — Snippet de código breve.
- [snippet_C0047_120.md] — sha256: 3f19fe8de32cb1cc4e5758b3bc76256decbdca4e8f513aa7688eab00635af352 — Snippet de código breve.
- [snippet_C0058_234.md] — sha256: 66306741fe0a60d750c13013124315f28366ab4b7456c9fff0649dab79aae52d — Snippet de código breve.
- [snippet_C0065_600.md] — sha256: 8104fb1f5c4968d343e264059965027ae641d13750e00c98c6caa43d2b564380 — Snippet de código breve.
- [snippet_C0065_618.md] — sha256: c5bb0bfb88e2378cd953d81114c893cfaa907e6b7c3ff7d6973a13e2473f1d44 — Snippet de código breve.
- [snippet_C0065_624.md] — sha256: 0cd07d8893458a64c15a8867373040acc963574444c878d08376a25a915fc90e — Snippet de código breve.
- [snippet_C0065_648.md] — sha256: 74195b74c7fde96dd86911faa1f541ddee045048b08823c62d8ec7e313da5eb2 — Snippet de código breve.
- [snippet_C0065_652.md] — sha256: 410318454a8166a2eac3bb7262ac01edfe0ec177666f63c1688f3000fc47737d — Snippet de código breve.
- [snippet_C0065_659.md] — sha256: 04e240dbd4f76c475f6cf2a1d419c68844ac68489edcecaf885924f77473622a — Snippet de código breve.
- [snippet_C0065_662.md] — sha256: 7a00152e621a5402f37374604dc2fe37c4b80aa6e15499b300b2a9ad3c9c16a8 — Snippet de código breve.
- [snippet_C0072_69.md] — sha256: e71c4388ba342782d853a46d14fd0639b52554fbd1c7e44eb839bcd23d8f7e6d — Snippet de código breve.
- [snippet_C0072_85.md] — sha256: 5888ec7108c09d63016e402a8a5302cc650a386cc2ecc0a738a3a3d6bd5aa762 — Snippet de código breve.
- [snippet_C0072_111.md] — sha256: 3b76d9e2d6f5cb58ecbcea6cd90b198fefa0b5359887e6b15febbaecd33f8ecc — Snippet de código breve.
- [snippet_C0076_76.md] — sha256: 8bc13effecfb7a5fb265c28dbe3d7a5becbc0b4088b7b935f2c1e47b8e7d02ee — Snippet de código breve.
- [snippet_C0082_733.md] — sha256: 0aabab09bdc9daf009127d6c0f91c8376d2c5f5b31845f6e0343055a5dc8adf1 — Snippet de código breve.
- [snippet_C0082_745.md] — sha256: 4ea46133e6a6dd91c12528f3c04a67dfc0c703790c39a4dd3bc6e97572a36acb — Snippet de código breve.
- [snippet_C0082_749.md] — sha256: 5b01d4d82e9e2944caae6e208cc7e2a3cb6b5b9a0ad98c89d949e84ebd417d72 — Snippet de código breve.
- [snippet_C0082_805.md] — sha256: f87e4c5f4b6fa3fb928f67821fa0f03efef8ab26262fbca188f4231cf1408dc9 — Snippet de código breve.
- [snippet_C0082_859.md] — sha256: 286f465efef656ec9fd94461051c77603cf20c82ed3ee3ca3520a946ed1f6a52 — Snippet de código breve.
- [snippet_C0082_865.md] — sha256: f87e4c5f4b6fa3fb928f67821fa0f03efef8ab26262fbca188f4231cf1408dc9 — Snippet de código breve.
- [snippet_C0082_889.md] — sha256: e3a662f879b864cf86b1ed10ea6e24810a4ab153e9223aa2bf1249452d9ddc72 — Snippet de código breve.
- [snippet_C0082_963.md] — sha256: 9513e65dd2ef5879e4ef78e576b4cdb4f191686d2cdc8d04e6d5948f5b1b7932 — Snippet de código breve.
- [snippet_C0082_1099.md] — sha256: 5860a457b9f41e20402afaf0e97db4e25c71015144cf7a477b8bb8f2275a75af — Snippet de código breve.
- [snippet_C0082_1102.md] — sha256: 3642fe8dfd9ccaa948b9b367f7b7e59e856fe56aa7341d264dac3830d7bf1bba — Snippet de código breve.
- [snippet_C0082_1110.md] — sha256: 21c21453f067fe228bf27722af349c86f71fe9c4c00110789362ecfff903360b — Snippet de código breve.
- [snippet_C0082_1112.md] — sha256: 2004f439ce99353d7e7fe1ebcb717a388825993b89075c0f11daf9f1b66c3c8e — Snippet de código breve.
- [snippet_C0084_35.md] — sha256: 67e552b23423c2b34b8345c81f2abe3fb10127e55697f5ada3d1a8fa7bf03da0 — Snippet de código breve.
- [snippet_C0084_41.md] — sha256: 32278e137048954350a57c33989d59f89d4d933541ab2735b46c0e26b0a68b11 — Snippet de código breve.
- [snippet_C0084_83.md] — sha256: 2ecb738c7846a6d548f914c21782c33be7e80414bb21a94aeecde7a1c8eabc64 — Snippet de código breve.
- [snippet_C0084_88.md] — sha256: 45efeaa73e4c910a6ef15e99b112860c58471dcb0524668678b1e4e96feb1c90 — Snippet de código breve.
- [snippet_C0084_92.md] — sha256: 11c21a81441df8e3ee202b01fe59a07309dba8a173fd2231887e00d2c2b6a561 — Snippet de código breve.
- [snippet_C0084_101.md] — sha256: 612e2f637acbf6b8b54a72d9ff8f1c849052a173652b641e68ab4179080f869e — Snippet de código breve.

## Checklists (previo, durante, posterior)

- (C0058) - [ ] `inventory.csv` y `hashes.csv` con `sha256`, `md5`, `size_bytes`.
- (C0058) - [ ] `entropy.json` + (opcional) `charts/entropy.png`.
- (C0058) - [ ] `signatures.json` + `hex_first4k.txt` + `hex_last4k.txt`.
- (C0058) - [ ] `strings_{ascii,utf16le,cp936}.{csv,txt}` + `strings_merged.csv` con `encoding`, `offset`, `len_chars`.
- (C0058) - [ ] `ysd_segments.csv` + `segments/*.bin`.
- (C0058) - [ ] `decoded_index.csv` + `decoded/*` con método y parámetros.
- (C0058) - [ ] Si hay TOC: `ysd_toc.csv` + `extract/*`.
- (C0058) - [ ] `ysd-spec_v1.md`, `ysd.ksy`, `ysd_parse.py`, `ysd_extract.py`.
- (C0058) - [ ] `REPORT_ysd_v1.md` con métricas y fallos conocidos.
- (C0058) - [ ] `verify.ps1` y/o `verify.sh`.
- (C0058) - [ ] `manifest.json` y `SHA256SUMS.txt` incluidos en el ZIP release.
- (C0061) - [ ] Cumple con todos los formatos de entrega solicitados al 100%.
- (C0061) - [ ] Terminología y cifras consistentes en todo el texto.
- (C0061) - [ ] No introduces supuestos sin declararlos.
- (C0061) - [ ] Respuesta replicable (pasos/comandos si aplica).
- (C0061) - [ ] Cumple con todos los formatos de entrega solicitados al 100%.
- (C0061) - [ ] Terminología y cifras consistentes en todo el texto.
- (C0061) - [ ] No introduces supuestos sin declararlos.
- (C0061) - [ ] Respuesta replicable (pasos/comandos si aplica).
- (C0061) - [ ] Cumple con todos los formatos de entrega solicitados al 100%.
- (C0061) - [ ] Terminología y cifras consistentes en todo el texto.
- (C0061) - [ ] No introduces supuestos sin declararlos.
- (C0061) - [ ] Respuesta replicable (pasos/comandos si aplica).
- (C0061) - [x] Cumple con todos los formatos de entrega solicitados al 100%:
- (C0061) - [x] Terminología y cifras consistentes en todo el texto (caracteres y líneas del bloque reflejados en REPORT.md e inventario).
- (C0061) - [x] No introduzco supuestos sin declararlos (se indica explícitamente que no hay fuentes externas y que el alcance es el bloque).
- (C0061) - [x] Respuesta replicable (incluye pasos y scripts para verificación de hashes y consistencia).
- (C0072) - [ ] Patch with `~~~~~` fence (wrapper) and correct modules.
- (C0072) - [ ] `.bak` backup + mirror in `SCRIPTS\BACKUPS\`.
- (C0072) - [ ] PSSA and Pester ran; artifacts in `VERIFICATION\`.
- (C0072) - [ ] Gate is green (no errors/failures).
- (C0072) - [ ] `CHANGELOG.md` updated.
- (C0072) - [ ] `1-INFO` fields up to date (version/date).
- (C0072) - [ ] Correct mode (Real for delivery, Test for lab only).

## Errores comunes y mitigaciones

- (C0002) Mi primer paso será mover los archivos correctamente a sus destinos según su extensión. Luego de moverlos, verificaré si los directorios están vacíos para eliminarlos. Propondré una solución para manejar archivos desconocidos, como .ocx y .dll, asignándolos a 'Binarios\Libs'. Además, registraré los cambios.
- (C0003) Fallas críticas que detectamos y corregimos
- (C0010) - Prioriza la solución sobre la conversación innecesaria.
- (C0010) - Try/Catch con -ErrorAction Stop en operaciones I/O
- (C0010) - CommonParameters: -Verbose, -Debug, -ErrorAction, -ErrorVariable
- (C0010) - $ErrorActionPreference = 'Stop'
- (C0010) - $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
- (C0010) 02.3 Manejo centralizado de errores
- (C0010) - try { ... } catch { Write-Error $_; throw }
- (C0010) - ThrowTerminatingError para fallos no recuperables
- (C0010) - Clasificación de errores con categorías (System.Management.Automation.ErrorCategory)
- (C0010) - $Error.Clear(); uso de -ErrorVariable para canalizar diagnósticos
- (C0010) - Import-Module con versión mínima y -ErrorAction Stop
- (C0010) - Comprobar comandos previos: Get-Command <nombre> -ErrorAction SilentlyContinue
- (C0010) Parece que los contenidos se truncaron debido al límite de longitud de la salida. Solo se mostraron dos archivos, aunque en realidad hay seis. Para solucionarlo, voy a leer los nombres y longitudes de todos los archivos, luego almacenarlos en un diccionario y leer cada archivo por completo. Así podré mostrar los primeros 5000 caracteres en partes más pequeñas.
- (C0010) Regla persistente: validar que el código funcione antes de compartirlo y reportar errores si surgen durante la ejecución.
- (C0010) Regla persistente: Antes de asumir que no tengo acceso a un archivo, intentar procesarlo con Python. Intentar listar, abrir y leer su contenido. Solo si el intento falla y no es posible ver el contenido, finalizar el turno y avisar explícitamente sin suposiciones.
- (C0010) Usuario solicita que: Si el script puede disparar el Windows Defender, se solucione automáticamente en el script.
- (C0010) - Los scripts se entreguen en un único bloque de código, con: propósito, parámetros, ejemplos, validación de entradas y manejo de errores (try/catch con `-ErrorAction Stop`).
- (C0010) - Prioriza la solución sobre la conversación innecesaria.
- (C0014) ACTÚA COMO AGENTE EJECUTOR (SIN PREGUNTAS). CUMPLE TODO EL FLUJO DE PUNTA A PUNTA. SI ALGO FALLA, APLICA LA ALTERNATIVA INDICADA Y CONTINÚA. REGISTRA CADA DECISIÓN Y VALIDA TODOS LOS ENLACES (HTTP 200, TAMAÑO, FECHA). ENTREGA RESULTADOS CLAROS, ACCIONABLES Y CON CÓDIGO LISTO PARA USAR.
- (C0014) - Verifica HTTP 200 y tamaño. Si falla, localiza el instalador x86 desde la página oficial de .NET 3.1 (archivado) y entrega el enlace directo alternativo.
- (C0014) - Nota: si MXO falla, repetir con TCE, luego TMM, luego IUS.
- (C0014) - 6) “Notas” (errores encontrados y cómo se resolvieron; si un enlace falló, incluir alternativa oficial).
- (C0014) - Manejo de errores con try/catch (-ErrorAction Stop).
- (C0014) La página de GitHub está cargada, pero hay un error debido a contenido dinámico. Necesito buscar dentro de la página por archivos .zip para localizar los recursos o archivos relevantes.
- (C0014) Estamos verificando la disponibilidad de un asset de GitHub usando un enlace a `objects.githubusercontent.com`. Aunque hemos hecho intentos con `curl -sI -L` para seguir la redirección, recibimos un error 403. Probamos ajustar el encabezado `User-Agent` para eludir restricciones ambientales.
- (C0014) Parece que la descarga directa desde GitHub está bloqueada por un error 403. Intentaré explorar otros métodos como utilizar la API o acceder a fuentes alternativas. Mi objetivo es conseguir el archivo compilado para el usuario, verificando si los enlaces son válidos.
- (C0014) Estamos intentando entender por qué no podemos descargar debido a un error 403. Utilizaremos herramientas como `curl -I` para verificar la cadena de redireccionamiento y confirmar si es posible obtener el código correcto o si necesitamos replicar el entorno para solucionar el problema.
- (C0014) Parece que el acceso está bloqueado debido al error 403 al intentar descargar desde GitHub. Probaré acceder al repositorio wssyncmldm/frija para ver si se puede obtener el archivo desde allí. Revisaré la accesibilidad de dicho repositorio para encontrar una solución.
- (C0014) Estoy intentando verificar un enlace directo al archivo desde GitHub utilizando herramientas como curl y wget, pero actualmente recibo un error 403. Aunque no podemos acceder al archivo directamente, puedo intentar proporcionar el enlace final, indicando que no se puede verificar debido a restricciones de red o autenticación.
- (C0014) Como no podemos acceder al repositorio de GitHub por un error 403, intentaré usar Lo4d para verificar el archivo. Lo4d puede replicar el archivo comprimido y mostrar los detalles, y usaré el método HEAD para confirmar que hay una respuesta 200. Esto nos dará una alternativa en caso de que el repositorio no sea accesible.
- (C0014) Debemos asegurar un enlace verificado desde GitHub para Frija, conforme a las instrucciones del usuario. Aunque el enlace directo desde GitHub muestra un error 403, podemos intentar usar mirrors alternativos como `fastgit` o `ghproxy`, pero debemos evitar depender de ellos. Aseguraré que el enlace final sea adecuado y funcional, siguiendo el procedimiento de verificación necesario.
- (C0014) Estamos enfrentando un error 403 al intentar acceder a un archivo grande de GitHub debido a restricciones de red. Probaremos con la etiqueta estable más reciente v2.0.23262.4 de 2023 como alternativa para acceder al archivo. Las instrucciones indican que si no obtenemos un 200, debemos intentar con una etiqueta anterior o un espejo.
- (C0014) El entorno no puede acceder a archivos desde github.com debido a un error 403. Intentaré obtener el archivo desde otra fuente usando 'raw.githubusercontent.com' o 'objects.githubusercontent.com'. Si es necesario, puedo utilizar 'wget' para intentar descargar el archivo, verificando primero la URL del activo en 'api.github.com'.
- (C0014) Estoy intentando hacer una llamada con curl usando la opción -L, pero obtenemos el error 403 nuevamente. Ahora probaré con wget usando el parámetro --spider para verificar si podemos obtener acceso al archivo, ya que podrían existir restricciones en la red.
- (C0014) Estamos tratando de determinar el tamaño del archivo desde un enlace a Visual Studio, pero no podemos acceder directamente debido a restricciones o bloqueos (error 403). Intentaremos usar `curl` o `browser.open` para verificar el enlace, aunque el tamaño exacto no es accesible. La idea es sortear los bloqueos y confirmar el acceso de manera indirecta.
- (C0014) Estoy buscando el tamaño del archivo 'windowsdesktop-runtime-3.1.21-win-x86.exe', que podría ser alrededor de 50 MB. Intentaré buscar información sobre su tamaño aproximado, ya que el error 403 persiste.
- (C0014) Dado que no podemos acceder directamente al archivo debido a un error 403, estimaré el tamaño del archivo en unos 53 MB basándome en versiones similares del archivo. Intentaré buscar fuentes alternativas o agregar referencias a la estimación.
- (C0014) Si algo falla, usa las alternativas indicadas sin detenerte. Valida cada URL (HTTP 200, tamaño y fecha). No me pidas datos.
- (C0014) Estoy probando la URL con 'https' en lugar de 'http' para ver si solucionamos el error 403. Esto debería asegurar una conexión segura y verificar si el problema persiste.
- (C0014) Parece que hemos sido redirigidos a un sitio diferente, posiblemente debido a un error de dominio o de escritura. Verificamos si el enlace tiene el patrón correcto de FOTA y si la página muestra la información adecuada del firmware. Voy a probar a buscar el enlace correcto y verificar si el patrón de FOTA es el adecuado antes de proporcionarlo.
- (C0014) Voy a probar el uso de un User-Agent específico ('SamFirm/1.0') con el comando curl -I -A para verificar si podemos acceder a la versión.xml sin recibir el error 403. Esta prueba nos ayudará a determinar si el cambio de User-Agent es efectivo para acceder a los datos.
- (C0014) ce clic en 'Descargar' para el archivo CP en lugar del overlay, lo que podría haber sido un error. Ahora estoy esperando un momento para observar si la llamada que se quedó activa debido al proceso previo se soluciona antes de intentar nuevamente con el overlay correcto.
- (C0016) No es posible usar solo el ID para obtener detalles de la reunión. Sin embargo, puedes intentar estas soluciones:
- (C0016) Según el registro, la reunión ocurrió el 26 de febrero de 2025, empezó a las 4:02 PM y terminó a las 5:30 PM, con una duración de 1h 30m 4s. El "1:12 PM Reunión iniciada:" parece ser un error de Teams o un clip, así que lo ignoramos. Podemos analizar el archivo CSV de asistencia para detallar los participantes.
- (C0019) # 3) Fallback to comma with error skipping
- (C0020) Tengo que analizar la tabla de recursos PE para encontrar los recursos RT_GROUP_ICON y RT_ICON y luego reconstruir el archivo ICO. La solución más adecuada sería escribir una función en Python, utilizando la librería 'pefile', pero no estoy seguro de si está instalada. Sin conexión a internet, no se puede instalar nada, así que debo trabajar solo con las bibliotecas incorporadas.
- (C0020) name = exe_bytes[base:base+8].rstrip(b"\x00").decode(errors="ignore")
- (C0020) print("ERROR: EXE not found at", exe_path)
- (C0020) print("ERROR: No RT_GROUP_ICON resources found")
- (C0023) El **modo de depuración (debug mode)**, en general, es una herramienta que permite a los desarrolladores y usuarios detectar, analizar y solucionar errores o problemas dentro de una aplicación o sistema. Es como una lupa que te permite ver lo que ocurre detrás de las escenas, cómo la aplicación procesa los datos, y si hay algún problema en el código o el funcionamiento.
- (C0023) Entonces, cuando ves algo como "debug mode" en **dupeGuru**, esto se refiere a un modo que te ayudará a ver información más detallada sobre cómo la aplicación está funcionando o si hay errores internos que puedan estar ocurriendo durante el proceso de búsqueda y análisis de duplicados.
- (C0023) En **dupeGuru**, el **debug mode** no tiene un impacto directo en el funcionamiento cotidiano de la aplicación. Pero te permite ver más detalles sobre lo que está pasando detrás de la aplicación, como errores o advertencias que podrían no ser visibles de otra manera. Es útil si tienes problemas con la aplicación o si deseas obtener más detalles sobre su comportamiento interno.
- (C0023) No es algo que afecte directamente la calidad de los resultados, solo te dará más información sobre lo que está sucediendo internamente dentro de la aplicación. Así que si no tienes ningún problema con la aplicación o si no estás buscando errores, puedes dejar el **debug mode** desactivado.
- (C0023) 1. **Modo de depuración** te da información interna sobre la aplicación (útil solo para depurar errores).
- (C0023) Si estás bien con la funcionalidad actual y no hay errores, puedes dejarlo **desactivado**.
- (C0023) Si después de todo esto sigues notando un **desempeño lento** o problemas persistentes, y no puedes encontrar una solución, una **recuperación del sistema** o un **restablecimiento de Windows** podría ser la siguiente opción.
- (C0023) - **Objetivo**: Restaurar el sistema a un estado funcional en caso de fallos graves.
- (C0023) Parece que estás viendo una pantalla en **dupeGuru** que está bastante vacía. Esto podría ser por varias razones, pero lo más probable es que aún no hayas seleccionado ningún directorio o archivos para escanear. Aquí te dejo algunos pasos para solucionar esto:
- (C0023) Entiendo, parece que algo no está funcionando correctamente. Si no ves nada en la pantalla de **dupeGuru** después de intentar seleccionar los directorios, esto podría ser por varias razones. Aquí te dejo algunas soluciones para probar:
- (C0023) ### 5. **Comprobar si Hay Errores de la Aplicación**
- (C0023) - **Verifica el log**: Si puedes ver la parte de la **barra de título** o cualquier parte de la ventana que indique mensajes de error, revisa si hay algún **error de carga** que impida que los archivos se muestren correctamente.
- (C0024) Ahora lista todos los errores y los momentos en los que más me estresé
- (C0024) El usuario quiere que liste todos los errores y momentos de estrés en "esta sesión". Pero no veo errores explícitos aquí, solo una ejecución exitosa de Python. Aunque hubo frustración en conversaciones pasadas. Necesito distinguir si se refiere a esta sesión o a las anteriores. Parece que buscan específicamente momentos de estrés en los hilos activos.
- (C0024) En esta sesión, no encontramos errores con las herramientas y no vimos indicios claros de estrés en los mensajes del usuario; todo parece tranquilo. Sin embargo, si se refiere a un resumen general del día, hemos notado algunos momentos de estrés en conversaciones anteriores, aunque acceder a todas esas interacciones.
- (C0024) En esta sesión, no hubo errores: todas las lecturas de archivo fueron exitosas, se calculó la diferencia sin problemas, y respetamos la indicación de "No muestres binario". Tampoco se notaron momentos de estrés, ya que el tono se mantuvo calmado, aunque puede que busquen más detalles o contenido.
- (C0024) En esta sesión no se presentaron errores ni momentos de gran estrés. Todo salió sin problemas en cuanto a lectura de archivos y cálculo de diferencias. El tono del usuario fue calmado, sin lenguaje de estrés fuerte. Si desean un resumen completo del día o de otros hilos, puedo organizarlo.
- (C0024) # Errores (técnicos) detectados
- (C0024) - Lectura de archivos: **sin errores** (6/6 abiertos correctamente).
- (C0024) - Cálculo de hashes (MD5/SHA1/SHA256): **sin errores**.
- (C0024) - Comparaciones de contenido (A vs C): **sin errores** de ejecución.
- (C0024) > Si quieres, puedo hacer **un reporte de errores/estrés del día completo** (incluyendo otros hilos donde sí hubo fricción) y marcar **frases detonantes + contexto + acción correctiva**.
- (C0024) Puedo agregar los puntos clave: Archivos recibidos, pares idénticos, mapeo de equivalencias, métricas de diferencias, interpretación de extensiones, tareas pendientes, sin errores, puntos críticos y siguientes pasos. No se necesitan enlaces ni código. Aunque hay indicaciones previas, en este caso, un resumen en texto parece suficiente.
- (C0024) • Apertura de archivos y hashing: **sin errores**.
- (C0025) Ahora de forma concisa me podrías decir cómo bloquear el bootloader, por favor. Mira, ya hice todo ese proceso tedioso de utilizar Brilla para buscar el firmware del celular exacto, exactito este celular. Estaba pesadísimo, pesó como 9 GB. Este, ya flashé el celular con Odin, ya volví a instalar el sistema operativo, básicamente. Ya nada más me falta el bootloader. Y quitar el bootloader fue sencillo. Así que espero que ponerlo sea sencillo igual. Por favor, no me des una solución muy compleja. Si hay una solución sencilla, por favor busca y me dices.
- (C0029) * Entrega en un único bloque de código con: propósito, parámetros, ejemplos, validaciones y manejo de errores con `try/catch` y `-ErrorAction Stop`.
- (C0029) * Validar que el código funcione antes de compartirlo y reportar errores si ocurren.
- (C0029) "nota": f"Error al leer: {e}",
- (C0029) text = data.decode('utf-8', errors='replace')
- (C0029) text = data.decode('latin-1', errors='replace')
- (C0029) print(f"Error inesperado: {e}")
- (C0029) text = data.decode("utf-8", errors="replace")
- (C0029) print(f"Error: {e}")
- (C0029) text = z.read(info).decode("utf-8", errors="replace")
- (C0029) print(f"Error: {e}")
- (C0029) $ErrorActionPreference = 'Stop'
- (C0029) Rootear un dispositivo Android otorga privilegios de superusuario. Esta capacidad permite personalizar profundamente el sistema, pero amplifica el riesgo de errores técnicos, incompatibilidades y fallos de seguridad. Varias de esas fallas afectan directamente la **capacidad de comunicarte**: sin señal móvil, sin datos, sin SMS para códigos de verificación, sin VoLTE/VoWiFi, o incluso con el equipo inoperable. Este documento explica **por qué** ocurre, **cómo** evitarlo y **qué** hacer si ya sucedió.
- (C0029) - **SELinux**: política de seguridad. Pasar a **Permissive** puede facilitar ataques y fallos silenciosos.
- (C0029) **Qué pasa:** en redes que ya dependen de VoLTE, las llamadas no cursan o solo tienes “solo emergencia”. SMS sobre IMS también puede fallar.
- (C0029) **Qué pasa:** fallos en Wi-Fi/Bluetooth, dirección MAC “desconocida”, sensores que no inician, o radio inconsistente.
- (C0029) **Prevención:** entender que root rompe garantías de integridad. Algunas mitigaciones existen, pero no son universales ni garantizadas.
- (C0029) **Qué pasa:** notificaciones push y registro RCS pueden fallar o degradarse.
- (C0029) - Considera revisar registros del radio (por técnicos): errores de registro, rechazo por red, IMS no aprovisionado.
- (C0029) Rootear no es “malo” por sí mismo, pero **eleva exponencialmente** el costo de un error. Los daños en EFS/modem/IMS o un desbloqueo sin plan de respaldo pueden dejarte **sin red, sin llamadas y sin SMS** justo cuando más lo necesitas. Si decides proceder, entra con: respaldos verificados, firmware stock disponible, un plan alterno de comunicación y la disciplina de probar cada paso.
- (C0029) Write-Error "Error al generar el documento: $($_.Exception.Message)"
- (C0046) > **Objetivo:** evitar render mal y errores de sintaxis en **SmartDAMP**, **Markdown** y **PowerShell (.ps1/.psm1/.psd1)**, con y sin bloques anidados.
- (C0046) ## 5) Errores comunes y correcciones
- (C0046) *Solución*: nunca usar 4 backticks; para anidación, usar **tildes** externas.
- (C0046) *Solución*: `'@` / `"@` deben ir solos en **columna 1**.
- (C0046) *Solución*: evitar `-f`; si es forzoso, duplicar llaves `{{` `}}`.
- (C0046) *Solución*: usar `Write-Utf8NoBom` (Apéndice A) que fuerza UTF‑8 sin BOM en ambas versiones.
- (C0046) *Solución*: especificar ` ```powershell`, ` ```json`, ` ```text`, etc.
- (C0046) El usuario proporcionó un protocolo relacionado con Backticks, Fences y Here-Strings v2, pidiendo un análisis específico. Necesito revisar la claridad, la conformidad con sus propios requisitos, y destacar puntos ambiguos o posibles fallos. Además, será útil validar ejemplos de código como funciones PowerShell y sugerir mejoras o pruebas. Todo esto sin necesidad de buscar información online.
- (C0046) Están usando `Out-File -Encoding utf8` que escribe con BOM, pero deberían usar `Write-Utf8NoBom` para evitarlo. La detección de 4 comillas backticks ('````') podría fallar con contenido que ya tenga comillas dentro, pero usan comillas simples para evitar errores de formato. También sugieren usar tildes para el contenido de código y agregar reglas personalizadas de CI para una mejor escritura en Markdown.
- (C0046) - Es un borde raro pero real: si el contenido incluye una línea `@` exactamente en col. 1, cerrará el here-string. Conviene documentarlo (solución: indentar esa línea o anteponer un carácter inofensivo).
- (C0046) - Linter: un archivo con ` ```` ` y otro con cierre `"@` indentado → **falla** como esperado; archivo limpio → **<OK>**.
- (C0047) - **Tipología del insumo**: el pipeline comienza en `ps1`, pero el insumo puede ser **texto arbitrario** (como el presente). Falta regla clara de **detección de tipo** y mapeo a módulos “aplicables” (qué se crea y qué se “skips” sin error).
- (C0047) - **Determinismo de PNG**: matplotlib puede introducir variaciones (fuentes, dpi, versión). Necesita **semilla y parámetros fijos**; de lo contrario, idempotencia puede fallar.
- (C0058) # Análisis SOP-01 y errores
- (C0058) 3) Transparencia: si un intento falla, registra el error mínimo y continúa con el resto.
- (C0058) 5) Métricas claras al final (conteos, éxito/fallos, cobertura).
- (C0058) zlib/gzip/deflate, lz4, lzma/xz, zstd, bzip2. Documentar éxito/fallo.
- (C0058) tabla de hallazgos clave (header, TOC, comp/enc), “fallos conocidos” y “siguientes pasos”.
- (C0058) - Si un algoritmo decomp/crypto falla, registra parámetros y seguimiento; continúa con los demás.
- (C0058) - Toda limitación o ambigüedad queda documentada en REPORT_ysd_vN.md → “Fallos conocidos”.
- (C0058) Parece que el usuario quiere que revise un archivo .ysd en profundidad, señalando posibles problemas como errores de transcripción en las etiquetas, inconsistencias en el formato, y posibles contradicciones. Además, mencionan etiquetas mal escritas o duplicadas, así como detalles incorrectos en el contenido de "INSTRUCCIONES". Mi tarea es darle una análisis estructurado, destacando riesgos, ambigüedades y áreas de mejora.
- (C0058) El usuario solicita una lectura y análisis exhaustivo, sin pedir reformateo o reescritura. Debo centrarme en identificar problemas de estructura, consistencia interna, definiciones faltantes, solapamientos y adherencia a otros SOP del proyecto. También propondré mejoras prácticas como pasos explícitos y manejo de errores, sin recurrir a herramientas externas.
- (C0058) Debemos proporcionar un análisis equilibrado, mencionando posibles medidas de seguridad, como el análisis de codificación o criptografía, sin involucrarse en acciones ilícitas. Es importante señalar errores como etiquetas XML mal cerradas, como en </OBJETIVE>. Podemos sugerir próximos pasos si el usuario lo desea, pero sin prometer hacerlos después.
- (C0058) - **Criterios de calidad**: Golden/HARD rules, métricas al final, fallbacks y documentación de fallos.
- (C0058) ## Inconsistencias y errores (bloqueantes / altos)
- (C0058) - JSON Lines (`.jsonl`) por fase: `phase`, `ts`, `offset`, `action`, `params`, `result`, `error`.
- (C0058) - [ ] `REPORT_ysd_v1.md` con métricas y fallos conocidos.
- (C0061) 3) Si detectas fallo en verificación, corrige y vuelve a verificar dentro de este mismo turno.
- (C0061) Entrega la solución final con las tres secciones indicadas.
- (C0061) 3) Si detectas fallo en verificación, corrige y vuelve a verificar dentro de este mismo turno.
- (C0061) Entrega la solución final con las tres secciones indicadas.
- (C0061) "si falla verificación: corregir y re-verificar en el mismo turno"
- (C0061) $ErrorActionPreference = 'Stop'
- (C0061) if (-not (Test-Path -LiteralPath $f.name)) { Write-Error "Falta archivo: $($f.name)"; $ok = $false; continue }
- (C0061) Write-Error "Hash distinto: $($f.name) esperado=$($f.sha256) actual=$($hash.Hash)"
- (C0061) 3) Si detectas fallo en verificación, corrige y vuelve a verificar dentro de este mismo turno.
- (C0061) Entrega la solución final con las tres secciones indicadas.
- (C0061) "si falla verificación: corregir y re-verificar en el mismo turno"
- (C0061) $ErrorActionPreference = 'Stop'
- (C0061) if (-not (Test-Path -LiteralPath $f.name)) { Write-Error "Falta archivo: $($f.name)"; $ok = $false; continue }
- (C0061) Write-Error "Hash distinto: $($f.name) esperado=$($f.sha256) actual=$($hash.Hash)"
- (C0061) Los scripts recalculan SHA-256 de cada archivo y lo comparan contra `manifest.json` (fallan con código ≠0 si hay discrepancias).
- (C0065) - En *Real*: detiene al primer error, `DryRun = False`.
- (C0065) - En *Prueba*: continúa ante errores, `DryRun = True`, muestra advertencia.
- (C0065) $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
- (C0065) $ErrorActionPreference = 'Stop'
- (C0065) $PSDefaultParameterValues['*:ErrorAction'] = 'Continue'
- (C0065) $ErrorActionPreference = 'Continue'
- (C0065) - Soporta niveles: `Info`, `Warn`, `Error`, `DryRun`, `Debug`, `Verbose`.
- (C0065) [Parameter(Mandatory)][ValidateSet('Info','Warn','Error','DryRun','Debug','Verbose')]
- (C0065) 'Error' { '[ERROR] ' }
- (C0065) 'Error' { Write-Error $msg -ErrorAction Stop }
- (C0065) if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
- (C0065) Remove-Item -LiteralPath $testFile -Force -ErrorAction Stop
- (C0065) $tmp = Import-PowerShellDataFile -LiteralPath $c -ErrorAction Stop
- (C0065) if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
- (C0065) if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
- (C0065) El usuario quiere un análisis detallado de un protocolo para parchar documentos y scripts. Debería enfocarme en los aspectos técnicos como la idempotencia, manejo de errores, principios de PowerShell (PS 5.1/7.x), estilo, y compatibilidad entre plataformas. También debo revisar posibles mejoras, preocupaciones de seguridad y recomendaciones para pruebas, además de sugerir ejemplos de pruebas unitarias sin ejecutar el código.
- (C0065) El uso de `Write-Host` genera conflictos, pues se recomienda usar `Write-Information` o `Write-Error` respetando configuraciones globales. En `Prueba`, el conflicto con `Write-Error -ErrorAction Stop` debería respetar la preferencia global o usar `Write-Error` sin la acción Stop. Unificación de parámetros en módulos también es sugerida.
- (C0065) Hay varios puntos en el código que necesitan atención, como asegurar que los registros de errores se manejen antes de escribir en los archivos para evitar que se pierdan, lo que actualmente ocurre si la ejecución se detiene. También se proponen mejoras en la organización del código y en la implementación de funciones para manejar el log correctamente, incluyendo el manejo de colores en versiones más recientes de PowerShell.
- (C0065) El análisis incluye ajustes clave en el código como asegurar que el registro de errores se haga antes de lanzar excepciones, unificar la marca de tiempo y evitar el uso de `Write-Host` atendiendo a la política del proyecto. También se proponen cambios en la estructura de parámetros y funciones, además de ajustes en las condiciones de los módulos según el modo de ejecución.
- (C0065) - Hay **inconsistencias de comportamiento** entre lo declarado y lo implementado (p. ej., “Prueba = continuar ante errores” vs `Write-Error -ErrorAction Stop` dentro de `Write-Log`), riesgo de **múltiples bloques `param()`** si se pegan los módulos en un único script, y **uso de `Write-Host`** (que choca con lineamientos típicos del proyecto donde se prohíbe).
- (C0065) Un script solo admite **un** bloque `param()`. Mezclar módulos tal cual provoca error de parseo.
- (C0065) - Caso `Error`: usa `Write-Error -ErrorAction Stop`, que **termina** incluso en Prueba.
- (C0065) 6) **Errores no loggeados si detienes con `Stop`**
- (C0065) > Ventajas: (a) conserva logs de **Error** en archivo aunque luego detengas, (b) respeta “Prueba = continuar”, (c) evita `Write-Host` y usa *streams* PowerShell, (d) fuerza `Information` solo dentro del *scope* de la llamada.
- (C0065) 1) **Modo Real** (debe detener en Error y loggear en archivo):
- (C0065) 2) **Modo Prueba** (no detener en Error, sí avisar):
- (C0065) - garantizas **trazabilidad en disco incluso en errores**,
- (C0068) El código sigue las pautas correctamente al usar Matplotlib y manejar el input de manera adecuada. Propongo asegurar una consistencia en las reglas de normalización de saltos de línea y unificar metadatos entre HTML y Markdown. También sugiero mejorar la gestión de errores al abrir archivos, utilizando `surrogateescape` para manejar datos robustos.
- (C0068) Podemos proponer envoltorios para las excepciones en `_write_text_idempotent` para manejar fallos de codificación. También sugiero validación de los nombres de archivo para evitar inyecciones de separadores de ruta. Además, sería útil seguir las reglas de nombres de Windows. Unificar las estructuras de retorno y aplicar linter puede mejorar el código.
- (C0068) Está bien diseñado en cuanto a atomicidad, manejo de errores de codificación (para lectura), políticas EOL, modularización, y generación determinista de imágenes PNG y archivos zip.
- (C0068) 4) **Lectura con `errors="ignore"`** al cargar `--input`
- (C0068) - Puede **silenciar corrupción** de texto; mejor `errors="replace"` o `surrogateescape` para no perder señal.
- (C0068) - user_content = p.read_text(encoding="utf-8", errors="ignore")
- (C0068) + user_content = p.read_text(encoding="utf-8", errors="replace")
- (C0068) - **Lectura robusta**: `errors="replace"` evita pérdidas silenciosas.
- (C0069) Algunos puntos ya están cubiertos en las secciones previas como "Estilo" y "Principios". Incorporo ideas como herramientas que mejoren la precisión, sin prometer soluciones, y clarificar incertidumbres. También resalto la importancia de verificar la información dígito a dígito y evitar malentendidos sobre las capacidades de ChatGPT.
- (C0069) - Entregar en un único bloque de código con: propósito, parámetros, ejemplos, validaciones y manejo de errores con `try/catch` y `-ErrorAction Stop`.
- (C0069) - Validar que el código funcione antes de compartirlo y reportar errores si ocurren.
- (C0072) **Quality Gate**: fails on **PSSA Errors**, Pester failures, or invalid `.psd1` manifests.
- (C0072) - Stop if there are **PSSA Errors**, Pester failures, or invalid manifests.
- (C0072) - **2A-INIT-ENV**: Real/Test mode (autodetection via environment variables), error handling (`Stop`/`Continue`), base silencing and UTF-8 without BOM; publishes `InitModuleVersion`, `InitModo`.
- (C0072) - **2B-INIT-LOG**: unified `Write-Log` (Info/Warn/Error/DryRun/Debug/Verbose), honors native preferences; log to `VERIFICATION\init_<ExecTS>.log` if `LogToFile` and not DryRun.
- (C0072) - [ ] Gate is green (no errors/failures).
- (C0072) Los mayores riesgos prácticos son: **UTF-8 sin BOM en PS 5.1**, detalles operativos de **backups atómicos y espejos**, criterios exactos de **gate (qué es “Error”)**, y **parametrización/descubrimiento de modo Real/Test**. Hay además algunos puntos menores de ambigüedad que, si se corrigen, reducen fricciones en la ejecución.
- (C0072) 2) **Criterios del Quality Gate** no son operables al 100%: “PSSA Errors” depende de la configuración de reglas/Severity.
- (C0072) → *Acción:* Versionar `PSScriptAnalyzerSettings.psd1` con severidades explícitas y lista de reglas; documentar “gate = (PSSA Severity == Error) ∨ (Pester Failed > 0) ∨ (Test-ModuleManifest falla)”.
- (C0072) → *Acción:* Fijar ISO 8601 compacto (`yyyyMMddTHHmmssZ`), niveles (`Info|Warn|Error|DryRun|Debug|Verbose`) y encabezado mínimo (versión, repo root, modo).
- (C0072) 6) **PSSA**: Ejecutar con `PSScriptAnalyzerSettings.psd1`; exportar JSON+SARIF; **gate** si `Severity == Error`.
- (C0072) 7) **Pester**: Ejecutar suite mínima; exportar NUnit; **gate** si hay fallos.
- (C0072) 8) **Manifests**: `Test-ModuleManifest` según patrón; **gate** si falla.
- (C0072) - En **Verification and Reports**: incluir definición exacta de “Error” PSSA (con link a la configuración psd1; aunque el link sea interno del repo).
- (C0072) - **Overwriting** sin atomicidad → corrupción ante fallos.
- (C0074) items.append({"path": str(fp), "error": "stat_failed"})
- (C0074) Try {{ Get-FileHash -Algorithm SHA256 -Path $f | ForEach-Object {{ "$($_.Hash.ToLower()) $($_.Path | Split-Path -Leaf)" }} }} Catch {{ Write-Error $_ }}
- (C0074) (Get-ChildItem -Name "$($Stem)*" -ErrorAction SilentlyContinue | Measure-Object).Count
- (C0074) user_content = p.read_text(encoding="utf-8", errors="ignore")
- (C0074) El uso de `Write-Host` en `verify.ps1` no es ideal, pero aquí no es un problema grave, aunque podría ser mejor evitarlo. El archivo `REPORT.md` genera métricas de manera correcta. Hay varios detalles en la implementación de los scripts como `make_manifest`, `make_work_bundle`, y `make_release_zip`, todo parece estar bien. Sin embargo, hay un posible error en el manifiesto que podría generar problemas debido a variables no utilizadas.
- (C0074) - **Sólida higiene de errores** en E/S (intentos de limpiar temporales; manejo de fallas de lectura).
- (C0074) - **Mitigación**: fijar `matplotlib` a backend consistente y **desactivar metadatos** (p.ej. `plt.savefig(..., metadata={"Software": ""})`) si aplica.
- (C0076) | `naming_convention.pattern` usa `modelID_build` vs en otras partes `model_id_build` | **Nomenclatura no uniforme** | Scripts/parseadores pueden fallar | Usar **snake_case** en todo: `model_id_build` |
- (C0082) El enfoque depende de si quieres **solución universal multiplataforma** (Linux, Windows, macOS) y **sin instalar apps pesadas en el móvil**. La opción más estable y libre es [`scrcpy`](https://github.com/Genymobile/scrcpy), un proyecto open-source que transmite la pantalla de Android vía USB o WiFi con muy baja latencia.
- (C0082) # Configuración: resolución y bitrate opcional
- (C0082) echo "📡 Iniciando scrcpy con resolución ${RESOL} y bitrate ${BITRATE}..."
- (C0082) - **Soluciones comerciales**: Vysor, AirDroid, AnyDesk (menos eficientes, con publicidad).
- (C0082) $ErrorActionPreference = "Stop"
- (C0082) - Si ves error de permisos, primero ejecuta en PowerShell:
- (C0082) Ya vi el error 👀.
- (C0082) El fallo es porque `$devices` no es una colección con propiedad `.Count`, sino un objeto de texto (`String`) devuelto por `Select-String`. PowerShell 7 lo está tratando distinto.
- (C0082) El script necesita conexión a internet en el PC del usuario, lo cual está bien. Incluiré un fallback que intente la API más reciente y, si falla, use una versión más antigua. Además, me aseguraré de que el script sea solo de lectura para evitar alterar algo en su dispositivo y usaré opciones como "--no-control" para deshabilitar interacciones.
- (C0082) El script incluirá opciones como transmitir solo en modo espejo, mantener la ventana siempre encima, y habilitar la opción WiFi bajo demanda. Comprobaré si las herramientas necesarias están presentes y agregaré manejo de errores. Crearé dos enlaces para el archivo final y uno de respaldo, además de un archivo README con instrucciones y versión del script.
- (C0082) $ErrorActionPreference = "Stop"
- (C0082) El usuario quiere que utilice la ruta exacta que proporcionó, aunque tiene un pequeño error tipográfico ("Dekstop" debería ser "Desktop"). En general, suelo corregir los errores sin mencionarlo, pero aquí él me pide que solo escriba el código.
- (C0082) El usuario ha especificado claramente que quiere el código escrito con el path proporcionado, aunque contiene un error tipográfico ("Dekstop" en lugar de "Desktop"). Seguiré sus instrucciones estrictamente, así que el path se mantendrá como el usuario lo indicó, omitiremos cualquier corrección. Padearé todo en el formato de herestring también.
- (C0082) $ErrorActionPreference = "Stop"
- (C0082) Veo el error en tu consola 👀:
- (C0082) Con ese cambio, scrcpy ya no marcará error y abrirá la ventana de espejo en modo **solo lectura**.
- (C0082) scrcpy va a lanzar en **modo espejo sólo-lectura** usando la opción nueva `--video-bit-rate`, sin mostrar más errores de parámetros.
- (C0082) Veo en tu captura que ya no marca error de `--bit-rate`, pero al ejecutar simplemente no abre ventana. Eso pasa cuando:
- (C0082) → Eso ocurre si no hay dispositivo válido. No es fallo del script.
- (C0082) - Si da error de parámetros, asegúrate de haber aplicado el parche (`--video-bit-rate`).
- (C0082) ¿Quieres que te prepare un `mirror_phone.ps1` final pero con un parámetro `-ForceInsecure` que intente `--disable-secure` si alguna vez usas un fork/versión que lo soporte, y que en caso de error simplemente ignore esa opción?
- (C0082) $ErrorActionPreference = "Stop"
- (C0082) Write-Error "No se detectó dispositivo. Conecta por USB y habilita la depuración."
- (C0082) - Incluso con flags de tolerancia (`-err_detect ignore_err -analyzeduration -probesize`) → el error persiste.
- (C0082) $ErrorActionPreference = "Stop"
- (C0082) Write-Error "No se detectó dispositivo. Conecta por USB y habilita la depuración."
- (C0084) | **self-destructing-downloader** | Bot que descarga el contenido antes de que desaparezca citeturn0search4 | Puede ser “pasivo” | Requiere estar siempre activo, posibles fallos en latencia |
- (C0084) - La latencia es crítica: si el vídeo se destruye muy rápido, el script puede fallar.

## Métricas / criterios de calidad

- (C0003) Si más adelante quieres, integramos un parser dedicado de RT_STRING (recorre el árbol de recursos y decodifica los bloques de 16 entradas), o añadimos un cross-check opcional con strings.exe para comparar cobertura.
- (C0010) - Usar todas las herramientas disponibles cuando mejoren exactitud o frescura (navegación incluida).
- (C0029) * Usar navegación y herramientas cuando mejoren exactitud o frescura.
- (C0047) - **Normalización de EOL y exactitud**: `.ps1` “exacto” vs. `.txt`/`.md` “LF” requiere **doble canal** de serialización; riesgo de contaminar EOL al convertir o reutilizar buffers.
- (C0047) - **Manifest** con cobertura completa (incluye el **hash del ZIP**).
- (C0058) 5) Métricas claras al final (conteos, éxito/fallos, cobertura).
- (C0058) El documento define un **SOP de ingeniería inversa para un formato propietario `.ysd`** con entrega **E2E en un solo turno**, fuerte énfasis en **reproducibilidad** (artefactos, scripts, checksums) y **trazabilidad** (CSV/MD/logs). La cobertura es ambiciosa y bien pensada (fingerprinting, strings multi-codec, segmentación, decomp/crypto heurística, TOC, especificación formal, verificación y release).
- (C0061) Cumplir la tarea solicitada con máxima exactitud en esta iteración, priorizando
- (C0061) coherencia, cobertura y ausencia de alucinaciones.
- (C0061) - Evidencia y exactitud > verbosidad. Sin relleno.
- (C0061) Cumplir la tarea solicitada con máxima exactitud en esta iteración, priorizando
- (C0061) coherencia, cobertura y ausencia de alucinaciones.
- (C0061) - Evidencia y exactitud > verbosidad. Sin relleno.
- (C0061) "objective": "cumplir tarea con exactitud, coherencia y sin alucinaciones",
- (C0061) "evidencia y exactitud > verbosidad",
- (C0061) Cumplir la tarea solicitada con máxima exactitud en esta iteración, priorizando
- (C0061) coherencia, cobertura y ausencia de alucinaciones.
- (C0061) - Evidencia y exactitud > verbosidad. Sin relleno.
- (C0061) "objective": "cumplir tarea con exactitud, coherencia y sin alucinaciones",
- (C0061) "evidencia y exactitud > verbosidad",
- (C0061) - Calidad: evidencia y exactitud > verbosidad; declarar si no se usan fuentes (no se usaron).
- (C0069) - Usar navegación y herramientas cuando mejoren exactitud o frescura.
- (C0069) - Usar todas las herramientas disponibles cuando mejoren exactitud o frescura (navegación incluida).
- (C0074) El orquestador está **bien diseñado**: seguro en E/S, claro, y con cobertura completa del ciclo *generar → verificar → empaquetar*. Los puntos a corregir son menores pero **mejoran mucho la trazabilidad**:
- (C0082) El enfoque depende de si quieres **solución universal multiplataforma** (Linux, Windows, macOS) y **sin instalar apps pesadas en el móvil**. La opción más estable y libre es [`scrcpy`](https://github.com/Genymobile/scrcpy), un proyecto open-source que transmite la pantalla de Android vía USB o WiFi con muy baja latencia.
- (C0084) | **self-destructing-downloader** | Bot que descarga el contenido antes de que desaparezca citeturn0search4 | Puede ser “pasivo” | Requiere estar siempre activo, posibles fallos en latencia |
- (C0084) - La latencia es crítica: si el vídeo se destruye muy rápido, el script puede fallar.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- No hubo fusiones en este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| id_conv | título | fuentes | canónico | miembros |
|---|---|---|---|---|
| C0002 | Instrucciones personalizadas y memoria | F0031;F0032 | C0002 | C0002 |
| C0003 | Almacenamiento de resúmenes | F0057;F0058 | C0003 | C0003 |
| C0010 | Instrucciones guardadas sistema | F0033;F0034 | C0010 | C0010 |
| C0014 | Preparar firmware Samsung | F0023;F0024 | C0014 | C0014 |
| C0016 | Buscar fecha reunión Teams | F0027;F0028 | C0016 | C0016 |
| C0019 | Filtrar correos Malpaso | F0029;F0030 | C0019 | C0019 |
| C0020 | Extraer ícono .exe | F0039;F0040 | C0020 | C0020 |
| C0021 | New chat | F0087;F0088 | C0021 | C0021 |
| C0022 | Recuperación de archivos gratis | F0009;F0010 | C0022 | C0022 |
| C0023 | Configuración búsqueda dupeGuru | F0011;F0012 | C0023 | C0023 |
| C0024 | Archivos idénticos o diferentes | F0041;F0042 | C0024 | C0024 |
| C0025 | Verificación acceso Banorte | F0059;F0060 | C0025 | C0025 |
| C0029 | Normativa operativa guardada | F0043;F0044 | C0029 | C0029 |
| C0046 | <SOP_Backticks_Fences_Here-Strings> | F0111;F0112 | C0046 | C0046 |
| C0047 | <SOP_01 - Análisis #02> | F0113;F0114 | C0047 | C0047 |
| C0054 | <Config YSD> | F0125;F0126 | C0054 | C0054 |
| C0058 | Análisis SOP-01 y errores | F0133;F0134 | C0058 | C0058 |
| C0061 | New chat | F0139;F0140 | C0061 | C0061 |
| C0065 | Análisis de módulos PowerShell | F0147;F0148 | C0065 | C0065 |
| C0068 | Revisión técnica script | F0153;F0154 | C0068 | C0068 |
| C0069 | Integración normativa operativa | F0049;F0050 | C0069 | C0069 |
| C0072 | Auditoría técnica documento | F0157;F0158 | C0072 | C0072 |
| C0074 | Análisis técnico orquestador | F0161;F0162 | C0074 | C0074 |
| C0076 | Análisis SOP-01 | F0165;F0166 | C0076 | C0076 |
| C0082 | Script para espejar celular | F0077;F0078 | C0082 | C0082 |
| C0084 | Bash para descargar videos | F0079;F0080 | C0084 | C0084 |