namespace Ws_Insights.Search.Processing.Regex
{
    /// <summary>
    /// Provides an interface to the Hyperscan regex engine via P/Invoke.  Hyperscan is optional
    /// and may not be available on all platforms.  This stub does not perform any matching.
    /// </summary>
    public class HyperscanEngine
    {
        public HyperscanEngine(string pattern) { }
        public bool IsAvailable => false;
    }
}