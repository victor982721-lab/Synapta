namespace Ws_Insights.Models;

public sealed record FileMatch(string Name, string Extension, string FullPath, long SizeBytes, string Snippet)
{
    public string SizeKilobytes => $"{SizeBytes / 1024d:F2}";
}
