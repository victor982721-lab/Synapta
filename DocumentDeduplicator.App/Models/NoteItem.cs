namespace DocumentDeduplicator.Models;

public class NoteItem : ObservableObject
{
    private string _title;
    private string _content;
    private DateTime _updatedAt;
    private string? _relatedFiles;

    public NoteItem()
    {
        _title = string.Empty;
        _content = string.Empty;
        _updatedAt = DateTime.UtcNow;
    }

    public Guid Id { get; init; } = Guid.NewGuid();

    public string Title
    {
        get => _title;
        set
        {
            if (SetProperty(ref _title, value))
            {
                UpdatedAt = DateTime.UtcNow;
            }
        }
    }

    public string Content
    {
        get => _content;
        set
        {
            if (SetProperty(ref _content, value))
            {
                UpdatedAt = DateTime.UtcNow;
            }
        }
    }

    public string? RelatedFiles
    {
        get => _relatedFiles;
        set => SetProperty(ref _relatedFiles, value);
    }

    public DateTime UpdatedAt
    {
        get => _updatedAt;
        private set => SetProperty(ref _updatedAt, value);
    }
}
