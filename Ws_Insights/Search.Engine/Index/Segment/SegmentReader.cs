using System.Collections.Generic;

namespace Ws_Insights.Search.Index.Segment
{
    /// <summary>
    /// Reads data from a single immutable segment.  In a real implementation the reader would
    /// support retrieving postings lists, metadata columns and Bloom filter lookups.  This stub
    /// exposes minimal structure for compilation.
    /// </summary>
    public class SegmentReader
    {
        public SegmentId Id { get; }

        public SegmentReader(SegmentId id)
        {
            Id = id;
        }

        public IEnumerable<int> GetPostings(string token)
        {
            // TODO: return document identifiers for the given token
            yield break;
        }
    }
}