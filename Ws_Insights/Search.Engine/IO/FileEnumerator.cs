using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Enumeration;
using System.Runtime.CompilerServices;
using System.Threading;
using System.Threading.Tasks;
using Ws_Insights.Search.Core;
using Ws_Insights.Search.Core.Flags;

namespace Ws_Insights.Search.IO
{
    /// <summary>
    /// High performance file enumerator that applies filters directly inside the enumeration
    /// pipeline.  The class leverages <see cref="FileSystemEnumerable{TResult}"/> so that
    /// attributes, extension checks and size limits happen without constructing managed
    /// <see cref="FileInfo"/> instances until a file has already been accepted.
    /// </summary>
    public sealed class FileEnumerator
    {
        private const FileAttributes DirectoryMask = FileAttributes.Directory;

        /// <summary>
        /// Enumerates files that satisfy the constraints described by <paramref name="options"/>.
        /// The method yields <see cref="FileInfo"/> instances asynchronously so it can be consumed
        /// directly from pipelines based on <c>await foreach</c>.
        /// </summary>
        public async IAsyncEnumerable<FileInfo> EnumerateAsync(
            SearchOptions options,
            [EnumeratorCancellation] CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(options.RootPath);

            if (!Directory.Exists(options.RootPath))
            {
                yield break;
            }

            var allowedExtensions = BuildExtensionSet(options.Extensions);
            var enumerationOptions = CreateEnumerationOptions(options.Flags);
            var minSize = options.MinFileSizeBytes.GetValueOrDefault();
            var maxSize = options.MaxFileSizeBytes.GetValueOrDefault();
            FileSystemEnumerable<FileInfo>.ShouldIncludePredicate includePredicate =
                (ref FileSystemEntry entry) => ShouldInclude(entry, allowedExtensions, minSize, maxSize);

            // FileSystemEnumerable avoids allocating FileInfo/FileSystemInfo for entries that end up
            // being filtered out.  Once we decide to include a file we materialise it as FileInfo so
            // downstream components can query metadata (length, timestamps, etc.).
            var fileEnumerable = new FileSystemEnumerable<FileInfo>(
                options.RootPath,
                (ref FileSystemEntry entry) => entry.ToFileInfo(),
                enumerationOptions)
            {
                ShouldIncludePredicate = includePredicate,
                ShouldRecursePredicate = CreateRecursePredicate(options.Flags)
            };

            var iterationBudget = 0;
            try
            {
                foreach (var file in fileEnumerable)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    yield return file;

                    // Yield the execution context periodically so UI threads can remain responsive
                    // when the consumer awaits this enumerator.
                    iterationBudget++;
                    if ((iterationBudget & 0x3F) == 0)
                    {
                        await Task.Yield();
                    }
                }
            }
            catch (UnauthorizedAccessException)
            {
                yield break;
            }
            catch (DirectoryNotFoundException)
            {
                yield break;
            }
        }

        private static EnumerationOptions CreateEnumerationOptions(SearchOptionFlags flags)
        {
            var attributesToSkip = FileAttributes.ReparsePoint;
            if (!flags.HasFlag(SearchOptionFlags.IncludeHidden))
            {
                attributesToSkip |= FileAttributes.Hidden;
            }

            if (!flags.HasFlag(SearchOptionFlags.IncludeSystem))
            {
                attributesToSkip |= FileAttributes.System;
            }

            return new EnumerationOptions
            {
                AttributesToSkip = attributesToSkip,
                IgnoreInaccessible = true,
                ReturnSpecialDirectories = false,
                RecurseSubdirectories = flags.HasFlag(SearchOptionFlags.IncludeSubfolders)
            };
        }

        private static FileSystemEnumerable<FileInfo>.ShouldRecursePredicate CreateRecursePredicate(SearchOptionFlags flags)
        {
            if (!flags.HasFlag(SearchOptionFlags.IncludeSubfolders))
            {
                return static (ref FileSystemEntry entry) => false;
            }

            // Returning true indicates the enumerator should continue exploring the directory.
            return static (ref FileSystemEntry entry) =>
            {
                return (entry.Attributes & DirectoryMask) != 0;
            };
        }

        private static bool ShouldInclude(
            in FileSystemEntry entry,
            HashSet<string> allowedExtensions,
            long minSize,
            long maxSize)
        {
            if ((entry.Attributes & DirectoryMask) != 0)
            {
                return false;
            }

            var extension = GetExtension(entry);
            if (allowedExtensions.Count > 0 && !allowedExtensions.Contains(extension))
            {
                return false;
            }

            if (minSize > 0 && entry.Length < minSize)
            {
                return false;
            }

            if (maxSize > 0 && entry.Length > maxSize)
            {
                return false;
            }

            return true;
        }

        private static HashSet<string> BuildExtensionSet(IReadOnlyList<string>? extensions)
        {
            var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (extensions is null || extensions.Count == 0)
            {
                return set;
            }

            foreach (var extension in extensions)
            {
                if (string.IsNullOrWhiteSpace(extension))
                {
                    continue;
                }

                var trimmed = extension.Trim();
                if (trimmed.StartsWith('.'))
                {
                    trimmed = trimmed[1..];
                }

                if (trimmed.Length == 0)
                {
                    continue;
                }

                set.Add(trimmed);
            }

            return set;
        }

        private static string GetExtension(in FileSystemEntry entry)
        {
            var fileName = entry.FileName.ToString();
            if (string.IsNullOrEmpty(fileName))
            {
                return string.Empty;
            }

            var index = fileName.LastIndexOf('.');
            if (index < 0 || index == fileName.Length - 1)
            {
                return string.Empty;
            }

            return fileName[(index + 1)..];
        }
    }
}