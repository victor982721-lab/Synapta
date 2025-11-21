namespace Neurologic.Core.Indexing;

/// <summary>
/// Expone utilidades simples para construir índices en memoria.
/// </summary>
public class IndexBuilder
{
    private readonly List<IndexEntry> _entries = new();

    public void AddOrUpdate(IndexEntry entry)
    {
        var existingIndex = _entries.FindIndex(e => string.Equals(e.Path, entry.Path, StringComparison.OrdinalIgnoreCase));
        if (existingIndex >= 0)
        {
            _entries[existingIndex] = entry;
        }
        else
        {
            _entries.Add(entry);
        }
    }

    public IReadOnlyCollection<IndexEntry> Entries => _entries.AsReadOnly();
}
