using System;

namespace Indexador.Core
{
    public static class HashProviderFactory
    {
        public static IHashProvider Create(string algorithm)
        {
            return (algorithm ?? string.Empty).Trim().ToUpperInvariant() switch
            {
                "SHA256" => new SHA256HashProvider(),
                "CRC32" => new Crc32HashProvider(),
                _ => throw new NotSupportedException($"El algoritmo '{algorithm}' no está soportado.")
            };
        }
    }
}
