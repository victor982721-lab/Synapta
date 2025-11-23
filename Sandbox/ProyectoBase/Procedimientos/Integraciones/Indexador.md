# Integración de ProyectoBase GUI/Wizard con el indexador

Este procedimiento describe cómo conectar la interfaz gráfica y el wizard existente en `ProyectoBase` con el motor común `Indexador` que ahora vive en `Sandbox\Indexador`. La idea es reutilizar la GUI y la experiencia paso a paso como “centro de mando” pero impulsado por el índice compartido.

## 1. Visualizar el índice desde la GUI

1. Añade una referencia al proyecto `Indexador.Core` dentro de `ProyectoBase.GUI`. Puedes hacerlo crea una librería `ProyectoBase.Integration` que consuma `Indexador.Core` y exponga servicios (por ejemplo `IIndexViewer`) que el ViewModel de la interfaz llame.
2. Desde la ventana principal (`MainWindow.xaml.cs`) recupera registros usando `IndexManager.GetRecords(root, dbPath)` y presenta los resultados en un `DataGrid` o `ListView`.
3. Aprovecha `IndexManager.FindDuplicates`, `BuildFileMap` o incluso los DTO de `Indexador.Api` para poblar los paneles de duplicados, mapa de carpetas y estados del índice; así la GUI muestra el mismo contenido que verías con `Filelist` y la API.

## 2. Usar el wizard como asistente del índice

1. El wizard (`WizardRunner`) puede tomar los mismos pasos que el `Run-PostRebootChecks` o el centro de control (`IndexadorControlCenter`). Por ejemplo, al avanzar por los pasos:
   * Paso 1: validar que el watcher está activo (`IndexadorWatcher`).
   * Paso 2: disparar `IndexManager.UpdateEntries` para refrescar solo archivos modificados.
   * Paso 3: abrir el log o la API (`IndexadorHealthCheck`) para mostrar resultados.
2. Implementa un servicio `IIndexCommandExecutor` (en `ProyectoBase.Core` o un proyecto compartido) que invoque los scripts (`scripts/Run-PostRebootChecks.ps1`, `scripts/IndexadorHealthCheck.ps1`) o los endpoints (`/summary`, `/duplicates`) según la opción que el wizard vaya mostrando.

## 3. Interfaz interactiva

1. Reemplaza los botones actuales de la GUI con llamadas a las nuevas funciones: “Actualizar índice” → `IndexManager.IndexDirectory`, “Ver duplicados” → `IndexManager.FindDuplicates`, “Abrir log” → `scripts/Monitor-IndexadorLog.ps1` o el nuevo API.
2. El wizard puede mostrar en tiempo real las salidas del watcher (`IndexadorWatcher.log`) leyendo el archivo con un `FileSystemWatcher` propio dentro del GUI para que el usuario vea los reintentos del watch.

## 4. Opciones extendidas

- Si deseas un centro de mando solo visual, puedes reutilizar el control panel `IndexadorControlCenter.ps1` como inspiracion: crea una vista dentro de la GUI con botones que llaman a los mismos scripts.
- Para evitar conflictos con `indexador.db`, asegúrate de que la GUI no intente ejecutar `dotnet run --watch` en paralelo con las tareas planificadas; en su lugar usa la API o invoca `IndexManager.UpdateEntries`.

Con esto la GUI/Wizard de `ProyectoBase` se convierte en un front-end para el indexador, conservando su diseño pero entregando datos reales y manteniendo sincronizado el motor que ahora vive en `Sandbox\Indexador`. Cuando estés listo, puedo ayudarte a crear un nuevo proyecto dentro de `ProyectoBase` que consuma esos servicios directamente (ViewModels, comandos, etc.). ¿Te gustaría avanzar con esa parte también?  

## 5. Ejemplo de ViewModel ya listo

El archivo `ProyectoBase\Integraciones\IndexadorViewModel.cs` (en este repositorio) es un ejemplo funcional de ViewModel que:

- Inyecta `IndexManager` y expone colecciones `ObservableCollection<ArchivoDto>`/`GrupoDuplicadoDto`.
- Tiene comandos `RefrescarCommand` y `MostrarDuplicadosCommand`.
- Llama a `IndexManager.GetRecords` y `FindDuplicates`, y publica un `Status` y bandera `IsBusy` para la UI.

Puedes copiar ese archivo a tu proyecto de GUI, instanciar el ViewModel en la ventana principal y enlazarlo a la vista mediante `DataContext`. Con eso la interfaz ya dispone de una capa de presentación que consume `Indexador.Core` sin reescribir lógica y te muestra cómo estructurar documentación y comandos.
