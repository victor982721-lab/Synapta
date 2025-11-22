using System.IO;

namespace Indexador.Core
{
    public sealed class Crc32HashProvider : IHashProvider
    {
        private static readonly uint[] Table = GenerateTable();

        public string AlgorithmName => "CRC32";

        public string ComputeHash(Stream stream)
        {
            stream.Position = 0;
            uint crc = 0xFFFFFFFF;
            Span<byte> buffer = stackalloc byte[8192];

            int read;
            while ((read = stream.Read(buffer)) > 0)
            {
                for (var i = 0; i < read; i++)
                {
                    crc = (crc >> 8) ^ Table[(crc ^ buffer[i]) & 0xFF];
                }
            }

            crc ^= 0xFFFFFFFF;
            return crc.ToString("X8");
        }

        private static uint[] GenerateTable()
        {
            const uint poly = 0xEDB88320u;
            var table = new uint[256];

            for (uint i = 0; i < 256; i++)
            {
                var entry = i;
                for (var j = 0; j < 8; j++)
                {
                    entry = (entry & 1) != 0 ? (entry >> 1) ^ poly : entry >> 1;
                }

                table[i] = entry;
            }

            return table;
        }
    }
}
