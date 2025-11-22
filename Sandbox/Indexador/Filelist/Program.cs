using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Indexador.Core;

namespace Filelist
{
    internal static class Program
    {
        public static int Main(string[] args)
        {
            var options = FilelistOptions.Parse(args);
            if (options == null)
            {
                ShowHelp();
                return 1;
            }

            var manager = new IndexManager();
            var rootPath = Path.GetFullPath(options.RootPath);
            var databasePath = string.IsNullOrWhiteSpace(options.DatabasePath)
                ? Path.Combine(rootPath, "indexador.db")
                : options.DatabasePath!;

            if (!File.Exists(databasePath))
            {
                Console.WriteLine($"No se encontró el índice en '{databasePath}'. Ejecuta --root con el watcher o indexador primero.");
                return 1;
            }

            var stopwatch = Stopwatch.StartNew();
            var records = manager.GetRecords(rootPath, databasePath)
                .Where(FilterRecord(options))
                .OrderBy(record => record.RelativePath, StringComparer.OrdinalIgnoreCase)
                .ToList();
            stopwatch.Stop();

            if (options.Verbose)
            {
                Console.WriteLine($"Registros cargados en {stopwatch.Elapsed.TotalSeconds:F2}s ({records.Count} archivos).");
            }

            var duplicates = manager.FindDuplicates(records).ToList();

            if (options.ShowSummary)
            {
                PrintSummary(records, duplicates);
            }

            if (options.ShowTop)
            {
                PrintTop(records, options.TopCount);
            }

            if (options.ShowList)
            {
                PrintFileList(records);
            }

            if (options.ShowDuplicates)
            {
                PrintDuplicates(duplicates);
            }

            if (options.ShowFileMap)
            {
                var map = manager.BuildFileMap(rootPath, databasePath);
                PrintFileMap(map);
            }

            return 0;
        }

        private static Func<IndexRecord, bool> FilterRecord(FilelistOptions options)
        {
            return record =>
            {
                if (!string.IsNullOrWhiteSpace(options.ExtensionFilter))
                {
                    var extension = Path.GetExtension(record.RelativePath);
                    if (!extension.Equals(options.ExtensionFilter, StringComparison.OrdinalIgnoreCase))
                        return false;
                }

                if (options.MinSize.HasValue && record.Size < options.MinSize.Value)
                    return false;

                if (options.MaxSize.HasValue && record.Size > options.MaxSize.Value)
                    return false;

                return true;
            };
        }

        private static void PrintSummary(IReadOnlyList<IndexRecord> records, IList<IGrouping<string, IndexRecord>> duplicates)
        {
            var totalFiles = records.Count;
            var totalSize = records.Sum(r => r.Size);
            var duplicateCount = duplicates.Sum(group => group.Count());

            Console.WriteLine();
            Console.WriteLine("Resumen de Filelist");
            Console.WriteLine($"  Archivos indexados: {totalFiles}");
            Console.WriteLine($"  Tamaño total: {FormatBytes(totalSize)}");
            Console.WriteLine($"  Duplicados detectados: {duplicateCount} ({duplicates.Count} hashes diferentes)");
        }

        private static void PrintTop(IReadOnlyList<IndexRecord> records, int topCount)
        {
            var topRecords = records
                .OrderByDescending(r => r.Size)
                .Take(topCount)
                .ToList();

            if (topRecords.Count == 0)
            {
                Console.WriteLine("No hay archivos para mostrar en top.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine($"Top {topRecords.Count} por tamaño:");
            Console.WriteLine("  Tamaño       | Ruta relativa");
            foreach (var record in topRecords)
            {
                Console.WriteLine($"  {FormatBytes(record.Size),12} | {record.RelativePath}");
            }
        }

        private static void PrintFileList(IReadOnlyList<IndexRecord> records)
        {
            if (records.Count == 0)
            {
                Console.WriteLine();
                Console.WriteLine("No hay archivos que mostrar.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine("Lista de archivos:");
            Console.WriteLine("  Archivo | Tamaño | Fecha modificación | Hash");
            foreach (var record in records)
            {
                Console.WriteLine($"  {record.RelativePath} | {FormatBytes(record.Size)} | {record.LastWriteUtc:yyyy-MM-dd HH:mm:ss} | {record.Hash}");
            }
        }

        private static void PrintDuplicates(IReadOnlyList<IGrouping<string, IndexRecord>> duplicates)
        {
            if (duplicates.Count == 0)
            {
                Console.WriteLine();
                Console.WriteLine("No se detectaron duplicados.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine("Duplicados encontrados:");
            foreach (var group in duplicates)
            {
                Console.WriteLine($"Hash {group.Key}:");
                foreach (var record in group)
                {
                    Console.WriteLine($"  • {record.RelativePath} ({FormatBytes(record.Size)})");
                }
            }
        }

        private static void PrintFileMap(IEnumerable<FileMapEntry> map)
        {
            var mapList = map.ToList();
            if (mapList.Count == 0)
            {
                Console.WriteLine();
                Console.WriteLine("No hay información de directorios disponible.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine("Mapa de directorios:");
            Console.WriteLine("  Directorio                        Archivos  Tamaño total  Duplicados");
            foreach (var entry in mapList)
            {
                Console.WriteLine($"  {entry.Directory,-30} {entry.FileCount,8} {FormatBytes(entry.TotalSize),16} {entry.DuplicateCount,12}");
            }
        }

        private static string FormatBytes(long bytes)
        {
            const double KB = 1 << 10;
            string[] suffixes = { "B", "KB", "MB", "GB", "TB" };
            double value = bytes;
            int index = 0;

            while (value >= KB && index < suffixes.Length - 1)
            {
                value /= KB;
                index++;
            }

            return $"{value:0.##} {suffixes[index]}";
        }

        private static void ShowHelp()
        {
            Console.WriteLine("Filelist - Consume el índice común y publica listados/duplicados.");
            Console.WriteLine();
            Console.WriteLine("Uso:");
            Console.WriteLine("  Filelist [--root <ruta>] [--db <archivo>] [--list] [--top <n>] [--duplicates] [--map]");
            Console.WriteLine();
            Console.WriteLine("Opciones:");
            Console.WriteLine("  --root <ruta>        Carpeta raíz del índice (por defecto el directorio actual).");
            Console.WriteLine("  --db <archivo>       Archivo SQLite generado por Indexador.");
            Console.WriteLine("  --list               Muestra cada archivo con hash, tamaño y fecha.");
            Console.WriteLine("  --top <n>            Lista los n archivos más grandes (por defecto 20).");
            Console.WriteLine("  --duplicates         Muestra los archivos duplicados agrupados por hash.");
            Console.WriteLine("  --map                Muestra el mapa de directorios contra los registros guardados.");
            Console.WriteLine("  --extension <ext>    Filtra archivos por extensión (por ejemplo .txt).");
            Console.WriteLine("  --min-size <bytes>   Excluye archivos más pequeños que este valor.");
            Console.WriteLine("  --max-size <bytes>   Excluye archivos más grandes que este valor.");
            Console.WriteLine("  --no-summary         No muestra el resumen general.");
            Console.WriteLine("  --verbose            Imprime métricas adicionales de carga.");
            Console.WriteLine("  --help, -h           Muestra esta ayuda.");
        }
    }
}
