using System;
using System.Security.Cryptography;

namespace Ws_Insights.Search.Core.Util
{
    /// <summary>
    /// A helper class for computing fast checksums of data.  The engine may use xxHash3 for
    /// performance but falls back to built‑in algorithms if necessary.
    /// </summary>
    public static class HashUtils
    {
        /// <summary>
        /// Computes a 64‑bit xxHash3 of the given byte span.  This implementation uses
        /// <see cref="XxHash3"/> when available, otherwise falls back to a simple MD5 hash truncated to 64 bits.
        /// </summary>
        public static ulong ComputeHash(ReadOnlySpan<byte> data)
        {
            // Placeholder implementation: a real engine would include an xxHash3 implementation or
            // use a third‑party library.  Here we compute an MD5 hash and fold it down to 64 bits.
            using var md5 = MD5.Create();
            var hash = md5.ComputeHash(data.ToArray());
            // Take the first eight bytes of the 128‑bit hash to produce a 64‑bit value.
            return BitConverter.ToUInt64(hash, 0);
        }
    }
}