using System;

namespace Ws_Insights.Search.Index.FileIdMap
{
    /// <summary>
    /// Represents a stable identifier for a file independent of its path.  On Windows this might
    /// be composed of the file index, size and timestamps.  The engine uses file identifiers to
    /// detect renamed or moved files.
    /// </summary>
    public readonly record struct FileId(Guid Value)
    {
        public static FileId NewId() => new FileId(Guid.NewGuid());
        public override string ToString() => Value.ToString("N");
    }
}