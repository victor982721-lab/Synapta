namespace Ws_Insights.Search.Index.Bloom
{
    /// <summary>
    /// Represents an in-memory Bloom filter.  In a complete implementation this would
    /// store a bit array and apply several hash functions.  This stub exposes only a config.
    /// </summary>
    public class BloomFilterStore
    {
        public BloomFilterConfig Config { get; }

        public BloomFilterStore(BloomFilterConfig config)
        {
            Config = config;
        }

        public void Add(string item)
        {
            // TODO: add item to filter
        }

        public bool MaybeContains(string item) => false;
    }
}