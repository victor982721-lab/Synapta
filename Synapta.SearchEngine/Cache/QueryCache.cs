using System.Collections.Generic;
using Synapta.SearchEngine.Core;

namespace Synapta.SearchEngine.Cache
{
    /// <summary>
    /// Caches the results of recent queries to avoid recomputing expensive searches.  Keys are
    /// normalised representations of <see cref="SearchOptions"/> and values are lists of document
    /// identifiers or search results.  This stub stores results as a list of <see cref="SearchResult"/>.
    /// </summary>
    public class QueryCache
    {
        private readonly LruCache<string, List<SearchResult>> _cache;
        public QueryCache(int capacity = 64)
        {
            _cache = new LruCache<string, List<SearchResult>>(capacity);
        }

        private static string NormaliseKey(SearchOptions options)
        {
            return $"{options.RootPath}|{options.Query}|{(int)options.Flags}";
        }

        public bool TryGet(SearchOptions options, out List<SearchResult> results)
        {
            return _cache.TryGet(NormaliseKey(options), out results!);
        }

        public void Put(SearchOptions options, List<SearchResult> results)
        {
            _cache.Put(NormaliseKey(options), results);
        }
    }
}