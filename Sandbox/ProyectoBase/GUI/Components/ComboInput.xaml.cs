using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class ComboInput : UserControl
    {
        public ComboInput()
        {
            InitializeComponent();
            Items = new ObservableCollection<string>();
        }

        public ObservableCollection<string> Items { get; set; }

        public static readonly DependencyProperty LabelProperty =
            DependencyProperty.Register(""Label"", typeof(string), typeof(ComboInput), new PropertyMetadata(""""));

        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(""Value"", typeof(string), typeof(ComboInput), new PropertyMetadata(""""));

        public string Label
        {
            get => (string)GetValue(LabelProperty);
            set => SetValue(LabelProperty, value);
        }

        public string Value
        {
            get => (string)GetValue(ValueProperty);
            set => SetValue(ValueProperty, value);
        }
    }
}
