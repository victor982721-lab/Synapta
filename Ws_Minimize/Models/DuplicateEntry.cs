namespace Deduplinside.Models;

public class DuplicateEntry
{
    public required string FilePath { get; init; }

    public required int LineNumber { get; init; }

    public required string Content { get; init; }
}
