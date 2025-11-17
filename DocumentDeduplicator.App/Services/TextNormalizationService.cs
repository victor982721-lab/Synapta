using System.Text.RegularExpressions;

namespace DocumentDeduplicator.Services;

public class TextNormalizationService
{
    private static readonly Regex WordRegex = new("[A-Za-zÀ-ÿ0-9']+", RegexOptions.Compiled);

    public IReadOnlyList<string> Tokenize(string text, ISet<string> stopwords)
    {
        var tokens = new List<string>();
        foreach (Match match in WordRegex.Matches(text.ToLowerInvariant()))
        {
            var word = match.Value;
            if (stopwords.Contains(word))
            {
                continue;
            }

            tokens.Add(word);
        }

        return tokens;
    }

    public IReadOnlyList<string> BuildNGrams(IReadOnlyList<string> tokens, int size)
    {
        var grams = new List<string>();
        if (size <= 1)
        {
            return grams;
        }

        for (var i = 0; i <= tokens.Count - size; i++)
        {
            grams.Add(string.Join(' ', tokens.Skip(i).Take(size)));
        }

        return grams;
    }
}
