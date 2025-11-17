namespace Ws_Insights.Search.Processing.Tokenizer
{
    /// <summary>
    /// Represents a single token within a document.  Tokens are defined by their start index
    /// and length within the original text.  Additional metadata such as hashes may be added.
    /// </summary>
    public readonly record struct Token(int Position, int Length);
}