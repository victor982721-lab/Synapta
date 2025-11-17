using System;
using System.IO;

namespace Ws_Insights.Search.Core.Util
{
    /// <summary>
    /// Provides helpers for normalizing file system paths.  All paths used by the engine should be passed
    /// through this utility before being stored or compared to ensure consistent casing and separators.
    /// </summary>
    public static class PathNormalizer
    {
        /// <summary>
        /// Normalizes the specified path by trimming whitespace, expanding environment variables,
        /// resolving relative segments and converting directory separators to the platform default.
        /// </summary>
        /// <param name="path">The path to normalize.</param>
        /// <returns>A normalized, absolute path.</returns>
        public static string Normalize(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                throw new ArgumentException("Path must not be null or whitespace", nameof(path));

            var expanded = Environment.ExpandEnvironmentVariables(path.Trim());
            string fullPath = Path.GetFullPath(expanded);
            return fullPath.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}