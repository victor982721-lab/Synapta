using System.Collections.Generic;

namespace Ws_Insights.Search.Index.MetadataStore.Columns
{
    /// <summary>
    /// Represents a column of arbitrary bit flags associated with documents.  These flags might
    /// indicate read-only status, hidden/system attributes or other properties.  This stub stores no values.
    /// </summary>
    public class FlagsColumn
    {
        public IReadOnlyList<int> Values { get; } = new List<int>();
    }
}