using System;

namespace ProyectoBase.GUI.ModuleSystem
{
    public class ModuleDescriptor
    {
        public string Id { get; set; } = """";
        public string Name { get; set; } = """";
        public Func<object> Factory { get; set; }
    }
}
