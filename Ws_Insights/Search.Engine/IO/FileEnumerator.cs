using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Enumerates files under a root path applying basic filters such as extension and size.
    /// This stub implementation walks the directory tree synchronously and yields file paths.
    /// </summary>
    public class FileEnumerator
    {
        public async IAsyncEnumerable<string> EnumerateAsync(string rootPath, IEnumerable<string> allowedExtensions)
        {
            foreach (var file in Directory.EnumerateFiles(rootPath, "*", SearchOption.AllDirectories))
            {
                yield return file;
                await Task.Yield();
            }
        }
    }
}