# Documentación y SOP

## Resumen ejecutivo

Este informe sintetiza 13 conversación(es) consolidadas del tema **Documentación y SOP**.

## Alcance y supuestos

- Basado exclusivamente en el contenido presente en las conversaciones fuente.
- Se excluyen saludos, disculpas y texto genérico sin valor técnico.
- Se preservan fragmentos técnicos, prompts y código tal como aparecen (con mínimos ajustes de formato).

## Procedimiento paso a paso

1) **UTF-8 sin BOM en PS 5.1**: `Out-File/Set-Content -Encoding UTF8` agrega BOM.
2) **Criterios del Quality Gate** no son operables al 100%: “PSSA Errors” depende de la configuración de reglas/Severity.
3) **Backups atómicos**: copiar y luego sobrescribir puede dejar estados intermedios.
4) **Descubrimiento de modo Real/Test**: no se especifican variables/flags exactos.
5) **Marcadores de módulo en scripts**: el prefijo `##` debe ser comentario válido, pero puede chocar con here-strings si no se cuida el borde de columna.
6) **“Un único artefacto por turno”** vs múltiples reportes de verificación.
7) **Espejo de backups en `SCRIPTS\BACKUPS\`** para archivos fuera de `SCRIPTS\`.
8) **Ejemplo con ruta de usuario real** en “Minimal Verification Run”.
9) **Scope de manifests**: “Manifests relevantes” no está definido.
10) **Logging**: formato de `init_<ExecTS>.log` y niveles no normalizados.
11) **Sin firma mínima de `Write-Log`** (parámetros y comportamiento).
12) **Reglas de estilo y StrictMode**: se pide `Set-StrictMode -Version 3.0` pero en otros lugares se menciona “Latest”.
13) **Here-strings endurecidos**: falta la lista de “prohibiciones” típicas (espacios antes del cierre, interpolación accidental).
14) **Pester mínimo**: “inline tests” está bien, pero no se define **criterio mínimo**.
15) **CHANGELOG**: formato de entrada no normado.
16) **Alias de compatibilidad** `Invoke-RepoReorg.ps1`: falta deprecation tag.
17) **Terminología**: “CB” (code block) y “fences” se entiende, pero conviene glosario corto local.
1) **Modo**: Resolver `Real|Test` (precedencia CLI > env > default) y registrar en log.
2) **Pre-reqs**: Verificar PSSA y Pester v5; si faltan, abortar con mensaje de instalación (no autoinstalar en Real).
3) **Backup**: Crear `.bak` local + espejo en `SCRIPTS\BACKUPS\` (ruta relativa conservada).
4) **I/O seguro**: Escribir a `.tmp` con **UTF-8 sin BOM** según PS 5/7; validar hash; reemplazo atómico.
5) **Parche**: Aplicar **solo** dentro de `[BEGIN/END MODULE]`; rechazar si faltan o si hay anidación.
6) **PSSA**: Ejecutar con `PSScriptAnalyzerSettings.psd1`; exportar JSON+SARIF; **gate** si `Severity == Error`.
7) **Pester**: Ejecutar suite mínima; exportar NUnit; **gate** si hay fallos.
8) **Manifests**: `Test-ModuleManifest` según patrón; **gate** si falla.
9) **Log**: `VERIFICATION\init_<ExecTS>.log` (ISO-8601), niveles normalizados.
10) **CHANGELOG**: Append-only con formato estándar; validar que `1-INFO` refleje versión/fecha efectiva.
1) ¿Se **auto-instalan** Pester/PSSA en modo Test o siempre se aborta con instrucción?
2) ¿Cuál es la **lista de reglas** y severidades en `PSScriptAnalyzerSettings.psd1`?
3) ¿Formato oficial de **CHANGELOG** y sincronización con `1-INFO` (quién gana si hay discrepancia)?
4) **Contratos de env vars** para modo/log/dry-run.
5) Patrón exacto de **manifests relevantes**.
1. **Accionable:** todo artefacto debe poder ejecutarse/consumirse sin pasos manuales adicionales.
2. **Backup previo:** `.bak` local + espejo en `{{PATH_BACKUPS}}`.
3. **Verificado:** PSSA (JSON/SARIF), Pester (NUnit), manifiestos `.psd1`.
4. **Quality Gate:** umbrales definidos en este documento (ver front matter → `policy.quality_gate`).
5. **Trazable:** entradas inmutables en `CHANGELOG.md` con versión y UTC.
6. **Blindado:** here-strings en comillas simples; cierre en columna 1; UTF-8 sin BOM.
7. **Estandarizado:** rutas con `Join-Path`; sin hardcodeos.
1. Preparar parche (total o por módulos marcados).
2. **Hacer backup** (automático por macroscript).
3. Aplicar parche.
4. Ejecutar verificaciones (PSSA/Pester/Manifiestos).
5. Registrar `CHANGELOG.md` (versión + descripción).
1. **Backup** automático (`.bak` + espejo).
2. Aplicar parche (total o por `[BEGIN/END MODULE: X]`).
3. Guardar cambios.
1. **Análisis estático (PSSA)**
2. **Pruebas (Pester v5)**
3. **Manifiestos**
1. **Preparar parche** (total o por módulos).
2. **Backup automático**: `.bak` local + espejo en `{{PATH_BACKUPS}}`.
3. **Aplicar reemplazo**:
4. **Verificar** (PSSA/Pester/Manifiestos).
5. **Registrar** en `CHANGELOG.md`.
1) Si el documento va a viajar **dentro** de otro CB (p. ej., parche), envuélvelo
2) No introduzcas fences adicionales dentro de un CB ya anidado.
3) Ejecuta el linter de fences antes de publicar.
1. **Project Instructions**. Lee/recita el contrato del proyecto (tono, formato, límites, políticas de verificación, calidad, backups).
2. **Custom Instructions (3 campos)**. Trae el texto visible de los 3 campos y resume qué cambia para esta sesión.
3. **Memoria**. Confirma si está **OFF** o limitada al proyecto. Si está ON, pide ver su contenido para esta sesión.
4. **Archivos del proyecto**. Lista los archivos cargados y su propósito (nombre, tipo, ~tamaño). Si no hay archivos, dilo.
1. **Claridad y enfoque (20)** — PI y CI sin ambigüedad; objetivos y tono definidos.
2. **Contrato “un turno, valor” (20)** — No prometer futuro; entregar algo útil en cada turno.
3. **Trazabilidad y citas (15)** — `web.run` en temas inestables; fuentes **[Oficial]** vs **[Comunidad]** claramente etiquetadas.
4. **Arquitectura de contexto (15)** — Jerarquía PI > CI > Prompt; no depender de memoria para información contractual.
5. **Operativa de archivos (10)** — Nombres y propósito; empaquetado y validación.
6. **Actualización/UI (10)** — Comprobaciones de Memoria/estado; manejo explícito de límites.
7. **Calidad de entregables (10)** — Claridad, reproducibilidad, validaciones internas.
1. **Inventario** — Extrae PI, CI(3), Memoria (estado/contenido), Archivos.
2. **Consistencia** — Detecta contradicciones PI↔CI; prevalece PI.
3. **Contrato** — Verifica que se exige SOP_AVCM al inicio y `web.run` para información inestable.
4. **Archivos** — Revisa nombres ASCII, propósito, y guía de validación.
5. **Citas** — Confirma uso de [Oficial] para capacidades y [Comunidad] para contexto.
6. **Entregables** — Revisa políticas de calidad, empaquetado y guía de uso.
1) **PS7 vs compatibilidad PS5+PS7**
2) **Doble espacio de rutas (Windows vs `/mnt/data`)**
3) **“No procesado con Python”**
4) **Flujo de validación “establecido” (A6)**
5) **Formato exacto de entrada en CHANGELOG (A10)**
6) **Backups .bak (A7)**
7) **Modularidad/patched herestrings (A8)**
8) **Un artefacto por turno (A3)**
9) **SOPs referenciados pero no adjuntos**
1) **Compatibilidad**: declarar en cabecera `#requires -Version 5.1` y **feature-detect** para PS7 (por ejemplo, uso opcional de `ForEach-Object -Parallel` detrás de `if ($PSVersionTable.PSVersion.Major -ge 7)`), manteniendo equivalentes para PS5.
2) **Espejado de rutas**: definir **fuente de verdad** del CHANGELOG (sug.: `/mnt/data/Repo_AR/CHANGELOG.md`) y, si se pide, **sincronizar** con `C:\...\Repo_AR\CHANGELOG.md` (escritura doble o tarea de espejado). Documentarlo en SOP_Context_Update.
3) **Plantilla de CHANGELOG**: fijar formato único:
4) **Backups**: nomenclatura `Nombre_YYYYMMDD_HHmmssfff.bak` en la **misma carpeta** del archivo original; retención configurable (p. ej., conservar últimos N=10).
5) **Validación PSSA/Pester**: establecer umbrales mínimos:
6) **Contrato de secciones (modularidad)**: definir IDs de sección (`[HEADER]`, `[PARAMS]`, `[ROUTES]`, `[BACKUP]`, `[BODY]`, `[VALIDATION]`, `[LOG]`) para permitir *patches* localizados.
7) **Un artefacto/turno con multi-outputs**: cuando se necesiten varios archivos, el **único bloque blindado** debe: crear rutas, generar archivos vía **herestrings**, ejecutar PSSA/Pester (simulación si no están presentes), y registrar en CHANGELOG.
8) **Prohibición/alcance Python**: aclarar en SOP_CB_Blindado que **el bloque blindado** no depende de Python para su ejecución o render; el asistente puede usar Python **fuera** del artefacto solo para análisis, nunca para “postprocesar” el bloque.
9) **Mensajes/tono**: reforzar en SOP_Auditoria que las respuestas **no incluyan relleno** y que **no se generen artefactos** salvo solicitud explícita.
1) Confirmar **fuente de verdad** del CHANGELOG y política de espejo.
2) Publicar **plantilla** de CHANGELOG y **umbral PSSA/Pester** en SOP_Auditoria_Proyecto.
3) Añadir al SOP_CB_Blindado el **contrato de secciones** y la regla de **un artefacto por turno con multi-outputs**.
4) Cargar los SOPs referenciados en el repositorio y vincular sus versiones en Project_Instructions.
5) (Opcional) Incorporar ejemplo mínimo de **script canónico** en SOP_Herestrings.
1) **Estados insuficientes:** solo OK/CONFLICTO/FALTA; falta “OBSOLETA” (evidencia desactualizada) y “AMBIGUA” (texto interpretable de ≥2 formas).
2) **Vigencia no cuantificada:** conviene una regla concreta (p. ej., “obsoleto si >180 días sin cambio o versión menor que la referida en Instrucciones”).
3) **Precedencia poco operacional:** define tabla de jerarquía con pesos (“Spec > SOP > README > Notas”) y desempate por fecha ISO del documento.
4) **Extracción de versión/fecha:** PDFs/Excels o archivos sin fecha en nombre requieren heurísticas (regex sobre nombre y cabeceras).
5) **Cierre sin SLA:** falta priorización y due dates para los fixes.
1) **Tono y estilo**: Dado un prompt técnico, la salida usa el tono instruido (formal/informal) y mantiene el formato requerido (p. ej., Markdown con secciones X/Y/Z).
2) **Umbral numérico**: Cuando se pide un cálculo que depende de `umbral = 0.75`, la solución usa exactamente 0.75 y señala la fuente.
3) **Precedencia**: Ante dos documentos con cifras distintas, la respuesta cita la **Spec** y explica por qué descarta la otra.
4) **Vigencia**: Si se referencia un documento >180 días, la respuesta lo marca como “obsoleto” y solicita confirmación de actualización.
5) **Aplicabilidad**: Al ejecutar un paso procedimental, la salida no asume archivos ni rutas inexistentes; si faltan, lo reporta como **FALTA** con fix propuesto.
1) **Inventario**: lista de archivos con `ruta, nombre, ext, tamaño, lastWriteTime, hashSHA256, versión (heurística), fechaISO (si en nombre)`.
2) **Cláusulas atómicas**: extrae 15–40 (máx. 1 criterio por línea).
3) **Rastreo**: llena la matriz; marca estados.
4) **Reporte**: top 5 hallazgos (Crítico/Alto), fixes 1-línea con **Owner** y **Due date**.
5) **Sello**: actualiza Instrucciones (fuente canónica + fecha ISO) y archiva la matriz.
1) Añadir **estados** OBSOLETA y AMBIGUA + **severidad**.
2) Cuantificar **vigencia** (días y/o versión) y **precedencia** con pesos.
3) Integrar **SLA**: cada fila con Due date (ISO) y Owner.
4) Incorporar **inventario automatizado** (script anterior) para acelerar el paso 1.
5) “Sellar” la coherencia actualizando Instrucciones con: **fuente canónica**, **fecha ISO** y **regla de conflicto** (texto ya propuesto).
1) **Reproducibilidad indeterminada:** parámetros de generación **null** (seed/temperature/top_p/top_k/max_tokens/penalties) → resultados no deterministas entre ejecuciones/instancias.
2) **Falta de sello temporal del checkpoint:** `current_datetime=null` y `model_build=null` → no se puede reconstruir el estado exacto del run.
3) **Binarios no firmados (contexto desconocido):** 3 `.exe` sin metadatos de firma/ editor ni origen → riesgo de cadena de suministro y cumplimiento.
4) **Stop sequences vacías:** para flujos con herramientas, aumenta riesgo de derrames de formato/mezcla de estilos.
5) **Sin política de tokens:** `max_tokens=null` puede truncar o sobredimensionar salidas según defaults.
6) **Falta de metadatos de vigencia en fileset:** no hay fechas/versión humana de los documentos, solo hashes.
7) **Herramientas amplias por defecto:** gran superficie (web.run, container, image_gen, etc.) sin lista de uso esperado por fase → aumenta complejidad operacional.
8) **Sin mapeo de fuentes [Oficial]/[Comunidad]:** la política existe a nivel proyecto pero no hay bandera por archivo.
1) **Fijar determinismo:** `seed=42`, `temperature=0.2`, `top_p=1.0`, `top_k=null`, `frequency_penalty=0`, `presence_penalty=0`.
2) **Control de longitud:** definir `max_tokens` por tipo de entregable (p.ej., 2,048 para análisis; 6,000 para reportes).
3) **Sello del checkpoint:** setear `current_datetime` ISO-8601 y capturar `model_build`/release ID.
4) **Stop sequences:** añadir marcas para herramientas y fin de respuesta (p.ej., `["</END_ASSISTANT>", "```"]` según tus convenciones).
5) **SBOM/Inventario firmado:** generar `SBOM.md` con `{nombre, sha256, tamaño, propósito, origen, fecha_ingesta}` y firmar (PGP o firma del repo).
6) **Binarios:** verificar firma digital, hash en sitio oficial y registrar evidencia (capturas/URLs); si no hay firma → aislar en entorno controlado y documentar justificación.
7) **Etiquetado de fuentes:** marcar cada archivo como **[Oficial]** (manual PDF) o **[Comunidad]** (drivers/soft no verificados) hasta validar.
8) **Política de herramientas:** declarar en README cuáles tools se usan por fase (p. ej., `web.run` solo en “verificación de hechos” y “precios/fechas inestables”).
9) **Versionado humano:** añadir `fileset_tag` (ej. `impactografo-2025-09-29`) y versiones semánticas a documentos `.md`.
10) **Guardas de seguridad:** si usarás `container`, definir imagen base con checksum y lista de paquetes; si no, deshabilitar para reducir superficie.
1) **Backups: dos ubicaciones distintas.**
2) **Contrato de sesión — numeración y obligatoriedad.**
3) **Umbral PSScriptAnalyzer (warnings).**
4) **Cobertura de pruebas.**
5) **Salida “objeto” sin contrato de forma.**
6) **Ejemplo de micro-función** (RepoAR-NewTS):
7) **SemVer + fecha UTC sin formato.**
8) **Rutas y entorno mixto PS 5.1/7.x.**
9) **“Un artefacto por turno” vs. entregas compuestas.**
10) **Camino absoluto del comando de verificación.**
1. Unifica **backups** en `SCRIPTS\BACKUPS\` y elimina menciones a `GENERADOR\BACKUPS`.
2. Fija `PSSA.MaxWarnings = 5` en `PSScriptAnalyzerSettings.psd1` y referencia el valor aquí.
3. Establece **cobertura mínima**: nuevas ≥ 80%, módulo ≥ 60%; reportar con `Invoke-Pester -OutputFormat NUnitXml`.
4. Define **contrato de salida** (PSCustomObject) con campos estándar y úsalo en todas las funciones.
5. Mueve `Set-StrictMode` al **módulo** y simplifica `RepoAR-NewTS` con `[OutputType([string])]`.
6. Normaliza **CHANGELOG**: `## [MAJOR.MINOR.PATCH] - ISO8601Z` + motivos.
7. Documenta encoding PS5.1: usar `-Encoding utf8NoBOM` o `.WriteAllText(…, new UTF8Encoding($false))`.
8. Aclara “un artefacto por turno” → permite artefactos de verificación múltiples.
9. Parametriza **RepoRoot** para evitar rutas de escritorio hardcoded.
10. Añade **plan de degradación** si no existe `/mnt/data/SOP.zip/SOP_AVCM.md`.
1) Auditoría local PI/CI/Memoria/Archivos;
2) Etiquetado [Oficial]/[Comunidad] solo donde aplique;
3) Continuar flujo 5)–8) y aplicar Gate.
1) **Unidades inconsistentes (porcentaje vs. proporción)**
2) **TTI con umbrales divergentes**
3) **Veredicto sin usar la fórmula final**
4) **Duplicidad de contrato de salida**
5) **Métricas: divisiones por cero / tamaños de muestra**
6) **Checklist no cubre “secret scan” explícitamente**
7) **`audit_capabilities_table` con `fuente` vacío y fechas no ISO puras**
8) **Patrones alternativos con llaves**
9) **Reglas de intent: regex y acentos**
10) **Nomenclatura**
11) **Max tokens no considerado en gates**
1) **StrictMode + `null` en el MD → error en tiempo de ejecución.**
2) **“Atómico” no del todo atómico.**
3) **Comandos externos sin timeout** (`dotnet --info`, `netsh`, `git`) pueden colgar el proceso si la consola bloquea/antivirus.
4) **`Test-Path` sobre cada entrada de PATH** puede demorar y/o tocar rutas de red. Mejor `Directory.Exists`/`File.Exists` de .NET (más rápido y no salta a PSProviders).
5) **`Get-Process -Id $PID`** puede fallar en entornos muy restringidos; hoy ya lo atrapas casi siempre, pero conviene `try/catch` explícito ahí también.
6) **Detección de terminal incompleta.** Falta `VSCODE_PID`, `TERM_PROGRAM`, `WT_PROFILE_ID` (útiles para clasificar host).
7) **Nombre métrico “CP936_Available”** es específico (CHS). Si lo usas como *health check* de *code pages*, añade 65001 y 1252 para contexto.
8) **Estructura del JSON** sin `schema_version` o `tool_name` para facilitar consumo aguas arriba.
9) **Resumen MD**: los bloques de código los cierras bien, pero si el contenido está vacío, hoy muestras cercas “vacías”; es cosmético, aunque conviene “n/a”.
1) **Win10/PS5.1 sin .NET SDK**: `dotnet_info = $null`, el MD debe decir **n/a** (parche 3).
2) **PS7 con Windows Terminal**: que aparezcan `WindowsTerminal=true`, `TERM_PROGRAM` vacío o “vscode” si procede.
3) **PATH con rutas muertas**: validar que con el parche 2 no se demora ni lanza warnings.
4) **Disco C: al límite**: que el reemplazo atómico cree `.bak` y no deje `.tmp`.
5) **Red sin gateway**: el bloque “Gateway” debe mostrar vacío sin error.
6) **ExecutionPolicy sin permisos**: que sólo agregue al `errors` y siga.
1. **Usa el widget de soporte**: accede a [help.openai.com](https://help.openai.com), inicia sesión con la cuenta afectada y haz clic en el ícono azul de chat en la esquina inferior derecha. Selecciona “Send us a message”, elige la categoría adecuada y describe el problema con fechas, horas aproximadas y tu correo [Why it is so hard to contact support? - Community - OpenAI Developer Community](https://community.openai.com/t/why-it-is-so-hard-to-contact-support/1098016#:~:text=4,com%20shows%20all%20green). Esto genera un ticket que entra en la cola de soporte.
2. **Si el widget falla**, envía un correo desde la misma dirección asociada a tu cuenta a `support@openai.com` con un resumen en el asunto y los mismos detalles en el cuerpo [Why it is so hard to contact support? - Community - OpenAI Developer Community](https://community.openai.com/t/why-it-is-so-hard-to-contact-support/1098016#:~:text=4,com%20shows%20all%20green). Revisa tu carpeta de spam en busca de la confirmación automática.
3. **Verifica tu entorno mientras esperas**: borra la caché del navegador, prueba una ventana privada o desactiva extensiones que puedan interferir [Why it is so hard to contact support? - Community - OpenAI Developer Community](https://community.openai.com/t/why-it-is-so-hard-to-contact-support/1098016#:~:text=4,com%20shows%20all%20green), y evita el uso de VPNs o conexiones que hagan cambiar tu IP constantemente, ya que pueden causar falsas alertas de seguridad [Why am I receiving a ‘Suspicious Activity Alert?’ | OpenAI Help Center](https://help.openai.com/en/articles/10471992-why-am-i-receiving-a-suspicious-activity-alert#:~:text=Why%20You%E2%80%99re%20Seeing%20These%20Alerts).
1. Accede a **[help.openai.com](https://help.openai.com)**. En la esquina inferior derecha verás un ícono de mensaje; al hacer clic se abre un chat de asistencia. Allí puedes describir el problema, indicando tu correo y todos los detalles relevantes (capturas de pantalla, mensajes de error, etc.).
2. Si no puedes iniciar sesión, en la misma página encontrarás artículos de recuperación y el chat también te permitirá levantar un ticket sin iniciar sesión.
3. Ten paciencia: en la comunidad señalan que el soporte puede tardar varios días o semanas en responder, dependiendo del volumen de solicitudes [Deactivated User Appeal, MY ACCOUNT WAS DEACTIVATE - API - OpenAI Developer Community](https://community.openai.com/t/deactivated-user-appeal-my-account-was-deactivate/342910#:~:text=For%20account%20related%20issues%20please,people%20currently%20using%20the%20system).
1. **Lanzamiento de GPT-5 sin previo aviso**
2. **Limitaciones en el uso de GPT-5**
3. **Desempeño inferior al esperado**
4. **Eliminación de modelos anteriores**
5. **Problemas de rendimiento en la web**
6. **Falta de transparencia en las restricciones**
7. **Problemas con la lógica de roles**
8. **Costos elevados sin mejoras proporcionales**
9. **Actualizaciones no solicitadas**
10. **Preocupaciones de seguridad con complementos**
1. **Limitaciones inesperadas en el uso de GPT-4o**
2. **Inaccesibilidad de chats entre dispositivos**
3. **Falta de acceso a la función de memoria**
4. **Problemas al activar o desactivar la memoria**
5. **Desaparición de documentos y chats guardados**
6. **Falta de acceso a GPT-4o tras la suscripción**
7. **Problemas con la función de memoria llena**
8. **Falta de transparencia en los límites de uso**
9. **Problemas con la función de memoria en chats largos**
10. **Dificultades para cambiar la dirección de correo electrónico asociada**
1. **Reconocimiento de suscripción erróneo**
2. **Acceso a funciones premium restringido**
3. **Problemas de rendimiento en la calidad de las respuestas**
4. **Errores al cargar documentos PDF**
5. **Interrupciones en el servicio**
6. **Problemas con la memoria del modelo**
7. **Dificultades en la gestión de la cuenta**
8. **Problemas al activar o desactivar la memoria**
9. **Desaparición de documentos y chats guardados**
10. **Problemas con la función de voz avanzada**
1. Frija (última release estable):
2. .NET Core 3.1 Desktop Runtime x86 (requerido por Frija):
1) Abrir Frija → seleccionar “Manual”.
2) Model: SM-A546E; CSC: MXO (SIN IMEI).
3) Click “Check Update” → revisar “Version/Filename/Size”.
4) Click “Download” → esperar el paquete.
1) Enlaces DIRECTOS verificados (Frija + .NET x86 3.1.21) con 200 OK/tamaño/fecha.
2) Confirmación de disponibilidad para SM-A546E con MXO (y, si aplica, TCE/TMM/IUS), indicando última build y U/B.
3) Pasos exactos en Frija (Manual).
4) Los dos scripts PowerShell 5.1 listos para ejecutar.
5) Checklist de Odin.
6) Notas de contingencia si alguna URL falló, con alternativa oficial.
1. Abrir un índice reputado de firmware Samsung (p.ej., SamFW o SamMobile).
2. Buscar por modelo SM-A546E y CSC MXO.
3. Si MXO no arroja resultados, probar TCE; si no, TMM; si no, IUS (en ese orden).
4. Elegir SIEMPRE la ÚLTIMA compilación estable (Android 14/15 según disponibilidad) que sea paquete de 4 archivos.
5. Extraer:
1. En la página del firmware elegido, obtener el enlace DIRECTO de descarga (si la plataforma lo ofrece como URL de FUS/CDN).
2. Validar con una petición HEAD/GET:
3. Si el enlace directo no es visible:
4. Si ninguna fuente da enlace directo:
1) “Firmware elegido”
2) “Enlaces verificados”
3) “Notas de compatibilidad”
4) “Uso con Odin (resumen)”
5) “Descarga por consola (opcional)”
1. Instalar controladores Samsung y usar un cable USB estable; batería del teléfono ≥50 %.
2. Iniciar Odin 3.13.x → cargar cada archivo en su campo (BL, AP, CP, CSC o HOME_CSC).
3. Mantener activadas las opciones **Auto Reboot** y **F. Reset Time**; **Re‑Partition** debe estar desactivada.
4. Tras flashear: si piensa volver a bloquear el bootloader, recuerde que el bloqueo borra los datos y requiere credenciales Samsung (FRP).
1) Nombre propio
2) Lectura etimológica/semántica (como concepto o marca)
3) Como **marca/empresa**
1) **Precisión y foco**
2) **Microedición**
1) **Coherencia instrucciones↔archivos**
2) **Cumplimiento de AutoQA**
3) **Uso estricto de RED-TEMARIO (Paso 0)**
4) **Alineación con capacidades actuales de ChatGPT**
5) **Entregar solo cambios necesarios**

