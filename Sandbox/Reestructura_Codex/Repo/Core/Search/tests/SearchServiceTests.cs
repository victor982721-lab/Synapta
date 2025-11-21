using Neurologic.Core.Indexing;
using Neurologic.Core.Search;
using Xunit;

namespace Neurologic.Core.Search.Tests;

public class SearchServiceTests
{
    [Fact]
    public void FindByName_FiltersByTerm()
    {
        var entries = new[]
        {
            new IndexEntry("/tmp/report.txt", 10, DateTime.UnixEpoch),
            new IndexEntry("/tmp/image.png", 20, DateTime.UnixEpoch)
        };

        var service = new SearchService();
        var results = service.FindByName(entries, "report").ToArray();

        Assert.Single(results);
        Assert.Equal("/tmp/report.txt", results[0].Path);
    }

    [Fact]
    public void FindByName_EmptyTerm_ReturnsEmpty()
    {
        var entries = Array.Empty<IndexEntry>();
        var service = new SearchService();

        Assert.Empty(service.FindByName(entries, " "));
    }
}
