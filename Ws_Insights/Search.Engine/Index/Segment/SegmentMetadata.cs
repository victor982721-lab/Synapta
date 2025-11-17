using System;

namespace Ws_Insights.Search.Index.Segment
{
    /// <summary>
    /// Contains descriptive information about a segment.  The metadata is stored in the segment
    /// header and summarises the number of documents, tokens and overall size of the segment.
    /// </summary>
    public class SegmentMetadata
    {
        public SegmentId Id { get; set; }
        public int DocumentCount { get; set; }
        public long TokenCount { get; set; }
        public long AverageDocumentSize { get; set; }
        public DateTime Timestamp { get; set; }
        public int MinDocId { get; set; }
        public int MaxDocId { get; set; }
    }
}