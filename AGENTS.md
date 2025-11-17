# AGENTS – Lineamientos Globales

Este documento describe las reglas generales para cualquier agente o script que colabore en los repositorios de **Synapta**. No está ligado a un proyecto específico: la intención es que toda contribución comparta la misma filosofía de modularidad extrema, rendimiento máximo y UX consistente.

## Principios rectores

1. **Modularidad reusables** – Cada script o biblioteca debe dividirse en piezas desacopladas, con APIs claras que permitan su reutilización entre repositorios. Evita dependencias circulares o código monolítico.
2. **Algoritmos avanzados por defecto** – Supón que la escala será grande. Prioriza estructuras eficientes, paralelismo, streaming y técnicas de reducción de memoria.
3. **Telemetría en tiempo real** – Siempre que sea posible expón métricas (progreso, rendimiento, errores) mediante eventos o canales observables que la UI pueda consumir.
4. **Oscuro/Claro en WPF** – Toda UI debe tener diccionarios de recursos diferenciados (Dark/Light) y permitir conmutar el tema sin reiniciar.
5. **Consistencia de scripts** – Scripts de automatización deben aceptar parámetros y producir salidas estructuradas (JSON/CSV) para fácil orquestación.

## Patrones técnicos

### Paralelismo y streaming

- Utiliza `System.Threading.Channels`, `IAsyncEnumerable` o pipelines basados en `Task` para procesar datos sin bloquear hilos.
- Diseña fases encadenadas (`producer → transform → sink`) donde cada etapa pueda ejecutarse en paralelo y regular su backpressure.
- Implementa `PauseToken` o equivalentes para pausar/resumir trabajo sin cancelar.

### Indexación y vigilancia de archivos

- Escucha eventos del **NTFS USN Journal** o `FileSystemWatcher` para detectar cambios incrementales.
- Mantén snapshots compactos (por ejemplo, mapas FileId → metadata) para comparación rápida.
- Usa hashing no criptográfico (xxHash, Murmur, FarmHash) para deduplicar o identificar fragmentos sin costo elevado; reserva SHA/CRC para validaciones finales.

### IO y llamadas nativas

- Cuando .NET no exponga la funcionalidad requerida, utiliza P/Invoke a APIs Win32 (ej. `CreateFile`, `DeviceIoControl`, `GetFileInformationByHandleEx`) encapsuladas en clases seguras y testeadas.
- Prefiere lecturas memory-mapped (`MemoryMappedFile`) o `FileStream` con `FileOptions.Asynchronous | FileOptions.SequentialScan` según el patrón de acceso.
- Evita cargar archivos completos a memoria si puedes procesarlos en streaming o por ventanas.

### UI WPF consistente

- Mantén diccionarios `ThemeDark.xaml` y `ThemeLight.xaml` con la misma clave de recursos.
- Exige indicadores en tiempo real: frames o paneles que muestren throughput, latencia, uso de cache, estado de tareas y logs.
- Usa bindings a `IProgress<T>` o streams Rx para refrescar métricas sin bloquear la UI.

### Scripts y automatización

- Scripts PowerShell/Bash deben exponerse como funciones o módulos; sin rutas codificadas.
- Ofrece *switches* para modo “fast debug” vs “max performance”.
- Documenta parámetros, precondiciones y ejemplos en comentarios tipo `SYNAPTA-HELP`.

## Checklist antes de enviar código

- [ ] ¿El componente está aislado y puede reutilizarse?
- [ ] ¿El pipeline soporta paralelismo configurable y procesamiento incremental/streaming?
- [ ] ¿Se exponen métricas o eventos para que la UI muestre indicadores?
- [ ] ¿La UI soporta tema claro/oscuro y conserva accesibilidad (contraste, tamaños)?
- [ ] ¿Los scripts aceptan parámetros y devuelven resultados estructurados?
- [ ] ¿La lógica de indexación incluye detección de cambios (NTFS Journal cuando aplique)?
- [ ] ¿Se usaron hashes y caches apropiados para reducir IO redundante?
- [ ] ¿Se encapsularon las llamadas Win32 con validaciones y manejo de errores coherentes?

Aplicando este marco, cualquier nuevo proyecto o script mantendrá el mismo estándar de eficiencia, claridad y mantenibilidad en todo el ecosistema Synapta.
