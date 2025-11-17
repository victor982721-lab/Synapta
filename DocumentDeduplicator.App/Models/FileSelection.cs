using System.Collections.ObjectModel;

namespace DocumentDeduplicator.Models;

public class FileSelection : ObservableObject
{
    private string? _preview;
    private bool _isJsonCandidate;

    public FileSelection(string path, long size)
    {
        Path = path;
        Size = size;
        Fragments = new ObservableCollection<TextFragment>();
    }

    public string Path { get; }

    public long Size { get; }

    public string Name => System.IO.Path.GetFileName(Path);

    public ObservableCollection<TextFragment> Fragments { get; }

    public string? Preview
    {
        get => _preview;
        set => SetProperty(ref _preview, value);
    }

    public bool IsJsonCandidate
    {
        get => _isJsonCandidate;
        set => SetProperty(ref _isJsonCandidate, value);
    }
}
