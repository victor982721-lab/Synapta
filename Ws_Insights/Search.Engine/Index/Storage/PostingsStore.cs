using System.Collections.Generic;

namespace Ws_Insights.Search.Index.Storage
{
    /// <summary>
    /// Stores and retrieves postings lists for a segment.  Each postings list contains a
    /// collection of document identifiers along with optional frequency and positional
    /// information.  This stub implementation exposes only a minimal API.
    /// </summary>
    public class PostingsStore
    {
        public IEnumerable<int> GetPostings(int tokenOrdinal)
        {
            // TODO: return document identifiers for the token
            yield break;
        }
    }
}