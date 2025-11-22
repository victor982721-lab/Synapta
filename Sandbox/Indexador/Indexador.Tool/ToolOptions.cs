using System;

namespace Indexador.Tool
{
    public sealed record ToolOptions
    {
        public string RootPath { get; set; } = Environment.CurrentDirectory;
        public string? DatabasePath { get; set; }
        public bool ForceHash { get; set; }
        public bool CleanMissing { get; set; } = true;
        public bool ShowDuplicates { get; set; }
        public string Source { get; set; } = "Indexador.Tool";
        public string HashAlgorithm { get; set; } = "CRC32";
        public bool ShowFileList { get; set; }
        public bool ShowFileMap { get; set; }
        public bool Watch { get; set; }
        public int DebounceMs { get; set; } = 1500;
    }
}
