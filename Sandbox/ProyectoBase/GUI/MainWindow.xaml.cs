using System.Windows;
using System.Windows.Controls;
using ProyectoBase.GUI.Views;
using ProyectoBase.GUI.Views.Tools.Search;

namespace ProyectoBase.GUI
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            foreach (var child in (this.Content as Grid).Children)
            {
                if (child is StackPanel panel)
                {
                    foreach (var elem in panel.Children)
                    {
                        if (elem is Button b)
                            b.Click += Navigate;
                    }
                }
            }

            MainFrame.Content = new HomeView();
        }

        private void Navigate(object sender, RoutedEventArgs e)
        {
            var tag = (sender as Button).Tag?.ToString();

            MainFrame.Content = tag switch
            {
                ""Home""   => new HomeView(),
                ""Config"" => new ConfigView(),
                ""Search"" => new SearchToolView(),
                _          => new HomeView()
            };
        }
    }
}
