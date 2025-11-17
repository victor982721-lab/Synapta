using System;

namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Collects various metrics about the execution of a search.  Statistics are intended for
    /// diagnostics, UI display and performance tuning rather than core algorithmic use.
    /// </summary>
    public class SearchStatistics
    {
        public long FilesScanned { get; set; }
        public long FilesSkippedByBloom { get; set; }
        public long FilesFromCache { get; set; }
        public long BytesReadFromDisk { get; set; }
        public long BytesReadFromCache { get; set; }
        public long MatchesFound { get; set; }
        public long SegmentsVisited { get; set; }
        public TimeSpan IndexLookupTime { get; set; }
        public TimeSpan DiskTime { get; set; }
        public TimeSpan ProcessingTime { get; set; }
        public TimeSpan TotalTime { get; set; }
    }
}