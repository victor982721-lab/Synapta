using System.Collections.Generic;

namespace Ws_Insights.Search.Public
{
    /// <summary>
    /// Exposes internal metrics of the engine for logging or display in advanced UIs.  The
    /// diagnostic information can include cache utilisation, segment counts and timing data.
    /// The stub implementation returns an empty dictionary.
    /// </summary>
    public static class Diagnostics
    {
        public static IDictionary<string, object> GetMetrics()
        {
            return new Dictionary<string, object>();
        }
    }
}