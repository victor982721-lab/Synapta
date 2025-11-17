using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Ws_Insights.Search.Core.Flags;
using Ws_Insights.Search.IO;

namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Coordinates the various stages involved in executing a search, from consulting the
    /// index through to reading files from disk and running pattern matching.  The
    /// implementation provided here is a placeholder; in a real engine each phase
    /// would be implemented with high performance in mind.
    /// </summary>
    public sealed class SearchPipeline
    {
        private readonly FileEnumerator _fileEnumerator;
        private readonly AsyncDiskScheduler _diskScheduler;

        public SearchPipeline(FileEnumerator? enumerator = null, AsyncDiskScheduler? diskScheduler = null)
        {
            _fileEnumerator = enumerator ?? new FileEnumerator();
            _diskScheduler = diskScheduler ?? new AsyncDiskScheduler();
        }

        /// <summary>
        /// Streams results asynchronously for the given context.  This method is designed to be
        /// consumed with await foreach.  The pipeline performs filtered file enumeration, schedules
        /// disk IO through <see cref="AsyncDiskScheduler"/> and emits <see cref="SearchResult"/>
        /// instances as soon as they are available.
        /// </summary>
        public async IAsyncEnumerable<SearchResult> ExecuteAsync(
            SearchContext context,
            [EnumeratorCancellation] CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(context);

            using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(
                cancellationToken,
                context.CancellationToken);
            var effectiveToken = linkedCts.Token;

            var options = context.Options;
            var matcher = SearchMatcher.Create(options);
            var statistics = context.Statistics;
            var stopwatch = Stopwatch.StartNew();

            long filesScanned = 0;
            long matchesFound = 0;
            long bytesRead = 0;

            var parallelism = Math.Max(1, options.MaxDegreeOfParallelism);
            var active = new List<Task<FileScanResult>>(parallelism);

            async Task<FileScanResult> AwaitNextAsync()
            {
                var completed = await Task.WhenAny(active).ConfigureAwait(false);
                active.Remove(completed);
                return await completed.ConfigureAwait(false);
            }

            await foreach (var fileInfo in _fileEnumerator.EnumerateAsync(options, effectiveToken))
            {
                var file = fileInfo; // prevent capturing loop variable
                active.Add(_diskScheduler.ScheduleAsync(
                    () => ScanFileAsync(file, matcher, effectiveToken),
                    effectiveToken));

                if (active.Count < parallelism)
                {
                    continue;
                }

                var scan = await AwaitNextAsync().ConfigureAwait(false);
                filesScanned++;
                matchesFound += scan.Matches.Count;
                bytesRead += scan.BytesRead;

                foreach (var match in scan.Matches)
                {
                    yield return match;
                }
            }

            while (active.Count > 0)
            {
                var scan = await AwaitNextAsync().ConfigureAwait(false);
                filesScanned++;
                matchesFound += scan.Matches.Count;
                bytesRead += scan.BytesRead;

                foreach (var match in scan.Matches)
                {
                    yield return match;
                }
            }

            stopwatch.Stop();
            statistics.FilesScanned = filesScanned;
            statistics.MatchesFound = matchesFound;
            statistics.BytesReadFromDisk = bytesRead;
            statistics.TotalTime = stopwatch.Elapsed;
            statistics.ProcessingTime = stopwatch.Elapsed;
        }

        private static async Task<FileScanResult> ScanFileAsync(
            FileInfo file,
            SearchMatcher matcher,
            CancellationToken cancellationToken)
        {
            var matches = new List<SearchResult>();
            long bytesRead = 0;

            try
            {
                using var stream = new FileStream(
                    file.FullName,
                    FileMode.Open,
                    FileAccess.Read,
                    FileShare.ReadWrite | FileShare.Delete,
                    bufferSize: 131072,
                    FileOptions.Asynchronous | FileOptions.SequentialScan);
                using var reader = new StreamReader(stream, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);

                var lineNumber = 0;
                string? line;
                while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) != null)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    lineNumber++;
                    foreach (var location in matcher.FindMatches(line))
                    {
                        matches.Add(new SearchResult
                        {
                            Path = file.FullName,
                            LineNumber = lineNumber,
                            Column = location.Index + 1,
                            Snippet = SnippetBuilder.Create(line, location),
                            MatchKind = matcher.Kind
                        });
                    }
                }

                bytesRead = stream.Position;
            }
            catch (IOException)
            {
                // Skip files that we cannot read; consumers can inspect statistics for totals.
            }
            catch (UnauthorizedAccessException)
            {
                // Swallow and continue – inaccessible files are expected when scanning system roots.
            }

            return new FileScanResult(matches, bytesRead);
        }

        private sealed class FileScanResult
        {
            public FileScanResult(List<SearchResult> matches, long bytesRead)
            {
                Matches = matches;
                BytesRead = bytesRead;
            }

            public List<SearchResult> Matches { get; }
            public long BytesRead { get; }
        }

        private sealed class SearchMatcher
        {
            private readonly Regex? _regex;
            private readonly string _literal;
            private readonly StringComparison _comparison;
            private readonly bool _wholeWord;
            private readonly bool _useRegex;

            private SearchMatcher(Regex? regex, string literal, bool caseSensitive, bool wholeWord, bool useRegex, SearchMatchKind kind)
            {
                _regex = regex;
                _literal = literal;
                _comparison = caseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
                _wholeWord = wholeWord;
                _useRegex = useRegex;
                Kind = kind;
            }

            public SearchMatchKind Kind { get; }

            public static SearchMatcher Create(SearchOptions options)
            {
                var query = options.Query ?? string.Empty;
                var useRegex = options.Flags.HasFlag(SearchOptionFlags.UseRegex);
                var caseSensitive = options.Flags.HasFlag(SearchOptionFlags.CaseSensitive);
                var wholeWord = options.Flags.HasFlag(SearchOptionFlags.WholeWord) && !useRegex;

                if (useRegex)
                {
                    var regexOptions = RegexOptions.Compiled | RegexOptions.Multiline;
                    if (!caseSensitive)
                    {
                        regexOptions |= RegexOptions.IgnoreCase;
                    }

                    var regex = new Regex(query, regexOptions);
                    return new SearchMatcher(regex, string.Empty, caseSensitive, wholeWord, true, SearchMatchKind.Regex);
                }

                return new SearchMatcher(null, query, caseSensitive, wholeWord, false,
                    wholeWord ? SearchMatchKind.WholeWord : SearchMatchKind.Literal);
            }

            public IEnumerable<MatchLocation> FindMatches(string text)
            {
                if (_useRegex && _regex is not null)
                {
                    foreach (Match match in _regex.Matches(text))
                    {
                        if (!match.Success)
                        {
                            continue;
                        }

                        yield return new MatchLocation(match.Index, Math.Max(1, match.Length));
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
                    var index = text.IndexOf(_literal, currentIndex, _comparison);
                    if (index < 0)
                    {
                        yield break;
                    }

                    var length = Math.Max(1, _literal.Length);
                    if (!_wholeWord || IsWholeWord(text, index, length))
                    {
                        yield return new MatchLocation(index, length);
                    }

                    currentIndex = index + length;
                }
            }

            private static bool IsWholeWord(string text, int index, int length)
            {
                static bool IsBoundary(string input, int idx)
                {
                    if (idx < 0 || idx >= input.Length)
                    {
                        return true;
                    }

                    var c = input[idx];
                    return !char.IsLetterOrDigit(c) && c != '_';
                }

                return IsBoundary(text, index - 1) && IsBoundary(text, index + length);
            }
        }

        private static class SnippetBuilder
        {
            private const int Window = 160;

            public static string Create(string line, MatchLocation location)
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    return string.Empty;
                }

                var start = Math.Max(0, location.Index - Window / 2);
                var end = Math.Min(line.Length, location.Index + location.Length + Window / 2);
                var length = Math.Max(0, end - start);
                var snippet = line.Substring(start, length).Trim();
                if (snippet.Length > Window)
                {
                    snippet = snippet[..Window] + "…";
                }

                return snippet.Replace('\t', ' ');
            }
        }

        private readonly record struct MatchLocation(int Index, int Length);
    }
}
