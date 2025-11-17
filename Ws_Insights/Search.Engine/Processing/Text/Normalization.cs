using System.Globalization;
using System.Text;

namespace Ws_Insights.Search.Processing.Text
{
    /// <summary>
    /// Provides helper methods for normalising text by removing accents, converting case, etc.  The
    /// stub implementation exposes a single method that performs basic normalisation.
    /// </summary>
    public static class Normalization
    {
        public static string Normalize(string input, bool caseSensitive)
        {
            if (string.IsNullOrEmpty(input))
                return input;

            string normalised = input.Normalize(NormalizationForm.FormD);
            var builder = new StringBuilder(normalised.Length);
            foreach (var ch in normalised)
            {
                var category = CharUnicodeInfo.GetUnicodeCategory(ch);
                if (category != UnicodeCategory.NonSpacingMark)
                {
                    builder.Append(ch);
                }
            }
            var result = builder.ToString().Normalize(NormalizationForm.FormC);
            return caseSensitive ? result : result.ToLowerInvariant();
        }
    }
}