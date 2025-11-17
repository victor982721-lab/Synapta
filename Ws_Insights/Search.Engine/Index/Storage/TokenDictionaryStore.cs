namespace Ws_Insights.Search.Index.Storage
{
    /// <summary>
    /// Provides an abstraction over the dictionary of tokens stored in a segment.  It maps
    /// string tokens to integer ordinals and optionally manages persistence to disk.  The
    /// stub implementation contains only minimal structure.
    /// </summary>
    public class TokenDictionaryStore
    {
        public int GetOrdinal(string token) => -1;
        public string GetToken(int ordinal) => string.Empty;
    }
}