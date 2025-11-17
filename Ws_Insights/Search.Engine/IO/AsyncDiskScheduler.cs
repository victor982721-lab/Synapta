using System;
using System.Threading;
using System.Threading.Tasks;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Coordinates concurrent reads from disk to avoid overwhelming the IO subsystem.  The scheduler
    /// uses a <see cref="SemaphoreSlim"/> to cap the number of simultaneous operations and provides a
    /// simple priority-neutral queue.  This greatly reduces the risk of saturating the storage stack
    /// when the caller fans out to dozens of files.
    /// </summary>
    public sealed class AsyncDiskScheduler : IAsyncDisposable
    {
        private readonly SemaphoreSlim _semaphore;

        public AsyncDiskScheduler(int maxConcurrency = 0)
        {
            if (maxConcurrency <= 0)
            {
                maxConcurrency = Math.Max(1, Environment.ProcessorCount / 2);
            }

            _semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);
        }

        public async Task<T> ScheduleAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(operation);
            await _semaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
            try
            {
                return await operation().ConfigureAwait(false);
            }
            finally
            {
                _semaphore.Release();
            }
        }

        public async ValueTask DisposeAsync()
        {
            await Task.Yield();
            _semaphore.Dispose();
        }
    }
}