using System.Collections.Generic;
using System.Windows.Controls;
using ProyectoBase.GUI.FormEngine;
using ProyectoBase.GUI.Components;

namespace ProyectoBase.GUI.Views.Tools.Search
{
    public partial class SearchToolView : UserControl
    {
        private SearchToolViewModel ViewModel;

        public SearchToolView()
        {
            InitializeComponent();
            ViewModel = new SearchToolViewModel(UpdateResults);
            LoadForm();
        }

        private void LoadForm()
        {
            var form = new List<FormField>
            {
                new FormField { Type = ""text"", Label = ""Ruta"", Default = ""C:\\" },
                new FormField { Type = ""text"", Label = ""Patrón Regex"", Default = ""CB blindado"" },
                new FormField { Type = ""toggle"", Label = ""Buscar en subcarpetas"", BoolDefault = true },
                new FormField { Type = ""toggle"", Label = ""Distinguir mayúsculas"", BoolDefault = false },
                new FormField { Type = ""number"", Label = ""Máximo de resultados"", Default = ""200"" },
                new FormField { Type = ""text"", Label = ""Extensiones (coma separadas)"", Default = ""txt,log"" },

                new FormField
                {
                    Type = ""section"",
                    Label = ""Acciones"",
                    SubFields = new List<FormField>
                    {
                        new FormField { Type = ""text"", Label = ""Ejecutar Búsqueda (click en botón)"" }
                    }
                }
            };

            FormHost.Content = FormBuilder.BuildForm(form);

            var button = new Button
            {
                Content = ""Ejecutar búsqueda"",
                Margin = new System.Windows.Thickness(0, 10, 0, 0),
                Padding = new System.Windows.Thickness(12),
                Background = System.Windows.Media.Brushes.SteelBlue,
                Foreground = System.Windows.Media.Brushes.White
            };

            button.Click += (s, e) =>
            {
                var values = FormBuilderInspector.ReadFormValues(FormHost.Content);
                ViewModel.Execute(values);
            };

            (FormHost.Content as Panel).Children.Add(button);
        }

        private void UpdateResults(List<string> results)
        {
            ResultsHost.Children.Clear();

            foreach (var r in results)
            {
                ResultsHost.Children.Add(
                    new TextBlock
                    {
                        Text = r,
                        Style = (System.Windows.Style)FindResource("BodyText")
                    }
                );
            }
        }
    }
}
