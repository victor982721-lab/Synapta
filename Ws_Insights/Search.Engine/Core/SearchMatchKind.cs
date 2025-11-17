namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Describes the kind of match that resulted in a <see cref="SearchResult"/>.  Different
    /// matching modes may have different performance or semantic characteristics, but the
    /// consumer can treat them uniformly.
    /// </summary>
    public enum SearchMatchKind
    {
        /// <summary>Match came from a literal substring comparison.</summary>
        Literal,

        /// <summary>Match came from a regular expression engine.</summary>
        Regex,

        /// <summary>Match satisfied the whole‑word constraint.</summary>
        WholeWord,

        /// <summary>Match satisfied a prefix search (e.g. starts with).</summary>
        Prefix
    }
}