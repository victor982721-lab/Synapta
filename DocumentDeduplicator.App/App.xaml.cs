using DocumentDeduplicator.Services;

namespace DocumentDeduplicator;

public partial class App : System.Windows.Application
{
    public ThemeService ThemeService { get; private set; } = null!;

    protected override void OnStartup(System.Windows.StartupEventArgs e)
    {
        base.OnStartup(e);
        ThemeService = new ThemeService(this);
        ThemeService.Apply(AppTheme.Light);
    }
}
