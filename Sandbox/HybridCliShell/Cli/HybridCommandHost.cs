using System.CommandLine;
using System.CommandLine.Invocation;
using HybridCliShell.Services;
using HybridCliShell.Telemetry;

namespace HybridCliShell.Cli;

public sealed class HybridCommandHost
{
    private readonly ThemeManager _themeManager;
    private readonly TelemetryStream _telemetryStream;
    private readonly Parser _parser;

    private static readonly string CliSwitch = "--cli";

    public HybridCommandHost(ThemeManager themeManager, TelemetryStream telemetryStream)
    {
        _themeManager = themeManager;
        _telemetryStream = telemetryStream;
        _parser = BuildParser();
    }

    public async Task<HybridCliResult> TryExecuteAsync(IReadOnlyList<string> args)
    {
        if (!args.Contains(CliSwitch, StringComparer.OrdinalIgnoreCase))
        {
            return HybridCliResult.Skipped;
        }

        string[] filtered = args.Where(a => !string.Equals(a, CliSwitch, StringComparison.OrdinalIgnoreCase)).ToArray();
        int exitCode = await _parser.InvokeAsync(filtered);
        return new HybridCliResult(true, exitCode);
    }

    private Parser BuildParser()
    {
        RootCommand root = new("Shell CLI")
        {
            Description = "Interfaz de línea de comandos para controlar el shell híbrido"
        };

        Option<ThemeVariant> themeOption = new("--theme", () => ThemeVariant.Dark, "Tema a aplicar (Dark|Light)");
        root.AddGlobalOption(themeOption);
        root.SetHandler((ThemeVariant variant) => _themeManager.ApplyTheme(variant), themeOption);

        Command statusCommand = new("status", "Muestra el estado del stream de telemetría");
        statusCommand.SetHandler(PrintStatus);
        root.AddCommand(statusCommand);

        Command pulseCommand = new("pulse", "Inyecta un pulso de telemetría para la UI");
        pulseCommand.SetHandler(ProducePulse);
        root.AddCommand(pulseCommand);

        return new CommandLineBuilder(root)
            .UseDefaults()
            .Build();
    }

    private void PrintStatus(InvocationContext context)
    {
        TelemetrySnapshot snapshot = _telemetryStream.GetSnapshot();
        context.Console.Out.WriteLine($"Metrics: {snapshot.ActiveOperations} activos, {snapshot.Throughput:N2} ops/s, tema { _themeManager.CurrentTheme }");
    }

    private void ProducePulse()
    {
        _telemetryStream.EmitPulse();
    }
}
