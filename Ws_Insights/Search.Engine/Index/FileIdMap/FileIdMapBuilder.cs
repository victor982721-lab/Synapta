using System.Collections.Generic;

namespace Ws_Insights.Search.Index.FileIdMap
{
    /// <summary>
    /// Builds a mapping from paths to <see cref="FileId"/> instances.  A real implementation
    /// would query the file system for file indices and other metadata.  This stub assigns
    /// new identifiers for every path.
    /// </summary>
    public class FileIdMapBuilder
    {
        private readonly Dictionary<string, FileId> _map = new();

        public FileId GetOrAdd(string path)
        {
            if (!_map.TryGetValue(path, out var id))
            {
                id = FileId.NewId();
                _map[path] = id;
            }
            return id;
        }
    }
}