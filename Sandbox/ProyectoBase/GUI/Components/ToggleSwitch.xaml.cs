using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class ToggleSwitch : UserControl
    {
        public ToggleSwitch()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty LabelProperty =
            DependencyProperty.Register(""Label"", typeof(string), typeof(ToggleSwitch), new PropertyMetadata(""""));

        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(""Value"", typeof(bool), typeof(ToggleSwitch), new PropertyMetadata(false));

        public string Label
        {
            get => (string)GetValue(LabelProperty);
            set => SetValue(LabelProperty, value);
        }

        public bool Value
        {
            get => (bool)GetValue(ValueProperty);
            set => SetValue(ValueProperty, value);
        }
    }
}
