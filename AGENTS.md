# AGENTS.md — Reglamento General Canónico v1.3  
**Instrucciones para agentes (Codex / ChatGPT / herramientas afines)**

---

## 0) Alcance
Agnóstico de lenguaje, plataforma y GUI. Norma de **calidad**, **seguridad**, **resiliencia** y **reproducibilidad**. Compatible con el formato abierto **AGENTS.md** usado por múltiples agentes y editores.

---

## 1) Principios
- Seguridad, determinismo e idempotencia > features.  
- Fallo con gracia: conservar estado útil, mensaje claro y ruta de recuperación.  
- Sin efectos globales irreversibles; todo cambio debe ser **reversible o acotado**.  
- Salidas con **orden estable** (sin dependencia de reloj/locale/aleatoriedad).  
- Proactividad: resolver con soluciones **simples/seguras**; alinear expectativas para reducir retrabajo.

---

## 2) Definiciones y contratos
- **ROOT**: directorio raíz permitido. Toda ruta **debe** resolverse y validarse bajo ROOT.  
- **run_id / op_id**: IDs únicos por ejecución/operación para correlación.  
- **Exit codes (cerrado)**: `0=ok`, `1=uso`, `2=validación`, `3=IO`, `4=red`, `5=timeout`, `6=permiso`, `7=estado`, `8=cancelación`.  
- **Formatos de salida**: JSON (estricto), Markdown y/o CSV. Documentar **esquema** (JSON Schema si aplica).  
- **Structured Outputs**: cuando se requiera salida estructurada, usar JSON Schema con cumplimiento estricto.

---

## 3) Convenciones de estilo y comunicación
- Indentación base 4 espacios; seguir convención idiomática del lenguaje.  
- Evitar **aliases/abreviaturas** ambiguas; preferir nombres y cmdlets explícitos.  
- Sin **globales**; encapsular estado, pasar parámetros explícitos.  
- Tono: directo y profesional; **conciso por defecto** (ampliar bajo pedido).

---

## 4) Validación de entradas
- Validar **todo** input (usuario, archivos, red, env) con límites explícitos.  
- Normalizar rutas/IDs; bloquear traversal (`..`), symlinks y objetivos fuera de **ROOT** tras normalización canónica.  
- Windows: rechazar nombres inválidos/reservados (`CON`, `PRN`, `AUX`, `NUL`, `COM1..`, `LPT1..`) y espacios/puntos finales.  
- Si el flujo no contempla binarios, **rechazarlos**; sanitizar antes de parsear/ejecutar.  
- **Parsing estricto**: fallar temprano con diagnóstico claro.

---

## 5) Codificación y datos
- Texto **UTF-8**; EOL documentado (CRLF/LF). Normalizar antes de procesar/escribir.  
- Unicode normalizado (NFC/NFD según plataforma) para rutas/nombres.  
- Fechas/números **culture-invariant**; tiempos en **UTC**.  
- JSON estricto (sin comentarios, NaN/Infinity ni trailing commas).

---

## 6) Manejo de errores y resiliencia
- Clasificar: **fatal / recuperable / warning**; sin excepciones sin capturar.  
- Reintentos con **tope** y **backoff exponencial con jitter**; al agotar, abortar y reportar.  
- Fallback razonable si faltan dependencias opcionales.  
- Aislar subsistemas (bulkhead) y cortar cascadas (circuit breaker).  
- Responder a **cancelación** y **timeouts**; comprobar tokens/señales en bucles.

---

## 7) Concurrencia, cancelación y presupuestos
- Locks/colas para secciones críticas; evitar carreras.  
- Timeouts por operación externa (procesos/E/S/red).  
- Paralelizar solo independiente; **DOP** por defecto `max(1, CPU-1)` y configurable.  
- **GUI**: trabajo pesado fuera del hilo de UI; actualizar con dispatcher seguro.  
- Presupuestos de **tiempo/tamaño** por etapa; cortar temprano con diagnóstico.

---

## 8) Logging y trazabilidad
- **JSONL append-only**, rotación por tamaño/fecha; jamás truncar activo.  
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
- Streaming en archivos grandes; cierre determinista (RAII/`finally`).  
- Deduplicación opcional: primer filtro por tamaño, luego hash.  
- Soporte **Dry-Run/WhatIf** para operaciones con efecto.

