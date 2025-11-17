namespace Ws_Insights.Search.Index.Bloom
{
    /// <summary>
    /// Reads Bloom filters stored on disk and allows checking for membership.  This stub
    /// implementation always returns false, indicating that items are not present.
    /// </summary>
    public class BloomFilterReader
    {
        public bool MaybeContains(string token) => false;
    }
}