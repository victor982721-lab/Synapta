using System;
using System.Collections.Generic;
using ProyectoBase.Core.Search;

namespace ProyectoBase.GUI.Views.Tools.Search
{
    public class SearchToolViewModel
    {
        private readonly Action<List<string>> Callback;

        public SearchToolViewModel(Action<List<string>> outputCallback)
        {
            Callback = outputCallback;
        }

        public void Execute(Dictionary<string, string> data)
        {
            var opt = new SearchOptions
            {
                Path = data["Ruta"],
                Pattern = data["Patrón Regex"],
                Recursive = data["Buscar en subcarpetas"] == "true",
                CaseSensitive = data["Distinguir mayúsculas"] == "true",
                MaxResults = int.Parse(data["Máximo de resultados"]),
                Extensions = new List<string>(data["Extensiones (coma separadas)"].Split(','))
            };

            var results = SearchEngine.FindMatches(opt);
            Callback(results);
        }
    }
}
