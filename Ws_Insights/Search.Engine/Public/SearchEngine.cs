using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Ws_Insights.Search.Core;
using Ws_Insights.Search.Cache;
using Ws_Insights.Search.Index;

namespace Ws_Insights.Search.Public
{
    /// <summary>
    /// Entry point for consumers of the search engine.  This class orchestrates search contexts
    /// and pipelines and exposes an easy to use asynchronous API.  The stub implementation
    /// delegates to <see cref="SearchPipeline"/> but returns no results.
    /// </summary>
    public class SearchEngine
    {
        private readonly IndexManager _indexManager;
        private readonly HotFileCache _hotFileCache;
        private readonly QueryCache _queryCache;
        private readonly SearchPipeline _pipeline;

        public SearchEngine(IndexManager indexManager, HotFileCache? hotFileCache = null, QueryCache? queryCache = null)
        {
            _indexManager = indexManager;
            _hotFileCache = hotFileCache ?? new HotFileCache();
            _queryCache = queryCache ?? new QueryCache();
            _pipeline = new SearchPipeline();
        }

        /// <summary>
        /// Starts a new search and returns a session token that can be used to stream results.
        /// </summary>
        public Task<SearchSession> StartSearchAsync(SearchOptions options, CancellationToken ct = default)
        {
            var context = new SearchContext(options, _indexManager, _hotFileCache, _queryCache, ct);
            return Task.FromResult(new SearchSession(context));
        }

        /// <summary>
        /// Streams results for an existing search session.  Each call returns a new asynchronous
        /// enumerable that yields results.  Callers can cancel via the cancellation token.
        /// </summary>
        public IAsyncEnumerable<SearchResult> StreamResultsAsync(SearchSession session, CancellationToken ct = default)
        {
            return _pipeline.ExecuteAsync(session.Context, ct);
        }

        /// <summary>
        /// Retrieves statistics for a completed or in‑progress search.
        /// </summary>
        public Task<SearchStatistics> GetStatisticsAsync(SearchSession session)
        {
            return Task.FromResult(session.Context.Statistics);
        }
    }

    /// <summary>
    /// Represents an opaque handle to an in‑progress search.  The session holds a reference to
    /// the underlying <see cref="SearchContext"/> but hides implementation details from the consumer.
    /// </summary>
    public class SearchSession
    {
        internal SearchContext Context { get; }
        internal SearchSession(SearchContext context)
        {
            Context = context;
        }
    }
}