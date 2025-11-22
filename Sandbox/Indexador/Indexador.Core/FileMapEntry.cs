namespace Indexador.Core
{
    public sealed record FileMapEntry
    {
        public string Directory { get; init; } = string.Empty;
        public int FileCount { get; init; }
        public long TotalSize { get; init; }
        public int DuplicateCount { get; init; }
    }
}