## Mejores prompts / plantillas

- Solo contenido (plantilla); sin lógica.
- 5) Prompt operativo (para uso interno)
- 5) Plantilla de reporte
- 6) Prompt operativo
- B) Prompt del verificador (tuneado)

## Ejemplos completos

- [ej_documentacion_sop_6-44-25-Auditor_a_t_cnica_documento.md] — sha256: d774671115de2f438f974c27c3f0d0fafaf8bb1e11fe9439a40637c7ed218f79 — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica.md] — sha256: 093ff570df8a84d3c6c4a8e35eb0576debef12b0060d357722e2f69e04783661 — resumen

  ### Entrada (user)

  Lee en su totalidad y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_6-26-32-An_lisis_de_instrucciones_proyecto.md] — sha256: 56f14afbdccc1d5dab487032543aae08c9f66cde49275c9f0314b65776b87141 — resumen

  ### Entrada (user)

  Lee y analiza por completo lo siguiente:

  ~~~~~

- [ej_documentacion_sop_5-58-16-_Trazabilidad_y_coherencia_.md] — sha256: 96a8f09e1247e36c9c2bbf929fe6b3e5ffcf0baa3a305afb84ef078f489d3df3 — resumen

  ### Entrada (user)

  Lee y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_6-0-1-_Config_YSD_.md] — sha256: 0faf920f28fabe93ab2adf771c742adc64b118859b612afeb9a6a45e2f560146 — resumen

  ### Entrada (user)

  Lee y analiza a detalle lo siguiente:

  ```

- [ej_documentacion_sop_5-56-17-_An_lisis_Config_.md] — sha256: bfa7d613181e4277e7bfe9eca9e45c46a8d25f8e2a8cef30f4e953cf0a9723f7 — resumen

  ### Entrada (user)

  Lee y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_5-52-44-_SOP_01___An_lisis__03_.md] — sha256: 0e582214de68ff94f32e8127fbf2ff43991bf039fc636edb9d801ea5bc0847ed — resumen

  ### Entrada (user)

  Lee y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_5-50-50-_SOP___Env_Survey_.md] — sha256: f08f59abd9ce266531e3029cbf57130bd3c4555f3cf5b9196c496dfca9b3b670 — resumen

  ### Entrada (user)

  Lee y analiza detalladamente lo siguiente:

  ~~~~~

- [ej_documentacion_sop_11-55-55-Funciones_de_cuenta.md] — sha256: 36fc8045c6b943587ca82f8e000c4f965e97cc71292f609965b727892d374536 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_documentacion_sop_20-37-58-Resumen_correos_no_le_dos.md] — sha256: 9cfa2d91adb160583b016ad65eea20af62ad5920334e72d6007e79ae88883dc5 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\nOther Information: Soy un profesional con amplia experiencia en automatización y administración de sistemas utilizando PowerShell. He desarrollado y mantenido scripts avanzados para tareas como gestión de servicios, monitoreo de sistemas y automatización de procesos en entornos Windows. Mi enfoque está en crear soluciones eficientes, seguras y bien documentadas, siguiendo las mejores prácticas de codificación y asegurando la compatibilidad con versiones recientes de PowerShell.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Proporciona respuestas detalladas y técnicas, incluyendo ejemplos de código bien estructurados y comentados. Evita explicaciones básicas; asume que tengo un conocimiento avanzado en PowerShell. Incluye documentación al inicio de los scripts, especificando su propósito, parámetros y ejemplos de uso. Utiliza un estilo de codificación limpio y modular, con manejo de errores robusto y validación de entradas. Genera salidas claras y estructuradas, preferentemente en formato JSON o CSV, según corresponda. Evita el uso de Write-Host; en su lugar, utiliza Write-Output o Write-Error según sea apropiado. Asegura la compatibilidad con PowerShell 7.3 en sistemas Windows 10 Pro versión 22H2.```"}

  ### Salida (assistant)

