using System;
using System.IO;
using System.Security.Cryptography;

namespace Indexador.Core
{
    public sealed class SHA256HashProvider : IHashProvider
    {
        public string AlgorithmName => "SHA256";

        public string ComputeHash(Stream stream)
        {
            if (stream == null)
                throw new ArgumentNullException(nameof(stream));

            stream.Position = 0;
            using var sha256 = SHA256.Create();
            var hash = sha256.ComputeHash(stream);
            return Convert.ToHexString(hash);
        }
    }
}
