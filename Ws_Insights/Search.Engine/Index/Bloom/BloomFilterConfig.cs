namespace Ws_Insights.Search.Index.Bloom
{
    /// <summary>
    /// Configuration parameters for creating Bloom filters.  A Bloom filter trades off storage
    /// space for false positives.  This stub exposes only minimal properties.
    /// </summary>
    public class BloomFilterConfig
    {
        public int HashFunctionCount { get; set; } = 3;
        public int BitCount { get; set; } = 1024;
    }
}