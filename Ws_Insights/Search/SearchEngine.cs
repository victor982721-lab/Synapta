using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Channels;
using System.Threading.Tasks;
using Ws_Insights.Models;
using Ws_Insights.Utilities;

namespace Ws_Insights.Search;

/// <summary>
/// High level orchestrator that wires together file enumeration, text scanning and
/// progress reporting so that the WPF UI can remain responsive while processing
/// large directory trees.
/// </summary>
public sealed class SearchEngine
{
    /// <summary>
    /// Launches a search operation using the provided options. Results are streamed
    /// via <paramref name="onMatch"/> while progress notifications are sent through
    /// <paramref name="progress"/>.
    /// </summary>
    public async Task SearchAsync(
        SearchOptions options,
        IProgress<SearchProgress>? progress,
        Func<FileMatch, Task> onMatch,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentNullException.ThrowIfNull(onMatch);

        var rootPath = ValidateAndNormalizeRoot(options.RootPath);
        if (string.IsNullOrWhiteSpace(options.Query))
        {
            throw new ArgumentException("La consulta no puede estar vacía.", nameof(options));
        }

        var extensionFilter = BuildExtensionFilter(options.Extensions);
        var plan = SearchPlan.Create(options);
        var concurrency = Math.Max(1, options.MaxDegreeOfParallelism);
        var channel = Channel.CreateBounded<FileInfo>(new BoundedChannelOptions(Math.Max(4, concurrency * 4))
        {
            FullMode = BoundedChannelFullMode.Wait,
            SingleReader = false,
            SingleWriter = true
        });

        var stopwatch = Stopwatch.StartNew();
        long filesScanned = 0;
        long matches = 0;
        long errors = 0;

        void Report(string? currentFile)
        {
            if (progress is null)
            {
                return;
            }

            var elapsed = stopwatch.Elapsed;
            var files = Interlocked.Read(ref filesScanned);
            var totalMatches = Interlocked.Read(ref matches);
            var totalErrors = Interlocked.Read(ref errors);
            var fps = elapsed.TotalSeconds > double.Epsilon
                ? files / elapsed.TotalSeconds
                : files;

            progress.Report(new SearchProgress
            {
                FilesScanned = (int)Math.Min(int.MaxValue, files),
                Matches = (int)Math.Min(int.MaxValue, totalMatches),
                Errors = (int)Math.Min(int.MaxValue, totalErrors),
                FilesPerSecond = fps,
                Elapsed = elapsed,
                CurrentFile = currentFile
            });
        }

        void IncrementErrors(string? file)
        {
            Interlocked.Increment(ref errors);
            Report(file);
        }

        void RecordFileCompletion(FileInfo file, int fileMatches)
        {
            Interlocked.Increment(ref filesScanned);
            if (fileMatches > 0)
            {
                Interlocked.Add(ref matches, fileMatches);
            }
            Report(file.FullName);
        }

        Report(currentFile: null);

        var workers = new Task[concurrency];
        for (var i = 0; i < workers.Length; i++)
        {
            workers[i] = Task.Run(() => WorkerAsync(
                channel.Reader,
                plan,
                options,
                onMatch,
                RecordFileCompletion,
                IncrementErrors,
                Report,
                cancellationToken), cancellationToken);
        }

        try
        {
            await foreach (var file in EnumerateFilesAsync(rootPath, options, extensionFilter, IncrementErrors, cancellationToken)
                .WithCancellation(cancellationToken).ConfigureAwait(false))
            {
                await channel.Writer.WriteAsync(file, cancellationToken).ConfigureAwait(false);
            }
        }
        finally
        {
            channel.Writer.TryComplete();
        }

        await Task.WhenAll(workers).ConfigureAwait(false);
        stopwatch.Stop();
        Report(currentFile: null);
    }

