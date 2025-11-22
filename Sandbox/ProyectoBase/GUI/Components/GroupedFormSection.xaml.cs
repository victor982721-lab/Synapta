using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.Components
{
    public partial class GroupedFormSection : UserControl
    {
        public GroupedFormSection()
        {
            InitializeComponent();
        }

        public static readonly DependencyProperty TitleProperty =
            DependencyProperty.Register(""Title"", typeof(string), typeof(GroupedFormSection), new PropertyMetadata(""Sección""));

        public string Title
        {
            get => (string)GetValue(TitleProperty);
            set => SetValue(TitleProperty, value);
        }
    }
}
