namespace DocumentDeduplicator.Models;

public class SummarySentence : ObservableObject
{
    private bool _isSelected;

    public SummarySentence(string text, double score, int order)
    {
        Text = text;
        Score = score;
        Order = order;
    }

    public string Text { get; }

    public double Score { get; }

    public int Order { get; }

    public bool IsSelected
    {
        get => _isSelected;
        set => SetProperty(ref _isSelected, value);
    }
}
