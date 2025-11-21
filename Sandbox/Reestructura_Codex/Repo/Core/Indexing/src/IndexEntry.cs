namespace Neurologic.Core.Indexing;

/// <summary>
/// Representa una entrada mínima en el índice de archivos.
/// </summary>
public record IndexEntry(string Path, long SizeBytes, DateTime LastModifiedUtc);
