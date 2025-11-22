using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class SectionHeader : UserControl
    {
        public SectionHeader()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty TextProperty =
            DependencyProperty.Register("Text", typeof(string), typeof(SectionHeader), new PropertyMetadata(""));

        public string Text
        {
            get => (string)GetValue(TextProperty);
            set => SetValue(TextProperty, value);
        }
    }
}
