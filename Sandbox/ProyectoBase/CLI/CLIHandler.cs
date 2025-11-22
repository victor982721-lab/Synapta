using System;
using ProyectoBase.Core;

namespace ProyectoBase.CLI
{
    public static class CLIHandler
    {
        public static void Run(string[] args)
        {
            var opt = Parse(args);
            var result = Logic.Execute(opt);

            if (opt.Verbose)
                Console.WriteLine($"[CLI] Resultado: {(result.Success ? "OK" : "FAIL")}");

            Console.WriteLine(result.Message);
        }

        private static Options Parse(string[] args)
        {
            var o = new Options();

            for (int i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "--path":
                        if (i + 1 < args.Length) 
                            o.Path = args[++i];
                        break;

                    case "--verbose":
                        o.Verbose = true;
                        break;

                    case "--help":
                    case "-h":
                        ShowHelp();
                        Environment.Exit(0);
                        break;
                }
            }

            return o;
        }

        private static void ShowHelp()
        {
            Console.WriteLine("ProyectoBase - CLI");
            Console.WriteLine();
            Console.WriteLine("Parámetros disponibles:");
            Console.WriteLine("  --path <ruta>      Ruta de trabajo");
            Console.WriteLine("  --verbose          Modo detallado");
            Console.WriteLine("  --help, -h         Mostrar ayuda");
            Console.WriteLine();
            Console.WriteLine("Ejemplo:");
            Console.WriteLine("  ProyectoBase.exe --path C:\\Datos --verbose");
        }
    }
}
