using System.Threading.Tasks;
using Ws_Insights.Search.Index;
using Ws_Insights.Search.IO;
using Ws_Insights.Search.Index.Segment;

namespace Ws_Insights.Search.Public
{
    /// <summary>
    /// Provides operations for building and maintaining the index.  The service wraps
    /// <see cref="IndexManager"/> and exposes asynchronous methods suitable for use by UIs.
    /// </summary>
    public class IndexService
    {
        private readonly IndexManager _indexManager;
        public IndexService(IndexManager indexManager)
        {
            _indexManager = indexManager;
        }

        public Task BuildFullAsync(string rootPath, IndexBuildOptions? options = null)
        {
            return _indexManager.BuildFullIndexAsync(rootPath);
        }

        public Task UpdateAsync(FileChangeSet changes)
        {
            return _indexManager.UpdateIndexAsync(changes);
        }

        public Task RebuildSegmentAsync(SegmentId id)
        {
            // TODO: implement selective segment rebuild
            return Task.CompletedTask;
        }

        public Task CompactAsync()
        {
            // TODO: trigger background merges
            return Task.CompletedTask;
        }
    }

    /// <summary>
    /// Options used when building a new index.  Future versions of the engine may allow
    /// configuration of thread counts, filter parameters, etc.  The stub is empty.
    /// </summary>
    public class IndexBuildOptions
    {
    }
}