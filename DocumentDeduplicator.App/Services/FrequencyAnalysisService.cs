using System.Linq;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class FrequencyAnalysisService
{
    private readonly FileService _fileService;
    private readonly TextNormalizationService _normalizationService;

    public FrequencyAnalysisService(FileService fileService, TextNormalizationService normalizationService)
    {
        _fileService = fileService;
        _normalizationService = normalizationService;
    }

    public async Task<IReadOnlyList<WordFrequency>> ComputeWordFrequenciesAsync(IEnumerable<FileSelection> files, int top, ISet<string> stopwords, CancellationToken cancellationToken = default)
    {
        var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        var filePresence = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);
        foreach (var file in files)
        {
            var text = await _fileService.ReadAllTextAsync(file.Path, cancellationToken).ConfigureAwait(false);
            var tokens = _normalizationService.Tokenize(text, stopwords);
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var token in tokens)
            {
                if (!counts.TryAdd(token, 1))
                {
                    counts[token]++;
                }

                seen.Add(token);
            }

            filePresence[file.Path] = seen;
        }

        var frequencies = counts
            .OrderByDescending(kvp => kvp.Value)
            .ThenBy(kvp => kvp.Key, StringComparer.OrdinalIgnoreCase)
            .Take(top)
            .Select(kvp => new WordFrequency(kvp.Key, kvp.Value, filePresence.Count(entry => entry.Value.Contains(kvp.Key))))
            .ToList();

        return frequencies;
    }

    public async Task<IReadOnlyList<PhraseFrequency>> ComputePhraseFrequenciesAsync(IEnumerable<FileSelection> files, int nGramSize, int top, ISet<string> stopwords, CancellationToken cancellationToken = default)
    {
        var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        var filePresence = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);
        foreach (var file in files)
        {
            var text = await _fileService.ReadAllTextAsync(file.Path, cancellationToken).ConfigureAwait(false);
            var tokens = _normalizationService.Tokenize(text, stopwords);
            var ngrams = _normalizationService.BuildNGrams(tokens, nGramSize);
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var gram in ngrams)
            {
                if (!counts.TryAdd(gram, 1))
                {
                    counts[gram]++;
                }

                seen.Add(gram);
            }

            filePresence[file.Path] = seen;
        }

        var frequencies = counts
            .OrderByDescending(kvp => kvp.Value)
            .ThenBy(kvp => kvp.Key, StringComparer.OrdinalIgnoreCase)
            .Take(top)
            .Select(kvp => new PhraseFrequency(kvp.Key, kvp.Value, filePresence.Count(entry => entry.Value.Contains(kvp.Key))))
            .ToList();

        return frequencies;
    }
}
