using System.IO;
using System.Threading.Tasks;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Provides a simplified abstraction over memory mapped file loading.  A memory mapped view
    /// avoids copying the file contents into managed memory.  In this stub implementation the
    /// file is read into a byte array.
    /// </summary>
    public static class MemoryMappedLoader
    {
        public static Task<byte[]> LoadAsync(string path)
        {
            // TODO: use MemoryMappedFile.CreateFromFile for zero-copy reads
            return Task.FromResult(File.ReadAllBytes(path));
        }
    }
}