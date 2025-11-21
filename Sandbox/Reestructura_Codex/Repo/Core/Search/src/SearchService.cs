using Neurologic.Core.Indexing;

namespace Neurologic.Core.Search;

/// <summary>
/// Motor básico de consultas sobre colecciones de <see cref="IndexEntry"/>.
/// </summary>
public class SearchService
{
    public IEnumerable<IndexEntry> FindByName(IEnumerable<IndexEntry> source, string term)
    {
        if (source is null)
        {
            throw new ArgumentNullException(nameof(source));
        }

        if (string.IsNullOrWhiteSpace(term))
        {
            return Array.Empty<IndexEntry>();
        }

        return source.Where(e => e.Path.Contains(term, StringComparison.OrdinalIgnoreCase));
    }
}
