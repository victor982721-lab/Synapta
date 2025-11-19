namespace HybridCliShell.Cli;

public readonly record struct HybridCliResult(bool Handled, int ExitCode)
{
    public static HybridCliResult Skipped => new(false, 0);
}
