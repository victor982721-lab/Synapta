using HybridCliShell.Services;
using HybridCliShell.Telemetry;
using HybridCliShell.ViewModels;
using HybridCliShell.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace HybridCliShell.Cli;

public sealed class HybridBootstrapper : IAsyncDisposable
{
    private readonly IHost _host;
    private readonly HybridCommandHost _commandHost;

    public HybridBootstrapper()
    {
        HostApplicationBuilder builder = Host.CreateApplicationBuilder();
        builder.Services.AddSingleton<ThemeManager>();
        builder.Services.AddSingleton<TelemetryStream>();
        builder.Services.AddSingleton<HybridCommandHost>();
        builder.Services.AddSingleton<ShellViewModel>();
        builder.Services.AddSingleton<ShellWindow>();

        _host = builder.Build();
        _commandHost = _host.Services.GetRequiredService<HybridCommandHost>();
        _host.StartAsync().GetAwaiter().GetResult();
    }

    public IServiceProvider Services => _host.Services;

    public async ValueTask DisposeAsync()
    {
        await _host.StopAsync();
        _host.Dispose();
    }

    public async Task<HybridCliResult> TryRunCliAsync(IReadOnlyList<string> args)
    {
        return await _commandHost.TryExecuteAsync(args);
    }
}