    private static async Task WorkerAsync(
        ChannelReader<FileInfo> reader,
        SearchPlan plan,
        SearchOptions options,
        Func<FileMatch, Task> onMatch,
        Action<FileInfo, int> onFileCompleted,
        Action<string?> reportError,
        Action<string?> reportCurrentFile,
        CancellationToken cancellationToken)
    {
        await foreach (var file in reader.ReadAllAsync(cancellationToken).ConfigureAwait(false))
        {
            cancellationToken.ThrowIfCancellationRequested();
            await options.PauseToken.WaitIfPausedAsync(cancellationToken).ConfigureAwait(false);
            reportCurrentFile(file.FullName);

            var matchesForFile = 0;
            try
            {
                matchesForFile = await ProcessFileAsync(file, plan, options.PauseToken, onMatch, cancellationToken)
                    .ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception)
            {
                reportError(file.FullName);
            }
            finally
            {
                onFileCompleted(file, matchesForFile);
            }
        }
    }

    private static async Task<int> ProcessFileAsync(
        FileInfo file,
        SearchPlan plan,
        PauseToken pauseToken,
        Func<FileMatch, Task> onMatch,
        CancellationToken cancellationToken)
    {
        using var stream = new FileStream(
            file.FullName,
            FileMode.Open,
            FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete,
            bufferSize: 81920,
            FileOptions.Asynchronous | FileOptions.SequentialScan);

        using var reader = new StreamReader(stream, detectEncodingFromByteOrderMarks: true);
        var lineNumber = 0;
        var matches = 0;

        while (!reader.EndOfStream)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await pauseToken.WaitIfPausedAsync(cancellationToken).ConfigureAwait(false);
            var line = await reader.ReadLineAsync().ConfigureAwait(false);
            if (line is null)
            {
                break;
            }

            lineNumber++;
            foreach (var location in plan.FindMatches(line))
            {
                matches++;
                var snippet = BuildSnippet(line, location);
                var match = new FileMatch(
                    file.Name,
                    file.Extension,
                    file.FullName,
                    file.Length,
                    $"Línea {lineNumber}: {snippet}");
                await onMatch(match).ConfigureAwait(false);
            }
        }

