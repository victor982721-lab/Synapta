using System.IO;
using Deduplinside.Models;

namespace Deduplinside.Services;

public interface ISearchService
{
    Task<IReadOnlyList<SearchHit>> SearchAsync(string filePath, string query, CancellationToken cancellationToken);
}

public class SearchService : ISearchService
{
    private const int SearchPreviewLimit = 500;

    public async Task<IReadOnlyList<SearchHit>> SearchAsync(string filePath, string query, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Array.Empty<SearchHit>();
        }

        var hits = new List<SearchHit>();
        var comparison = StringComparison.OrdinalIgnoreCase;
        var normalizedQuery = query.Trim();

        await using var stream = new FileStream(
            filePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 1024 * 16,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        using var reader = new StreamReader(stream);
        string? line;
        var lineNumber = 0;

        while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) is not null)
        {
            cancellationToken.ThrowIfCancellationRequested();
            lineNumber++;

            if (line.IndexOf(normalizedQuery, comparison) >= 0)
            {
                hits.Add(new SearchHit
                {
                    FilePath = filePath,
                    LineNumber = lineNumber,
                    Snippet = line.Trim()
                });
            }

            if (hits.Count >= SearchPreviewLimit)
            {
                break;
            }
        }

        return hits;
    }
}
