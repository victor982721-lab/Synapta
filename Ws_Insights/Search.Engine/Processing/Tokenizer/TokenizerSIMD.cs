using System.Collections.Generic;
using Ws_Insights.Search.Processing.Tokenizer;

namespace Ws_Insights.Search.Processing.Tokenizer
{
    /// <summary>
    /// Tokenises text using vectorised operations to achieve high throughput.  The stub
    /// implementation simply splits on whitespace.
    /// </summary>
    public static class TokenizerSIMD
    {
        public static IEnumerable<Token> Tokenize(string text)
        {
            int index = 0;
            foreach (var part in text.Split(' ', '\n', '\r', '\t'))
            {
                if (string.IsNullOrEmpty(part))
                    continue;
                yield return new Token(index, part.Length);
                index += part.Length + 1;
            }
        }
    }
}