namespace Neurologic.Core.FileSystem;

/// <summary>
/// Utilidades mínimas para operaciones de sistema de archivos.
/// </summary>
public static class FileSystemService
{
    /// <summary>
    /// Normaliza una ruta usando separadores de directorio estándar.
    /// </summary>
    public static string NormalizePath(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new ArgumentException("La ruta no puede estar vacía", nameof(path));
        }

        return path.Replace('\\', '/').TrimEnd('/');
    }
}
