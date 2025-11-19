namespace HybridCliShell.Telemetry;

public readonly record struct TelemetrySnapshot(DateTimeOffset Timestamp, int ActiveOperations, double Throughput);
