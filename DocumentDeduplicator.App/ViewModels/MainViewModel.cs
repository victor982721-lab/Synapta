using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using DocumentDeduplicator.Commands;
using DocumentDeduplicator.Exporting;
using DocumentDeduplicator.Models;
using DocumentDeduplicator.Services;
using WinForms = System.Windows.Forms;

namespace DocumentDeduplicator.ViewModels;

public class MainViewModel : ObservableObject
{
    private const string DefaultStopwords = "de,la,que,el,en,y,a,los,del,se,las,por,un,para,con,no,una,su,al,lo,como,mas,o,pero,sus,le,ya,si,sobre,este,porque,esta,entre,cuando,muy,sin,todo,esto,mi,yo,tu,ella,ello";

    private readonly FileService _fileService = new();
    private readonly TextNormalizationService _normalizationService = new();
    private readonly FrequencyAnalysisService _frequencyService;
    private readonly ShingleAnalysisService _shingleService;
    private readonly DeduplicationService _deduplicationService;
    private readonly SummaryService _summaryService;
    private readonly NotesService _notesService = new();
    private readonly ExportService _exportService = new();
    private readonly ThemeService _themeService;

    private FileSelection? _selectedFile;
    private string? _selectedFileContent;
    private string _stopWordsText = DefaultStopwords;
    private bool _isBusy;
    private string _progressText = "Listo";
    private double _progressValue;
    private string _summaryText = string.Empty;
    private NoteItem? _selectedNote;
    private string _fragmentLabelInput = "Fragmento personalizado";
    private int _fragmentStartLine = 1;
    private int _fragmentEndLine = 5;
    private string? _jsonStatus;
    private bool _usePlaceholders = true;
    private bool _sortJsonKeys = true;

    public MainViewModel(ThemeService themeService)
    {
        _themeService = themeService;
        _frequencyService = new FrequencyAnalysisService(_fileService, _normalizationService);
        _shingleService = new ShingleAnalysisService(_fileService, _normalizationService);
        _deduplicationService = new DeduplicationService(_fileService);
        _summaryService = new SummaryService(_fileService, _normalizationService);

        Files = new ObservableCollection<FileSelection>();
        WordFrequencies = new ObservableCollection<WordFrequency>();
        PhraseFrequencies = new ObservableCollection<PhraseFrequency>();
        DuplicateBlocks = new ObservableCollection<DuplicateBlock>();
        Similarities = new ObservableCollection<SimilarityResult>();
        DeduplicationPreviews = new ObservableCollection<DeduplicationPreview>();
        SummarySentences = new ObservableCollection<SummarySentence>();
        Notes = new ObservableCollection<NoteItem>();
        ExtractedFragments = new ObservableCollection<TextFragment>();

        SelectFilesCommand = new AsyncRelayCommand(_ => SelectFilesAsync());
        ClearFilesCommand = new RelayCommand(_ => ClearFiles());
        AnalyzeCommand = new AsyncRelayCommand(_ => RunAnalysisAsync());
        ExtractFragmentCommand = new AsyncRelayCommand(_ => ExtractFragmentAsync());
        AutoExtractJsonCommand = new AsyncRelayCommand(_ => AutoExtractJsonAsync());
        ApplyDeduplicationCommand = new AsyncRelayCommand(_ => ApplyDeduplicationAsync());
        ExportCommand = new AsyncRelayCommand(_ => ExportAsync());
        AddNoteCommand = new RelayCommand(_ => AddNote());
        DeleteNoteCommand = new RelayCommand(_ => DeleteNote(), _ => SelectedNote is not null);
        SaveNotesCommand = new AsyncRelayCommand(_ => SaveNotesAsync());
        ToggleThemeCommand = new RelayCommand(_ => _themeService.Toggle());

        TopWordsCount = 25;
        PhraseSize = 3;
        TopPhrasesCount = 15;
        ShingleSize = 5;
        DeduplicationMinFiles = 2;
        DeduplicationMinOccurrences = 3;
        SummarySentenceCount = 8;
        SimilarityThreshold = 0.3;

        _ = LoadNotesAsync();
    }

    public ObservableCollection<FileSelection> Files { get; }

    public ObservableCollection<WordFrequency> WordFrequencies { get; }

    public ObservableCollection<PhraseFrequency> PhraseFrequencies { get; }

    public ObservableCollection<DuplicateBlock> DuplicateBlocks { get; }

    public ObservableCollection<SimilarityResult> Similarities { get; }

    public ObservableCollection<DeduplicationPreview> DeduplicationPreviews { get; }

    public ObservableCollection<SummarySentence> SummarySentences { get; }

    public ObservableCollection<NoteItem> Notes { get; }

    public ObservableCollection<TextFragment> ExtractedFragments { get; }

    public ICommand SelectFilesCommand { get; }

    public ICommand ClearFilesCommand { get; }

    public ICommand AnalyzeCommand { get; }

    public ICommand ExtractFragmentCommand { get; }

    public ICommand AutoExtractJsonCommand { get; }

    public ICommand ApplyDeduplicationCommand { get; }

    public ICommand ExportCommand { get; }

