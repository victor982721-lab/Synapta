using System.Windows;

namespace DocumentDeduplicator.Services;

public enum AppTheme
{
    Light,
    Dark
}

public class ThemeService
{
    private readonly System.Windows.Application _application;
    private readonly Uri _light = new("Themes/ThemeLight.xaml", UriKind.Relative);
    private readonly Uri _dark = new("Themes/ThemeDark.xaml", UriKind.Relative);

    public ThemeService(System.Windows.Application application)
    {
        _application = application;
    }

    public AppTheme CurrentTheme { get; private set; } = AppTheme.Light;

    public void Apply(AppTheme theme)
    {
        var resourceUri = theme == AppTheme.Dark ? _dark : _light;
        var dictionaries = _application.Resources.MergedDictionaries;
        dictionaries.Clear();
        dictionaries.Add(new ResourceDictionary { Source = resourceUri });
        CurrentTheme = theme;
    }

    public void Toggle()
    {
        Apply(CurrentTheme == AppTheme.Light ? AppTheme.Dark : AppTheme.Light);
    }
}
