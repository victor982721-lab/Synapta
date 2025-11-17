using System.Collections.Generic;
using Ws_Insights.Utilities;

namespace Ws_Insights.Search;

/// <summary>
/// Represents the set of knobs exposed by the UI when launching a search operation.
/// The object is immutable once constructed via object initialisers so that it can be
/// safely shared with background tasks.
/// </summary>
public sealed class SearchOptions
{
    /// <summary>Gets the root directory that will be scanned.</summary>
    public string RootPath { get; init; } = string.Empty;

    /// <summary>Gets the raw query entered by the user.</summary>
    public string Query { get; init; } = string.Empty;

    /// <summary>Gets the list of extensions (with or without a leading dot) to include.</summary>
    public IReadOnlyList<string> Extensions { get; init; } = new List<string>();

    /// <summary>Gets a value indicating whether the match should be case sensitive.</summary>
    public bool CaseSensitive { get; init; }

    /// <summary>Gets a value indicating whether the query represents a regular expression.</summary>
    public bool UseRegex { get; init; }

    /// <summary>Gets a value indicating whether literal searches must match whole words.</summary>
    public bool WholeWord { get; init; }

    /// <summary>Gets a value indicating whether subfolders should be traversed.</summary>
    public bool IncludeSubfolders { get; init; } = true;

    /// <summary>Gets a value indicating whether hidden files are eligible.</summary>
    public bool IncludeHidden { get; init; }

    /// <summary>Gets a value indicating whether system files are eligible.</summary>
    public bool IncludeSystem { get; init; }

    /// <summary>Gets the maximum number of files processed concurrently.</summary>
    public int MaxDegreeOfParallelism { get; init; } = Environment.ProcessorCount;

    /// <summary>Gets the upper file size limit in bytes. Values less than or equal to zero disable the limit.</summary>
    public long? MaxFileSizeBytes { get; init; }

    /// <summary>Gets the lower file size limit in bytes. Values less than or equal to zero disable the limit.</summary>
    public long? MinFileSizeBytes { get; init; }

    /// <summary>Gets the cooperative pause token supplied by the UI.</summary>
    public PauseToken PauseToken { get; init; } = PauseToken.None;
}
