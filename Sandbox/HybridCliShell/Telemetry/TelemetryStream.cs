using System.Collections.Concurrent;
using System.Threading.Channels;

namespace HybridCliShell.Telemetry;

public sealed class TelemetryStream
{
    private readonly Channel<TelemetrySnapshot> _channel = Channel.CreateUnbounded<TelemetrySnapshot>();
    private readonly ConcurrentQueue<TelemetrySnapshot> _history = new();
    private readonly PeriodicTimer _timer = new(TimeSpan.FromSeconds(2));

    public TelemetryStream()
    {
        _ = PumpAsync();
    }

    public IAsyncEnumerable<TelemetrySnapshot> ConsumeAsync(CancellationToken token) => _channel.Reader.ReadAllAsync(token);

    public TelemetrySnapshot GetSnapshot()
    {
        if (_history.TryPeek(out TelemetrySnapshot? snapshot))
        {
            return snapshot;
        }

        return new TelemetrySnapshot(DateTimeOffset.Now, 0, 0);
    }

    public void EmitPulse()
    {
        TelemetrySnapshot snapshot = new(DateTimeOffset.Now, Random.Shared.Next(1, 6), Random.Shared.NextDouble() * 100);
        _channel.Writer.TryWrite(snapshot);
        _history.Enqueue(snapshot);
        Trim();
    }

    private async Task PumpAsync()
    {
        while (await _timer.WaitForNextTickAsync())
        {
            EmitPulse();
        }
    }

    private void Trim()
    {
        while (_history.Count > 32 && _history.TryDequeue(out _))
        {
        }
    }
}
