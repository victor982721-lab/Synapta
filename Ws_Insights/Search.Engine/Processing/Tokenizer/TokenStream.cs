using System.Collections;
using System.Collections.Generic;

namespace Ws_Insights.Search.Processing.Tokenizer
{
    /// <summary>
    /// Provides an enumerable wrapper around a collection of tokens.  The stream may
    /// be materialised or generated on the fly.  This stub simply wraps a list.
    /// </summary>
    public class TokenStream : IEnumerable<Token>
    {
        private readonly IEnumerable<Token> _tokens;

        public TokenStream(IEnumerable<Token> tokens)
        {
            _tokens = tokens;
        }

        public IEnumerator<Token> GetEnumerator() => _tokens.GetEnumerator();
        IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
    }
}