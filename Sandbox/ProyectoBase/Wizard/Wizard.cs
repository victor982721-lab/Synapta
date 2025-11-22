using System;
using ProyectoBase.Core;

namespace ProyectoBase.Wizard
{
    public static class WizardRunner
    {
        public static void Run()
        {
            Console.WriteLine("=== ProyectoBase Wizard ===");
            Console.WriteLine();

            var options = new Options();

            // PATH
            Console.Write("Ingrese la ruta de trabajo: ");
            options.Path = Console.ReadLine()?.Trim() ?? string.Empty;

            // VERBOSE
            Console.Write("¿Modo verbose? (s/n): ");
            var verboseInput = Console.ReadLine()?.Trim().ToLower();
            options.Verbose = verboseInput == "s" || verboseInput == "si" || verboseInput == "sí";

            Console.WriteLine();
            Console.WriteLine("Procesando...");
            Console.WriteLine();

            var result = Logic.Execute(options);

            Console.WriteLine(result.Message);
        }
    }
}
