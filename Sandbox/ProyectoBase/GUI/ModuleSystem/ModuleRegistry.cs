using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;

namespace ProyectoBase.GUI.ModuleSystem
{
    public static class ModuleRegistry
    {
        private static readonly List<ModuleDescriptor> _modules = new List<ModuleDescriptor>();

        static ModuleRegistry()
        {
            RegisterBuiltIn();
            AutoScanTools();
        }

        private static void RegisterBuiltIn()
        {
            _modules.Add(new ModuleDescriptor
            {
                Id = ""Home"",
                Name = ""Inicio"",
                Factory = () => new ProyectoBase.GUI.Views.HomeView()
            });

            _modules.Add(new ModuleDescriptor
            {
                Id = ""Config"",
                Name = ""Configuración"",
                Factory = () => new ProyectoBase.GUI.Views.ConfigView()
            });
        }

        // ========== AUTO-SCAN ==========
        private static void AutoScanTools()
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;

            string toolPath = Path.Combine(baseDir, ""GUI"", ""Views"", ""Tools"");

            if (!Directory.Exists(toolPath))
                return;

            // Buscar TODAS las clases que terminen en *ToolView
            var viewTypes = Assembly.GetExecutingAssembly()
                .GetTypes()
                .Where(t => t.FullName != null &&
                           t.FullName.Contains(""Views.Tools"") &&
                           t.Name.EndsWith(""ToolView""));

            foreach (var type in viewTypes)
            {
                string id = type.Name.Replace(""ToolView"", """");

                string name = SplitCamelCase(id);

                _modules.Add(new ModuleDescriptor
                {
                    Id = id,
                    Name = name,
                    Factory = () => Activator.CreateInstance(type)
                });
            }
        }

        private static string SplitCamelCase(string input)
        {
            return string.Concat(input.Select((x, i) =>
                i > 0 && char.IsUpper(x) ? "" "" + x : x.ToString()
            ));
        }

        public static List<ModuleDescriptor> GetAll() => _modules;

        public static ModuleDescriptor? Get(string id)
        {
            return _modules.FirstOrDefault(x => x.Id.Equals(id, StringComparison.OrdinalIgnoreCase));
        }
    }
}
