using System;

namespace Ws_Insights.Search.Processing
{
    /// <summary>
    /// Contains general helper methods for operating on <see cref="Span{T}"/> and <see cref="ReadOnlySpan{T}"/>.
    /// The methods provided here are simple stand‑ins for more efficient algorithms that avoid
    /// allocations when working with memory spans.
    /// </summary>
    public static class SpanHelpers
    {
        /// <summary>
        /// Searches for a subspan within a span of characters.  Returns the index of the first
        /// occurrence or ‑1 if not found.  This stub delegates to <see cref="string.IndexOf(string)"/>.
        /// </summary>
        public static int IndexOf(ReadOnlySpan<char> span, ReadOnlySpan<char> value)
        {
            return span.ToString().IndexOf(value.ToString(), StringComparison.Ordinal);
        }
    }
}