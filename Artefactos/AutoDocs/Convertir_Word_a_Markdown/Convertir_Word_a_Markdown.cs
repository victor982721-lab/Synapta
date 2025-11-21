using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

internal static class Program
{
    private static int Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.WriteLine("Uso: dotnet run -- archivo.docx [salida.md]");
            return 1;
        }

        var docxPath = args[0];
        if (!File.Exists(docxPath))
        {
            Console.WriteLine($"No se encontró el archivo: {docxPath}");
            return 1;
        }

        string mdPath = args.Length >= 2
            ? args[1]
            : Path.ChangeExtension(docxPath, ".md");

        var lines = MarkdownConverter.Convert(docxPath);
        File.WriteAllLines(mdPath, lines, new UTF8Encoding(false));

        Console.WriteLine($"Markdown generado: {mdPath}");
        return 0;
    }
}

internal static class MarkdownConverter
{
    private static readonly Regex BeneficioRegex =
        new(@"^[A-ZÁÉÍÓÚÑ][^:]{1,80}:", RegexOptions.Compiled);

    private static readonly Regex CitationClusterRegex =
        new(@"\[\d+\](?:\s*\[\d+\]){1,}", RegexOptions.Compiled);

    public static List<string> Convert(string docxPath)
    {
        using var doc = WordprocessingDocument.Open(docxPath, false);
        var body = doc.MainDocumentPart!.Document.Body!;

        var lines = new List<string>();

        foreach (var child in body.ChildElements)
        {
            if (child is Paragraph p)
            {
                var line = ParagraphToMarkdown(p, doc);
                if (!string.IsNullOrWhiteSpace(line))
                {
                    lines.Add(line);
                    lines.Add(string.Empty);
                }
            }
            else if (child is Table t)
            {
                var tableLines = TableToMarkdown(t);
                if (tableLines.Count > 0)
                {
                    lines.AddRange(tableLines);
                    lines.Add(string.Empty);
                    lines.Add(string.Empty);
                }
            }
        }

        lines = PostProcess(lines);
        return lines;
    }

    private static string ParagraphToMarkdown(Paragraph p, WordprocessingDocument doc)
    {
        var text = GetParagraphText(p).Trim();
        if (string.IsNullOrEmpty(text))
            return string.Empty;

        var styleName = (GetParagraphStyleName(p, doc) ?? string.Empty)
            .ToLowerInvariant();

        // Encabezados
        if (styleName.Contains("heading"))
        {
            int level = 1;
            for (int n = 1; n <= 6; n++)
            {
                if (styleName.Contains(n.ToString(), StringComparison.Ordinal))
                {
                    level = n;
                    break;
                }
            }

            return new string('#', level) + " " + text;
        }

        if (styleName.Contains("title"))
        {
            return "# " + text;
        }

        // Listas (simple por estilo)
        if (styleName.Contains("list") ||
            styleName.Contains("bullet") ||
            styleName.Contains("number"))
        {
            return "* " + text;
        }

        // Párrafo normal
        return text;
    }

    private static string GetParagraphText(Paragraph p)
    {
        var sb = new StringBuilder();
        foreach (var run in p.Descendants<Run>())
        {
            foreach (var t in run.Descendants<Text>())
            {
                sb.Append(t.Text);
            }
        }

        return sb.ToString();
    }

    private static string? GetParagraphStyleName(Paragraph p, WordprocessingDocument doc)
    {
        var styleId = p.ParagraphProperties?.ParagraphStyleId?.Val;
        if (styleId is null)
            return null;

        var stylesPart = doc.MainDocumentPart!.StyleDefinitionsPart;
        if (stylesPart is null)
            return styleId;

        var styles = stylesPart.Styles;
        if (styles is null)
            return styleId;

        var style = styles.Elements<Style>()
            .FirstOrDefault(s => s.StyleId == styleId);

        return style?.StyleName?.Val ?? styleId;
    }

    private static List<string> TableToMarkdown(Table table)
    {
        var rows = table.Elements<TableRow>().ToList();
        if (rows.Count == 0)
            return new List<string>();

        static string CellText(TableCell c)
        {
            var sb = new StringBuilder();
            foreach (var t in c.Descendants<Text>())
            {
                sb.Append(t.Text);
            }
            return sb.ToString().Replace('\n', ' ').Replace('\r', ' ').Trim();
        }

        var headerCells = rows[0].Elements<TableCell>().Select(CellText).ToList();
        var lines = new List<string>();

        // Encabezado
        lines.Add("| " + string.Join(" | ", headerCells) + " |");
        lines.Add("| " + string.Join(" | ", headerCells.Select(_ => "---")) + " |");

        // Filas
        foreach (var row in rows.Skip(1))
        {
            var cells = row.Elements<TableCell>().Select(CellText).ToList();
            lines.Add("| " + string.Join(" | ", cells) + " |");
        }

        return lines;
    }

