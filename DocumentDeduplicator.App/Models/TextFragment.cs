namespace DocumentDeduplicator.Models;

public class TextFragment : ObservableObject
{
    private string _content;
    private string? _prettyJson;

    public TextFragment(string label, string sourceFile, int startLine, int endLine, string content, bool isJson = false)
    {
        Label = label;
        SourceFile = sourceFile;
        StartLine = startLine;
        EndLine = endLine;
        _content = content;
        IsJson = isJson;
        Hash = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(content)));
    }

    public string Label { get; }

    public string SourceFile { get; }

    public int StartLine { get; }

    public int EndLine { get; }

    public string Hash { get; }

    public bool IsJson { get; }

    public string Content
    {
        get => _content;
        set => SetProperty(ref _content, value);
    }

    public string? PrettyJson
    {
        get => _prettyJson;
        set => SetProperty(ref _prettyJson, value);
    }
}
