namespace Deduplinside.Models;

public class FileProcessingResult
{
    public required string FilePath { get; init; }

    public required string OutputPath { get; init; }

    public long ProcessedLines { get; init; }

    public long DuplicateLines { get; init; }

    public IReadOnlyList<DuplicateEntry> DuplicateEntries { get; init; } = Array.Empty<DuplicateEntry>();
}
