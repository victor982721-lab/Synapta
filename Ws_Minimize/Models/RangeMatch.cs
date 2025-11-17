namespace Deduplinside.Models;

public class RangeMatch
{
    public required string FilePath { get; init; }

    public required int StartLine { get; init; }

    public required int EndLine { get; init; }

    public required string Content { get; init; }
}
