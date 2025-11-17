using Ws_Insights.Search.Index.Segment;

namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Represents a single search hit. A result ties together a document path, the location within
    /// the document that matched, a snippet of surrounding text and optional metadata such as a
    /// score or match kind.
    /// </summary>
    public class SearchResult
    {
        /// <summary>Gets or sets the full file system path of the document containing the match.</summary>
        public string Path { get; set; } = string.Empty;

        /// <summary>Gets or sets the one‑based line number where the match begins.</summary>
        public int LineNumber { get; set; }
        
        /// <summary>Gets or sets the one‑based column number within the line where the match begins.</summary>
        public int Column { get; set; }

        /// <summary>Gets or sets a short snippet of text surrounding the match.  Snippets are intended
        /// for display in a UI rather than further processing.</summary>
        public string Snippet { get; set; } = string.Empty;

        /// <summary>Gets or sets an optional score used for ranking results.  Higher scores indicate
        /// more relevant results.  A value of zero means no score has been assigned.</summary>
        public double Score { get; set; }

        /// <summary>Gets or sets the type of match that produced this result.</summary>
        public SearchMatchKind MatchKind { get; set; }

        /// <summary>Gets or sets the identifier of the segment containing the document that matched.
        /// This value may be <c>null</c> if the result was produced outside the index (for example,
        /// during a non‑indexed scan).</summary>
        public SegmentId? SegmentId { get; set; }

        /// <summary>Gets or sets the identifier of the document within a segment.  This value may be
        /// <c>null</c> for results produced by non‑indexed scans.</summary>
        public int? DocId { get; set; }
    }
}