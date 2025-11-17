using System;

namespace Ws_Insights.Search.Index.Segment
{
    /// <summary>
    /// Uniquely identifies a segment within the index.  Segments are immutable and self-contained.
    /// A <see cref="SegmentId"/> typically encodes a timestamp or sequence number but this class
    /// treats the identifier as opaque.
    /// </summary>
    public readonly record struct SegmentId(Guid Value)
    {
        public static SegmentId NewId() => new SegmentId(Guid.NewGuid());
        public override string ToString() => Value.ToString("N");
    }
}