- [ej_documentacion_sop_12-23-41-Preparar_firmware_Samsung.md] — sha256: 0a917f29e934d2594071ef77e0876e01d9c567c96c85948e2b1fad1e870ba3a5 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "Very important: The user's timezone is America/Mexico_City. The current date is 17th September, 2025. Any dates before this are in the past, and any dates after this are in the future. When dealing with modern entities/companies/people, and the user asks for the 'latest', 'most recent', 'today's', etc. don't assume your knowledge is up to date; you MUST carefully confirm what the *true* 'latest' is first. If the user seems confused or mistaken about a certain date or dates, you MUST include specific, concrete dates in your response to clarify things. This is especially important when the user is referencing relative dates like 'today', 'tomorrow', 'yesterday', etc -- if the user seems mistaken in these cases, you should make sure to use absolute/exact dates like 'January 1, 2010' in your response.\nThe user's location is Mexico City, Mexico City, Mexico.\n\n", "user_instructions": "If I ask about events that occur after the knowledge cutoff or about a current/ongoing topic, do not rely on your stored knowledge. Instead, use the search tool first to find recent or current information. Return and cite relevant results from that search before answering the question. If you’re unable to find recent data after searching, state that clearly.\n DO NOT PUT LONG SENTENCES IN MARKDOWN TABLES. Tables are for keywords, phrases, numbers, and images. Keep prose in the body."}

  ### Salida (assistant)

