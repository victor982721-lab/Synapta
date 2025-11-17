using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Ws_Insights.Search.Processing.Regex
{
    /// <summary>
    /// Wraps regular expression matching behind a common interface.  The engine can use the
    /// built‑in <see cref="System.Text.RegularExpressions.Regex"/> or fallback to Hyperscan when
    /// available.  This stub implementation uses <see cref="Regex"/> directly.
    /// </summary>
    public class RegexEngine
    {
        private readonly Regex _regex;
        public RegexEngine(string pattern, RegexOptions options = RegexOptions.None)
        {
            _regex = new Regex(pattern, options | RegexOptions.Compiled);
        }

        public IEnumerable<int> FindMatches(string text)
        {
            foreach (Match match in _regex.Matches(text))
            {
                yield return match.Index;
            }
        }
    }
}