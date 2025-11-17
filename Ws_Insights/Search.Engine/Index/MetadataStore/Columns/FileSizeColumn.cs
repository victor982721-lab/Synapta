using System.Collections.Generic;

namespace Ws_Insights.Search.Index.MetadataStore.Columns
{
    /// <summary>
    /// Represents a column of file sizes for documents in a segment.  Consumers can apply
    /// minimum and maximum filters to quickly narrow down candidates.  This stub stores no values.
    /// </summary>
    public class FileSizeColumn
    {
        public IReadOnlyList<long> Values { get; } = new List<long>();
    }
}