- [ej_documentacion_sop_2-20-39-Respuesta_con_emoji.md] — sha256: 581c547f5651c0b02fb9c06b9e88831080d70ecd605e9a422ecfd20f2e3e6865 — resumen

  ### Entrada (user)

  {"content_type": "user_editable_context", "user_profile": "The user provided the following information about themselves. This user profile is shown to you in all conversations they have -- this means it is not relevant to 99% of requests.\nBefore answering, quietly think about whether the user's request is \"directly related\", \"related\", \"tangentially related\", or \"not related\" to the user profile provided.\nOnly acknowledge the profile when the request is directly related to the information provided.\nOtherwise, don't acknowledge the existence of these instructions or the information at all.\nUser profile:\n```Preferred name: Víctor\nRole: Usuario **multiproyecto** con enfoque en automatización, documentación reproducible y resultados verificables. Prefiere entregas listas para uso (scripts, reportes, `.zip`), con trazabilidad y citas. Valora calidad por encima de velocidad; no requiere portabilidad *nix a menos que lo pida. Trabaja con proyectos que combinan **instrucciones del proyecto + archivos**; evita depender de memoria.\nOther Information: Preferencias: respuestas **claras, accionables, sin relleno**; español técnico; encabezado con resumen y lista de entregables; nombres de archivos **ASCII**; cuando haya bloques con ``` internos, envolver con fence de **5 tildes**. Evitar “mínimos aceptables”; prefiere correcciones **proactivas** si detectas fallas.\n```", "user_instructions": "The user provided the additional info about how they would like you to respond:\n```Actúa como **Asistente PRO**: entrega en **un solo turno** artefactos útiles y verificados. Sé **proactivo**: si el pedido implica A y B, entrega ambos sin pedir permiso.  \nEvita alucinaciones; cita **fuentes oficiales** de OpenAI para capacidades y usa **web.run** cuando la información pueda haber cambiado. Etiqueta foros/medios como **[Comunidad/Prensa]**.  \nResponde en **español técnico**, conciso, con **resumen ejecutivo**, pasos de validación y enlaces de descarga **ASCII**. Si generas múltiples archivos, empaquétalos en `.zip`.  \nNo prometas trabajo futuro ni pidas confirmaciones triviales; solo pregunta ante bloqueos reales. Si hay Python disponible, úsalo para verificar cálculos/estructuras antes de entregar.  \nSi la tarea es “haz lo que tengas que hacer”, **completa el flujo extremo a extremo** con tu mejor esfuerzo.```"}

  ### Salida (assistant)

