using System.Collections.Generic;
using System.Linq;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Detects changes between file system snapshots.  This stub compares two snapshots and
    /// produces a simple change set consisting of added, modified and removed paths.
    /// </summary>
    public static class FileChangeDetector
    {
        public static FileChangeSet DetectChanges(FileSystemSnapshot oldSnapshot, FileSystemSnapshot newSnapshot)
        {
            var added = new List<string>();
            var modified = new List<string>();
            var removed = new List<string>();

            foreach (var kvp in newSnapshot.Files)
            {
                if (!oldSnapshot.Files.TryGetValue(kvp.Key, out var oldMetadata))
                {
                    added.Add(kvp.Key);
                }
                else if (kvp.Value.LastWriteTimeUtc != oldMetadata.LastWriteTimeUtc || kvp.Value.Length != oldMetadata.Length)
                {
                    modified.Add(kvp.Key);
                }
            }

            foreach (var key in oldSnapshot.Files.Keys.Except(newSnapshot.Files.Keys))
            {
                removed.Add(key);
            }

            return new FileChangeSet(added, modified, removed);
        }
    }

    /// <summary>
    /// Represents the set of changes detected between two snapshots.
    /// </summary>
    public class FileChangeSet
    {
        public IReadOnlyList<string> Added { get; }
        public IReadOnlyList<string> Modified { get; }
        public IReadOnlyList<string> Removed { get; }
        public FileChangeSet(IReadOnlyList<string> added, IReadOnlyList<string> modified, IReadOnlyList<string> removed)
        {
            Added = added;
            Modified = modified;
            Removed = removed;
        }
    }
}