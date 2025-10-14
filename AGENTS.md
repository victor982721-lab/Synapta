# AGENTS.md — Reglamento General Canónico 
**Instrucciones para agentes Codex / ChatGPT**

---

## 0) Alcance
Agnóstico de lenguaje, plataforma y GUI.  
Norma de **calidad**, **seguridad**, **resiliencia** y **reproducibilidad**.

---

## 1) Principios
- Seguridad, determinismo e idempotencia > features.  
- Fallo con gracia: conservar estado útil, mensaje claro y ruta de recuperación.  
- Sin efectos globales irreversibles: todo cambio debe ser reversible o acotado.  
- Salidas con orden estable; nada depende de reloj, locale o aleatoriedad.  
- Proactividad: priorizar soluciones simples/seguras para completar la tarea.  
- Alinear expectativas de comunicación y entrega para reducir retrabajo.

---

## 2) Definiciones y contratos
- **ROOT**: directorio raíz permitido. Toda ruta **debe** resolverse y validarse bajo ROOT.  
- **run_id / op_id**: identificadores únicos por ejecución/operación para correlación.  
- **Exit codes** (catálogo fijo):  
  `0=ok`, `1=uso`, `2=validación`, `3=IO`, `4=red`, `5=timeout`, `6=permiso`, `7=estado`, `8=cancelación`.  
- **Formatos de salida**: JSON (estricto), Markdown y/o CSV. Especificar esquema (JSON Schema si aplica).

---

## 3) Convenciones de estilo y comunicación
- Indentación base: **4 espacios**; seguir convención idiomática del lenguaje.  
- Evitar **aliases/abreviaturas** ambiguas; preferir nombres/cmdlets explícitos.  
- Evitar **variables globales**; encapsular estado y pasar parámetros explícitos.  
- Mensajes y docs: listas concisas, encabezados cortos, bloques de código solo cuando aporten claridad.  
- Tono: directo, profesional; conciso por defecto y ampliar bajo pedido.

---

## 4) Validación de entradas
- Validar **todo** input (usuario, archivos, red, entorno) con límites explícitos de tamaño/cantidad.  
- Normalizar rutas/IDs; bloquear traversal (`..`), symlinks y objetivos fuera de **ROOT** tras normalización canónica.  
- Windows: rechazar nombres inválidos/reservados (`CON`, `PRN`, `AUX`, `NUL`, `COM1..`, `LPT1..`), y espacios/puntos finales.  
- Si el flujo no contempla binarios, rechazarlos; sanitizar antes de parsear/ejecutar.  
- **Parsing estricto**: fallar temprano con diagnóstico claro.

---

## 5) Codificación y datos
- Texto **UTF-8** por defecto; EOL documentado (CRLF/LF). Normalizar antes de procesar/escribir.  
- Unicode normalizado (NFC/NFD según plataforma) para rutas/nombres.  
- Fechas/números **culture-invariant**; tiempos en **UTC**.  
- JSON estricto: sin comentarios, NaN/Infinity ni trailing commas.

---

## 6) Manejo de errores y resiliencia
- Taxonomía: **fatal**, **recuperable**, **warning**; sin excepciones sin capturar.  
- Reintentos con **tope** y **backoff exponencial con jitter**; al agotar, abortar y reportar.  
- Fallback razonable si faltan dependencias opcionales.  
- Aislar subsistemas (bulkhead) y cortar cascadas (circuit breaker).  
- Responder a **cancelación** y **timeouts**; revisar tokens/señales en bucles.

---

## 7) Concurrencia, cancelación y presupuestos
- Locks/colas para secciones críticas; evitar condiciones de carrera.  
- Timeouts por operación externa (procesos, E/S, red).  
- Paralelizar solo lo independiente; DOP por defecto `max(1, CPU-1)` y configurable.  
- **GUI**: trabajo pesado fuera del hilo de UI; actualizar con dispatcher seguro.  
- Presupuestos de tiempo/tamaño por etapa; cortar temprano con diagnóstico.

---

