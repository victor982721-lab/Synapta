using System.Collections.Generic;
using System.Threading.Tasks;

namespace Ws_Insights.Search.Public
{
    /// <summary>
    /// Provides advanced analysis and reporting functionality over the index.  Examples include
    /// coverage reports and optimisation suggestions.  The stub exposes no methods.
    /// </summary>
    public class Analyzer
    {
        public Task<IDictionary<string, object>> GetCoverageReportAsync()
        {
            // TODO: implement analysis of indexed vs. non indexed files
            return Task.FromResult<IDictionary<string, object>>(new Dictionary<string, object>());
        }
    }
}