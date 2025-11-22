using System;
using System.IO;

namespace Indexador.Core
{
    internal static class PathTools
    {
        public static string NormalizePath(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                throw new ArgumentException("La ruta no puede estar vacía.", nameof(path));

            return Path.GetFullPath(path)
                .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
    }
}
