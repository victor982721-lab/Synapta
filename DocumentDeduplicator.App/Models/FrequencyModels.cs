namespace DocumentDeduplicator.Models;

public record WordFrequency(string Word, int Count, int FileCount);

public record PhraseFrequency(string Phrase, int Count, int FileCount);

public record DuplicateBlock(string Hash, string Text, int Frequency, int FileCount, IReadOnlyCollection<string> Files);

public record SimilarityResult(string FileA, string FileB, double SimilarityPercentage);

public class DeduplicationPreview : ObservableObject
{
    private bool _isSelected;

    public DeduplicationPreview(string label, string text, IReadOnlyCollection<string> files, int occurrences)
    {
        Label = label;
        Text = text;
        Files = files;
        Occurrences = occurrences;
    }

    public string Label { get; }

    public string Text { get; }

    public IReadOnlyCollection<string> Files { get; }

    public int Occurrences { get; }

    public bool IsSelected
    {
        get => _isSelected;
        set => SetProperty(ref _isSelected, value);
    }
}
