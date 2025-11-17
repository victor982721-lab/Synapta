using System.Threading;
using Ws_Insights.Search.Core;
using Ws_Insights.Search.Index;
using Ws_Insights.Search.Cache;

namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Represents the state associated with a single search operation.  The context groups together
    /// the options chosen by the user, references to shared components such as the index manager
    /// and caches, and accumulates statistics as results are produced.
    /// </summary>
    public class SearchContext
    {
        public SearchContext(SearchOptions options, IndexManager indexManager, HotFileCache hotFileCache, QueryCache queryCache, CancellationToken cancellationToken)
        {
            Options = options;
            IndexManager = indexManager;
            HotFileCache = hotFileCache;
            QueryCache = queryCache;
            CancellationToken = cancellationToken;
            Statistics = new SearchStatistics();
        }

        /// <summary>Gets the options that control this search.</summary>
        public SearchOptions Options { get; }

        /// <summary>Gets the index manager used to query on‑disk segments.</summary>
        public IndexManager IndexManager { get; }

        /// <summary>Gets the cache used for hot file contents.</summary>
        public HotFileCache HotFileCache { get; }

        /// <summary>Gets the cache used for previously issued queries.</summary>
        public QueryCache QueryCache { get; }

        /// <summary>Gets the statistics accumulated while executing this search.</summary>
        public SearchStatistics Statistics { get; }

        /// <summary>Gets the cancellation token that allows the caller to cancel the search.</summary>
        public CancellationToken CancellationToken { get; }
    }
}