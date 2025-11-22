using System;
using System.Collections.Generic;

namespace ProyectoBase.GUI.FormEngine
{
    public class FormField
    {
        public string Type { get; set; } = ""text"";  
        public string Label { get; set; } = """";        
        public string Default { get; set; } = """";      
        public bool BoolDefault { get; set; } = false;  
        public List<FormField>? SubFields { get; set; }  

        // Nuevos extras
        public string Placeholder { get; set; } = """";
        public string HelpText { get; set; } = """";

        // Validación
        public Func<string, bool>? Validation { get; set; }

        // Eventos declarativos
        public Action<string>? OnChange { get; set; }
        public Action<Dictionary<string,string>>? OnSubmit { get; set; }
    }
}
