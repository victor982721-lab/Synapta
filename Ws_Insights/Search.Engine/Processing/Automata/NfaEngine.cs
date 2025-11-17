namespace Ws_Insights.Search.Processing.Automata
{
    /// <summary>
    /// Executes a non‑deterministic finite automaton.  NFAs are more flexible but slower than
    /// DFAs.  The stub implementation does not support complex patterns and returns no matches.
    /// </summary>
    public class NfaEngine
    {
        public static NfaEngine Empty { get; } = new NfaEngine();
        public NfaEngine() { }

        public bool Match(string text) => false;
    }
}