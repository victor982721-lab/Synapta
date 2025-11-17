using System.Threading;
using System.Threading.Tasks;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Coordinates concurrent reads from disk to avoid overwhelming the IO subsystem.  This stub
    /// implementation performs no scheduling and simply runs the provided delegate immediately.
    /// </summary>
    public class AsyncDiskScheduler
    {
        public Task<T> ScheduleAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
        {
            // TODO: limit concurrency based on estimated IO bandwidth
            return operation();
        }
    }
}