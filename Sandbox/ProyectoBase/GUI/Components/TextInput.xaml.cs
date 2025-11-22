using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class TextInput : UserControl
    {
        public TextInput()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty LabelProperty =
            DependencyProperty.Register(""Label"", typeof(string), typeof(TextInput), new PropertyMetadata(""""));

        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(""Value"", typeof(string), typeof(TextInput), new PropertyMetadata(""""));

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
