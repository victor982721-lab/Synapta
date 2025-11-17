namespace Ws_Insights.Search.Index.Bloom
{
    /// <summary>
    /// Builds Bloom filters from sets of items.  The builder uses the supplied configuration
    /// to determine the size of the filter and the number of hash functions.  This stub
    /// implementation does not actually construct a Bloom filter.
    /// </summary>
    public class BloomFilterBuilder
    {
        private readonly BloomFilterConfig _config;

        public BloomFilterBuilder(BloomFilterConfig config)
        {
            _config = config;
        }

        public BloomFilterStore BuildForTokens(string[] tokens)
        {
            // TODO: build a Bloom filter from tokens
            return new BloomFilterStore(_config);
        }
    }
}