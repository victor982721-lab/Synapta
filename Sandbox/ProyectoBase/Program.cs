using System;
using ProyectoBase.CLI;
using ProyectoBase.Wizard;

namespace ProyectoBase
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                WizardRunner.Run();
                return;
            }

            if (args.Length == 1 && args[0].Equals("--wizard", StringComparison.OrdinalIgnoreCase))
            {
                WizardRunner.Run();
                return;
            }

            CLIHandler.Run(args);
        }
    }
}
