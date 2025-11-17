using System;

namespace Ws_Insights.Search.Core.Flags
{
    /// <summary>
    /// Flags that control search behaviour. Multiple flags can be combined to form a single bitmask
    /// passed through <see cref="Core.SearchOptions"/>. Each flag enables or disables a specific
    /// feature such as case sensitivity or regex mode.
    /// </summary>
    [Flags]
    public enum SearchOptionFlags
    {
        /// <summary>No flags specified.</summary>
        None = 0,

        /// <summary>Perform a case-sensitive search.</summary>
        CaseSensitive = 1 << 0,

        /// <summary>Interpret the query as a regular expression.</summary>
        UseRegex = 1 << 1,

        /// <summary>Only match whole words.</summary>
        WholeWord = 1 << 2,

        /// <summary>Include subfolders when enumerating files.</summary>
        IncludeSubfolders = 1 << 3,

        /// <summary>Include hidden files in the search.</summary>
        IncludeHidden = 1 << 4,

        /// <summary>Include system files in the search.</summary>
        IncludeSystem = 1 << 5
    }
}