using System;

namespace Ws_Insights.Search.Core.Util
{
    /// <summary>
    /// Defines an abstraction over the concept of time.  This allows the engine to be unit tested
    /// without relying on real wall clock time, and enables scenarios such as time freezing or
    /// deterministic playback.
    /// </summary>
    public interface ITimeProvider
    {
        DateTimeOffset Now { get; }
    }

    /// <summary>
    /// Provides access to a global time provider.  By default the provider uses the system clock
    /// but can be swapped for a mock during testing.
    /// </summary>
    public static class TimeProvider
    {
        private static ITimeProvider _current = new SystemTimeProvider();

        /// <summary>
        /// Gets or sets the current <see cref="ITimeProvider"/> used by the engine.  Assigning a new
        /// provider allows time to be controlled for testing purposes.
        /// </summary>
        public static ITimeProvider Current
        {
            get => _current;
            set => _current = value ?? throw new ArgumentNullException(nameof(value));
        }

        private sealed class SystemTimeProvider : ITimeProvider
        {
            public DateTimeOffset Now => DateTimeOffset.UtcNow;
        }
    }
}