    public ICommand AddNoteCommand { get; }

    public ICommand DeleteNoteCommand { get; }

    public ICommand SaveNotesCommand { get; }

    public ICommand ToggleThemeCommand { get; }

    public FileSelection? SelectedFile
    {
        get => _selectedFile;
        set
        {
            if (SetProperty(ref _selectedFile, value) && value is not null)
            {
                _ = LoadPreviewAsync(value);
            }
        }
    }

    public string? SelectedFileContent
    {
        get => _selectedFileContent;
        set => SetProperty(ref _selectedFileContent, value);
    }

    public string StopWordsText
    {
        get => _stopWordsText;
        set => SetProperty(ref _stopWordsText, value);
    }

    public bool IsBusy
    {
        get => _isBusy;
        set => SetProperty(ref _isBusy, value);
    }

    public string ProgressText
    {
        get => _progressText;
        set => SetProperty(ref _progressText, value);
    }

    public double ProgressValue
    {
        get => _progressValue;
        set => SetProperty(ref _progressValue, value);
    }

    public string SummaryText
    {
        get => _summaryText;
        set => SetProperty(ref _summaryText, value);
    }

    public NoteItem? SelectedNote
    {
        get => _selectedNote;
        set => SetProperty(ref _selectedNote, value);
    }

    public string FragmentLabelInput
    {
        get => _fragmentLabelInput;
        set => SetProperty(ref _fragmentLabelInput, value);
    }

    public int FragmentStartLine
    {
        get => _fragmentStartLine;
        set => SetProperty(ref _fragmentStartLine, value);
    }

    public int FragmentEndLine
    {
        get => _fragmentEndLine;
        set => SetProperty(ref _fragmentEndLine, value);
    }

    public string? JsonStatus
    {
        get => _jsonStatus;
        set => SetProperty(ref _jsonStatus, value);
    }

    public bool UsePlaceholders
    {
        get => _usePlaceholders;
        set => SetProperty(ref _usePlaceholders, value);
    }

    public bool SortJsonKeys
    {
        get => _sortJsonKeys;
        set => SetProperty(ref _sortJsonKeys, value);
    }

    public int TopWordsCount { get; set; }

    public int PhraseSize { get; set; }

    public int TopPhrasesCount { get; set; }

    public int ShingleSize { get; set; }

    public int DeduplicationMinFiles { get; set; }

    public int DeduplicationMinOccurrences { get; set; }

    public double SimilarityThreshold { get; set; }

    public int SummarySentenceCount { get; set; }

