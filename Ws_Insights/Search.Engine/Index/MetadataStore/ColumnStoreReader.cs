using System.Collections.Generic;

namespace Ws_Insights.Search.Index.MetadataStore
{
    /// <summary>
    /// Reads columnar metadata from persistent storage.  Each column contains a homogeneous set
    /// of values (for example, file sizes or timestamps) and can be scanned independently.  This
    /// stub returns default values.
    /// </summary>
    public class ColumnStoreReader
    {
        public IReadOnlyList<T> ReadColumn<T>(string name)
        {
            // TODO: read column from disk
            return new List<T>();
        }
    }
}