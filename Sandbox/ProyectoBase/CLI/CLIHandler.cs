using System;
using ProyectoBase.Core.Search;

namespace ProyectoBase.CLI
{
    public static class CLIHandler
    {
        public static void Run(string[] args)
        {
            if (args.Length == 0)
            {
                ShowHelp();
                return;
            }

            var cmd = args[0].ToLower();

            switch (cmd)
            {
                case ""search"":
                    RunSearch(args);
                    break;

                case ""--help"":
                default:
                    ShowHelp();
                    break;
            }
        }

        private static void RunSearch(string[] args)
        {
            string path = ""C:\\";;
            string pattern = """";;
            bool recursive = true;
            bool caseSensitive = false;
            int max = 200;
            var extensions = new System.Collections.Generic.List<string> { ""txt"", ""log"" };

            for (int i = 1; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case ""--path"": path = args[++i]; break;
                    case ""--pattern"": pattern = args[++i]; break;
                    case ""--recursive"": recursive = true; break;
                    case ""--norecursive"": recursive = false; break;
                    case ""--casesensitive"": caseSensitive = true; break;
                    case ""--max"": max = int.Parse(args[++i]); break;
                    case ""--ext"": extensions = new System.Collections.Generic.List<string>(args[++i].Split(',')); break;
                }
            }

            var opt = new SearchOptions
            {
                Path = path,
                Pattern = pattern,
                Recursive = recursive,
                CaseSensitive = caseSensitive,
                MaxResults = max,
                Extensions = extensions
            };

            var results = SearchEngine.FindMatches(opt);

            foreach (var r in results)
                Console.WriteLine(r);
        }

        private static void ShowHelp()
        {
            Console.WriteLine(""Comandos disponibles:"");
            Console.WriteLine(""  search --path <ruta> --pattern <regex> [--recursive|--norecursive] --max 200 --ext txt,log"");
        }
    }
}
