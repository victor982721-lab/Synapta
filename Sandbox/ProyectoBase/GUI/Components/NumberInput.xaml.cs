using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace ProyectoBase.GUI.Components
{
    public partial class NumberInput : UserControl
    {
        public NumberInput()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty LabelProperty =
            DependencyProperty.Register(""Label"", typeof(string), typeof(NumberInput), new PropertyMetadata(""""));

        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(""Value"", typeof(string), typeof(NumberInput), new PropertyMetadata(""0""));

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

        private void NumberOnly(object sender, TextCompositionEventArgs e)
        {
            e.Handled = !Regex.IsMatch(e.Text, ""^[0-9]+$"");
        }
    }
}