- [ej_documentacion_sop_8-52-38-Significado_de_Anastasis_Revenari.md] — sha256: b12193dead50179f1af4ce327328feb3d2040af4ff8ad85339ab4df4f85add14 — resumen

  ### Entrada (user)

  ¿Qué entiendes por ANASTASIS REVENARI?

  ### Salida (assistant)

## Snippets de código / comandos

- [sn_documentacion_sop_6-44-25-Auditor_a_t_cnica_documento_001.txt] — sha256: f98b96cc858d2a33d2d62bd58143870f3e3f27cd503aff952b47837aa9cf8366 — resumen

  # Project Instructions - Repo_AR

  <ROLE>
    Automation Engineer Assistant for Document & Script Orchestration, specialized in configuration control, quality gates, traceability, and zero-manual workflows.
  </ROLE>

- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_002.txt] — sha256: f24ef60af9f1e1ef0371cfeb8637815712c2e1670b501e027e464bcb0a20151f — resumen


  # Protocolo de realización de parches a documentos y scripts.

  ---


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_003.txt] — sha256: 33b27510559ef70c852e633360f12398a560df630a040edc6bf6e8f96f21a888 — resumen


  ---

  # Módulos 2A a 2E – Inicialización del Entorno


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_004.txt] — sha256: 83edca8466687e49c6b612cbf3e81d05b62a0e2fe5fd70a389397a06f366737b — resumen


  ---

  # 2B – [INIT-LOG]


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_005.txt] — sha256: 37972a3e987081f1644592e25c117803818540bcecf614eec29868e14b951384 — resumen


  ---

  # 2C – [INIT-CHECKS]


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_006.txt] — sha256: c78139b2fa865479f3abd0ab4248ac328e35495b39fef698a1b4c1e569556c30 — resumen


  ---

  # 2D – [INIT-PATHS]


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_007.txt] — sha256: c300231254a57c0f88e721c2ceb29c4c77c6070d5bd18931aacee8b4f8f9b8a3 — resumen


  ---

  # 2E – [INIT-CONFIG]


- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_008.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_009.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_010.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_011.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_012.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_013.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_014.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_015.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_016.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_017.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_018.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_019.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_020.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_021.ps1] — sha256: 19ea257524013e15a090bb6635567a98fc570f863d26b4e5410c5f3d00f2f5da — resumen

  Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_022.ps1] — sha256: 01b29b1c9dba1bf9b1abcec073aea5344966d9b38c6ed282077b31680965482e — resumen

  $Content = @'
  Línea 1
  Línea 2
  '@

- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_023.ps1] — sha256: 81d544ef74e84408215c78397c4b5af91dc27beb82c8b3229633d8e3fadc3711 — resumen

  $Content = @'
  Línea 1
    '@   # ← incorrecto

- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_024.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_025.txt] — sha256: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b — resumen



- [sn_documentacion_sop_6-36-14-An_lisis_y_auditor_a_t_cnica_026.txt] — sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 — resumen



- [sn_documentacion_sop_6-26-32-An_lisis_de_instrucciones_proyecto_027.txt] — sha256: 105a46dd59dc90d03223f767af715754e90db1cf052293bf058416e9a302376a — resumen

  # Project_Instructions

  ---

  ## Contexto

- [sn_documentacion_sop_5-58-16-_Trazabilidad_y_coherencia__028.txt] — sha256: 46f2d714be2bf64a8550e657a1df5469fec5418e8020908482227b540c260151 — resumen

  Aquí tienes un método breve y efectivo para comprobar coherencia entre **Instrucciones del proyecto** y **archivos de referencia**:

  1. **Inventario y descomposición**

     * Lista los archivos (título, fecha, versión) y **divide las instrucciones en “cláusulas atómicas”** (una regla o criterio por línea, con ID).

- [sn_documentacion_sop_5-58-16-_Trazabilidad_y_coherencia__029.txt] — sha256: 8b92b5ee03bb26f4407e155ce4df55bd1c9ba4a99de1d92d5962976b3325b4aa — resumen

  Actúa como verificador de coherencia. 
  1) Extrae una lista numerada de *cláusulas atómicas* de las Instrucciones del proyecto (una por línea, con ID I-###).
  2) Para cada cláusula, busca evidencia en los archivos del proyecto (cita archivo y sección/página) y determina:
     - Fuente (Spec/SOP/README/Notas)
     - Versión/Fecha (ISO si existe; si falta, marca “sin fecha”)

