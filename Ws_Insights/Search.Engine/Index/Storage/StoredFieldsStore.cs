using System.Collections.Generic;

namespace Ws_Insights.Search.Index.Storage
{
    /// <summary>
    /// Provides access to stored fields for documents in a segment.  Stored fields may include
    /// snippets of text or other metadata that are expensive to recompute.  This stub
    /// implementation returns empty values.
    /// </summary>
    public class StoredFieldsStore
    {
        public IReadOnlyDictionary<string, object> GetFields(int docId)
        {
            // TODO: retrieve arbitrary stored fields for a document
            return new Dictionary<string, object>();
        }
    }
}