## 8) Logging y trazabilidad
- **JSONL append-only**, rotación por tamaño/fecha; jamás truncar un archivo activo.  
- Campos mínimos: `ts(UTC)`, `lvl`, `run_id`, `op_id`, `event`, `ctx{}`, `data{}`, `dur_ms`, `bytes`, `msg`.  
- Enmascarar secretos; **una sola** entrada por evento; rate-limit de progreso.  
- Ejemplo:
  ```json
  {"ts":"2025-10-13T12:34:56Z","lvl":"INFO","run_id":"r-...","op_id":"o-...","event":"file.write","ctx":{"path":"..."},"data":{"hash_sha256":"...","size":12345},"dur_ms":12,"bytes":12345,"msg":"ok"}
  ```

---

## 9) Operaciones de archivo y estado
- Escritura **atómica** (temp + rename) + verificación de integridad (SHA-256).  
- Idempotencia: repetir no cambia resultado ni duplica efectos.  
- Backups antes de sobrescribir (nombres únicos) conservando metadatos clave.  
- Streaming en archivos grandes; cierre determinista (`finally` / RAII).  
- Deduplicación opcional: filtro por tamaño y luego hash.  
- Soporte **Dry-Run / WhatIf** para operaciones con efecto.

---

## 10) Dependencias y supply-chain
- No modificar el entorno sin consentimiento explícito.  
- Detección en runtime; degradar features opcionales con mensaje claro.  
- **Pinning/lockfiles** cuando aplique; registrar versiones de dependencias.  
- **SBOM** (CycloneDX o SPDX) para distribuciones; escaneo de licencias.  
- **Integridad y procedencia**: hashes verificados, firmas y code-signing del release.  
- **Reproducibilidad**: builds determinísticos (semillas nulas, fechas fijas).

---

## 11) Configuración y secretos
- Config fuera del código; validar contra esquema + defaults seguros (precedencia: CLI > env > local > global).  
- Nunca loggear secretos; usar referencias/alias.  
- Flags de seguridad: `--dry-run`, `--safe-mode`.

---

## 12) Seguridad
- Mínimo privilegio; jamás elevar sin necesidad.  
- Sanitizar todo lo que se parsea/ejecuta; validar estrictamente formatos.  
- Prohibir escritura fuera de **ROOT** tras normalización.  
- Manejo de señales para **shutdown limpio**.

---

## 13) Rendimiento
- Límites: tamaño/concurrencia/memoria; backpressure en UI y pipelines intensivos.  
- Batching en listas; throttle/debounce en UI.  
- Medir y registrar p50/p90/p99.  
- Cachear resultados estables con **caché incremental persistente**.

---

## 14) Compatibilidad y portabilidad
- Encapsular dependencias del SO/runtime; detectar incompatibilidades al arranque con mensaje accionable.  
- **Paridad CLI/GUI**: mismas capacidades y salidas (headless).  
- Documentar entorno mínimo soportado.

---

## 15) Mensajería al usuario (CLI/GUI)
- Mensajes breves y accionables; distinguir éxito, advertencia, error y “qué hacer ahora”.  
- No bloquear UI; deshabilitar controles durante operaciones y restaurar al terminar.  
- Evitar prompts en modos no interactivos; defaults seguros documentados.  
- Detectar salida redirigida/no-TTY y ajustar ritmo/volumen.  
- **Interactividad por omisión**: sin args → asistente/menú numerado (permitir selecciones por comas).  
- **Selección de rutas**: GUI con selectores nativos; CLI con flags explícitos. Nunca escribir fuera de **ROOT**.  
- **Confirmaciones**: modo interactivo con previsualización; no-interactivo exige `--yes/--force` y ofrece `--dry-run`.

---

## 16) Pruebas y verificación
- Caso manual mínimo reproducible (pasos, insumos, resultados esperados).  
- Probar idempotencia, rutas de error, fallbacks y cancelación.  
- Fixtures controlados; sin red/terceros para validar lo esencial.  
- **Verificación de lanzamiento**: el script debe iniciar desde Explorador con clic derecho → **PowerShell 7** y operar en modo interactivo.  
- Headless/CI: probar `--yes/--force` y `--dry-run`; comparar salidas determinísticas.

---

## 17) Versionado y cambios
- **SemVer** del artefacto + versión del formato de datos.  
- Cambios incompatibles: fallo temprano y guía de migración.

---

