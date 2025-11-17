using System.Runtime.CompilerServices;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class FileService
{
    public async Task<string> ReadAllTextAsync(string path, CancellationToken cancellationToken = default)
    {
        using var stream = new FileStream(path, new FileStreamOptions
        {
            Access = FileAccess.Read,
            Mode = FileMode.Open,
            Share = FileShare.ReadWrite,
            Options = FileOptions.Asynchronous | FileOptions.SequentialScan
        });
        using var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
        var content = await reader.ReadToEndAsync().ConfigureAwait(false);
        cancellationToken.ThrowIfCancellationRequested();
        return content;
    }

    public async IAsyncEnumerable<string> ReadLinesAsync(string path, [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var stream = new FileStream(path, new FileStreamOptions
        {
            Access = FileAccess.Read,
            Mode = FileMode.Open,
            Share = FileShare.ReadWrite,
            Options = FileOptions.Asynchronous | FileOptions.SequentialScan
        });
        using var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
        while (!reader.EndOfStream)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var line = await reader.ReadLineAsync().ConfigureAwait(false);
            if (line is not null)
            {
                yield return line;
            }
        }
    }

    public async Task<TextFragment> ExtractFragmentByLinesAsync(string path, int startLine, int endLine, string label, CancellationToken cancellationToken = default)
    {
        if (startLine < 1 || endLine < startLine)
        {
            throw new ArgumentException("Rango inválido de líneas.");
        }

        var builder = new StringBuilder();
        var currentLine = 0;
        await foreach (var line in ReadLinesAsync(path, cancellationToken).ConfigureAwait(false))
        {
            currentLine++;
            if (currentLine < startLine)
            {
                continue;
            }

            if (currentLine > endLine)
            {
                break;
            }

            builder.AppendLine(line);
        }

        return new TextFragment(label, path, startLine, endLine, builder.ToString());
    }

    public async Task<IReadOnlyList<TextFragment>> DetectJsonFragmentsAsync(string path, bool sortKeys, CancellationToken cancellationToken = default)
    {
        var text = await ReadAllTextAsync(path, cancellationToken).ConfigureAwait(false);
        var fragments = new List<TextFragment>();
        foreach (var fragment in DetectJsonObjects(text, path, sortKeys))
        {
            fragments.Add(fragment);
        }

        foreach (var fragment in DetectJsonLines(text, path, sortKeys))
        {
            fragments.Add(fragment);
        }

        return fragments;
    }

    public async Task SaveTextAsync(string content, string destinationPath, bool createBackup, CancellationToken cancellationToken = default)
    {
        var target = destinationPath;
        var backupPath = createBackup ? target + ".bak" : null;
        if (createBackup && File.Exists(target) && backupPath is not null)
        {
            File.Copy(target, backupPath, overwrite: true);
        }

        var tempFile = target + ".tmp";
        await File.WriteAllTextAsync(tempFile, content, cancellationToken).ConfigureAwait(false);
        File.Copy(tempFile, target, overwrite: true);
        File.Delete(tempFile);
    }

    private IEnumerable<TextFragment> DetectJsonObjects(string text, string path, bool sortKeys)
    {
        var stack = new Stack<int>();
        var fragments = new List<TextFragment>();
        for (var i = 0; i < text.Length; i++)
        {
            var c = text[i];
            if (c == '{')
            {
                stack.Push(i);
            }
            else if (c == '}' && stack.Count > 0)
            {
                var start = stack.Pop();
                if (stack.Count == 0)
                {
                    var length = i - start + 1;
                    var snippet = text.Substring(start, length);
                    if (TryFormatJson(snippet, sortKeys, out var pretty))
                    {
                        var startLine = CountLines(text.AsSpan(0, start)) + 1;
                        var endLine = startLine + CountLines(text.AsSpan(start, length));
                        var fragment = new TextFragment($"JSON_{fragments.Count + 1}", path, startLine, endLine, snippet, isJson: true)
                        {
                            PrettyJson = pretty
                        };
                        fragments.Add(fragment);
                    }
                }
            }
        }

        return fragments;
    }

    private IEnumerable<TextFragment> DetectJsonLines(string text, string path, bool sortKeys)
    {
        var fragments = new List<TextFragment>();
        var lines = text.Split('\n');
        for (var i = 0; i < lines.Length; i++)
        {
            var line = lines[i].Trim();
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            if (!line.StartsWith('{') || !line.EndsWith('}'))
            {
                continue;
            }

            if (TryFormatJson(line, sortKeys, out var pretty))
            {
                var fragment = new TextFragment($"JSONL_{fragments.Count + 1}", path, i + 1, i + 1, line, isJson: true)
                {
                    PrettyJson = pretty
                };
                fragments.Add(fragment);
            }
        }

        return fragments;
    }

    private static bool TryFormatJson(string snippet, bool sortKeys, out string pretty)
    {
        try
        {
            var node = JsonNode.Parse(snippet);
            if (node is null)
            {
                pretty = string.Empty;
                return false;
            }

            if (sortKeys)
            {
                SortJsonNode(node);
            }

            var options = new JsonSerializerOptions
            {
                WriteIndented = true
            };
            pretty = node.ToJsonString(options);
            return true;
        }
        catch
        {
            pretty = string.Empty;
            return false;
        }
    }

    private static void SortJsonNode(JsonNode node)
    {
        if (node is JsonObject obj)
        {
            var entries = obj.ToList();
            obj.Clear();
            foreach (var (key, value) in entries.OrderBy(entry => entry.Key, StringComparer.OrdinalIgnoreCase))
            {
                obj[key] = value;
                if (value is not null)
                {
                    SortJsonNode(value);
                }
            }
        }
        else if (node is JsonArray array)
        {
            foreach (var child in array)
            {
                if (child is not null)
                {
                    SortJsonNode(child);
                }
            }
        }
    }

    private static int CountLines(ReadOnlySpan<char> span)
    {
        var count = 0;
        foreach (var c in span)
        {
            if (c == '\n')
            {
                count++;
            }
        }

        return count;
    }
}
