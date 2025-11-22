using System.IO;

namespace Indexador.Core
{
    internal sealed record HashCandidate
    (
        string FullPath,
        string RelativePath,
        FileInfo Info,
        IndexRecord? Known
    );
}
