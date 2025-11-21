using Neurologic.Core.FileSystem;
using Neurologic.Core.Indexing;
using Neurologic.Core.Search;

namespace Neurologic.Sandbox.ProyectoEjemplo;

public static class Program
{
    public static int Main(string[] args)
    {
        var normalized = FileSystemService.NormalizePath(args.FirstOrDefault() ?? "/tmp/demo.txt");
        var builder = new IndexBuilder();
        builder.AddOrUpdate(new IndexEntry(normalized, 128, DateTime.UtcNow));

        var search = new SearchService();
        var results = search.FindByName(builder.Entries, Path.GetFileName(normalized));

        foreach (var entry in results)
        {
            Console.WriteLine($"[indexado] {entry.Path} ({entry.SizeBytes} bytes)");
        }

        return 0;
    }
}
