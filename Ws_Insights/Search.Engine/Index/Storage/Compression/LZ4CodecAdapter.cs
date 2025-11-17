namespace Ws_Insights.Search.Index.Storage.Compression
{
    /// <summary>
    /// Adapts a third‑party LZ4 implementation to a simple interface used by the engine.  In a real
    /// implementation this class would P/Invoke a native library or use a managed LZ4 codec.  The
    /// methods below simply return the input unchanged.
    /// </summary>
    public static class LZ4CodecAdapter
    {
        public static byte[] Compress(byte[] data) => data;
        public static byte[] Decompress(byte[] data, int uncompressedLength) => data;
    }
}