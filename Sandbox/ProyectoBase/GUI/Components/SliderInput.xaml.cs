using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class SliderInput : UserControl
    {
        public SliderInput()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty LabelProperty =
            DependencyProperty.Register(""Label"", typeof(string), typeof(SliderInput), new PropertyMetadata(""""));

        public static readonly DependencyProperty ValueProperty =
            DependencyProperty.Register(""Value"", typeof(double), typeof(SliderInput), new PropertyMetadata(0.0));

        public static readonly DependencyProperty MinProperty =
            DependencyProperty.Register(""Min"", typeof(double), typeof(SliderInput), new PropertyMetadata(0.0));

        public static readonly DependencyProperty MaxProperty =
            DependencyProperty.Register(""Max"", typeof(double), typeof(SliderInput), new PropertyMetadata(100.0));

        public string Label
        {
            get => (string)GetValue(LabelProperty);
            set => SetValue(LabelProperty, value);
        }

        public double Value
        {
            get => (double)GetValue(ValueProperty);
            set => SetValue(ValueProperty, value);
        }

        public double Min
        {
            get => (double)GetValue(MinProperty);
            set => SetValue(MinProperty, value);
        }

        public double Max
        {
            get => (double)GetValue(MaxProperty);
            set => SetValue(MaxProperty, value);
        }
    }
}