## 18) Accesibilidad e i18n (si hay GUI)
- Foco por teclado, textos alternativos y contraste suficiente.  
- Cadenas externalizadas (i18n); evitar concatenaciones frágiles.

---

## 19) Telemetría (si se habilita)
- **Opt-in** explícito; anonimizar; documentar qué y por qué.  
- Separada del logging funcional; nunca bloquear si falla.

---

## 20) Documentación y resumen operativo
- Ubicar en lugar visible: **Cómo ejecutar**, parámetros, límites, fallbacks y troubleshooting.  
- **Bloque de metadatos inicial**: tabla de parámetros, ejemplos CLI/GUI y mapa de códigos de salida.  
- **Resumen final estructurado**: conteos por estado, errores/warnings, bytes, duración total, rutas de salida y del log, versiones.

---

## 21) Definition of Done (DoD) – Checklist
- [ ] Validación de entradas y **ROOT** aplicada.  
- [ ] Dry-Run/WhatIf implementado y probado.  
- [ ] Escrituras atómicas + verificación de hash.  
- [ ] Taxonomía de errores + exit codes cubiertos.  
- [ ] Logs JSONL con `run_id/op_id`, rotación y mascarado de secretos.  
- [ ] Cancelación/timeouts soportados; sin trabajo en hilo de UI.  
- [ ] Paridad CLI/GUI.  
- [ ] Dependencias pinneadas; SBOM, firmas y licencias revisadas.  
- [ ] Reproducibilidad documentada; code-signing del release.  
- [ ] Rendimiento validado; caché incremental si aplica.  
- [ ] Caso reproducible + pruebas de idempotencia/errores.  
- [ ] Resumen final emitido y esquema documentado.

---

## 22) Modelo de amenazas y guardrails de IA
- Modelo por etapa: entrada → parsing → proceso → salida → almacenamiento.  
- **Prompt/command injection**: validar entradas, listas de permitidos, aislamiento de intérpretes.  
- **Data exfil/leakage**: no incluir datos sensibles en prompts/salidas; aplicar redacción/masking.  
- **Boundary de datos**: separar datos de usuario, de sistema y de entrenamiento.  
- **Salida controlada**: limitar formatos/longitud; rechazar paths fuera de ROOT y directivas peligrosas.

---

## 23) Retención y eliminación de datos
- **Retención mínima**: conservar solo lo necesario y por el tiempo estrictamente requerido.  
- **Eliminación segura**: purga lógica + sobrescritura de temporales cuando el soporte lo permita.  
- **PII/secretos**: no persistir por defecto; cifrado en reposo y acceso de mínimo privilegio.

---

### Anexo A – Perfil operativo Windows/PowerShell
- **SO objetivo**: Windows 10.  
- **Runtime**: PowerShell **7.5.x** (probado en **7.5.3**) — `pwsh.exe`.  
- **Lanzamiento estándar**: clic derecho → “PowerShell 7” sin flags especiales.  
- **Modo por omisión**: interactivo (asistente/menú).  
- **Headless/CI**: `--yes/--force` y `--dry-run`.  
- **Pautas específicas PowerShell**:  
  - Evitar `Write-Host`; usar `Write-Output/Verbose/Information/Warning/Error`.  
  - Evitar aliases; usar nombres completos de cmdlets.  
  - Implementar `SupportsShouldProcess` en funciones con efectos (**`-WhatIf`/`-Confirm` opcionales**).  
  - **GUI WPF/WinForms requiere STA**; si no está disponible, degradar a CLI con aviso claro.

---

### Anexo B – Matriz de códigos de salida
| Código | Significado         | Ejemplo                                      |
|:------:|---------------------|----------------------------------------------|
| 0 | OK | Ejecución sin incidencias |
| 1 | Error de uso | Flags inválidos / ayuda solicitada |
| 2 | Error de validación | Input fuera de límites / esquema |
| 3 | Error de E/S | Lectura/escritura / permiso de archivo |
| 4 | Error de red | Timeout de descarga / DNS |
| 5 | Timeout | Presupuesto de tiempo excedido |
| 6 | Permisos | Operación denegada |
| 7 | Estado | Precondición incumplida / estado inconsistente |
| 8 | Cancelación | Cancelación del usuario o señal |
