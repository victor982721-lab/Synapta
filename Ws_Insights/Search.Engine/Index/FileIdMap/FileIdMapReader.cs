using System.Collections.Generic;

namespace Ws_Insights.Search.Index.FileIdMap
{
    /// <summary>
    /// Reads the mapping from paths to file identifiers from disk.  In a real implementation
    /// this class would load persisted state.  Here it wraps an in-memory dictionary provided
    /// at construction time.
    /// </summary>
    public class FileIdMapReader
    {
        private readonly IReadOnlyDictionary<string, FileId> _map;

        public FileIdMapReader(IReadOnlyDictionary<string, FileId> map)
        {
            _map = map;
        }

        public bool TryGetId(string path, out FileId id) => _map.TryGetValue(path, out id);
    }
}