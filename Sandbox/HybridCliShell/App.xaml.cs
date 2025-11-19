using System.Windows;
using HybridCliShell.Cli;
using HybridCliShell.Windows;
using Microsoft.Extensions.DependencyInjection;

namespace HybridCliShell;

public partial class App : Application
{
    private HybridBootstrapper? _bootstrapper;

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _bootstrapper = new HybridBootstrapper();

        HybridCliResult cliResult = await _bootstrapper.TryRunCliAsync(e.Args);
        if (cliResult.Handled)
        {
            Shutdown(cliResult.ExitCode);
            return;
        }

        MainWindow = _bootstrapper.Services.GetRequiredService<ShellWindow>();
        MainWindow?.Show();
    }

    protected override async void OnExit(ExitEventArgs e)
    {
        if (_bootstrapper is not null)
        {
            await _bootstrapper.DisposeAsync();
        }

        base.OnExit(e);
    }
}