    private static List<string> PostProcess(List<string> lines)
    {
        lines = EnhanceBeneficios(lines);
        lines = CleanFileLines(lines);
        lines = CollapseReferenceClusters(lines);
        lines = WrapMarkdownLines(lines, width: 100);

        // Limpiar vacías al final
        while (lines.Count > 0 && string.IsNullOrWhiteSpace(lines[^1]))
            lines.RemoveAt(lines.Count - 1);

        return lines;
    }

    private static List<string> EnhanceBeneficios(List<string> lines)
    {
        var result = new List<string>();
        int i = 0;

        while (i < lines.Count)
        {
            var line = lines[i];
            var stripped = line.Trim();
            result.Add(line);

            if (stripped.StartsWith("Beneficios:", StringComparison.OrdinalIgnoreCase))
            {
                i++;
                while (i < lines.Count)
                {
                    var cur = lines[i];
                    var curTrim = cur.Trim();

                    // Nuevo encabezado: detenemos
                    if (curTrim.StartsWith("#", StringComparison.Ordinal))
                        break;

                    // Vacías se conservan
                    if (string.IsNullOrWhiteSpace(curTrim))
                    {
                        result.Add(cur);
                        i++;
                        continue;
                    }

                    // Mantener listas/tablas existentes
                    if (curTrim.StartsWith("* ") ||
                        curTrim.StartsWith("- ") ||
                        curTrim.StartsWith("+ ") ||
                        curTrim.StartsWith("|") ||
                        curTrim.StartsWith("> "))
                    {
                        result.Add(cur);
                        i++;
                        continue;
                    }

                    // Candidato a bullet tipo "TextoCorto: resto..."
                    if (BeneficioRegex.IsMatch(curTrim))
                    {
                        result.Add("* " + curTrim);
                    }
                    else
                    {
                        result.Add(cur);
                    }

                    i++;
                }

                continue;
            }

            i++;
        }

        return result;
    }

    private static List<string> CleanFileLines(List<string> lines)
    {
        var result = new List<string>();
        foreach (var line in lines)
        {
            if (line.TrimStart().StartsWith("file://", StringComparison.OrdinalIgnoreCase))
                continue;

            result.Add(line);
        }

        return result;
    }

    private static List<string> CollapseReferenceClusters(List<string> lines)
    {
        static string ReplaceCluster(Match m)
        {
            var nums = Regex.Matches(m.Value, @"\[(\d+)\]")
                            .Cast<Match>()
                            .Select(mm => mm.Groups[1].Value)
                            .Distinct()
                            .ToList();

            if (nums.Count == 1)
                return $"[{nums[0]}]";

            return "[" + string.Join(",", nums) + "]";
        }

        var result = new List<string>();
        foreach (var line in lines)
        {
            var replaced = CitationClusterRegex.Replace(line, ReplaceCluster);
            result.Add(replaced);
        }

        return result;
    }

    private static List<string> WrapMarkdownLines(List<string> lines, int width)
    {
        var wrapped = new List<string>();

        foreach (var line in lines)
        {
            var stripped = line.TrimEnd();
            if (string.IsNullOrWhiteSpace(stripped))
            {
                wrapped.Add(string.Empty);
                continue;
            }

            // No envolver encabezados, listas, tablas, hr
            if (stripped.StartsWith("#") ||
                stripped.StartsWith("* ") ||
                stripped.StartsWith("- ") ||
                stripped.StartsWith("+ ") ||
                stripped.StartsWith("|") ||
                stripped == "---")
            {
                wrapped.Add(stripped);
                continue;
            }

            // Párrafo normal
            foreach (var w in WrapText(stripped, width).Split('\n'))
            {
                wrapped.Add(w);
            }
        }

        // Limpiar dobles vacías consecutivas
        var result = new List<string>();
        bool prevEmpty = false;
        foreach (var l in wrapped)
        {
            if (string.IsNullOrWhiteSpace(l))
            {
                if (!prevEmpty)
                {
                    result.Add(string.Empty);
                    prevEmpty = true;
                }
            }
            else
            {
                result.Add(l);
                prevEmpty = false;
            }
        }

        return result;
    }

    private static string WrapText(string text, int width)
    {
        var words = text.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (words.Length == 0)
            return string.Empty;

        var sb = new StringBuilder();
        var line = new StringBuilder();

        foreach (var word in words)
        {
            if (line.Length == 0)
            {
                line.Append(word);
            }
            else if (line.Length + 1 + word.Length <= width)
            {
                line.Append(' ').Append(word);
            }
            else
            {
                if (sb.Length > 0)
                    sb.Append('\n');

                sb.Append(line);
                line.Clear();
                line.Append(word);
            }
        }

        if (line.Length > 0)
        {
            if (sb.Length > 0)
                sb.Append('\n');

            sb.Append(line);
        }

        return sb.ToString();
    }
}
