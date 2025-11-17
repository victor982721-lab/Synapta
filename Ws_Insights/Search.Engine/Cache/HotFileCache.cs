using System.Threading.Tasks;
using Ws_Insights.Search.IO;

namespace Ws_Insights.Search.Cache
{
    /// <summary>
    /// Caches the contents of recently accessed files in memory to avoid repeated disk reads.  The
    /// cache is keyed by file path and stores the raw bytes.  This stub uses <see cref="LruCache{TKey, TValue}"/>
    /// internally and reads file data via <see cref="MemoryMappedLoader"/>.
    /// </summary>
    public class HotFileCache
    {
        private readonly LruCache<string, byte[]> _cache;

        public HotFileCache(int capacity = 128)
        {
            _cache = new LruCache<string, byte[]>(capacity);
        }

        public async Task<byte[]> GetOrAddAsync(string path)
        {
            if (_cache.TryGet(path, out var data))
            {
                return data;
            }
            data = await MemoryMappedLoader.LoadAsync(path);
            _cache.Put(path, data);
            return data;
        }
    }
}