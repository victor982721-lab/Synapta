using Neurologic.Core.FileSystem;
using Xunit;

namespace Neurologic.Core.FileSystem.Tests;

public class FileSystemServiceTests
{
    [Theory]
    [InlineData("C:/Temp/", "C:/Temp")]
    [InlineData("C\\Temp\\folder", "C/Temp/folder")]
    public void NormalizePath_StandardizesSeparators(string input, string expected)
    {
        var result = FileSystemService.NormalizePath(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void NormalizePath_Empty_Throws()
    {
        Assert.Throws<ArgumentException>(() => FileSystemService.NormalizePath(" "));
    }
}
