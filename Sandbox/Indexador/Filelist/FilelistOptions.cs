using System;

namespace Filelist
{
    internal sealed record FilelistOptions
    {
        public string RootPath { get; init; } = Environment.CurrentDirectory;
        public string? DatabasePath { get; init; }
        public bool ShowList { get; init; }
        public bool ShowSummary { get; init; } = true;
        public bool ShowTop { get; init; }
        public int TopCount { get; init; } = 20;
        public bool ShowDuplicates { get; init; }
        public bool ShowFileMap { get; init; }
        public string? ExtensionFilter { get; init; }
        public long? MinSize { get; init; }
        public long? MaxSize { get; init; }
        public bool Verbose { get; init; }

        public static FilelistOptions? Parse(string[] args)
        {
            if (args.Length == 0)
                return new FilelistOptions();

            var options = new FilelistOptions();

            for (var i = 0; i < args.Length; i++)
            {
                var token = args[i].ToLowerInvariant();

                switch (token)
                {
                    case "--root":
                        if (i + 1 < args.Length)
                            options = options with { RootPath = args[++i] };
                        break;
                    case "--db":
                    case "--database":
                        if (i + 1 < args.Length)
                            options = options with { DatabasePath = args[++i] };
                        break;
                    case "--list":
                        options = options with { ShowList = true };
                        break;
                    case "--top":
                        if (i + 1 < args.Length && int.TryParse(args[++i], out var count))
                            options = options with { ShowTop = true, TopCount = Math.Max(1, count) };
                        else
                            options = options with { ShowTop = true };
                        break;
                    case "--duplicates":
                        options = options with { ShowDuplicates = true };
                        break;
                    case "--map":
                        options = options with { ShowFileMap = true };
                        break;
                    case "--extension":
                        if (i + 1 < args.Length)
                            options = options with { ExtensionFilter = args[++i] };
                        break;
                    case "--min-size":
                        if (i + 1 < args.Length && long.TryParse(args[++i], out var min))
                            options = options with { MinSize = Math.Max(0, min) };
                        break;
                    case "--max-size":
                        if (i + 1 < args.Length && long.TryParse(args[++i], out var max))
                            options = options with { MaxSize = Math.Max(0, max) };
                        break;
                    case "--no-summary":
                        options = options with { ShowSummary = false };
                        break;
                    case "--verbose":
                        options = options with { Verbose = true };
                        break;
                    case "--help":
                    case "-h":
                        return null;
                    default:
                        Console.WriteLine($"Argumento desconocido: {args[i]}");
                        return null;
                }
            }

            return options;
        }
    }
}
