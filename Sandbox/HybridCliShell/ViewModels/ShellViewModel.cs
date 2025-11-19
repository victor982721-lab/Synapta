using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using HybridCliShell.Services;
using HybridCliShell.Telemetry;

namespace HybridCliShell.ViewModels;

public partial class ShellViewModel : ObservableObject, IDisposable
{
    private readonly ThemeManager _themeManager;
    private readonly TelemetryStream _telemetryStream;
    private readonly ObservableCollection<TelemetrySnapshot> _samples = new();
    private readonly ObservableCollection<string> _logs = new();
    private readonly CancellationTokenSource _cts = new();

    public ReadOnlyObservableCollection<TelemetrySnapshot> Samples { get; }
    public ReadOnlyObservableCollection<string> Logs { get; }

    [ObservableProperty]
    private string _currentTheme = "Light";

    [ObservableProperty]
    private string _status = "Esperando telemetría...";

    public IAsyncRelayCommand ToggleThemeCommand { get; }
    public IAsyncRelayCommand ForcePulseCommand { get; }

    public ShellViewModel(ThemeManager themeManager, TelemetryStream telemetryStream)
    {
        _themeManager = themeManager;
        _telemetryStream = telemetryStream;
        Samples = new ReadOnlyObservableCollection<TelemetrySnapshot>(_samples);
        Logs = new ReadOnlyObservableCollection<string>(_logs);

        ToggleThemeCommand = new AsyncRelayCommand(ToggleThemeAsync);
        ForcePulseCommand = new AsyncRelayCommand(ForcePulseAsync);

        _themeManager.ThemeChanged += (_, variant) => CurrentTheme = variant.ToString();
        _ = ObserveTelemetryAsync(_cts.Token);
    }

    private Task ToggleThemeAsync()
    {
        ThemeVariant next = _themeManager.CurrentTheme == ThemeVariant.Dark ? ThemeVariant.Light : ThemeVariant.Dark;
        _themeManager.ApplyTheme(next);
        AppendLog($"Tema cambiado a {next}");
        return Task.CompletedTask;
    }

    private Task ForcePulseAsync()
    {
        _telemetryStream.EmitPulse();
        AppendLog("Pulso manual emitido");
        return Task.CompletedTask;
    }

    private async Task ObserveTelemetryAsync(CancellationToken token)
    {
        try
        {
            await foreach (TelemetrySnapshot snapshot in _telemetryStream.ConsumeAsync(token))
            {
                _samples.Insert(0, snapshot);
                while (_samples.Count > 20)
                {
                    _samples.RemoveAt(_samples.Count - 1);
                }

                Status = $"{snapshot.ActiveOperations} operaciones activas • {snapshot.Throughput:N2} ops/s";
            }
        }
        catch (OperationCanceledException)
        {
        }
    }

    private void AppendLog(string message)
    {
        string enriched = $"[{DateTimeOffset.Now:HH:mm:ss}] {message}";
        _logs.Insert(0, enriched);
        while (_logs.Count > 10)
        {
            _logs.RemoveAt(_logs.Count - 1);
        }
    }

    public void Dispose()
    {
        _cts.Cancel();
        _cts.Dispose();
    }
}