---

## 10) Dependencias y supply-chain
- No modificar el entorno sin consentimiento explícito.  
- Detección en runtime; degradar features opcionales con mensaje claro.  
- **Pinning/lockfiles**; registrar versiones de dependencias.  
- **SBOM** (CycloneDX o SPDX) y escaneo de licencias para artefactos distribuibles.  
- **Integridad/procedencia**: hashes verificados, firmas y **code-signing** del release.  
- **Reproducibilidad**: builds determinísticos (semillas nulas/fechas fijas).

---

## 11) Configuración, secretos y seguridad de cuenta
- Config fuera del código; validar contra esquema + defaults seguros (precedencia: CLI > env > local > global).  
- Nunca loggear secretos; usar referencias/alias y proveedores seguros.  
- Incluir **safety_identifier** por usuario/sesión en llamadas de API cuando aplique.  

---

## 12) Seguridad (guardrails)
- **Mínimo privilegio**; jamás elevar sin necesidad.  
- Sanitizar **todo** lo que se parsea/ejecuta; validar formatos estrictamente.  
- Prohibir escritura fuera de **ROOT** tras normalización.  
- **Amenazas LLM (OWASP Top-10)**: mitigar **prompt injection**, filtrado de salidas y secretos, supply-chain, agencia excesiva, consumo no acotado, etc.  
- Manejo de señales para **shutdown limpio**.

---

## 13) Rendimiento
- Límites: **tamaño/concurrencia/memoria**; backpressure en UI y pipelines intensivos.  
- Batching en listas; throttle/debounce en UI.  
- Medir y registrar **p50/p90/p99** cuando aplique.  
- Caché de resultados estables con **caché incremental persistente**.

---

## 14) Compatibilidad y portabilidad
- Encapsular dependencias del SO/runtime; detectar incompatibilidades al arranque con mensaje accionable.  
- **Paridad CLI/GUI**: mismas capacidades y salidas (headless).  
- Documentar entorno mínimo soportado.

---

## 15) Mensajería al usuario (CLI/GUI)
- Mensajes breves y **accionables**; indicar “qué pasó” y “qué hacer ahora”.  
- No bloquear UI; deshabilitar controles durante operaciones y restaurar al terminar.  
- Evitar prompts en modo **no interactivo**; defaults seguros documentados.  
- Detectar salida redirigida/no-TTY y ajustar ritmo/volumen.  
- **Interactividad por omisión**: sin args → asistente/menú numerado (permitir selecciones por comas).  
- **Selección de rutas**: GUI con selectores nativos; CLI con flags. Nunca escribir fuera de **ROOT**.  
- **Confirmaciones**: en interactivo, previsualizar; en no-interactivo, exigir `--yes/--force` y ofrecer `--dry-run`.

---

## 16) Pruebas y verificación
- Caso manual mínimo reproducible (pasos, insumos, resultados esperados).  
- Probar idempotencia, rutas de error, fallbacks y cancelación.  
- Fixtures controlados; sin red/terceros para validar lo esencial.  
- **Evals/“evaluation flywheel”** para robustecer prompts y salidas estructuradas.  
- Headless/CI: probar `--yes/--force` y `--dry-run`; comparar salidas determinísticas.

---

## 17) Versionado y cambios
- **SemVer** del artefacto + versión de formatos de datos.  
- Cambios incompatibles: fallo temprano y guía de migración.

---

## 18) Accesibilidad e i18n (si hay GUI)
- Foco por teclado, textos alternativos y contraste suficiente.  
- Cadenas externalizadas (i18n); evitar concatenaciones frágiles.

---

## 19) Telemetría (si se habilita)
- **Opt-in** explícito; anonimizar; documentar qué y por qué.  
- Separada del logging funcional; **nunca bloqueante**.

---

## 20) Documentación y resumen operativo
- Ubicar visible: **Cómo ejecutar**, parámetros, límites, fallbacks y troubleshooting.  
- **Bloque de metadatos inicial**: tabla de parámetros, ejemplos CLI/GUI, mapa de **exit codes**.  
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
- [ ] Evals automáticas para prompts/salidas estructuradas.

