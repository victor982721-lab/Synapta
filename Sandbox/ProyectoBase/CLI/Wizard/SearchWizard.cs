using System;
using ProyectoBase.Core.Search;

namespace ProyectoBase.CLI.Wizard
{
    public static class SearchWizard
    {
        public static void Start()
        {
            Console.WriteLine(""--- Búsqueda Avanzada (Wizard) ---"");

            Console.Write(""Ruta: "");
            string path = Console.ReadLine();

            Console.Write(""Patrón Regex: "");
            string pattern = Console.ReadLine();

            Console.Write(""Buscar recursivo (s/n): "");
            bool recursive = (Console.ReadLine()?.ToLower() == ""s"");

            Console.Write(""Distinguir mayúsculas (s/n): "");
            bool caseSensitive = (Console.ReadLine()?.ToLower() == ""s"");

            Console.Write(""Máximo de resultados: "");
            int max = int.Parse(Console.ReadLine());

            Console.Write(""Extensiones (comma separadas): "");
            var exts = new System.Collections.Generic.List<string>(Console.ReadLine().Split(','));

            var opt = new SearchOptions
            {
                Path = path,
                Pattern = pattern,
                Recursive = recursive,
                CaseSensitive = caseSensitive,
                MaxResults = max,
                Extensions = exts
            };

            Console.WriteLine();
            Console.WriteLine(""--- Resultados ---"");

            var results = SearchEngine.FindMatches(opt);

            foreach (var r in results)
                Console.WriteLine(r);
        }
    }
}
