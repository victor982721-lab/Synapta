using System.Collections.Concurrent;
using System.IO.Hashing;
using System.Linq;
using System.Text;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class ShingleAnalysisService
{
    private readonly FileService _fileService;
    private readonly TextNormalizationService _normalizationService;

    public ShingleAnalysisService(FileService fileService, TextNormalizationService normalizationService)
    {
        _fileService = fileService;
        _normalizationService = normalizationService;
    }

    public async Task<(IReadOnlyList<DuplicateBlock> Duplicates, IReadOnlyList<SimilarityResult> Similarities)> AnalyzeAsync(IEnumerable<FileSelection> files, int shingleSize, ISet<string> stopwords, CancellationToken cancellationToken = default)
    {
        var shingleOccurrences = new ConcurrentDictionary<string, List<(string file, string text)>>();
        var fileShingles = new ConcurrentDictionary<string, HashSet<string>>();
        foreach (var file in files)
        {
            var text = await _fileService.ReadAllTextAsync(file.Path, cancellationToken).ConfigureAwait(false);
            var tokens = _normalizationService.Tokenize(text, stopwords);
            if (tokens.Count < shingleSize)
            {
                continue;
            }

            var hashes = new HashSet<string>(StringComparer.Ordinal);
            for (var i = 0; i <= tokens.Count - shingleSize; i++)
            {
                var shingle = string.Join(' ', tokens.Skip(i).Take(shingleSize));
                var hash = Convert.ToHexString(XxHash64.Hash(Encoding.UTF8.GetBytes(shingle)));
                hashes.Add(hash);
                var list = shingleOccurrences.GetOrAdd(hash, _ => new List<(string file, string text)>());
                list.Add((file.Path, shingle));
            }

            fileShingles[file.Path] = hashes;
        }

        var duplicates = shingleOccurrences
            .Where(entry => entry.Value.Count > 1)
            .Select(entry =>
            {
                var filesList = entry.Value.Select(v => v.file).Distinct().ToList();
                return new DuplicateBlock(entry.Key, entry.Value[0].text, entry.Value.Count, filesList.Count, filesList);
            })
            .OrderByDescending(d => d.Frequency)
            .ToList();

        var similarities = new List<SimilarityResult>();
        var fileList = fileShingles.Keys.ToList();
        for (var i = 0; i < fileList.Count; i++)
        {
            for (var j = i + 1; j < fileList.Count; j++)
            {
                var setA = fileShingles[fileList[i]];
                var setB = fileShingles[fileList[j]];
                var intersection = setA.Intersect(setB).Count();
                var union = setA.Union(setB).Count();
                if (union == 0)
                {
                    continue;
                }

                var similarity = (double)intersection / union * 100d;
                similarities.Add(new SimilarityResult(fileList[i], fileList[j], Math.Round(similarity, 2)));
            }
        }

        return (duplicates, similarities);
    }
}
