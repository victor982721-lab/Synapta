namespace Ws_Insights.Search.Index.MetadataStore
{
    /// <summary>
    /// Writes columnar metadata to persistent storage.  Column stores are contiguous blocks of
    /// homogeneous values that allow for very fast scanning.  This stub performs no work.
    /// </summary>
    public class ColumnStoreWriter
    {
        public void WriteColumn<T>(string name, T[] values)
        {
            // TODO: write column to disk
        }
    }
}