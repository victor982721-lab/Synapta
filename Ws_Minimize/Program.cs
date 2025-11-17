using System;

namespace Deduplinside;

public static class Program
{
    [STAThread]
    public static void Main(string[] args)
    {
        var application = new App();
        application.InitializeComponent();
        application.Run();
    }
}