        return matches;
    }

    private static string BuildSnippet(string line, MatchLocation location)
    {
        if (string.IsNullOrWhiteSpace(line))
        {
            return string.Empty;
        }

        const int window = 160;
        var start = Math.Max(0, location.Index - window / 2);
        var end = Math.Min(line.Length, location.Index + location.Length + window / 2);
        var length = Math.Max(0, end - start);
        var snippet = line.Substring(start, length).Trim();
        if (snippet.Length > window)
        {
            snippet = snippet[..window] + "…";
        }
        return snippet.Replace('\t', ' ');
    }

    private static string ValidateAndNormalizeRoot(string rootPath)
    {
        if (string.IsNullOrWhiteSpace(rootPath))
        {
            throw new ArgumentException("La carpeta raíz es obligatoria.", nameof(rootPath));
        }

        var fullPath = Path.GetFullPath(rootPath);
        if (!Directory.Exists(fullPath))
        {
            throw new DirectoryNotFoundException($"La carpeta '{fullPath}' no existe.");
        }

        return fullPath;
    }

    private static HashSet<string> BuildExtensionFilter(IReadOnlyList<string>? extensions)
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (extensions is null)
        {
            return set;
        }

        foreach (var extension in extensions)
        {
            if (string.IsNullOrWhiteSpace(extension))
            {
                continue;
            }

            var cleaned = extension.Trim();
            if (cleaned.StartsWith('.'))
            {
                cleaned = cleaned[1..];
            }

            if (cleaned.Length == 0)
            {
                continue;
            }

            set.Add(cleaned);
        }

        return set;
    }

    private static async IAsyncEnumerable<FileInfo> EnumerateFilesAsync(
        string rootPath,
        SearchOptions options,
        HashSet<string> extensions,
        Action<string?> reportError,
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        var attributesToSkip = FileAttributes.ReparsePoint;
        if (!options.IncludeHidden)
        {
            attributesToSkip |= FileAttributes.Hidden;
        }

        if (!options.IncludeSystem)
        {
            attributesToSkip |= FileAttributes.System;
        }

        var enumerationOptions = new EnumerationOptions
        {
            IgnoreInaccessible = true,
            RecurseSubdirectories = options.IncludeSubfolders,
            ReturnSpecialDirectories = false,
            AttributesToSkip = attributesToSkip
        };

        IEnumerable<string> candidates;
        try
        {
            candidates = Directory.EnumerateFiles(rootPath, searchPattern: "*", enumerationOptions);
        }
        catch (Exception)
        {
            reportError(rootPath);
            yield break;
        }

        foreach (var path in candidates)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await options.PauseToken.WaitIfPausedAsync(cancellationToken).ConfigureAwait(false);

            FileInfo? fileInfo = null;
            try
            {
                fileInfo = new FileInfo(path);
                if (!fileInfo.Exists)
                {
                    continue;
                }

                if (!ShouldIncludeFile(fileInfo, options, extensions))
                {
                    continue;
                }
            }
            catch (Exception)
            {
                reportError(path);
                continue;
            }

            yield return fileInfo;
            await Task.Yield();
        }
    }

    private static bool ShouldIncludeFile(FileInfo file, SearchOptions options, HashSet<string> extensions)
    {
        if (extensions.Count > 0)
        {
            var ext = file.Extension ?? string.Empty;
            var normalized = ext.StartsWith('.') ? ext[1..] : ext;
            if (!extensions.Contains(normalized))
            {
                return false;
            }
        }

        var size = file.Length;
        var min = options.MinFileSizeBytes.GetValueOrDefault();
        if (min > 0 && size < min)
        {
            return false;
        }

        var max = options.MaxFileSizeBytes.GetValueOrDefault();
        if (max > 0 && size > max)
        {
            return false;
        }

        var attributes = file.Attributes;
        if (!options.IncludeHidden && attributes.HasFlag(FileAttributes.Hidden))
        {
            return false;
        }

        if (!options.IncludeSystem && attributes.HasFlag(FileAttributes.System))
        {
            return false;
        }

        return true;
    }

    private sealed class SearchPlan
    {
        private readonly bool _useRegex;
        private readonly Regex? _regex;
        private readonly string _literal;
        private readonly bool _wholeWord;
        private readonly StringComparison _comparison;

        private SearchPlan(bool useRegex, Regex? regex, string literal, bool wholeWord, bool caseSensitive)
        {
            _useRegex = useRegex;
            _regex = regex;
            _literal = literal;
            _wholeWord = wholeWord;
            _comparison = caseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
        }

        public static SearchPlan Create(SearchOptions options)
        {
            if (options.UseRegex)
            {
                var regexOptions = RegexOptions.Compiled | RegexOptions.Multiline;
                if (!options.CaseSensitive)
                {
                    regexOptions |= RegexOptions.IgnoreCase;
                }
                var regex = new Regex(options.Query, regexOptions);
                return new SearchPlan(true, regex, string.Empty, wholeWord: false, options.CaseSensitive);
            }

            return new SearchPlan(false, null, options.Query, options.WholeWord, options.CaseSensitive);
        }

        public IEnumerable<MatchLocation> FindMatches(string text)
        {
            if (_useRegex)
            {
                if (_regex is null)
                {
                    yield break;
                }

                foreach (Match match in _regex.Matches(text))
                {
                    if (!match.Success)
                    {
                        continue;
                    }

                    var length = Math.Max(1, match.Length);
                    yield return new MatchLocation(match.Index, length);
                }
                yield break;
            }

            if (string.IsNullOrEmpty(_literal))
            {
                yield break;
            }

            var currentIndex = 0;
            while (true)
            {
                var foundIndex = text.IndexOf(_literal, currentIndex, _comparison);
                if (foundIndex < 0)
                {
                    yield break;
                }

                if (!_wholeWord || IsWholeWord(text, foundIndex, _literal.Length))
                {
                    yield return new MatchLocation(foundIndex, Math.Max(1, _literal.Length));
                }

                currentIndex = foundIndex + Math.Max(1, _literal.Length);
            }
        }

        private static bool IsWholeWord(string text, int index, int length)
        {
            bool IsBoundaryChar(int idx)
            {
                if (idx < 0 || idx >= text.Length)
                {
                    return true;
                }
                var c = text[idx];
                return !char.IsLetterOrDigit(c) && c != '_';
            }

            return IsBoundaryChar(index - 1) && IsBoundaryChar(index + length);
        }
    }

    private readonly record struct MatchLocation(int Index, int Length);
}
