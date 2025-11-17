using System;

namespace Ws_Insights.Search;

/// <summary>
/// Snapshot of metrics produced while a search is running. The UI consumes these
/// values to update progress indicators, throughput graphs and status text.
/// </summary>
public sealed class SearchProgress
{
    public int FilesScanned { get; init; }
    public int Matches { get; init; }
    public int Errors { get; init; }
    public double FilesPerSecond { get; init; }
    public TimeSpan Elapsed { get; init; }
    public string? CurrentFile { get; init; }
}
