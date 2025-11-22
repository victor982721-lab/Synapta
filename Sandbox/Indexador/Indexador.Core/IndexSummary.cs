using System;

namespace Indexador.Core
{
    public sealed record IndexSummary
    {
        public int ScannedFiles { get; init; }
        public int UpdatedFiles { get; init; }
        public int SkippedFiles { get; init; }
        public int RemovedFiles { get; init; }
        public TimeSpan Duration { get; init; }
        public string DatabasePath { get; init; } = string.Empty;
        public string RootPath { get; init; } = string.Empty;
    }
}
