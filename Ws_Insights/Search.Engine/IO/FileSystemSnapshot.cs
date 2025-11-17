using System.Collections.Generic;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Represents a snapshot of the file system at a point in time.  It maps file paths to
    /// metadata (size, timestamps).  Snapshots can be compared to detect changes.
    /// </summary>
    public class FileSystemSnapshot
    {
        public IReadOnlyDictionary<string, FileMetadata> Files { get; }

        public FileSystemSnapshot(IReadOnlyDictionary<string, FileMetadata> files)
        {
            Files = files;
        }
    }
}