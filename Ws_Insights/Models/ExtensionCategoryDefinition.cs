namespace Ws_Insights.Models;

public sealed record ExtensionCategoryDefinition(string Name, string Description, IReadOnlyList<string> Extensions);
