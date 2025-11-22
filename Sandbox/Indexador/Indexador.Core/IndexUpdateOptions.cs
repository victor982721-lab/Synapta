namespace Indexador.Core
{
    public sealed record IndexUpdateOptions
    {
        public string RootPath { get; init; } = string.Empty;
        public string? DatabasePath { get; init; }
        public bool ForceHash { get; init; }
        public bool CleanMissing { get; init; } = true;
        public string HashAlgorithm { get; init; } = "CRC32";
        public string Source { get; init; } = "Indexador.Core";
        public int MaxParallelism { get; init; } = Environment.ProcessorCount;
    }
}
