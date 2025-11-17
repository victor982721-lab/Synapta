using System.Threading.Tasks;

namespace Ws_Insights.Search.Index.Segment
{
    /// <summary>
    /// Builds a new immutable segment from a set of documents and associated metadata.  A full
    /// implementation would tokenise input, build postings lists, write column stores and Bloom
    /// filters.  This stub class provides only an asynchronous entry point.
    /// </summary>
    public class SegmentWriter
    {
        public Task<SegmentId> WriteAsync(object input)
        {
            // TODO: write segment files to disk
            return Task.FromResult(SegmentId.NewId());
        }
    }
}