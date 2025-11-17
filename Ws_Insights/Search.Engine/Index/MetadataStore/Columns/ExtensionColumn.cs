using System.Collections.Generic;

namespace Ws_Insights.Search.Index.MetadataStore.Columns
{
    /// <summary>
    /// Represents a column mapping documents to extension identifiers.  Extensions are stored as
    /// integers referencing a small dictionary of unique extensions.  This stub stores no values.
    /// </summary>
    public class ExtensionColumn
    {
        public IReadOnlyList<int> Values { get; } = new List<int>();
    }
}