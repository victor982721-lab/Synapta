using Deduplinside.Infrastructure;

namespace Deduplinside.Models;

public class AnalysisStats : ObservableObject
{
    private long _processedLines;
    private long _duplicateLines;
    private long _rangeMatches;
    private int _totalFiles;
    private int _completedFiles;
    private double _linesPerSecond;
    private string _etaText = "Idle";

    public long ProcessedLines
    {
        get => _processedLines;
        set => SetProperty(ref _processedLines, value);
    }

    public long DuplicateLines
    {
        get => _duplicateLines;
        set => SetProperty(ref _duplicateLines, value);
    }

    public long RangeMatches
    {
        get => _rangeMatches;
        set => SetProperty(ref _rangeMatches, value);
    }

    public int TotalFiles
    {
        get => _totalFiles;
        set => SetProperty(ref _totalFiles, value);
    }

    public int CompletedFiles
    {
        get => _completedFiles;
        set => SetProperty(ref _completedFiles, value);
    }

    public double LinesPerSecond
    {
        get => _linesPerSecond;
        set => SetProperty(ref _linesPerSecond, value);
    }

    public string EtaText
    {
        get => _etaText;
        set => SetProperty(ref _etaText, value);
    }

    public void Reset()
    {
        ProcessedLines = 0;
        DuplicateLines = 0;
        RangeMatches = 0;
        TotalFiles = 0;
        CompletedFiles = 0;
        LinesPerSecond = 0;
        EtaText = "Calculating...";
    }
}
