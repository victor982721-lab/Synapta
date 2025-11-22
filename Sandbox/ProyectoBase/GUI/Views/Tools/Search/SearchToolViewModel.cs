using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace ProyectoBase.GUI.Views.Tools.Search
{
    public class SearchToolViewModel
    {
        private readonly Action<List<string>> Output;

        public SearchToolViewModel(Action<List<string>> callback)
        {
            Output = callback;
        }

        public void Execute(Dictionary<string, string> data)
        {
            var results = new List<string>();

            string path = data["Ruta"];
            string pattern = data["Patrón Regex"];
            bool recursive = data["Buscar en subcarpetas"] == "true";
            bool caseSensitive = data["Distinguir mayúsculas"] == "true";
            int maxResults = int.Parse(data["Máximo de resultados"]);
            var exts = data["Extensiones (coma separadas)"].Split(',');

            var files = Directory.GetFiles(
                path, "*.*",
                recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly
            );

            foreach (var f in files)
            {
                foreach (var ext in exts)
                {
                    if (f.EndsWith(ext.Trim(), StringComparison.OrdinalIgnoreCase))
                    {
                        string content = File.ReadAllText(f);
                        var options = caseSensitive ? RegexOptions.None : RegexOptions.IgnoreCase;

                        var matches = Regex.Matches(content, pattern, options);

                        foreach (Match m in matches)
                        {
                            results.Add($"{f} → {m.Value}");
                            if (results.Count >= maxResults)
                                break;
                        }
                    }
                }

                if (results.Count >= maxResults)
                    break;
            }

            Output(results);
        }
    }
}
