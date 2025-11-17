using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Threading;
using Deduplinside.Commands;
using Deduplinside.Models;
using Deduplinside.Services;
using Microsoft.Win32;

namespace Deduplinside.ViewModels;

public class MainViewModel : ViewModelBase
{
    private readonly IDeduplicationService _deduplicationService;
    private readonly IMergeService _mergeService;
    private readonly ISearchService _searchService;
    private readonly IRangeExtractionService _rangeExtractionService;
    private readonly Dispatcher _dispatcher;
    private readonly List<string> _recentOutputs = new();
    private readonly Dictionary<string, long> _perFileProgress = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, long> _perFileDuplicates = new(StringComparer.OrdinalIgnoreCase);
    private readonly object _progressGate = new();
    private CancellationTokenSource? _cts;
    private bool _isProcessing;
    private bool _useParallelProcessing = true;
    private string _searchQuery = string.Empty;
    private string _rangeStartMarker = string.Empty;
    private string _rangeEndMarker = string.Empty;
    private string _previewContent = "Aún no hay vistas previas.";
    private string _statusMessage = "Listo";
    private string? _lastRangeExportPath;

    public MainViewModel(
        IDeduplicationService deduplicationService,
        IMergeService mergeService,
        ISearchService searchService,
        IRangeExtractionService rangeExtractionService)
    {
        _deduplicationService = deduplicationService;
        _mergeService = mergeService;
        _searchService = searchService;
        _rangeExtractionService = rangeExtractionService;
        _dispatcher = Dispatcher.CurrentDispatcher;

        Files = new ObservableCollection<FileItem>();
        DuplicateEntries = new ObservableCollection<DuplicateEntry>();
        RangeMatches = new ObservableCollection<RangeMatch>();
        SearchHits = new ObservableCollection<SearchHit>();
        ExtensionOptions = new ObservableCollection<FileExtensionOption>(CreateDefaultExtensions());
        Stats = new AnalysisStats();
        Stats.PropertyChanged += StatsOnPropertyChanged;

        Files.CollectionChanged += (_, __) => RefreshCommandStates();
        RangeMatches.CollectionChanged += (_, __) => RefreshCommandStates();

        BrowseFilesCommand = new RelayCommand(BrowseFiles);
        ClearFilesCommand = new RelayCommand(ClearFiles, () => Files.Any());
        ProcessFilesCommand = new AsyncRelayCommand(ProcessFilesAsync, CanProcessFiles);
        MergeFilesCommand = new AsyncRelayCommand(MergeFilesAsync, CanMergeFiles);
        ExportRangesCommand = new AsyncRelayCommand(ExportRangesAsync, () => RangeMatches.Any());
        SearchCommand = new AsyncRelayCommand(RunSearchAsync, () => _recentOutputs.Any());
        CancelCommand = new RelayCommand(CancelProcessing, () => IsProcessing);
    }

    public ObservableCollection<FileItem> Files { get; }

    public ObservableCollection<DuplicateEntry> DuplicateEntries { get; }

    public ObservableCollection<RangeMatch> RangeMatches { get; }

    public ObservableCollection<SearchHit> SearchHits { get; }

    public ObservableCollection<FileExtensionOption> ExtensionOptions { get; }

    public AnalysisStats Stats { get; }

    public RelayCommand BrowseFilesCommand { get; }

    public RelayCommand ClearFilesCommand { get; }

    public AsyncRelayCommand ProcessFilesCommand { get; }

    public AsyncRelayCommand MergeFilesCommand { get; }

    public AsyncRelayCommand ExportRangesCommand { get; }

    public AsyncRelayCommand SearchCommand { get; }

    public RelayCommand CancelCommand { get; }

    public bool IsProcessing
    {
        get => _isProcessing;
        private set
        {
            if (SetProperty(ref _isProcessing, value))
            {
                RefreshCommandStates();
            }
        }
    }

    public bool UseParallelProcessing
    {
        get => _useParallelProcessing;
        set
        {
            if (SetProperty(ref _useParallelProcessing, value))
            {
                OnPropertyChanged(nameof(UseQueuedProcessing));
            }
        }
    }

    public bool UseQueuedProcessing
    {
        get => !UseParallelProcessing;
        set => UseParallelProcessing = !value;
    }

    public string SearchQuery
    {
        get => _searchQuery;
        set => SetProperty(ref _searchQuery, value);
    }

