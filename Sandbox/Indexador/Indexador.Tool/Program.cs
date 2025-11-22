using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Indexador.Core;

namespace Indexador.Tool
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            var options = ParseArguments(args);
            if (options == null)
            {
                ShowHelp();
                return;
            }

            var manager = new IndexManager();
            var updateOptions = new IndexUpdateOptions
            {
                RootPath = options.RootPath,
                DatabasePath = options.DatabasePath,
                ForceHash = options.ForceHash,
                CleanMissing = options.CleanMissing,
                Source = options.Source,
                HashAlgorithm = options.HashAlgorithm
            };

            var summary = manager.IndexDirectory(updateOptions);
            updateOptions = updateOptions with { RootPath = summary.RootPath };

            Console.WriteLine($"Ruta: {summary.RootPath}");
            Console.WriteLine($"Base de índice: {summary.DatabasePath}");
            Console.WriteLine($"Archivos procesados: {summary.ScannedFiles} (actualizados {summary.UpdatedFiles}, omitidos {summary.SkippedFiles})");
            Console.WriteLine($"Entradas eliminadas: {summary.RemovedFiles}");
            Console.WriteLine($"Duración: {summary.Duration:c}");

            IReadOnlyList<IndexRecord> records = Array.Empty<IndexRecord>();
            if (options.ShowDuplicates || options.ShowFileList || options.ShowFileMap)
            {
                records = manager.GetRecords(summary.RootPath, summary.DatabasePath);
            }

            if (options.ShowFileList)
            {
                PrintFileList(records);
            }

            if (options.ShowFileMap)
            {
                var map = manager.BuildFileMap(summary.RootPath, summary.DatabasePath);
                PrintFileMap(map);
            }

            if (options.ShowDuplicates)
            {
                var duplicates = manager.FindDuplicates(records).ToList();

                if (duplicates.Count == 0)
                {
                    Console.WriteLine("No se encontraron duplicados en la base de índice.");
                }
                else
                {
                    Console.WriteLine("Duplicados detectados:");
                    foreach (var group in duplicates)
                    {
                        Console.WriteLine($"Hash {group.Key}:");
                        foreach (var record in group)
                        {
                            Console.WriteLine($"  • {record.RelativePath} ({record.Size} bytes)");
                        }
                    }
                }
            }

            if (options.Watch)
            {
                StartWatcher(manager, updateOptions, options, summary);
            }
        }

        private static ToolOptions? ParseArguments(string[] args)
        {
            if (args.Length == 0)
                return new ToolOptions();

            var options = new ToolOptions();

            for (var i = 0; i < args.Length; i++)
            {
                switch (args[i].ToLowerInvariant())
                {
                    case "--root":
                        if (i + 1 < args.Length)
                            options.RootPath = args[++i];
                        break;
                    case "--db":
                    case "--database":
                        if (i + 1 < args.Length)
                            options.DatabasePath = args[++i];
                        break;
                    case "--force":
                        options.ForceHash = true;
                        break;
                    case "--no-clean":
                        options.CleanMissing = false;
                        break;
                    case "--duplicates":
                        options.ShowDuplicates = true;
                        break;
                    case "--filelist":
                        options.ShowFileList = true;
                        break;
                    case "--filemap":
                        options.ShowFileMap = true;
                        break;
                    case "--watch":
                        options.Watch = true;
                        break;
                    case "--debounce":
                        if (i + 1 < args.Length && int.TryParse(args[++i], out var ms))
                            options.DebounceMs = Math.Max(200, ms);
                        break;
                    case "--source":
                        if (i + 1 < args.Length)
                            options.Source = args[++i];
                        break;
                    case "--hash":
                        if (i + 1 < args.Length)
                            options.HashAlgorithm = args[++i];
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

        private static void ShowHelp()
        {
            Console.WriteLine("Indexador.Tool - CLI para mantener la base de índice común.");
            Console.WriteLine();
            Console.WriteLine("Uso:");
            Console.WriteLine("  Indexador.Tool [--root <ruta>] [--db <archivo>] [--force] [--duplicates] [--filelist] [--filemap]");
            Console.WriteLine();
            Console.WriteLine("Opciones:");
            Console.WriteLine("  --root <ruta>        Carpeta raíz a escanear (por defecto el directorio actual).");
            Console.WriteLine("  --db <archivo>       Archivo SQLite que guardará el índice (por defecto Indexador.db dentro de la raíz).");
            Console.WriteLine("  --force              Forzar recálculo de hashes.");
            Console.WriteLine("  --no-clean           No eliminar registros cuya ruta ya no existe.");
            Console.WriteLine("  --duplicates         Mostrar duplicados por hash luego de indexar.");
            Console.WriteLine("  --filelist           Listar los archivos indexados luego de ejecutar el escaneo.");
            Console.WriteLine("  --filemap            Mostrar un mapa de directorios con recuentos y tamaños.");
            Console.WriteLine("  --hash <algoritmo>   Algoritmo de hash (CRC32 por defecto, SHA256 para colisiones más estrictas).");
            Console.WriteLine("  --source <etiqueta>  Etiqueta para los registros (por ejemplo el nombre del proyecto consumidor).");
            Console.WriteLine("  --help, -h           Mostrar esta ayuda.");
            Console.WriteLine("  --watch             Mantener un watcher y actualizar el índice en vivo.");
            Console.WriteLine("  --debounce <ms>      Tiempo de espera antes de ejecutar el lote de cambios (por defecto 1500 ms).");
        }

        private static void StartWatcher(IndexManager manager, IndexUpdateOptions updateOptions, ToolOptions options, IndexSummary summary)
        {
            var debounce = TimeSpan.FromMilliseconds(Math.Max(200, options.DebounceMs));
            using var watcher = new IndexWatcher(manager, updateOptions, debounce, updated =>
            {
                Console.WriteLine($"Watcher actualizó {updated.UpdatedFiles} archivos (duración {updated.Duration:c}).");
            }, ex => Console.WriteLine($"Watcher error: {ex.Message}"));

            watcher.Start();
            Console.WriteLine($"Watcher activo en {summary.RootPath}. Presiona Ctrl+C para detener.");

            using var mre = new ManualResetEventSlim(false);
            ConsoleCancelEventHandler? handler = null;
            handler = (sender, args) =>
            {
                args.Cancel = true;
                mre.Set();
            };

            Console.CancelKeyPress += handler;
            try
            {
                mre.Wait();
            }
            finally
            {
                Console.CancelKeyPress -= handler;
            }
        }

        private static void PrintFileList(IReadOnlyList<IndexRecord> records)
        {
            if (records.Count == 0)
            {
                Console.WriteLine("La base de índice no contiene archivos.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine("Archivo | Tamaño | Última modificación");
            foreach (var record in records.OrderBy(r => r.RelativePath, StringComparer.OrdinalIgnoreCase))
            {
                Console.WriteLine($"  {record.RelativePath} | {record.Size:N0} bytes | {record.LastWriteUtc:yyyy-MM-dd HH:mm:ss}");
            }
        }

        private static void PrintFileMap(IEnumerable<FileMapEntry> map)
        {
            var mapList = map.ToList();
            if (mapList.Count == 0)
            {
                Console.WriteLine("No hay directorios indexados para generar el mapa.");
                return;
            }

            Console.WriteLine();
            Console.WriteLine("Directorio                       Archivos  Tamaño total  Duplicados");
            foreach (var entry in mapList)
            {
                Console.WriteLine($"  {entry.Directory,-30} {entry.FileCount,8} {entry.TotalSize,14:N0} {entry.DuplicateCount,12}");
            }
        }
    }
}
