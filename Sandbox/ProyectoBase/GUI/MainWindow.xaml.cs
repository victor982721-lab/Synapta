using System.Windows;
using System.Windows.Media.Animation;
using ProyectoBase.GUI.Views;
using System.Windows.Controls;
using System.Linq;

namespace ProyectoBase.GUI
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            ApplyFade(new HomeView());
            MoveHighlightTo(SidebarPanel.Children[0] as Button);
        }

        private void ApplyFade(object newPage)
        {
            MainFrame.Content = newPage;
            var fade = (Storyboard)FindResource("FadeInStoryboard");
            fade.Begin(MainFrame);
        }

        private void MoveHighlightTo(Button btn)
        {
            var index = SidebarPanel.Children.IndexOf(btn);
            double newTop = index * 42; // altura aproximada por botón

            var storyboard = (Storyboard)FindResource("SlideHighlightStoryboard");
            var animation = storyboard.Children[0] as DoubleAnimation;
            animation.To = newTop;

            storyboard.Begin(HighlightBar);
        }

        private void OnNavHome(object sender, RoutedEventArgs e)
        {
            ApplyFade(new HomeView());
            MoveHighlightTo(sender as Button);
        }

        private void OnNavConfig(object sender, RoutedEventArgs e)
        {
            ApplyFade(new ConfigView());
            MoveHighlightTo(sender as Button);
        }

        private void OnNavLogs(object sender, RoutedEventArgs e)
        {
            ApplyFade(new LogsView());
            MoveHighlightTo(sender as Button);
        }

        private void OnNavTools(object sender, RoutedEventArgs e)
        {
            ApplyFade(new ToolsView());
            MoveHighlightTo(sender as Button);
        }

        private void OnLightTheme(object sender, RoutedEventArgs e)
        {
            ThemeManager.ApplyLightTheme();
        }

        private void OnDarkTheme(object sender, RoutedEventArgs e)
        {
            ThemeManager.ApplyDarkTheme();
        }
    }
}
