using Neurologic.Core.Indexing;
using Xunit;

namespace Neurologic.Core.Indexing.Tests;

public class IndexBuilderTests
{
    [Fact]
    public void AddOrUpdate_AddsNewEntry()
    {
        var builder = new IndexBuilder();
        builder.AddOrUpdate(new IndexEntry("file.txt", 10, DateTime.UnixEpoch));

        Assert.Single(builder.Entries);
    }

    [Fact]
    public void AddOrUpdate_ReplacesExisting()
    {
        var builder = new IndexBuilder();
        var initial = new IndexEntry("file.txt", 10, DateTime.UnixEpoch);
        builder.AddOrUpdate(initial);

        var updated = new IndexEntry("file.txt", 20, DateTime.UnixEpoch.AddDays(1));
        builder.AddOrUpdate(updated);

        Assert.Single(builder.Entries);
        Assert.Equal(20, builder.Entries.First().SizeBytes);
    }
}
