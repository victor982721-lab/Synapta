namespace Deduplinside.Models;

public class SearchHit
{
    public required string FilePath { get; init; }

    public required int LineNumber { get; init; }

    public required string Snippet { get; init; }
}
