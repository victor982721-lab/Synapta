using System.IO;
using Deduplinside.Models;

namespace Deduplinside.Services;

public interface IMergeService
{
    Task<string> MergeAndDeduplicateAsync(
        IEnumerable<string> inputFiles,
        string outputPath,
        IProgress<ProcessingProgress>? progress,
        CancellationToken cancellationToken);
}

public class MergeService : IMergeService
{
    public async Task<string> MergeAndDeduplicateAsync(
        IEnumerable<string> inputFiles,
        string outputPath,
        IProgress<ProcessingProgress>? progress,
        CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);
        var seen = new HashSet<string>(StringComparer.Ordinal);
        long processedLines = 0;
        long duplicateLines = 0;

        await using var outputStream = new FileStream(
            outputPath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            bufferSize: 1024 * 32,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        await using var writer = new StreamWriter(outputStream);

        foreach (var file in inputFiles)
        {
            cancellationToken.ThrowIfCancellationRequested();
            long processedForFile = 0;
            long duplicatesForFile = 0;

            await using var inputStream = new FileStream(
                file,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                bufferSize: 1024 * 32,
                FileOptions.Asynchronous | FileOptions.SequentialScan);

            using var reader = new StreamReader(inputStream);
            string? line;

            while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) is not null)
            {
                cancellationToken.ThrowIfCancellationRequested();
                processedLines++;
                processedForFile++;

                if (seen.Add(line))
                {
                    await writer.WriteLineAsync(line).ConfigureAwait(false);
                }
                else
                {
                    duplicateLines++;
                    duplicatesForFile++;
                }

                progress?.Report(new ProcessingProgress
                {
                    FilePath = file,
                    ProcessedLines = processedForFile,
                    DuplicateLines = duplicatesForFile
                });
            }
        }

        await writer.FlushAsync().ConfigureAwait(false);
        return outputPath;
    }
}
