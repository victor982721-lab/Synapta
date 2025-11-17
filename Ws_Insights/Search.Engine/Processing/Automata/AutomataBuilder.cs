namespace Ws_Insights.Search.Processing.Automata
{
    /// <summary>
    /// Builds deterministic finite automata (DFAs) from simple search patterns.  The stub
    /// implementation returns an identity matcher that simply checks for substring presence.
    /// </summary>
    public static class AutomataBuilder
    {
        public static DfaMatcher BuildLiteral(string pattern)
        {
            return new DfaMatcher(pattern);
        }
    }
}