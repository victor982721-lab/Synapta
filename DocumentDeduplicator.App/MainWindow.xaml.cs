using System.Windows;
using DocumentDeduplicator.Services;
using DocumentDeduplicator.ViewModels;

namespace DocumentDeduplicator;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        if (System.Windows.Application.Current is App app)
        {
            DataContext = new MainViewModel(app.ThemeService);
        }
    }
}