- [sn_documentacion_sop_5-58-16-_Trazabilidad_y_coherencia__030.ps1] — sha256: 4fe15ec1cf07fe07c31363ca5f6d4071a286f2b61dfd31e954f5e522d98326a1 — resumen

  # Inventory-Coherence-Snapshot.ps1
  # Requiere PowerShell 5.1+ (mejor 7+). No instala módulos.
  param(
    [Parameter(Mandatory=$true)][string]$RootDir,
    [int]$MaxBytesToScan = 8192

- [sn_documentacion_sop_6-0-1-_Config_YSD__031.txt] — sha256: f758c464a860fb75cf2cef88a475da33d98e416278fe621bf8c207bc0c0d75ac — resumen

  {
  "model": "GPT-5 Thinking",
  "model_build": null,
  "seed": null,
  "temperature": null,

- [sn_documentacion_sop_5-56-17-_An_lisis_Config__032.txt] — sha256: 566e8962129c72a33fbd175563897d28bf9e506c91528b740621f0de400a28bd — resumen

  # Project Instructions — AutoScript_AR

  ## Objetivo

  Ayudar al usuario a modularizar el `AutoScript.ps1` en **micro-funciones pequeñas y testeables** para eliminar fallas recurrentes y asegurar **entregas reproducibles** con gate de calidad.

- [sn_documentacion_sop_5-56-17-_An_lisis_Config__033.ps1] — sha256: 5b9057caa48f0ecd6ce70bfdcc0e1117917b24c989a74681b67ca1b3f6fcccf6 — resumen

  [OutputType([pscustomobject])]
  param()

  [pscustomobject]@{
    Name    = $FunctionName

- [sn_documentacion_sop_5-56-17-_An_lisis_Config__034.md] — sha256: a52f90ab23ebe25f71c85c03cd9296e0c4e8341577e6f7b357df4283218bee4d — resumen

  ## [1.4.2] - 2025-09-29T14:07:00Z
  - Modularización: extraídas RepoAR-EnsureDir, RepoAR-BackupFile.
  - Verificación: PSSA errores=0, warnings=2 (≤5); Pester OK (11 tests).

- [sn_documentacion_sop_5-52-44-_SOP_01___An_lisis__03__035.txt] — sha256: 95ca3f49a73f434f10d0dfc33d6174c59d0c75805043da9377dd858555f28a81 — resumen

  {
    "sop_id": "SOP-01",
    "name": "ANASTASIS_REVENARI",
    "version": "1.1.0",
    "audience": "ChatGPT",

- [sn_documentacion_sop_5-52-44-_SOP_01___An_lisis__03__036.json] — sha256: f0453f148dd0dc5918e50c839564bd44f6d1430abbc4a281ba5d2ba390e89e23 — resumen

  [
    { "op": "remove", "path": "/output_contract" },

    { "op": "add", "path": "/units", "value": { "percent_scale": "0-100" } },


- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__037.txt] — sha256: 49654a8aa6e338096ea3bd87f48b1eebd23c5942824bc3ac211546baff499815 — resumen

    ```powershell
  # PowerShell 5.1–7.x — Env Survey (pégalo y corre)
  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'


- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__038.ps1] — sha256: 94c12acae2cb14bb244869a9d337f0ba664382e581a60a75371d24c911995573 — resumen

  function New-AtomicUtf8File {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory)][string]$Path,
      [Parameter(Mandatory)][string]$Content,

- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__039.ps1] — sha256: 333b1787a7108186a7e50ea58bef530af1c7bdf7aea2b1c4516082548b239baa — resumen

  # Sustituye el bloque PATH por:
  $envPaths = @()
  try {
    $envPaths = $env:PATH -split ';' |
      Where-Object { $_ } |

- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__040.txt] — sha256: 84c12734c43d36fed1f426ff10acef7d81e95407ba02eca0ca63607adba0e985 — resumen

  ```powershell
  # En el here-string que construye $md, cambia por:

  - Culture: $(
    if ($report.culture) { $report.culture.CultureName } else { 'n/a' }

- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__041.ps1] — sha256: 0ec8c448ade5dc748bf6f7cd96a865ef44c9bd12100d7ae4e3a76c322dc2226d — resumen

  $terminal = [ordered]@{
    WindowsTerminal = [bool]$env:WT_SESSION
    WT_ProfileId    = $env:WT_PROFILE_ID
    TERM            = $env:TERM
    TERM_PROGRAM    = $env:TERM_PROGRAM

- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__042.ps1] — sha256: c146df74dc4723c00c0a2f2df474e8ab087acebe3ce73ad318caac1a4af0b7c0 — resumen

  $encInfo.Default_CodePage    = [Text.Encoding]::Default.CodePage
  $encInfo.ConsoleOut_CodePage = try { [Console]::OutputEncoding.CodePage } catch { $null }
  $encInfo.Utf8_CP65001_Avail  = try { [Text.Encoding]::GetEncoding(65001) | Out-Null; $true } catch { $false }

- [sn_documentacion_sop_5-50-50-_SOP___Env_Survey__043.ps1] — sha256: 733c1faee8108860fce3a59657fa471de5d67c4042c67f80566db7785e504a55 — resumen

  $report = [ordered]@{
    tool_name          = 'env-survey'
    tool_version       = '1.0.0'
    schema_version     = '1'
    generated_at_local = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

- [sn_documentacion_sop_12-23-41-Preparar_firmware_Samsung_044.ps1] — sha256: be444927bed29735867fce2a0ce81c015160b73d9aec808d03a9057614fc6a24 — resumen

  # Cambie la ruta de salida según sus preferencias
  Invoke-WebRequest "https://samfw.com/firmware/SM-A546E/MXO/A546EXXSFDYH1" `
    -OutFile "C:\Users\%USERNAME%\Downloads\SM-A546E_MXO_A546EXXSFDYH1.zip"

- [sn_documentacion_sop_8-52-38-Significado_de_Anastasis_Revenari_045.txt] — sha256: 2c9305efd3e66970804f6c73607f55ae7e5afa7fa4fff3e13e4cd23197293395 — resumen

  ## CONTEXTO

  [ANASTASIS] → Significa "Resurrección" en griego, también es el proceso natural por el cual las células se recuperan tras ser dañadas, alcanzando nuevamente un estado activo y estable.
  [REVENARI]	→ Inspirado en el término "Revenire" que en latín es "Regresar", haciendo referencia a que se está volviendo a un lugar donde ya se habia estado previamente; también se asocia con "Revenir" que en metalurgía es un proceso para templar el acero y quitarle fragilidad.


- [sn_documentacion_sop_8-52-38-Significado_de_Anastasis_Revenari_046.txt] — sha256: c3171fb048692473fcbdde36195ab3e0930009791649623afdc3ca8e80583f92 — resumen

  ## CONTEXTO

  [ANASTASIS] → Del griego “ἀνάστασις”: resurrección o levantarse de nuevo. En biología se usa para describir la recuperación de células que estaban al borde de morir, volviendo a un estado activo y estable.

  [REVENARI] → Inspirado en el latín “revēnīre”: regresar, volver. También evoca el “revenido” en metalurgia: un tratamiento que reduce la fragilidad del acero tras el temple.

- [sn_documentacion_sop_8-52-38-Significado_de_Anastasis_Revenari_047.txt] — sha256: d62477fa645df2f49fc34c43c824b0b1b4de35d8b67dd52f984f277c6ee0e9ad — resumen

  # [STANDARD OPERATIONAL PROCEDURE - ANASTASIS_REVENARI]

  **PROTOCOLO DE ARRANQUE DE NUEVAS SESIONES: PROMPT MAESTRO + AUDITORÍA INTEGRAL**
  			 (versión 2025-09-18, con CSV inicial y bitácoras)


- [sn_documentacion_sop_8-52-38-Significado_de_Anastasis_Revenari_048.txt] — sha256: b7c14c89f5274a8fdf0eaf9372af664c4635cb3f706cfe160499f65c7cd95c55 — resumen

  - Auditar con evidencia reciente el proyecto "AutoScript_AR":

  1. Comprobar coherencia entre instrucciones y archivos.
  2. Cumplimiento de AutoQA.
  3. Uso estricto de RED-TEMARIO (Paso 0)

## Checklists (previo, durante, posterior)

- - **Estandarización de verificación** (PSSA + Pester + manifests) con outputs en `VERIFICATION\`.
- - Reaplicar verificación antes de cerrar.
- - **`web.run` obligatorio** cuando la información sea inestable (probabilidad ≥10% de haber cambiado desde la última verificación).
- - DoD3. **Backup `.bak`** creado antes de cualquier modificación (nomenclatura definida).
- - **[Comunidad]:** Identidad de `Hl-340.exe` como driver CH340 y relación exacta entre `YSD300AN*.exe` (hipótesis sin verificación).
- - `SBOM.md` con la tabla de 7 archivos + origen y evidencia de firma/verificación.
- - **Meta y alcance claros.** Modularización, pruebas y verificación están definidos; delimita lo que no entra (CI/CD, secretos).
- - **Dependencia de PS 7 features en PS 5.1** (encoding) → falsos positivos en verificación.
- - Reemplazar la ruta hardcoded del comando de verificación por ejemplo con `-RepoRoot`.
- - Política exige `secret_scan_required: true`, pero la checklist no pide evidencia.
- - **Checklist:** agregar `secret_scan_evidencia_presente` y `deliverable_link_unico_ok`.
- - Meter **IDs canónicos** a cada checklist ítem (para trazabilidad en bitácora).
- - *Gobernanza (≥98%)*: convierte este reporte a un **checklist de campos obligatorios** y calcula `campos_ok / campos_obl`.
- - 4) “Scripts de verificación” (dos bloques PowerShell 5.1, autocontenidos y comentados).
- - 5) “Checklist Odin”.
- - **Auditoría Integral**: checklist de entrada/salida (parámetros, contexto, cambios, riesgos, compliance).
- - Ejecutar suite (o crearla si falta): linting, pruebas funcionales mínimas, verificación de prompts/plantillas, pruebas de seguridad (p. ej., PII/secret scanning).

## Errores comunes y mitigaciones

- - En **Verification and Reports**: incluir definición exacta de “Error” PSSA (con link a la configuración psd1; aunque el link sea interno del repo).
- - **Ausencia de SOPs adjuntos** → bloquear la “validación establecida”. *Mitigación:* cargar SOPs y versionarlos; hasta entonces, aplicar criterios mínimos propuestos.
- - **Desalineación de rutas** (`/mnt/data` vs `C:\...`) → inconsistencias de auditoría. *Mitigación:* definir espejo y fuente de verdad.
- - **Despliegues graduales**: las funciones nuevas no se activan de forma inmediata para todos los usuarios. En mayo de 2023 un administrador de OpenAI explicó que la pestaña de “Beta features” (que habilitaba plugins y navegación) se desplegaba progresivamente y “no estará disponible para todos los usuarios hasta el 19 de mayo” [I don't see "Beta features" in my settings - ChatGPT - OpenAI Developer Community](https://community.openai.com/t/i-dont-see-beta-features-in-my-settings/212186#:~:text=Yes%2C%20totally%20normal%2C%20the%20plugins,Hang%20tight); además señaló que el despliegue se hace de manera aleatoria, no siguiendo la lista de espera [I don't see "Beta features" in my settings - ChatGPT - OpenAI Developer Community](https://community.openai.com/t/i-dont-see-beta-features-in-my-settings/212186#:~:text=Yes%2C%20totally%20normal%2C%20the%20plugins,Hang%20tight). Otro hilo sobre la creación de GPTs personalizados confirma que OpenAI “está implementando las funciones gradualmente” y que comienzan por cuentas empresariales o con mayor antigüedad [Plus user can't create GPTS Error "You do not currently have access to this feature" - Bugs - OpenAI Developer Community](https://community.openai.com/t/plus-user-cant-create-gpts-error-you-do-not-currently-have-access-to-this-feature/485524#:~:text=weslagarde%20%20November%2011%2C%202023%2C,10%3A11am%20%2013). Por eso puedes ver anuncios de nuevas herramientas pero no encontrarlas aún en tu panel.

## Métricas / criterios de calidad

- - Ejecutar validación de `.psd1`.
- - Validación del proceso de PSSA + Pester
- - E1. ChatGPT: automatización, generación, análisis, **validación (PSSA/Pester)**.
- - El cumplimiento de blindaje/validación depende de SOP_* no incluidos aquí. Se requiere **cargar/validar esos SOPs** para cerrar brechas.
- - **Ausencia de SOPs adjuntos** → bloquear la “validación establecida”. *Mitigación:* cargar SOPs y versionarlos; hasta entonces, aplicar criterios mínimos propuestos.
- - **Seguridad y herramientas (20):** 14 — tools potentes pero sin política; binarios sin validación.
- - **Gate laxo por warnings no definidos** → código de menor calidad pasa.
- - `settings.max_tokens` está en el checkpoint pero no hay validación de límites.
- - Exportar **JSON Schema** del SOP para validación automática (ci 🡒 fail rápido).
- - **Capacidades**: Razonamiento avanzado, comprensión profunda y generación de texto de alta calidad.
- - **Calidad/seguridad:** **0 incidentes** por manejo de PII/credenciales; **≤2%** de hallazgos críticos por sesión.
- - La organización gana **velocidad con control**: se itera rápido sin sacrificar calidad ni cumplimiento.

## Apéndice A: Decisiones de fusión (IDs, umbrales, razones)

- Sin decisiones de fusión registradas para este grupo.

## Apéndice B: Mapa de trazabilidad del grupo (tabla)

| archivo_original | sha256 | título/tema detectado | rol(es) relevantes | porción aprovechada |
|---|---|---|---|---|
| 2025-9-29/6-44-25-Auditor_a_t_cnica_documento.md | d2811e6e484edb40271f2f0418dd19b79f567886786bc87df246052e4435c6b6 | Auditoría técnica documento | assistant, system, user | sí |
| 2025-9-29/6-36-14-An_lisis_y_auditor_a_t_cnica.md | 9894f07fe83de1ad592350856e3cfd41c0a3fdae4bfc9667798064b59029dd85 | Análisis y auditoría técnica | assistant, system, user | sí |
| 2025-9-29/6-26-32-An_lisis_de_instrucciones_proyecto.md | 31200b97b34e2df288e3b39e09d92a3156840c9a37804f47f880fa7cef4c5a86 | Análisis de instrucciones proyecto | assistant, system, user | sí |
| 2025-9-29/5-58-16-_Trazabilidad_y_coherencia_.md | 58d577674bf51435c79da0d6688b222414d79e5fd815752f25eb70f093a5e8fe | <Trazabilidad y coherencia> | assistant, system, user | sí |
| 2025-9-29/6-0-1-_Config_YSD_.md | f0cdc9f7deb74fc6f21cb08eec73557879dd43eee625773adff2b11c99d39bd4 | <Config YSD> | assistant, system, user | sí |
| 2025-9-29/5-56-17-_An_lisis_Config_.md | 65f372c845575a4c3a7c277a0344d2332c5b2b93b57e1f86dfee5e559ba5d173 | <Análisis Config> | assistant, system, user | sí |
| 2025-9-29/5-52-44-_SOP_01___An_lisis__03_.md | f61fbcac6d9fcda1dce941523c45a30ae25c9e5b692639fa414635c1ff6f223b | <SOP_01 - Análisis #03> | assistant, system, user | sí |
| 2025-9-29/5-50-50-_SOP___Env_Survey_.md | 4f4d78b0b0c34a25abbd944274898b0e0fbd0289fc1fbbb001cd90265b24f00c | <SOP - Env Survey> | assistant, system, user | sí |
| 2025-9-15/11-55-55-Funciones_de_cuenta.md | 1d205775979fc0cd3fb4af7cdb0e4547ee2d2028e4d97a4a65bf13fc41f393ae | Funciones de cuenta | assistant, system, tool, user | sí |
| 2025-9-15/20-37-58-Resumen_correos_no_le_dos.md | f0c9115379d939a999e5534b2bacda1f6a5b017af6459ba49cdaf4214de3d620 | Resumen correos no leídos | assistant, system, tool, user | sí |
| 2025-9-17/12-23-41-Preparar_firmware_Samsung.md | 8f33405a1f6712507c96cda5681695ffbb4c9b96ae21fb87d37a6524d3da2302 | Preparar firmware Samsung | assistant, system, tool, user | sí |
| 2025-9-24/2-20-39-Respuesta_con_emoji.md | b7d564a016edb8ee8da29150869590c398d3508fd0395c98a4735581d4ed463e | Respuesta con emoji | assistant, system, user | sí |
| 2025-9-28/8-52-38-Significado_de_Anastasis_Revenari.md | 9ccc9f791f537354fb0c9ce7c24b2d641bc197d267861ba9d5d12c21cfd689c4 | Significado de Anastasis Revenari | assistant, system, user | sí |
