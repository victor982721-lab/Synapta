using System.Windows;
using System.Windows.Controls;
using ProyectoBase.GUI.ModuleSystem;

namespace ProyectoBase.GUI
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            LoadSidebar();
            LoadDefault();
        }

        private void LoadSidebar()
        {
            foreach (var module in ModuleRegistry.GetAll())
            {
                var btn = new Button
                {
                    Content = module.Name,
                    Tag = module.Id,
                    Margin = new Thickness(0, 5, 0, 5),
                    Style = (Style)FindResource(""SidebarButtonStyle"")
                };

                btn.Click += Navigate;
                Sidebar.Children.Add(btn);
            }
        }

        private void LoadDefault()
        {
            MainFrame.Content = ModuleRegistry.Get(""Home"")?.Factory();
        }

        private void Navigate(object sender, RoutedEventArgs e)
        {
            string id = (string)((Button)sender).Tag;

            var module = ModuleRegistry.Get(id);
            if (module != null)
                MainFrame.Content = module.Factory();
        }
    }
}
