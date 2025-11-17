using System;
using System.IO;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// Reads file system metadata for a given path.  Metadata includes file size and timestamps.
    /// </summary>
    public static class FileMetadataReader
    {
        public static FileMetadata Read(string path)
        {
            var info = new FileInfo(path);
            return new FileMetadata
            {
                Path = path,
                Length = info.Length,
                CreationTimeUtc = info.CreationTimeUtc,
                LastWriteTimeUtc = info.LastWriteTimeUtc
            };
        }
    }

    /// <summary>
    /// Represents metadata about a file on disk.
    /// </summary>
    public class FileMetadata
    {
        public string Path { get; set; } = string.Empty;
        public long Length { get; set; }
        public DateTime CreationTimeUtc { get; set; }
        public DateTime LastWriteTimeUtc { get; set; }
    }
}