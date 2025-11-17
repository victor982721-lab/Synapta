namespace Ws_Insights.Search.Index.Storage
{
    /// <summary>
    /// Defines the logical layout of files that comprise a segment on disk.  The constants
    /// specified here are used by the writer and reader to locate metadata, postings and
    /// other information.  Adjusting these values will require versioning of segments.
    /// </summary>
    public static class SegmentFileLayout
    {
        public const string SegmentInfoFileName = "segment-info.bin";
        public const string TokenDictionaryFileName = "tokens.bin";
        public const string PostingsFileName = "postings.bin";
        public const string PathsFileName = "paths.bin";
        public const string StoredFieldsFileName = "stored.bin";
        public const string MetadataFileName = "meta.bin";
        public const string BloomFileName = "bloom.bin";
    }
}