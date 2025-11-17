using System.Linq;
using System.Text;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class SummaryService
{
    private readonly FileService _fileService;
    private readonly TextNormalizationService _normalizationService;

    public SummaryService(FileService fileService, TextNormalizationService normalizationService)
    {
        _fileService = fileService;
        _normalizationService = normalizationService;
    }

    public async Task<IReadOnlyList<SummarySentence>> BuildSummaryAsync(IEnumerable<FileSelection> files, int maxSentences, ISet<string> stopwords, IEnumerable<PhraseFrequency>? highPhrases, CancellationToken cancellationToken = default)
    {
        var builder = new StringBuilder();
        foreach (var file in files)
        {
            var text = await _fileService.ReadAllTextAsync(file.Path, cancellationToken).ConfigureAwait(false);
            builder.AppendLine(text);
        }

        var aggregated = builder.ToString();
        if (string.IsNullOrWhiteSpace(aggregated))
        {
            return Array.Empty<SummarySentence>();
        }

        var tokens = _normalizationService.Tokenize(aggregated, stopwords);
        var frequencies = tokens.GroupBy(t => t).ToDictionary(g => g.Key, g => g.Count(), StringComparer.OrdinalIgnoreCase);
        var sentences = SplitSentences(aggregated);
        var sentenceScores = new List<SummarySentence>();
        for (var index = 0; index < sentences.Count; index++)
        {
            var sentence = sentences[index];
            var sentenceTokens = _normalizationService.Tokenize(sentence, stopwords);
            if (sentenceTokens.Count == 0)
            {
                continue;
            }

            double score = sentenceTokens.Sum(token => frequencies.TryGetValue(token, out var value) ? value : 0);
            if (highPhrases is not null)
            {
                foreach (var phrase in highPhrases)
                {
                    if (phrase.Count == 0)
                    {
                        continue;
                    }

                    if (sentence.Contains(phrase.Phrase, StringComparison.OrdinalIgnoreCase))
                    {
                        score += phrase.Count;
                    }
                }
            }

            var positionWeight = 1d + (double)(sentences.Count - index) / sentences.Count;
            score *= positionWeight;
            sentenceScores.Add(new SummarySentence(sentence.Trim(), Math.Round(score, 2, MidpointRounding.AwayFromZero), index));
        }

        return sentenceScores
            .OrderByDescending(s => s.Score)
            .ThenBy(s => s.Order)
            .Take(maxSentences)
            .OrderBy(s => s.Order)
            .ToList();
    }

    private static List<string> SplitSentences(string text)
    {
        var sentences = new List<string>();
        var current = new StringBuilder();
        foreach (var c in text)
        {
            current.Append(c);
            if (c is '.' or '!' or '?')
            {
                var sentence = current.ToString().Trim();
                if (!string.IsNullOrWhiteSpace(sentence))
                {
                    sentences.Add(sentence);
                }

                current.Clear();
            }
        }

        var remaining = current.ToString().Trim();
        if (!string.IsNullOrWhiteSpace(remaining))
        {
            sentences.Add(remaining);
        }

        return sentences;
    }
}
