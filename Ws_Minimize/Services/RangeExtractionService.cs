using System.IO;
using System.Text;
using Deduplinside.Models;

namespace Deduplinside.Services;

public interface IRangeExtractionService
{
    Task<IReadOnlyList<RangeMatch>> ExtractAsync(
        string filePath,
        string startMarker,
        string endMarker,
        CancellationToken cancellationToken);

    Task ExportAsync(IEnumerable<RangeMatch> matches, string outputPath, CancellationToken cancellationToken);
}

public class RangeExtractionService : IRangeExtractionService
{
    public async Task<IReadOnlyList<RangeMatch>> ExtractAsync(
        string filePath,
        string startMarker,
        string endMarker,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(startMarker) || string.IsNullOrWhiteSpace(endMarker))
        {
            return Array.Empty<RangeMatch>();
        }

        var matches = new List<RangeMatch>();
        var comparison = StringComparison.OrdinalIgnoreCase;
        var builder = new StringBuilder();
        var capturing = false;
        var startLine = 0;
        var lineNumber = 0;

        await using var stream = new FileStream(
            filePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 1024 * 16,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        using var reader = new StreamReader(stream);
        string? line;

        while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) is not null)
        {
            cancellationToken.ThrowIfCancellationRequested();
            lineNumber++;

            if (!capturing && line.IndexOf(startMarker, comparison) >= 0)
            {
                capturing = true;
                startLine = lineNumber;
                builder.Clear();
            }

            if (capturing)
            {
                builder.AppendLine(line);

                if (line.IndexOf(endMarker, comparison) >= 0)
                {
                    capturing = false;
                    matches.Add(new RangeMatch
                    {
                        FilePath = filePath,
                        StartLine = startLine,
                        EndLine = lineNumber,
                        Content = builder.ToString().TrimEnd()
                    });
                    builder.Clear();
                }
            }
        }

        return matches;
    }

    public async Task ExportAsync(IEnumerable<RangeMatch> matches, string outputPath, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);

        await using var stream = new FileStream(
            outputPath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            bufferSize: 1024 * 16,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        await using var writer = new StreamWriter(stream);
        foreach (var match in matches)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await writer.WriteLineAsync($"File: {match.FilePath}").ConfigureAwait(false);
            await writer.WriteLineAsync($"Lines: {match.StartLine}-{match.EndLine}").ConfigureAwait(false);
            await writer.WriteLineAsync(match.Content).ConfigureAwait(false);
            await writer.WriteLineAsync(new string('-', 64)).ConfigureAwait(false);
        }

        await writer.FlushAsync().ConfigureAwait(false);
    }
}
