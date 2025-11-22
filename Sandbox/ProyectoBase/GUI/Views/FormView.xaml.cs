using System.Collections.Generic;
using System.Windows.Controls;
using ProyectoBase.GUI.FormEngine;

namespace ProyectoBase.GUI.Views
{
    public partial class FormView : UserControl
    {
        public FormView()
        {
            InitializeComponent();

            // Ejemplo inicial (puede cambiarse dinámicamente luego)
            var form = new List<FormField>
            {
                new FormField { Type = ""text"", Label = ""Nombre"" },
                new FormField { Type = ""number"", Label = ""Edad"", Default = ""25"" },
                new FormField { Type = ""toggle"", Label = ""Activo"", BoolDefault = true },
                new FormField { Type = ""combo"", Label = ""Rol"", Items = new List<string> {""Admin"",""User"",""Guest""} },
                
                new FormField
                {
                    Type = ""section"",
                    Label = ""Preferencias"",
                    SubFields = new List<FormField>
                    {
                        new FormField { Type = ""slider"", Label = ""Volumen"", Min = 0, Max = 100, DoubleDefault = 50 },
                        new FormField { Type = ""multiline"", Label = ""Notas"" }
                    }
                }
            };

            FormHost.Content = FormBuilder.BuildForm(form);
        }
    }
}
