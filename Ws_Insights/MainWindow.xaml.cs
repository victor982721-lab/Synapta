using Microsoft.Win32; // Diálogos estándar de Windows (SaveFileDialog, etc.)
using System.Collections.Generic; // List<T>, etc.
using System.Collections.ObjectModel; // ObservableCollection<T>
using System.ComponentModel; // INotifyPropertyChanged, ListSortDirection, etc.
using System.Diagnostics; // Process.Start para abrir archivos / Explorer
using System.IO; // File, Directory, rutas, tamaños, etc.
using System.Linq; // Extensiones LINQ (Take, ToList, etc.)
using System.Text; // StringBuilder para reportes Markdown
using System.Threading; // CancellationTokenSource, CancellationToken
using System.Threading.Tasks; // Task, async/await
using System.Windows; // Tipos base WPF (Window, Thickness, MessageBox)
using System.Windows.Controls; // Controles WPF (GridViewColumnHeader, etc.)
using System.Windows.Data; // CollectionViewSource, ListCollectionView
using System.Windows.Input; // Key, eventos de teclado
using Ws_Insights.File_Extensions; // Ventanas de diálogo propias (ExtensionManagerWindow)
using Ws_Insights.Models; // Modelos como FileMatch
using Ws_Insights.Reporting; // CsvExporter y utilidades de reporte
using Ws_Insights.Search; // SearchEngine, SearchOptions, SearchProgress
using Ws_Insights.Utilities; // PauseTokenSource, PauseToken y utilidades varias

namespace Ws_Insights; // Namespace principal de la aplicación

public partial class MainWindow : Window, INotifyPropertyChanged // Ventana principal WPF que notifica cambios a la UI
{
    private readonly SearchEngine _engine = new(); // Motor de búsqueda de texto en archivos
    private readonly ObservableCollection<FileMatch> _results = new(); // Colección observable de resultados de búsqueda
    private readonly ObservableCollection<string> _logEntries = new(); // Colección observable para el log de eventos

    // Catálogo fijo de grupos de extensiones (para el administrador de extensiones)
    private readonly List<ExtensionCategoryDefinition> _extensionCatalog = new()
    {
        // Archivos de scripts y utilidades
        new("Scripts", "PowerShell, Python y utilidades", new[]{".ps1",".psm1",".psd1",".py",".sh",".bat",".cmd",".cs",".js",".ts"}),
        // Documentos de Office (Word, Excel, CSV)
        new("Documentos Office", "Word, Excel, CSV", new[]{".docx",".doc",".xlsx",".xls",".csv",".pptx"}),
        // Archivos web y de marcado
        new("Web / Markup", "HTML, JSON, XML", new[]{".html",".htm",".css",".xml",".json",".jsonl",".yaml",".yml",".manifest"}),
        // Texto plano y registros
        new("Texto plano", "Registros y notas", new[]{".txt",".md",".log",".ini",".cfg",".ndjson",".reg"}),
        // PDFs y formatos similares
        new("PDF / Otros", "PDF y similares", new[]{".pdf",".rtf"})
    };

    private readonly List<string> _selectedExtensions = new(); // Lista actual de extensiones filtradas activas

    private CancellationTokenSource? _cts; // Fuente de cancelación para la búsqueda en curso
    private PauseTokenSource? _pauseTokenSource; // Fuente de pausa/reanudación para el motor de búsqueda
    private Task? _runningTask; // Task actual de búsqueda asíncrona
    private ListCollectionView? _resultsView; // Vista de colección para ordenar/filtrar resultados
    private GridViewColumnHeader? _lastHeader; // Última cabecera de columna usada para ordenar
    private ListSortDirection _lastSortDirection = ListSortDirection.Ascending; // Dirección de orden actual
    private bool _isDarkTheme = true; // Indicador de tema oscuro (solo decorativo por ahora)
    private bool _isSidebarCollapsed; // Estado de colapso de la barra lateral
    private double _sidebarWidth = 360; // Ancho actual de la barra lateral
    private string? _lastMarkdownReport; // Copia del último reporte Markdown generado

