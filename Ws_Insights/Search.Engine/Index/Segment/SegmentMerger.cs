using System.Collections.Generic;
using System.Threading.Tasks;

namespace Ws_Insights.Search.Index.Segment
{
    /// <summary>
    /// Combines multiple smaller segments into a larger, more efficient one.  Merges rebalance
    /// postings and recompute Bloom filters.  This stub simply returns a new segment id.
    /// </summary>
    public class SegmentMerger
    {
        public Task<SegmentId> MergeAsync(IEnumerable<SegmentReader> segments)
        {
            // TODO: merge segments and write a new one to disk
            return Task.FromResult(SegmentId.NewId());
        }
    }
}