using System.Text;
using Neurologic.Sandbox.ProyectoEjemplo;
using Xunit;

namespace Neurologic.Sandbox.ProyectoEjemplo.Tests;

public class ProgramTests
{
    [Fact]
    public void Main_WritesIndexedEntry()
    {
        var output = new StringBuilder();
        using var writer = new StringWriter(output);
        Console.SetOut(writer);

        var exitCode = Program.Main(new[] { "C:/Data/demo.txt" });

        writer.Flush();
        Assert.Equal(0, exitCode);
        Assert.Contains("demo.txt", output.ToString());
    }
}