    private string _rootPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments); // Carpeta raíz por defecto
    private string _query = string.Empty; // Texto de búsqueda actual
    private bool _caseSensitive; // Búsqueda sensible a mayúsculas/minúsculas
    private bool _useRegex; // Indica si se usa expresión regular
    private bool _wholeWord; // Coincidencia de palabra completa
    private bool _includeSubfolders = true; // Incluir subcarpetas en el escaneo
    private bool _includeHidden; // Incluir archivos ocultos
    private bool _includeSystem; // Incluir archivos de sistema
    private int _maxParallelism = Math.Max(1, Environment.ProcessorCount); // Grado de paralelismo máximo permitido
    private double _minFileSizeMb; // Tamaño mínimo de archivo en MB
    private double _maxFileSizeMb = 512; // Tamaño máximo de archivo en MB
    private double _resultFontSize = 12; // Tamaño de fuente de los resultados en la UI
    private string _currentFile = string.Empty; // Ruta del archivo actual en proceso
    private int _filesScanned; // Contador de archivos escaneados
    private int _matches; // Contador de coincidencias
    private int _errors; // Contador de errores
    private double _throughput; // Rendimiento (archivos/segundo)
    private string _elapsedDisplay = "00:00:00"; // Tiempo transcurrido formateado para la UI
    private string _extensionSummary = string.Empty; // Resumen de extensiones activas para la UI
    private string _pauseButtonText = "Pausar"; // Texto actual del botón de pausa/reanudar
    private string _themeGlyph = "🌙"; // Icono actual del botón de tema

    public event PropertyChangedEventHandler? PropertyChanged; // Evento de notificación de cambios para bindings

    public MainWindow() // Constructor de la ventana principal
    {
        InitializeComponent(); // Inicializa componentes definidos en XAML
        DataContext = this; // Asigna this como origen de datos para bindings
        LoadExtensions(); // Carga extensiones iniciales a partir del catálogo
        UpdateExtensionSummary(); // Actualiza el resumen de extensiones en la UI
        SidebarWidth = _sidebarWidth; // Aplica el ancho inicial de la barra lateral
        ThemeGlyph = _themeGlyph; // Establece el ícono inicial del tema

        _resultsView = (ListCollectionView)CollectionViewSource.GetDefaultView(Results); // Obtiene la vista de colección de resultados
        _resultsView.SortDescriptions.Add(new SortDescription(nameof(FileMatch.Name), ListSortDirection.Ascending)); // Ordena por nombre ascendente
        _resultsView.IsLiveSorting = true; // Habilita ordenación en vivo cuando cambian los datos
    }

    public ObservableCollection<FileMatch> Results => _results; // Resultados enlazados a la UI
    public ObservableCollection<string> LogEntries => _logEntries; // Entradas de log enlazadas a la UI

    public string RootPath // Carpeta raíz seleccionada
    {
        get => _rootPath; // Devuelve la carpeta raíz actual
        set { _rootPath = value; OnPropertyChanged(); } // Actualiza la carpeta y notifica a la UI
    }

    public string Query // Texto de búsqueda
    {
        get => _query; // Devuelve la consulta actual
        set { _query = value; OnPropertyChanged(); } // Actualiza la consulta y notifica a la UI
    }

    public bool CaseSensitive // Flag de sensibilidad a mayúsculas/minúsculas
    {
        get => _caseSensitive; // Devuelve el valor actual
        set { _caseSensitive = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public bool UseRegex // Flag de uso de expresiones regulares
    {
        get => _useRegex; // Devuelve el estado actual
        set { _useRegex = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public bool WholeWord // Flag de coincidencia de palabra completa
    {
        get => _wholeWord; // Devuelve el estado actual
        set { _wholeWord = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public bool IncludeSubfolders // Flag para incluir subcarpetas
    {
        get => _includeSubfolders; // Devuelve el estado actual
        set { _includeSubfolders = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public bool IncludeHidden // Flag para incluir archivos ocultos
    {
        get => _includeHidden; // Devuelve el estado actual
        set { _includeHidden = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public bool IncludeSystem // Flag para incluir archivos de sistema
    {
        get => _includeSystem; // Devuelve el estado actual
        set { _includeSystem = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public int MaxParallelism // Grado máximo de paralelismo configurado por el usuario
    {
        get => _maxParallelism; // Devuelve el valor actual
        set { _maxParallelism = Math.Clamp(value, 1, MaxParallelismCeiling); OnPropertyChanged(); } // Restringe valor y notifica
    }

    public int MaxParallelismCeiling => Math.Max(4, Environment.ProcessorCount * 2); // Límite superior permitido para paralelismo

    public double MinFileSizeMb // Tamaño mínimo de archivo en MB
    {
        get => _minFileSizeMb; // Devuelve el valor actual
        set
        {
            var newValue = Math.Max(0, Math.Min(value, MaxFileSizeMb)); // Limita entre 0 y MaxFileSizeMb
            if (Math.Abs(_minFileSizeMb - newValue) < double.Epsilon) return; // Si no cambia, no notifica
            _minFileSizeMb = newValue; // Actualiza el campo
            OnPropertyChanged(); // Notifica a la UI
        }
    }

    public double MaxFileSizeMb // Tamaño máximo de archivo en MB
    {
        get => _maxFileSizeMb; // Devuelve el valor actual
        set
        {
            var newValue = Math.Max(10, value); // Impone mínimo de 10 MB
            if (newValue < MinFileSizeMb)
            {
                MinFileSizeMb = newValue; // Ajusta el mínimo si quedó por encima del máximo
            }
            if (Math.Abs(_maxFileSizeMb - newValue) < double.Epsilon) return; // Evita notificar si no cambió
            _maxFileSizeMb = newValue; // Actualiza el campo
            OnPropertyChanged(); // Notifica a la UI
        }
    }

    public double ResultFontSize // Tamaño de fuente de los resultados
    {
        get => _resultFontSize; // Devuelve el tamaño actual
        set { _resultFontSize = Math.Clamp(value, 10, 22); OnPropertyChanged(); } // Limita y notifica
    }

    public string CurrentFile // Archivo actualmente procesado
    {
        get => _currentFile; // Devuelve la ruta actual
        private set { _currentFile = value; OnPropertyChanged(); } // Actualiza internamente y notifica
    }

    public int FilesScanned // Archivos escaneados hasta ahora
    {
        get => _filesScanned; // Devuelve el contador
        private set { _filesScanned = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public int Matches // Coincidencias encontradas
    {
        get => _matches; // Devuelve el contador
        private set { _matches = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public int Errors // Errores ocurridos
    {
        get => _errors; // Devuelve el contador
        private set { _errors = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public double Throughput // Rendimiento en archivos por segundo
    {
        get => _throughput; // Devuelve el valor actual
        private set { _throughput = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public string ElapsedDisplay // Texto de tiempo transcurrido formateado
    {
        get => _elapsedDisplay; // Devuelve el valor actual
        private set { _elapsedDisplay = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public string ExtensionSummary // Resumen de extensiones activas
    {
        get => _extensionSummary; // Devuelve el resumen actual
        private set { _extensionSummary = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public double SidebarWidth // Ancho de la barra lateral
    {
        get => _sidebarWidth; // Devuelve el ancho actual
        private set
        {
            if (Math.Abs(_sidebarWidth - value) < double.Epsilon) return; // Si no cambia, no hace nada
            _sidebarWidth = value; // Actualiza el ancho
            OnPropertyChanged(); // Notifica que SidebarWidth cambió
            OnPropertyChanged(nameof(SidebarBorderThickness)); // Notifica que también cambió el grosor del borde
        }
    }

    public Thickness SidebarBorderThickness => SidebarWidth < 1 ? new Thickness(0) : new Thickness(1); // Grosor del borde según colapso

    public string SidebarToggleGlyph => _isSidebarCollapsed ? "❯" : "❮"; // Icono según estado de la barra lateral

    public string ThemeGlyph // Icono del botón de tema
    {
        get => _themeGlyph; // Devuelve el icono actual
        private set { _themeGlyph = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    public string PauseButtonText // Texto del botón de pausa/reanudar
    {
        get => _pauseButtonText; // Devuelve el texto actual
        private set { _pauseButtonText = value; OnPropertyChanged(); } // Actualiza y notifica
    }

    private async void OnStartSearch(object sender, RoutedEventArgs e) // Manejador para iniciar la búsqueda
    {
        if (_runningTask is { IsCompleted: false }) // Evita iniciar si ya hay una búsqueda en curso
            return;

        if (!Directory.Exists(RootPath)) // Valida que la carpeta exista
        {
            System.Windows.MessageBox.Show("La ruta seleccionada no existe."); // Muestra mensaje si no existe
            return; // Sale sin iniciar
        }

        if (string.IsNullOrWhiteSpace(Query)) // Valida que haya texto de búsqueda
        {
            System.Windows.MessageBox.Show("Ingrese el texto a buscar."); // Muestra advertencia
            return; // Sale sin iniciar
        }

        if (_selectedExtensions.Count == 0) // Verifica que haya extensiones seleccionadas
        {
            System.Windows.MessageBox.Show("Seleccione al menos una extensión."); // Advierte al usuario
            return; // Sale sin iniciar
        }

        Results.Clear(); // Limpia resultados anteriores
        LogEntries.Clear(); // Limpia el log anterior
        AppendLog($"[+] Carpeta: {RootPath}"); // Registra la carpeta en el log
        AppendLog($"[+] Consulta: {Query}"); // Registra la consulta en el log
        AppendLog($"[+] Extensiones: {string.Join(", ", _selectedExtensions)}"); // Registra las extensiones activas

        ResetStats(); // Reinicia contadores de métricas
        _cts = new CancellationTokenSource(); // Crea nueva fuente de cancelación
        _pauseTokenSource?.Dispose(); // Libera cualquier fuente de pausa previa
        _pauseTokenSource = new PauseTokenSource(); // Crea nueva fuente de pausa
        PauseButtonText = "Pausar"; // Restaura texto del botón de pausa
        StopButton.IsEnabled = true; // Habilita botón de detener
        PauseButton.IsEnabled = true; // Habilita botón de pausa
        StartButton.IsEnabled = false; // Deshabilita botón de inicio
        ExportButton.IsEnabled = false; // Deshabilita exportar CSV mientras busca
        MarkdownButton.IsEnabled = false; // Deshabilita exportar Markdown hasta tener reporte
        _lastMarkdownReport = null; // Limpia reporte anterior
        IsPaused = false; // Marca que no está en pausa

        var options = new SearchOptions // Construye opciones de búsqueda
        {
            RootPath = RootPath, // Carpeta raíz
            Query = Query, // Texto a buscar
            CaseSensitive = CaseSensitive, // Sensible a mayúsculas
            UseRegex = UseRegex, // Usar regex
            WholeWord = WholeWord && !UseRegex, // Palabra completa solo si no es regex
            IncludeSubfolders = IncludeSubfolders, // Incluir subcarpetas
            Extensions = _selectedExtensions.ToList(), // Copia de lista de extensiones
            MaxDegreeOfParallelism = MaxParallelism, // Paralelismo máximo
            MaxFileSizeBytes = (long)(MaxFileSizeMb * 1024 * 1024), // Tamaño máximo en bytes
            MinFileSizeBytes = (long)(MinFileSizeMb * 1024 * 1024), // Tamaño mínimo en bytes
            IncludeHidden = IncludeHidden, // Incluir ocultos
            IncludeSystem = IncludeSystem, // Incluir de sistema
            PauseToken = _pauseTokenSource.Token // Token de pausa
        };

        var progress = new Progress<SearchProgress>(p => // Callback de progreso
        {
            FilesScanned = p.FilesScanned; // Actualiza archivos escaneados
            Matches = p.Matches; // Actualiza coincidencias
            Errors = p.Errors; // Actualiza errores
            Throughput = p.FilesPerSecond; // Actualiza rendimiento
            ElapsedDisplay = p.Elapsed.ToString(@"hh\:mm\:ss"); // Actualiza tiempo formateado
            CurrentFile = p.CurrentFile ?? string.Empty; // Actualiza archivo actual
        });

        try
        {
            _runningTask = _engine.SearchAsync( // Inicia búsqueda asíncrona
                options, // Opciones de búsqueda
                progress, // Reporte de progreso
                match => Dispatcher.InvokeAsync(() => Results.Add(match)).Task, // Agrega resultados en el hilo de UI
                _cts.Token); // Token de cancelación

            await _runningTask; // Espera a que termine la búsqueda
            AppendLog("✔ Búsqueda finalizada."); // Registra finalización exitosa
        }
        catch (OperationCanceledException)
        {
            AppendLog("⚠ Búsqueda cancelada."); // Registra que se canceló
        }
        catch (Exception ex)
        {
            AppendLog($"✖ Error inesperado: {ex.Message}"); // Registra error inesperado
        }
        finally
        {
            _cts?.Dispose(); // Libera fuente de cancelación
            _cts = null; // Limpia referencia
            _pauseTokenSource?.Dispose(); // Libera fuente de pausa
            _pauseTokenSource = null; // Limpia referencia
            IsPaused = false; // Asegura que no quede marcado como en pausa
            StartButton.IsEnabled = true; // Rehabilita inicio
            PauseButton.IsEnabled = false; // Deshabilita pausa
            StopButton.IsEnabled = false; // Deshabilita detener
            ExportButton.IsEnabled = Results.Count > 0; // Habilita exportar si hay resultados
        }
    }

    private void OnStopSearch(object sender, RoutedEventArgs e) // Manejador del botón Detener
    {
        _cts?.Cancel(); // Solicita cancelación de la búsqueda
        _pauseTokenSource?.Resume(); // Reanuda si estaba en pausa para que termine ordenadamente
    }

    private bool IsPaused // Propiedad interna para sincronizar estado de pausa
    {
        set
        {
            PauseButtonText = value ? "Reanudar" : "Pausar"; // Cambia texto del botón según estado
            MarkdownButton.IsEnabled = value && Results.Count > 0; // Habilita Markdown solo si está en pausa y hay resultados
        }
    }

    private void OnPauseOrResume(object sender, RoutedEventArgs e) // Manejador del botón Pausar/Reanudar
    {
        if (_pauseTokenSource is null) // Si no hay fuente de pausa, no hace nada
            return;

        if (_pauseTokenSource.IsPaused) // Si ya está en pausa
        {
            _pauseTokenSource.Resume(); // Reanuda
            AppendLog("▶ Búsqueda reanudada."); // Registra acción en log
            IsPaused = false; // Marca estado como no pausado
        }
        else
        {
            _pauseTokenSource.Pause(); // Pone en pausa
            AppendLog("⏸ Búsqueda en pausa."); // Registra acción en log
            _lastMarkdownReport = GenerateMarkdownReport(); // Genera snapshot de reporte Markdown
            MarkdownButton.IsEnabled = true; // Habilita botón de exportar Markdown
            IsPaused = true; // Marca estado como pausado
        }
    }

    private void OnBrowseClick(object sender, RoutedEventArgs e) // Manejador del botón para elegir carpeta
    {
        using var dialog = new System.Windows.Forms.FolderBrowserDialog // Crea diálogo para seleccionar carpeta
        {
            SelectedPath = Directory.Exists(RootPath) ? RootPath : Environment.CurrentDirectory, // Ruta inicial
            Description = "Selecciona la carpeta base" // Texto de ayuda
        };

        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK) // Si el usuario acepta
        {
            RootPath = dialog.SelectedPath; // Actualiza la ruta raíz
        }
    }

    private async void OnExportResults(object sender, RoutedEventArgs e) // Exporta resultados a CSV
    {
        if (Results.Count == 0) // Si no hay resultados
        {
            System.Windows.MessageBox.Show("No hay resultados que exportar."); // Advierte al usuario
            return; // Sale
        }

        var dialog = new Microsoft.Win32.SaveFileDialog // Diálogo para guardar archivo
        {
            Filter = "CSV (*.csv)|*.csv", // Filtro de tipo CSV
            FileName = $"ws_oraculus_{DateTime.Now:yyyyMMdd_HHmmss}.csv" // Nombre sugerido con timestamp
        };

        if (dialog.ShowDialog() != true) // Si el usuario cancela
            return; // Sale

        try
        {
            await CsvReporter.ExportAsync(dialog.FileName, Results); // Exporta resultados a CSV de forma asíncrona
            AppendLog($"Reporte guardado en {dialog.FileName}"); // Registra ruta del reporte
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show($"No se pudo exportar el reporte: {ex.Message}"); // Muestra mensaje de error
        }
    }

    private void OnExportMarkdown(object sender, RoutedEventArgs e) // Exporta reporte Markdown
    {
        if (string.IsNullOrWhiteSpace(_lastMarkdownReport)) // Verifica que haya un reporte generado
        {
            System.Windows.MessageBox.Show("Genera un reporte pausando la búsqueda primero."); // Indica al usuario qué hacer
            return; // Sale
        }

        var dialog = new Microsoft.Win32.SaveFileDialog // Diálogo para guardar Markdown
        {
            Filter = "Markdown (*.md)|*.md", // Filtro de archivos .md
            FileName = $"ws_oraculus_{DateTime.Now:yyyyMMdd_HHmmss}.md" // Nombre sugerido con timestamp
        };

        if (dialog.ShowDialog() != true) // Si el usuario cancela
            return; // Sale

        File.WriteAllText(dialog.FileName, _lastMarkdownReport); // Escribe el contenido Markdown en disco
        AppendLog($"Markdown guardado en {dialog.FileName}"); // Registra operación en log
    }

    private void OnOpenSelectedFile(object? sender, RoutedEventArgs e) // Abre el archivo seleccionado en el visor por defecto
    {
        if (ResultsList.SelectedItem is not FileMatch match) // Comprueba que haya selección válida
            return; // Si no hay, sale

        try
        {
            Process.Start(new ProcessStartInfo // Lanza el archivo con la asociación por defecto
            {
                FileName = match.FullPath, // Ruta completa del archivo
                UseShellExecute = true // Usa Shell para respetar asociaciones del sistema
            });
        }
        catch (Exception ex)
        {
            System.Windows.MessageBox.Show($"No se pudo abrir: {ex.Message}"); // Muestra error si falla
        }
    }

    private void OnRevealInExplorer(object sender, RoutedEventArgs e) // Abre Explorer seleccionando el archivo
    {
        if (ResultsList.SelectedItem is not FileMatch match) // Verifica selección
            return;

        Process.Start("explorer.exe", $"/select,\"{match.FullPath}\""); // Ejecuta Explorer con el archivo seleccionado
    }

    private void OnCopyPath(object sender, RoutedEventArgs e) // Copia la ruta del archivo seleccionado al portapapeles
    {
        if (ResultsList.SelectedItem is FileMatch match) // Si hay selección válida
        {
            System.Windows.Clipboard.SetText(match.FullPath); // Copia la ruta completa al clipboard
        }
    }

    private void OnResultsKeyDown(object sender, System.Windows.Input.KeyEventArgs e) // Maneja teclas sobre la lista de resultados
    {
        if (e.Key == Key.Enter) // Si se presiona Enter
        {
            OnOpenSelectedFile(sender, e); // Abre el archivo seleccionado
            e.Handled = true; // Marca el evento como manejado
        }
    }

    private void OnCopyLog(object sender, RoutedEventArgs e) // Copia el log al portapapeles
    {
        if (LogEntries.Count == 0) return; // Si no hay log, sale
        System.Windows.Clipboard.SetText(string.Join(Environment.NewLine, LogEntries)); // Copia todas las entradas separadas por salto de línea
    }

    private void OnClearLog(object sender, RoutedEventArgs e) // Limpia el log
    {
        LogEntries.Clear(); // Borra todas las entradas
    }

    private void OnToggleTheme(object sender, RoutedEventArgs e) // Cambia icono de tema (oscuro/claro)
    {
        _isDarkTheme = !_isDarkTheme; // Invierte el estado interno de tema
        ThemeGlyph = _isDarkTheme ? "🌙" : "☀"; // Actualiza icono según estado
        AppendLog("Modo claro aún no está disponible; el icono es decorativo por ahora."); // Deja constancia en el log
    }

    private void OnToggleSidebar(object sender, RoutedEventArgs e) // Colapsa o expande la barra lateral
    {
        _isSidebarCollapsed = !_isSidebarCollapsed; // Invierte el estado
        SidebarWidth = _isSidebarCollapsed ? 0 : 360; // Ancho 0 cuando está colapsada, 360 cuando está visible
        OnPropertyChanged(nameof(SidebarToggleGlyph)); // Notifica cambio del icono de toggle
    }

    private void OnManageExtensions(object sender, RoutedEventArgs e) // Abre el administrador de extensiones
    {
        var dialog = new ExtensionManagerWindow(_extensionCatalog, _selectedExtensions) { Owner = this }; // Crea ventana de administración
        if (dialog.ShowDialog() == true) // Si el usuario guarda cambios
        {
            _selectedExtensions.Clear(); // Limpia lista actual
            _selectedExtensions.AddRange(dialog.SelectedExtensions); // Copia las extensiones seleccionadas desde el diálogo
            UpdateExtensionSummary(); // Actualiza resumen en la UI
        }
    }

    private void AppendLog(string message) // Agrega una línea al log con timestamp
    {
        if (LogEntries.Count > 300) // Si el log es muy largo
        {
            LogEntries.RemoveAt(0); // Elimina la entrada más antigua
        }
        LogEntries.Add($"{DateTime.Now:HH:mm:ss} {message}"); // Agrega la nueva entrada con hora
    }

    private void ResetStats() // Reinicia contadores de métricas
    {
        FilesScanned = 0; // Resetea archivos escaneados
        Matches = 0; // Resetea coincidencias
        Errors = 0; // Resetea errores
        Throughput = 0; // Resetea rendimiento
        ElapsedDisplay = "00:00:00"; // Resetea tiempo transcurrido
        CurrentFile = string.Empty; // Limpia archivo actual
    }

    private void LoadExtensions() // Carga extensiones por defecto desde el catálogo
    {
        _selectedExtensions.Clear(); // Limpia lista actual
        foreach (var definition in _extensionCatalog) // Recorre cada categoría
        {
            foreach (var ext in definition.Extensions) // Recorre cada extensión de la categoría
            {
                var normalized = NormalizeExtension(ext); // Normaliza (punto inicial, minúsculas)
                if (!_selectedExtensions.Contains(normalized)) // Evita duplicados
                {
                    _selectedExtensions.Add(normalized); // Agrega extensión normalizada
                }
            }
        }
    }

    private void UpdateExtensionSummary() // Actualiza el resumen visible de extensiones activas
    {
        if (_selectedExtensions.Count == 0) // Si no hay extensiones seleccionadas
        {
            ExtensionSummary = "Ninguna extensión seleccionada"; // Texto por defecto
            return; // Sale
        }

        var preview = string.Join(", ", _selectedExtensions.Take(8)); // Toma las primeras 8 extensiones para vista previa
        if (_selectedExtensions.Count > 8) // Si hay más de 8
        {
            preview += $" … (+{_selectedExtensions.Count - 8})"; // Indica cuántas adicionales hay
        }
        ExtensionSummary = $"{_selectedExtensions.Count} activas: {preview}"; // Compone texto final
    }

    private static string NormalizeExtension(string ext) // Normaliza una extensión de archivo
    {
        if (string.IsNullOrWhiteSpace(ext)) // Si está vacía o nula
            return string.Empty; // Devuelve cadena vacía
        return ext.StartsWith('.') ? ext.ToLowerInvariant() : $".{ext.ToLowerInvariant()}"; // Fuerza minúsculas y punto al inicio
    }

    private string GenerateMarkdownReport() // Construye un resumen Markdown de resultados
    {
        var sb = new StringBuilder(); // Usa StringBuilder para eficiencia
        sb.AppendLine($"# Ws_Insights - Resumen {DateTime.Now:yyyy-MM-dd HH:mm:ss}"); // Título con fecha y hora
        sb.AppendLine(); // Línea en blanco
        sb.AppendLine($"- Carpeta: `{RootPath}`"); // Carpeta raíz
        sb.AppendLine($"- Consulta: `{Query}`"); // Texto de búsqueda
        sb.AppendLine($"- Extensiones: {string.Join(", ", _selectedExtensions)}"); // Extensiones activas
        sb.AppendLine($"- Archivos revisados: {FilesScanned}"); // Archivos escaneados
        sb.AppendLine($"- Coincidencias: {Matches}"); // Coincidencias
        sb.AppendLine($"- Errores: {Errors}"); // Errores
        sb.AppendLine(); // Línea en blanco
        sb.AppendLine("## Resultados"); // Encabezado de sección de resultados
        foreach (var match in Results.Take(30)) // Recorre hasta 30 resultados
        {
            sb.AppendLine($"- **{match.Name}** ({match.Extension}) — `{match.FullPath}`"); // Línea con nombre, extensión y ruta
            sb.AppendLine($"  - Tamaño: {match.SizeKilobytes} KB"); // Tamaño en KB
            sb.AppendLine($"  - Fragmento: {match.Snippet}"); // Fragmento de texto encontrado
        }
        return sb.ToString(); // Devuelve el Markdown generado
    }

    private void OnGridHeaderClick(object sender, RoutedEventArgs e) // Maneja clic en encabezados de columna para ordenar
    {
        if (e.OriginalSource is not GridViewColumnHeader header || header.Tag is not string sortBy) // Verifica que la fuente sea cabecera válida
            return; // Si no, sale

        var direction = _lastHeader == header && _lastSortDirection == ListSortDirection.Ascending
            ? ListSortDirection.Descending
            : ListSortDirection.Ascending; // Alterna la dirección si se hace clic en la misma columna

        _lastHeader = header; // Actualiza última cabecera usada
        _lastSortDirection = direction; // Actualiza última dirección
        ApplySort(sortBy, direction); // Aplica ordenación con esos parámetros
    }

    private void ApplySort(string propertyName, ListSortDirection direction) // Aplica ordenamiento a la vista de resultados
    {
        _resultsView ??= (ListCollectionView)CollectionViewSource.GetDefaultView(Results); // Asegura que _resultsView esté inicializada
        _resultsView.SortDescriptions.Clear(); // Limpia ordenaciones anteriores
        _resultsView.SortDescriptions.Add(new SortDescription(propertyName, direction)); // Agrega nueva descripción de orden
    }

    private void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? name = null) // Notifica cambio de propiedad
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name)); // Dispara evento si hay suscriptores
}