    public string RangeStartMarker
    {
        get => _rangeStartMarker;
        set => SetProperty(ref _rangeStartMarker, value);
    }

    public string RangeEndMarker
    {
        get => _rangeEndMarker;
        set => SetProperty(ref _rangeEndMarker, value);
    }

    public string PreviewContent
    {
        get => _previewContent;
        private set => SetProperty(ref _previewContent, value);
    }

    public string StatusMessage
    {
        get => _statusMessage;
        private set => SetProperty(ref _statusMessage, value);
    }

    public string? LastRangeExportPath
    {
        get => _lastRangeExportPath;
        private set => SetProperty(ref _lastRangeExportPath, value);
    }

    public double OverallProgress =>
        Stats.TotalFiles == 0
            ? 0
            : Math.Round((double)Stats.CompletedFiles / Stats.TotalFiles * 100, 1);

    private void StatsOnPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(AnalysisStats.TotalFiles) or nameof(AnalysisStats.CompletedFiles))
        {
            OnPropertyChanged(nameof(OverallProgress));
        }
    }

    private void BrowseFiles()
    {
        var dialog = new OpenFileDialog
        {
            Filter = "Documents|*.txt;*.md;*.log;*.csv;*.json|Todos|*.*",
            Multiselect = true,
            Title = "Seleccionar documentos para Deduplinside"
        };

        if (dialog.ShowDialog() != true)
        {
            return;
        }

        var allowed = GetAllowedExtensions();
        foreach (var file in dialog.FileNames)
        {
            if (!allowed.Contains(Path.GetExtension(file), StringComparer.OrdinalIgnoreCase))
            {
                continue;
            }

            if (Files.Any(f => string.Equals(f.FullPath, file, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            Files.Add(new FileItem(file));
        }

        StatusMessage = Files.Any()
            ? $"{Files.Count} archivo(s) en cola."
            : "No hubo archivos válidos.";
        RefreshCommandStates();
    }

    private void ClearFiles()
    {
        Files.Clear();
        RefreshCommandStates();
    }

    private bool CanProcessFiles() => Files.Any() && !IsProcessing;

    private bool CanMergeFiles() => Files.Count > 1 && !IsProcessing;

    private async Task ProcessFilesAsync()
    {
        var files = Files.Where(f => f.IsQueued).Select(f => f.FullPath).Where(File.Exists).ToList();
        var allowed = GetAllowedExtensions();
        files = files.Where(f => allowed.Contains(Path.GetExtension(f), StringComparer.OrdinalIgnoreCase)).ToList();

        if (!files.Any())
        {
            StatusMessage = "No hay archivos con las extensiones seleccionadas.";
            return;
        }

        _cts?.Cancel();
        _cts?.Dispose();
        _cts = new CancellationTokenSource();
        var token = _cts.Token;

        IsProcessing = true;
        DuplicateEntries.Clear();
        RangeMatches.Clear();
        SearchHits.Clear();
        _recentOutputs.Clear();

        Stats.Reset();
        _perFileProgress.Clear();
        _perFileDuplicates.Clear();
        Stats.TotalFiles = files.Count;
        Stats.EtaText = "Procesando...";
        var stopwatch = Stopwatch.StartNew();

        var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        var outputRoot = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
            "Deduplinside",
            "Outputs",
            timestamp);
        Directory.CreateDirectory(outputRoot);

        var progress = new Progress<ProcessingProgress>(p => OnProgressReported(p, stopwatch.Elapsed));

        try
        {
            if (UseParallelProcessing && files.Count > 1)
            {
                var maxDegree = Math.Max(1, Environment.ProcessorCount - 1);
                using var throttler = new SemaphoreSlim(maxDegree);

                await Parallel.ForEachAsync(files, token, async (file, ct) =>
                {
                    await throttler.WaitAsync(ct).ConfigureAwait(false);
                    try
                    {
                        await ProcessSingleFileAsync(file, outputRoot, progress, ct, stopwatch).ConfigureAwait(false);
                    }
                    finally
                    {
                        throttler.Release();
                    }
                }).ConfigureAwait(false);
            }
            else
            {
                foreach (var file in files)
                {
                    token.ThrowIfCancellationRequested();
                    await ProcessSingleFileAsync(file, outputRoot, progress, token, stopwatch).ConfigureAwait(false);
                }
            }

            if (RangeMatches.Any())
            {
                await AutoExportRangesAsync(token).ConfigureAwait(false);
            }

            StatusMessage = "Procesamiento completado.";
        }
        catch (OperationCanceledException)
        {
            StatusMessage = "Procesamiento cancelado.";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
        }
        finally
        {
            stopwatch.Stop();
            IsProcessing = false;
        }
    }

    private async Task ProcessSingleFileAsync(
        string file,
        string outputRoot,
        IProgress<ProcessingProgress> progress,
        CancellationToken token,
        Stopwatch stopwatch)
    {
        var result = await _deduplicationService
            .ProcessFileAsync(file, outputRoot, progress, token)
            .ConfigureAwait(false);

        var preview = await BuildPreviewAsync(result.OutputPath, token).ConfigureAwait(false);
        var searchHits = await _searchService.SearchAsync(result.OutputPath, SearchQuery, token).ConfigureAwait(false);
        var ranges = await _rangeExtractionService
            .ExtractAsync(result.OutputPath, RangeStartMarker, RangeEndMarker, token)
            .ConfigureAwait(false);

        _dispatcher.Invoke(() =>
        {
            _recentOutputs.Add(result.OutputPath);

            foreach (var duplicate in result.DuplicateEntries)
            {
                DuplicateEntries.Add(duplicate);
            }

            foreach (var hit in searchHits)
            {
                SearchHits.Add(hit);
            }

            foreach (var range in ranges)
            {
                RangeMatches.Add(range);
            }

            Stats.CompletedFiles += 1;
            Stats.RangeMatches = RangeMatches.Count;
            UpdateSpeed(stopwatch.Elapsed);
            PreviewContent = preview;
            StatusMessage = $"Procesado {Path.GetFileName(result.FilePath)}";
        });
    }

    private async Task MergeFilesAsync()
    {
        var files = Files.Select(f => f.FullPath).Where(File.Exists).ToList();
        if (files.Count < 2)
        {
            StatusMessage = "Seleccione al menos dos archivos.";
            return;
        }

        var dialog = new SaveFileDialog
        {
            Title = "Guardar documento fusionado",
            Filter = "Texto|*.txt|Markdown|*.md|Datos|*.log;*.csv;*.json|Todos|*.*",
            FileName = $"Deduplinside-Merged-{DateTime.Now:yyyyMMdd_HHmmss}.txt"
        };

        if (dialog.ShowDialog() != true)
        {
            return;
        }

        _cts?.Cancel();
        _cts?.Dispose();
        _cts = new CancellationTokenSource();
        var token = _cts.Token;

        IsProcessing = true;
        _perFileProgress.Clear();
        _perFileDuplicates.Clear();
        Stats.Reset();
        var progress = new Progress<ProcessingProgress>(p => OnProgressReported(p, TimeSpan.Zero));

        try
        {
            await _mergeService.MergeAndDeduplicateAsync(files, dialog.FileName, progress, token).ConfigureAwait(false);
            StatusMessage = $"Merge listo en {dialog.FileName}";
        }
        catch (OperationCanceledException)
        {
            StatusMessage = "Merge cancelado.";
        }
        finally
        {
            IsProcessing = false;
        }
    }

    private async Task ExportRangesAsync()
    {
        if (!RangeMatches.Any())
        {
            StatusMessage = "No hay rangos para exportar.";
            return;
        }

        var dialog = new SaveFileDialog
        {
            Title = "Exportar rangos encontrados",
            Filter = "Texto|*.txt|Todos|*.*",
            FileName = $"Deduplinside-Ranges-{DateTime.Now:yyyyMMdd_HHmmss}.txt"
        };

        if (dialog.ShowDialog() != true)
        {
            return;
        }

        await _rangeExtractionService.ExportAsync(RangeMatches, dialog.FileName, CancellationToken.None)
            .ConfigureAwait(false);
        LastRangeExportPath = dialog.FileName;
        StatusMessage = $"Rangos exportados en {dialog.FileName}";
    }

    private async Task AutoExportRangesAsync(CancellationToken token)
    {
        var exportRoot = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
            "Deduplinside",
            "RangeExports");
        var exportPath = Path.Combine(exportRoot, $"Ranges-{DateTime.Now:yyyyMMdd_HHmmss}.txt");
        await _rangeExtractionService.ExportAsync(RangeMatches, exportPath, token).ConfigureAwait(false);
        LastRangeExportPath = exportPath;
    }

    private async Task RunSearchAsync()
    {
        if (!_recentOutputs.Any())
        {
            StatusMessage = "Ejecuta un proceso para tener material de búsqueda.";
            return;
        }

        var lastOutput = _recentOutputs.Last();
        var hits = await _searchService.SearchAsync(lastOutput, SearchQuery, CancellationToken.None).ConfigureAwait(false);
        var ranges = await _rangeExtractionService
            .ExtractAsync(lastOutput, RangeStartMarker, RangeEndMarker, CancellationToken.None)
            .ConfigureAwait(false);

        _dispatcher.Invoke(() =>
        {
            SearchHits.Clear();
            foreach (var hit in hits)
            {
                SearchHits.Add(hit);
            }

            RangeMatches.Clear();
            foreach (var range in ranges)
            {
                RangeMatches.Add(range);
            }

            Stats.RangeMatches = RangeMatches.Count;
            StatusMessage = "Búsqueda aplicada al último resultado.";
        });
    }

    private void CancelProcessing()
    {
        if (!IsProcessing)
        {
            return;
        }

        _cts?.Cancel();
    }

    private void OnProgressReported(ProcessingProgress report, TimeSpan elapsed)
    {
        if (string.IsNullOrWhiteSpace(report.FilePath))
        {
            return;
        }

        lock (_progressGate)
        {
            _perFileProgress[report.FilePath] = report.ProcessedLines;
            _perFileDuplicates[report.FilePath] = report.DuplicateLines;
            Stats.ProcessedLines = _perFileProgress.Values.Sum();
            Stats.DuplicateLines = _perFileDuplicates.Values.Sum();
        }

        UpdateSpeed(elapsed);
    }

    private void UpdateSpeed(TimeSpan elapsed)
    {
        if (elapsed.TotalSeconds > 0 && Stats.ProcessedLines > 0)
        {
            Stats.LinesPerSecond = Math.Round(Stats.ProcessedLines / elapsed.TotalSeconds, 2);
        }

        if (Stats.CompletedFiles >= Stats.TotalFiles && Stats.TotalFiles > 0)
        {
            Stats.EtaText = "Completado";
            return;
        }

        if (Stats.CompletedFiles > 0 && Stats.CompletedFiles < Stats.TotalFiles)
        {
            var avg = elapsed.TotalSeconds / Stats.CompletedFiles;
            var remaining = Stats.TotalFiles - Stats.CompletedFiles;
            var eta = TimeSpan.FromSeconds(avg * remaining);
            Stats.EtaText = eta.ToString(@"hh\:mm\:ss");
        }
    }

    private static async Task<string> BuildPreviewAsync(string filePath, CancellationToken token)
    {
        var builder = new StringBuilder();
        await using var stream = new FileStream(
            filePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 1024 * 8,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        using var reader = new StreamReader(stream);
        string? line;
        var count = 0;
        const int maxLines = 60;

        while (count < maxLines && (line = await reader.ReadLineAsync().ConfigureAwait(false)) is not null)
        {
            token.ThrowIfCancellationRequested();
            builder.AppendLine(line);
            count++;
        }

        return builder.ToString().TrimEnd();
    }

    private HashSet<string> GetAllowedExtensions()
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var option in ExtensionOptions.Where(o => o.IsChecked))
        {
            set.Add(option.Extension.StartsWith(".") ? option.Extension : "." + option.Extension);
        }

        return set;
    }

    private static IEnumerable<FileExtensionOption> CreateDefaultExtensions() =>
        new[]
        {
            new FileExtensionOption(".txt"),
            new FileExtensionOption(".md"),
            new FileExtensionOption(".log"),
            new FileExtensionOption(".csv"),
            new FileExtensionOption(".json")
        };

    private void RefreshCommandStates()
    {
        ClearFilesCommand.RaiseCanExecuteChanged();
        ProcessFilesCommand.RaiseCanExecuteChanged();
        MergeFilesCommand.RaiseCanExecuteChanged();
        ExportRangesCommand.RaiseCanExecuteChanged();
        SearchCommand.RaiseCanExecuteChanged();
        CancelCommand.RaiseCanExecuteChanged();
    }
}
