using System.Windows;

namespace HybridCliShell.Services;

public sealed class ThemeManager
{
    private static readonly Uri PaletteUri = new("Themes/Palette.xaml", UriKind.Relative);
    private static readonly Uri DarkThemeUri = new("Themes/ThemeDark.xaml", UriKind.Relative);
    private static readonly Uri LightThemeUri = new("Themes/ThemeLight.xaml", UriKind.Relative);

    public ThemeVariant CurrentTheme { get; private set; } = ThemeVariant.Light;

    public event EventHandler<ThemeVariant>? ThemeChanged;

    public void ApplyTheme(ThemeVariant variant)
    {
        if (Application.Current == null)
        {
            CurrentTheme = variant;
            ThemeChanged?.Invoke(this, variant);
            return;
        }

        ResourceDictionary[] dictionaries =
        {
            new() { Source = PaletteUri },
            new() { Source = variant == ThemeVariant.Dark ? DarkThemeUri : LightThemeUri }
        };

        Application.Current.Resources.MergedDictionaries.Clear();
        foreach (ResourceDictionary dictionary in dictionaries)
        {
            Application.Current.Resources.MergedDictionaries.Add(dictionary);
        }

        CurrentTheme = variant;
        ThemeChanged?.Invoke(this, variant);
    }
}
