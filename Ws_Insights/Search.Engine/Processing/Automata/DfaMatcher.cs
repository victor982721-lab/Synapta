using System.Collections.Generic;

namespace Ws_Insights.Search.Processing.Automata
{
    /// <summary>
    /// Executes a deterministic finite automaton over input text.  This stub implementation
    /// performs a simple substring search using <see cref="string.Contains(string)"/> and
    /// yields the starting indices of matches.
    /// </summary>
    public class DfaMatcher
    {
        private readonly string _pattern;
        public DfaMatcher(string pattern)
        {
            _pattern = pattern;
        }

        public IEnumerable<int> FindMatches(string text)
        {
            if (string.IsNullOrEmpty(_pattern) || string.IsNullOrEmpty(text))
                yield break;

            int index = 0;
            while ((index = text.IndexOf(_pattern, index, System.StringComparison.Ordinal)) >= 0)
            {
                yield return index;
                index += _pattern.Length;
            }
        }
    }
}