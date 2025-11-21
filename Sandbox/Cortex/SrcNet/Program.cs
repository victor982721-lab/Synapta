using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Collections.Generic;
using System.Management.Automation.Language;

namespace Convertir_Parseo
{
    internal static class Program
    {
        static int Main(string[] args)
        {
            if (args.Length == 0 || args[0] == "-h" || args[0] == "--help")
            {
                PrintUsage();
                return 1;
            }

            var inputPath = args[0];

            if (!File.Exists(inputPath))
            {
                Console.Error.WriteLine($"No se encontró el archivo: {inputPath}");
                return 1;
            }

            bool inPlace = args.Skip(1).Any(a => string.Equals(a, "--in-place", StringComparison.OrdinalIgnoreCase));

            string originalText = File.ReadAllText(inputPath, Encoding.UTF8);

            Console.WriteLine($"Analizando: {inputPath}");
            Console.WriteLine();

            var result = AnalyzeAndFix(originalText);

            if (!result.Success)
            {
                Console.WriteLine("No se pudo corregir heurísticamente el script.");
            }

            string outputPath = inPlace
                ? inputPath
                : GetOutputPath(inputPath);

            File.WriteAllText(outputPath, result.FixedText, Encoding.UTF8);

            Console.WriteLine();
            Console.WriteLine($"Análisis completado. Errores originales: {result.OriginalErrorCount}.");
            Console.WriteLine(result.FixedErrorCount == 0
                ? "El script corregido no presenta errores de parseo."
                : $"El script corregido aún presenta {result.FixedErrorCount} errores de parseo.");

            Console.WriteLine($"Archivo generado: {outputPath}");
            return 0;
        }

        private static void PrintUsage()
        {
            Console.WriteLine("Uso:");
            Console.WriteLine("  Convertir_Parseo.exe <ruta_script.ps1> [--in-place]");
            Console.WriteLine();
            Console.WriteLine("Ejemplo:");
            Console.WriteLine("  Convertir_Parseo.exe C\\Scripts\\MiScript.ps1");
        }

        private static string GetOutputPath(string inputPath)
        {
            string dir = Path.GetDirectoryName(inputPath) ?? "";
            string name = Path.GetFileNameWithoutExtension(inputPath);
            string ext = Path.GetExtension(inputPath);
            string candidate = Path.Combine(dir, $"{name}.fixed{ext}");
            int i = 1;
            while (File.Exists(candidate))
            {
                candidate = Path.Combine(dir, $"{name}.fixed.{i}{ext}");
                i++;
            }
            return candidate;
        }

        private sealed record FixResult(
            bool Success,
            string FixedText,
            int OriginalErrorCount,
            int FixedErrorCount
        );

        private static FixResult AnalyzeAndFix(string text)
        {
            // Parse original
            Token[] tokens;
            ParseError[] errors;
            var ast = Parser.ParseInput(text, out tokens, out errors);

            if (errors.Length == 0)
            {
                // Nada que corregir
                Console.WriteLine("No se encontraron errores de parseo en el script original.");
                return new FixResult(true, text, 0, 0);
            }

            Console.WriteLine("Errores detectados en el script original:");
            foreach (var e in errors)
            {
                Console.WriteLine($"  Línea {e.Extent.StartLineNumber}, Col {e.Extent.StartColumnNumber}: {e.Message}");
            }

            string fixedText = ApplyHeuristicFixes(text, errors);

            // Re-parse
            Token[] tokens2;
            ParseError[] errors2;
            var ast2 = Parser.ParseInput(fixedText, out tokens2, out errors2);

            Console.WriteLine();
            Console.WriteLine("Después de aplicar fixes heurísticos:");
            if (errors2.Length == 0)
            {
                Console.WriteLine("  No se encontraron errores de parseo.");
            }
            else
            {
                foreach (var e in errors2)
                {
                    Console.WriteLine($"  Línea {e.Extent.StartLineNumber}, Col {e.Extent.StartColumnNumber}: {e.Message}");
                }
            }

            bool ok = errors2.Length <= errors.Length;

            return new FixResult(ok, fixedText, errors.Length, errors2.Length);
        }

        private static string ApplyHeuristicFixes(string text, IReadOnlyList<ParseError> errors)
        {
            var sb = new StringBuilder(text);

            // Heurística muy simple: intentar cerrar ) } ] si faltan, al final del archivo.
            var allMessages = string.Join("\n", errors.Select(e => e.Message));

            int difParen = CountChar(text, '(') - CountChar(text, ')');
            int difBrace = CountChar(text, '{') - CountChar(text, '}');
            int difBracket = CountChar(text, '[') - CountChar(text, ']');

            int toAddParen = Math.Max(0, difParen);
            int toAddBrace = Math.Max(0, difBrace);
            int toAddBracket = Math.Max(0, difBracket);

            if (allMessages.IndexOf("Missing closing ')'", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                toAddParen = Math.Max(toAddParen, 1);
            }
            if (allMessages.IndexOf("Missing closing '}'", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                toAddBrace = Math.Max(toAddBrace, 1);
            }
            if (allMessages.IndexOf("Missing closing ']'", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                toAddBracket = Math.Max(toAddBracket, 1);
            }

            if (toAddParen + toAddBrace + toAddBracket > 0)
            {
                sb.AppendLine();
                sb.AppendLine("# --- Fixes heurísticos añadidos automáticamente ---");
            }

            for (int i = 0; i < toAddParen; i++)
            {
                sb.AppendLine(")");
            }
            for (int i = 0; i < toAddBrace; i++)
            {
                sb.AppendLine("}");
            }
            for (int i = 0; i < toAddBracket; i++)
            {
                sb.AppendLine("]");
            }

            return sb.ToString();
        }

        private static int CountChar(string source, char ch)
        {
            int c = 0;
            foreach (var x in source)
            {
                if (x == ch)
                    c++;
            }
            return c;
        }
    }
}
