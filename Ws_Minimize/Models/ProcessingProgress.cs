namespace Deduplinside.Models;

public class ProcessingProgress
{
    public string? FilePath { get; init; }

    public long ProcessedLines { get; init; }

    public long DuplicateLines { get; init; }
}
