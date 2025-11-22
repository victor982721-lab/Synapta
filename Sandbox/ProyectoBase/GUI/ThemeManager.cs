using System;
using System.Windows;

namespace ProyectoBase.GUI
{
    public static class ThemeManager
    {
        public static void ApplyLightTheme()
        {
            ApplyTheme("Styles/Theme.Light.xaml");
        }

        public static void ApplyDarkTheme()
        {
            ApplyTheme("Styles/Theme.Dark.xaml");
        }

        private static void ApplyTheme(string themePath)
        {
            var app = Application.Current;

            app.Resources.MergedDictionaries.Clear();

            // Tema moderno base
            app.Resources.MergedDictionaries.Add(
                new ResourceDictionary
                {
                    Source = new Uri("Styles/ModernTheme.xaml", UriKind.Relative)
                }
            );

            // Tema Light o Dark
            app.Resources.MergedDictionaries.Add(
                new ResourceDictionary
                {
                    Source = new Uri(themePath, UriKind.Relative)
                }
            );
        }
    }
}