    private async Task SelectFilesAsync()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "Textos|*.txt;*.md;*.json;*.csv;*.log|Todos|*.*",
            Multiselect = true
        };

        if (dialog.ShowDialog() == true)
        {
            Files.Clear();
            foreach (var file in dialog.FileNames)
            {
                var info = new FileInfo(file);
                Files.Add(new FileSelection(file, info.Length));
            }

            await SaveNotesAsync();
        }
    }

    private void ClearFiles()
    {
        Files.Clear();
        WordFrequencies.Clear();
        PhraseFrequencies.Clear();
        DuplicateBlocks.Clear();
        Similarities.Clear();
        DeduplicationPreviews.Clear();
        SummarySentences.Clear();
        SelectedFile = null;
        SelectedFileContent = null;
        SummaryText = string.Empty;
    }

    private async Task LoadPreviewAsync(FileSelection file)
    {
        try
        {
            var preview = await _fileService.ReadAllTextAsync(file.Path);
            file.Preview = preview.Length > 5000 ? preview[..5000] + "..." : preview;
            SelectedFileContent = file.Preview;
        }
        catch (Exception ex)
        {
            ProgressText = $"No se pudo cargar el archivo: {ex.Message}";
        }
    }

    private async Task ExtractFragmentAsync()
    {
        if (SelectedFile is null)
        {
            return;
        }

        try
        {
            var fragment = await _fileService.ExtractFragmentByLinesAsync(SelectedFile.Path, FragmentStartLine, FragmentEndLine, FragmentLabelInput);
            SelectedFile.Fragments.Add(fragment);
            ExtractedFragments.Add(fragment);
            JsonStatus = $"Fragmento guardado ({fragment.Hash[..8]}...)";
        }
        catch (Exception ex)
        {
            JsonStatus = ex.Message;
        }
    }

    private async Task AutoExtractJsonAsync()
    {
        if (SelectedFile is null)
        {
            return;
        }

        try
        {
            var fragments = await _fileService.DetectJsonFragmentsAsync(SelectedFile.Path, SortJsonKeys);
            SelectedFile.Fragments.Clear();
            foreach (var fragment in fragments)
            {
                SelectedFile.Fragments.Add(fragment);
                ExtractedFragments.Add(fragment);
            }

            JsonStatus = fragments.Count == 0 ? "No se detectaron bloques JSON" : $"Se detectaron {fragments.Count} fragmentos JSON";
        }
        catch (Exception ex)
        {
            JsonStatus = ex.Message;
        }
    }

    private async Task RunAnalysisAsync()
    {
        if (!Files.Any())
        {
            ProgressText = "Agrega archivos antes de analizar";
            return;
        }

        IsBusy = true;
        ProgressValue = 0;
        var stopwords = BuildStopwordsSet();
        try
        {
            ProgressText = "Analizando palabras...";
            var words = await _frequencyService.ComputeWordFrequenciesAsync(Files, TopWordsCount, stopwords);
            UpdateCollection(WordFrequencies, words);
            ProgressValue = 0.25;

            ProgressText = "Analizando frases...";
            var phrases = await _frequencyService.ComputePhraseFrequenciesAsync(Files, PhraseSize, TopPhrasesCount, stopwords);
            UpdateCollection(PhraseFrequencies, phrases);
            ProgressValue = 0.45;

            ProgressText = "Buscando duplicados...";
            var (duplicates, similarities) = await _shingleService.AnalyzeAsync(Files, ShingleSize, stopwords);
            UpdateCollection(DuplicateBlocks, duplicates);
            UpdateCollection(Similarities, similarities.Where(s => s.SimilarityPercentage >= SimilarityThreshold));
            ProgressValue = 0.7;

            var previews = _deduplicationService.BuildPreview(duplicates, DeduplicationMinFiles, DeduplicationMinOccurrences);
            UpdateCollection(DeduplicationPreviews, previews);

            ProgressText = "Generando resumen...";
            var summary = await _summaryService.BuildSummaryAsync(Files, SummarySentenceCount, stopwords, phrases);
            UpdateCollection(SummarySentences, summary);
            SummaryText = string.Join(' ', SummarySentences.Select(s => s.Text));
            ProgressValue = 1;
            ProgressText = "Análisis completado";
        }
        catch (Exception ex)
        {
            ProgressText = $"Error: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    private async Task ApplyDeduplicationAsync()
    {
        var selected = DeduplicationPreviews.Where(p => p.IsSelected).ToList();
        if (selected.Count == 0)
        {
            ProgressText = "Selecciona fragmentos para deduplicar";
            return;
        }

        var firstFile = Files.FirstOrDefault();
        if (firstFile is null)
        {
            return;
        }

        var rootFolder = Path.GetDirectoryName(firstFile.Path) ?? Environment.CurrentDirectory;
        var fragmentFolder = Path.Combine(rootFolder, "Fragmentos_deduplicados");
        var backupFolder = Path.Combine(rootFolder, "Backup");
        try
        {
            await _deduplicationService.ApplyAsync(selected, UsePlaceholders, fragmentFolder, backupFolder);
            ProgressText = $"Deduplicación aplicada ({selected.Count} fragmentos)";
        }
        catch (Exception ex)
        {
            ProgressText = $"Error deduplicando: {ex.Message}";
        }
    }

    private async Task ExportAsync()
    {
        using var dialog = new WinForms.FolderBrowserDialog
        {
            Description = "Selecciona la carpeta destino para los reportes"
        };

        if (dialog.ShowDialog() != WinForms.DialogResult.OK || string.IsNullOrWhiteSpace(dialog.SelectedPath))
        {
            return;
        }

        var content = new ExportContent(WordFrequencies.ToList(), PhraseFrequencies.ToList(), DuplicateBlocks.ToList(), DeduplicationPreviews.ToList(), SummarySentences.ToList(), Notes.ToList());
        try
        {
            await _exportService.ExportAsync(dialog.SelectedPath, content);
            ProgressText = $"Resultados exportados a {dialog.SelectedPath}";
        }
        catch (Exception ex)
        {
            ProgressText = $"Error exportando: {ex.Message}";
        }
    }

    private void AddNote()
    {
        var note = new NoteItem
        {
            Title = "Nueva nota",
            Content = string.Empty,
            RelatedFiles = string.Join('\n', Files.Select(f => f.Path))
        };
        Notes.Insert(0, note);
        SelectedNote = note;
    }

    private void DeleteNote()
    {
        if (SelectedNote is null)
        {
            return;
        }

        Notes.Remove(SelectedNote);
        SelectedNote = null;
    }

    private async Task SaveNotesAsync()
    {
        try
        {
            await _notesService.SaveAsync(Notes);
        }
        catch (Exception ex)
        {
            ProgressText = $"No se pudieron guardar las notas: {ex.Message}";
        }
    }

    private async Task LoadNotesAsync()
    {
        try
        {
            var stored = await _notesService.LoadAsync();
            System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            {
                Notes.Clear();
                foreach (var note in stored.OrderByDescending(n => n.UpdatedAt))
                {
                    Notes.Add(note);
                }
            });
        }
        catch (Exception ex)
        {
            ProgressText = $"No se pudieron cargar notas: {ex.Message}";
        }
    }

    private ISet<string> BuildStopwordsSet()
    {
        return new HashSet<string>(StopWordsText
            .Split(new[] { ',', '\n', '\r', '\t' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(word => word.Trim().ToLowerInvariant()), StringComparer.OrdinalIgnoreCase);
    }

    private static void UpdateCollection<T>(ObservableCollection<T> target, IEnumerable<T> items)
    {
        target.Clear();
        foreach (var item in items)
        {
            target.Add(item);
        }
    }
}