---

## 22) Prompt & Agent Patterns (mejores prácticas)
- **Instrucciones claras** y delimitadores; ejemplos mínimos y relevantes.  
- **Structured Outputs** (JSON Schema con `strict`) para fiabilidad de formato.  
- **Función/Herramienta**: describir inputs/outputs; desactivar paralelismo si el esquema lo exige; validar antes de ejecutar.  
- **Autoverificación**: pedir al agente que valide formato y precondiciones antes de continuar.  
- **No registrar razonamiento interno**; emitir solo **resúmenes** o trazas útiles.  
- **Evals** continuas (datasets de casos reales + rúbricas) y **optimizador de prompts** cuando aplique.  
- **Modelo adecuado a la tarea** (multimodal/razonamiento vs. costo/latencia) y rutas de **degradación** seguras.

---

## 23) Retención y eliminación de datos
- **Retención mínima**: conservar lo necesario y el tiempo estrictamente requerido.  
- **Eliminación segura**: purga lógica + sobrescritura de temporales cuando el soporte lo permita.  
- **PII/secretos**: no persistir por defecto; cifrado en reposo y acceso de mínimo privilegio.

---

## 24) Perfil operativo — **Codex CLI** (integrado)
**Roles**  
- **guardian** (pre-flight): normaliza rutas bajo ROOT, límites de tamaño/formato, evalúa amenazas (prompt/command injection).  
- **planner**: transforma Prompt-CANON → plan + DAG; asigna presupuestos de tiempo/tamaño.  
- **resolver**: resuelve dependencias/lockfiles; verifica licencias; genera **SBOM** (CycloneDX/SPDX).  
- **builder**: genera código/artefactos; escritura atómica + SHA-256 + backups.  
- **tester**: pruebas rápidas + caso manual reproducible; valida idempotencia y rutas de error/cancelación.  
- **signer**: firma artefactos y release (code-signing); anota procedencia y hashes.  
- **publisher**: empaqueta y publica según política de versiones/canales.  
- **reporter**: emite resumen operativo y evidencia.  
- **ux**: asistentes/menús; throttling de progreso; confirma según modo.

**Pipeline**  
`ingest → plan → resolve → build → test → sign → publish → report`

**Modos**  
- **Interactivo (por omisión)**: asistentes/menús; previsualiza y confirma.  
- **Headless/CI**: `--yes/--force` suprime confirmaciones; `--dry-run` disponible; salidas determinísticas.  
- **GUI**: requiere **STA**; degrada a CLI si no disponible.

---

## 25) Entorno de referencia Windows/PowerShell
- **SO objetivo**: Windows 10.  
- **Runtime**: PowerShell **7.5.x** (`pwsh.exe`).  
- **Lanzamiento estándar**: clic derecho → “PowerShell 7” sin flags especiales.  
- **Pautas PowerShell**:  
  - Evitar `Write-Host`; usar `Write-Output/Verbose/Information/Warning/Error`.  
  - Evitar aliases; usar nombres completos de cmdlets.  
  - Implementar `SupportsShouldProcess` en funciones con efectos (**`-WhatIf`/`-Confirm` opcionales**).  
  - **Pruebas**: Pester para unit/integration; PSScriptAnalyzer para linting.  
  - **Verificación de lanzamiento**: debe iniciar desde Explorador con clic derecho → PowerShell 7 y operar en modo interactivo.

---

### Anexo A — Matriz de códigos de salida
| Código | Significado | Ejemplo |
|:--:|---|---|
| 0 | OK | Ejecución sin incidencias |
| 1 | Error de uso | Flags inválidos / ayuda solicitada |
| 2 | Error de validación | Input fuera de límites / esquema |
| 3 | Error de E/S | Lectura/escritura / permiso de archivo |
| 4 | Error de red | Timeout de descarga / DNS |
| 5 | Timeout | Presupuesto de tiempo excedido |
| 6 | Permisos | Operación denegada |
| 7 | Estado | Precondición incumplida / estado inconsistente |
| 8 | Cancelación | Cancelación del usuario o señal |

---

**Fin del documento (v1.3)**
