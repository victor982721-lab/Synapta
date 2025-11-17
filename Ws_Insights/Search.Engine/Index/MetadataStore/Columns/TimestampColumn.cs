using System;
using System.Collections.Generic;

namespace Ws_Insights.Search.Index.MetadataStore.Columns
{
    /// <summary>
    /// Represents a column of timestamps (creation or modification times) for documents in a segment.
    /// Timestamps are stored as <see cref="DateTime"/> values for simplicity.  This stub stores no values.
    /// </summary>
    public class TimestampColumn
    {
        public IReadOnlyList<DateTime> Values { get; } = new List<DateTime>();
    }
}