using System.IO;

namespace Indexador.Core
{
    public interface IHashProvider
    {
        string AlgorithmName { get; }

        string ComputeHash(Stream stream);
    }
}
