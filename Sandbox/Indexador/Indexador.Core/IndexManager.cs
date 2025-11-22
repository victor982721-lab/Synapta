using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Indexador.Core
{
    public sealed class IndexManager
    {
        private sealed record IndexContext(string RootPath, IndexDatabase Database, string Algorithm, Func<IHashProvider> ProviderFactory, string Source, Dictionary<string, IndexRecord> Existing);

        public IndexSummary IndexDirectory(IndexUpdateOptions options)
        {
            var context = CreateContext(options);
            var stopwatch = Stopwatch.StartNew();
            var processed = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var summary = new IndexSummary
            {
                RootPath = context.RootPath,
                DatabasePath = context.Database.DatabasePath
            };

            var candidates = new List<HashCandidate>();

            foreach (var file in Directory.EnumerateFiles(context.RootPath, "*", SearchOption.AllDirectories))
            {
                try
                {
                    var info = new FileInfo(file);
                    var normalizedFullPath = PathTools.NormalizePath(info.FullName);
                    var relativePath = Path.GetRelativePath(context.RootPath, normalizedFullPath);

                    processed.Add(normalizedFullPath);
                    summary = summary with { ScannedFiles = summary.ScannedFiles + 1 };

                    context.Existing.TryGetValue(normalizedFullPath, out var known);
                    var needsHash = options.ForceHash ||
                                    known == null ||
                                    known.Size != info.Length ||
                                    known.LastWriteUtc != info.LastWriteTimeUtc;

                    if (!needsHash)
                    {
                        summary = summary with { SkippedFiles = summary.SkippedFiles + 1 };
                        continue;
                    }

                    candidates.Add(new HashCandidate(normalizedFullPath, relativePath, info, known));
                }
                catch (UnauthorizedAccessException)
                {
                    continue;
                }
            }

            var records = ComputeRecords(candidates, context, options.MaxParallelism);

            foreach (var record in records)
            {
                context.Database.Upsert(record);
            }

            summary = summary with { UpdatedFiles = summary.UpdatedFiles + records.Count };

            var removed = options.CleanMissing
                ? context.Database.RemoveMissing(context.RootPath, processed)
                : 0;

            stopwatch.Stop();
            summary = summary with
            {
                RemovedFiles = removed,
                Duration = stopwatch.Elapsed
            };

            return summary;
        }

        public IndexSummary UpdateEntries(IndexUpdateOptions options, IEnumerable<string> candidatePaths)
        {
            if (candidatePaths == null)
                throw new ArgumentNullException(nameof(candidatePaths));

            var context = CreateContext(options);
            var stopwatch = Stopwatch.StartNew();
            var summary = new IndexSummary
            {
                RootPath = context.RootPath,
                DatabasePath = context.Database.DatabasePath
            };

            var processed = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var candidates = new List<HashCandidate>();

            foreach (var path in candidatePaths)
            {
                if (string.IsNullOrWhiteSpace(path))
                    continue;

                string normalizedFullPath;
                try
                {
                    normalizedFullPath = PathTools.NormalizePath(path);
                }
                catch (ArgumentException)
                {
                    continue;
                }

                if (!normalizedFullPath.StartsWith(context.RootPath, StringComparison.OrdinalIgnoreCase))
                    continue;

                if (!processed.Add(normalizedFullPath))
                    continue;

                if (!File.Exists(normalizedFullPath))
                {
                    var removed = context.Database.DeletePaths(new[] { normalizedFullPath });
                    summary = summary with { RemovedFiles = summary.RemovedFiles + removed };
                    continue;
                }

                var info = new FileInfo(normalizedFullPath);
                var relativePath = Path.GetRelativePath(context.RootPath, normalizedFullPath);
                summary = summary with { ScannedFiles = summary.ScannedFiles + 1 };

                context.Existing.TryGetValue(normalizedFullPath, out var known);
                var needsHash = options.ForceHash ||
                                known == null ||
                                known.Size != info.Length ||
                                known.LastWriteUtc != info.LastWriteTimeUtc;

                if (!needsHash)
                {
                    summary = summary with { SkippedFiles = summary.SkippedFiles + 1 };
                    continue;
                }

                candidates.Add(new HashCandidate(normalizedFullPath, relativePath, info, known));
            }

            var records = ComputeRecords(candidates, context, options.MaxParallelism);
            foreach (var record in records)
            {
                context.Database.Upsert(record);
            }

            summary = summary with { UpdatedFiles = summary.UpdatedFiles + records.Count };

            stopwatch.Stop();
            summary = summary with { Duration = stopwatch.Elapsed };
            return summary;
        }

        private static IndexContext CreateContext(IndexUpdateOptions options)
        {
            if (options == null)
                throw new ArgumentNullException(nameof(options));

            if (string.IsNullOrWhiteSpace(options.RootPath))
                throw new ArgumentException("Es necesario especificar la ruta raíz.", nameof(options.RootPath));

            var rootPath = PathTools.NormalizePath(options.RootPath);
            if (!Directory.Exists(rootPath))
                throw new DirectoryNotFoundException($"La ruta {rootPath} no existe.");

            var databasePath = string.IsNullOrWhiteSpace(options.DatabasePath)
                ? Path.Combine(rootPath, "indexador.db")
                : options.DatabasePath;

            var algorithm = options.HashAlgorithm?.Trim().ToUpperInvariant() ?? "CRC32";
            var database = new IndexDatabase(databasePath);
            var existing = database.GetRecords(rootPath)
                .ToDictionary(r => PathTools.NormalizePath(r.FullPath), StringComparer.OrdinalIgnoreCase);

            return new IndexContext(rootPath, database, algorithm, () => HashProviderFactory.Create(algorithm), options.Source ?? string.Empty, existing);
        }

        private static IReadOnlyList<IndexRecord> ComputeRecords(IEnumerable<HashCandidate> candidates, IndexContext context, int maxParallelism)
        {
            if (candidates == null)
                return Array.Empty<IndexRecord>();

            var providerFactory = context.ProviderFactory;
            var algorithm = context.Algorithm;
            var bag = new ConcurrentBag<IndexRecord>();

            var options = new ParallelOptions
            {
                MaxDegreeOfParallelism = Math.Max(1, maxParallelism)
            };

            Parallel.ForEach(candidates, options, candidate =>
            {
                var hashValue = ComputeHash(providerFactory, candidate.FullPath);

                var record = new IndexRecord
                {
                    FullPath = candidate.FullPath,
                    RootPath = context.RootPath,
                    RelativePath = candidate.RelativePath,
                    Size = candidate.Info.Length,
                    LastWriteUtc = candidate.Info.LastWriteTimeUtc,
                    Hash = hashValue,
                    HashAlgorithm = algorithm,
                    CreatedUtc = candidate.Known?.CreatedUtc ?? DateTime.UtcNow,
                    ModifiedUtc = DateTime.UtcNow,
                    Tags = candidate.Known?.Tags ?? string.Empty,
                    Notes = candidate.Known?.Notes ?? string.Empty,
                    Source = context.Source
                };

                bag.Add(record);
            });

            return bag.ToList();
        }

        public IReadOnlyList<IndexRecord> GetRecords(string rootPath, string databasePath)
        {
            var database = new IndexDatabase(databasePath);
            return database.GetRecords(rootPath);
        }

        public IReadOnlyList<FileMapEntry> BuildFileMap(string rootPath, string databasePath)
        {
            var records = GetRecords(rootPath, databasePath);
            return records
                .GroupBy(record => NormalizeDirectory(Path.GetDirectoryName(record.RelativePath)), StringComparer.OrdinalIgnoreCase)
                .Select(group => new FileMapEntry
                {
                    Directory = group.Key,
                    FileCount = group.Count(),
                    TotalSize = group.Sum(record => record.Size),
                    DuplicateCount = group
                        .GroupBy(record => record.Hash, StringComparer.OrdinalIgnoreCase)
                        .Where(dupe => dupe.Count() > 1)
                        .Sum(dupe => dupe.Count())
                })
                .OrderByDescending(entry => entry.FileCount)
                .ThenBy(entry => entry.Directory, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public IEnumerable<IGrouping<string, IndexRecord>> FindDuplicates(IEnumerable<IndexRecord> records)
        {
            return records
                .Where(r => !string.IsNullOrWhiteSpace(r.Hash))
                .GroupBy(r => r.Hash, StringComparer.OrdinalIgnoreCase)
                .Where(group => group.Count() > 1);
        }

        private static string ComputeHash(Func<IHashProvider> providerFactory, string filePath)
        {
            using var stream = File.OpenRead(filePath);
            var provider = providerFactory();
            return provider.ComputeHash(stream);
        }

        private static string NormalizeDirectory(string? directory)
        {
            if (string.IsNullOrWhiteSpace(directory))
                return ".";

            return directory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}
