using System.IO;
using Deduplinside.Models;

namespace Deduplinside.Services;

public interface IDeduplicationService
{
    Task<FileProcessingResult> ProcessFileAsync(
        string filePath,
        string outputDirectory,
        IProgress<ProcessingProgress>? progress,
        CancellationToken cancellationToken);
}

public class DeduplicationService : IDeduplicationService
{
    private const int DuplicatePreviewLimit = 500;

    public async Task<FileProcessingResult> ProcessFileAsync(
        string filePath,
        string outputDirectory,
        IProgress<ProcessingProgress>? progress,
        CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(outputDirectory);
        var fileName = Path.GetFileNameWithoutExtension(filePath);
        var extension = Path.GetExtension(filePath);
        var outputPath = Path.Combine(outputDirectory, $"{fileName}_dedup{extension}");

        var seen = new HashSet<string>(StringComparer.Ordinal);
        var duplicateEntries = new List<DuplicateEntry>();
        long processedLines = 0;
        long duplicateLines = 0;

        await using var inputStream = new FileStream(
            filePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 1024 * 32,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        using var reader = new StreamReader(inputStream);

        await using var outputStream = new FileStream(
            outputPath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            bufferSize: 1024 * 32,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        await using var writer = new StreamWriter(outputStream);

        string? line;
        while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) is not null)
        {
            cancellationToken.ThrowIfCancellationRequested();
            processedLines++;

            var normalized = line;
            if (seen.Add(normalized))
            {
                await writer.WriteLineAsync(normalized).ConfigureAwait(false);
            }
            else
            {
                duplicateLines++;
                if (duplicateEntries.Count < DuplicatePreviewLimit)
                {
                    duplicateEntries.Add(new DuplicateEntry
                    {
                        FilePath = filePath,
                        LineNumber = (int)processedLines,
                        Content = normalized
                    });
                }
            }

            progress?.Report(new ProcessingProgress
            {
                FilePath = filePath,
                ProcessedLines = processedLines,
                DuplicateLines = duplicateLines
            });
        }

        await writer.FlushAsync().ConfigureAwait(false);

        return new FileProcessingResult
        {
            FilePath = filePath,
            OutputPath = outputPath,
            ProcessedLines = processedLines,
            DuplicateLines = duplicateLines,
            DuplicateEntries = duplicateEntries
        };
    }
}
