using System.Windows;
using Deduplinside.Services;
using Deduplinside.ViewModels;

namespace Deduplinside;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var viewModel = new MainViewModel(
            new DeduplicationService(),
            new MergeService(),
            new SearchService(),
            new RangeExtractionService());

        var window = new MainWindow
        {
            DataContext = viewModel
        };

        MainWindow = window;
        window.Show();
    }
}
