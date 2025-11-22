using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace ProyectoBase.Core.Search
{
    public static class SearchEngine
    {
        public static List<string> FindMatches(SearchOptions opt)
        {
            var results = new List<string>();

            if (!Directory.Exists(opt.Path))
                return results;

            var files = Directory.GetFiles(
                opt.Path,
                ""*.*"",
                opt.Recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly
            );

            foreach (var file in files)
            {
                if (!MatchesExtension(file, opt.Extensions))
                    continue;

                string text;
                try { text = File.ReadAllText(file); }
                catch { continue; }

                var regexOptions = opt.CaseSensitive ? RegexOptions.None : RegexOptions.IgnoreCase;

                foreach (Match match in Regex.Matches(text, opt.Pattern, regexOptions))
                {
                    results.Add($"{file} → {match.Value}");

                    if (results.Count >= opt.MaxResults)
                        return results;
                }
            }

            return results;
        }

        private static bool MatchesExtension(string file, List<string> exts)
        {
            foreach (var ext in exts)
            {
                if (file.EndsWith(ext.Trim(), StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }
    }

    public class SearchOptions
    {
        public string Path { get; set; } = """";
        public string Pattern { get; set; } = """";
        public bool Recursive { get; set; } = false;
        public bool CaseSensitive { get; set; } = false;
        public int MaxResults { get; set; } = 100;
        public List<string> Extensions { get; set; } = new List<string>();
    }
}
