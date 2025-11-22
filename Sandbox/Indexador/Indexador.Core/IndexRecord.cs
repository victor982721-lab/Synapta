using System;

namespace Indexador.Core
{
    public sealed record IndexRecord
    {
        public string FullPath { get; init; } = string.Empty;
        public string RootPath { get; init; } = string.Empty;
        public string RelativePath { get; init; } = string.Empty;
        public long Size { get; init; }
        public DateTime LastWriteUtc { get; init; }
        public string Hash { get; init; } = string.Empty;
        public string HashAlgorithm { get; init; } = "SHA256";
        public string Tags { get; init; } = string.Empty;
        public string Notes { get; init; } = string.Empty;
        public DateTime CreatedUtc { get; init; }
        public DateTime ModifiedUtc { get; init; }
        public string Source { get; init; } = string.Empty;
    }
}
