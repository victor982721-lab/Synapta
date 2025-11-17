namespace Ws_Insights.Search.Processing.Text
{
    /// <summary>
    /// Provides precomputed lookup tables for character classification.  A full implementation
    /// would include tables for letters, digits, whitespace and delimiters used by the tokenizer.
    /// The stub defines empty tables.
    /// </summary>
    public static class CharsetTables
    {
        public static readonly bool[] IsLetter = new bool[256];
        public static readonly bool[] IsDigit = new bool[256];
        public static readonly bool[] IsWhitespace = new bool[256];
        public static readonly bool[] IsDelimiter = new bool[256];
    }
}