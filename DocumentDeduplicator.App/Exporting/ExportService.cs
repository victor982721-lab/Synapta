using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Exporting;

public record ExportContent(
    IReadOnlyCollection<WordFrequency> Words,
    IReadOnlyCollection<PhraseFrequency> Phrases,
    IReadOnlyCollection<DuplicateBlock> Duplicates,
    IReadOnlyCollection<DeduplicationPreview> Deduplication,
    IReadOnlyCollection<SummarySentence> Summary,
    IReadOnlyCollection<NoteItem> Notes);

public class ExportService
{
    public async Task ExportAsync(string folderPath, ExportContent content, CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(folderPath);
        var jsonPath = Path.Combine(folderPath, "analisis.json");
        await using (var stream = new FileStream(jsonPath, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            await JsonSerializer.SerializeAsync(stream, content, new JsonSerializerOptions { WriteIndented = true }, cancellationToken).ConfigureAwait(false);
        }

        await File.WriteAllTextAsync(Path.Combine(folderPath, "palabras.csv"), BuildCsv(content.Words, "Palabra,Frecuencia,Archivos"), cancellationToken).ConfigureAwait(false);
        await File.WriteAllTextAsync(Path.Combine(folderPath, "frases.csv"), BuildCsv(content.Phrases, "Frase,Frecuencia,Archivos"), cancellationToken).ConfigureAwait(false);
        await File.WriteAllTextAsync(Path.Combine(folderPath, "duplicados.csv"), BuildCsv(content.Duplicates, "Hash,Texto,Frecuencia,Archivos"), cancellationToken).ConfigureAwait(false);
        await File.WriteAllTextAsync(Path.Combine(folderPath, "deduplicacion.csv"), BuildCsv(content.Deduplication, "Etiqueta,Archivos,Veces"), cancellationToken).ConfigureAwait(false);
        await File.WriteAllTextAsync(Path.Combine(folderPath, "resumen.csv"), BuildCsv(content.Summary, "Oracion,Puntuacion,Orden"), cancellationToken).ConfigureAwait(false);
        await File.WriteAllTextAsync(Path.Combine(folderPath, "notas.csv"), BuildCsv(content.Notes, "Titulo,Fecha,Archivos"), cancellationToken).ConfigureAwait(false);
    }

    private static string BuildCsv<T>(IEnumerable<T> items, string header)
    {
        var builder = new StringBuilder();
        builder.AppendLine(header);
        foreach (var item in items)
        {
            builder.AppendLine(EscapeRow(item));
        }

        return builder.ToString();
    }

    private static string EscapeRow<T>(T item)
    {
        var values = new List<string>();
        switch (item)
        {
            case WordFrequency word:
                values.Add(word.Word);
                values.Add(word.Count.ToString());
                values.Add(word.FileCount.ToString());
                break;
            case PhraseFrequency phrase:
                values.Add(phrase.Phrase);
                values.Add(phrase.Count.ToString());
                values.Add(phrase.FileCount.ToString());
                break;
            case DuplicateBlock duplicate:
                values.Add(duplicate.Hash);
                values.Add(duplicate.Text);
                values.Add(duplicate.Frequency.ToString());
                values.Add(string.Join(' ', duplicate.Files));
                break;
            case DeduplicationPreview preview:
                values.Add(preview.Label);
                values.Add(string.Join(' ', preview.Files));
                values.Add(preview.Occurrences.ToString());
                break;
            case SummarySentence sentence:
                values.Add(sentence.Text);
                values.Add(sentence.Score.ToString());
                values.Add(sentence.Order.ToString());
                break;
            case NoteItem note:
                values.Add(note.Title);
                values.Add(note.UpdatedAt.ToString("u"));
                values.Add(note.RelatedFiles ?? string.Empty);
                break;
            default:
                values.Add(item?.ToString() ?? string.Empty);
                break;
        }

        return string.Join(',', values.Select(EscapeCsv));
    }

    private static string EscapeCsv(string value)
    {
        if (value.Contains('"') || value.Contains(','))
        {
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }

        return value;
    }
}
