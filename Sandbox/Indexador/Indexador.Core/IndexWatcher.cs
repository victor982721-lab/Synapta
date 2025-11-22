using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;

namespace Indexador.Core
{
    public sealed class IndexWatcher : IDisposable
    {
        private readonly IndexManager _manager;
        private readonly IndexUpdateOptions _options;
        private readonly Action<IndexSummary>? _onUpdated;
        private readonly Action<Exception>? _onError;
        private readonly FileSystemWatcher _watcher;
        private readonly Timer _timer;
        private readonly HashSet<string> _pending = new(StringComparer.OrdinalIgnoreCase);
        private readonly object _lock = new();
        private readonly string _rootPath;
        private readonly TimeSpan _debounce;
        private bool _disposed;

        public IndexWatcher(IndexManager manager, IndexUpdateOptions options, TimeSpan debounce, Action<IndexSummary>? onUpdated = null, Action<Exception>? onError = null)
        {
            _manager = manager ?? throw new ArgumentNullException(nameof(manager));
            _options = options ?? throw new ArgumentNullException(nameof(options));
            _onUpdated = onUpdated;
            _onError = onError;
            _debounce = debounce > TimeSpan.Zero ? debounce : TimeSpan.FromMilliseconds(500);
            _rootPath = PathTools.NormalizePath(options.RootPath);
            _timer = new Timer(OnTimer, null, Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);

            _watcher = new FileSystemWatcher(_rootPath)
            {
                IncludeSubdirectories = true,
                NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.DirectoryName
            };

            _watcher.Changed += OnChanged;
            _watcher.Created += OnChanged;
            _watcher.Deleted += OnChanged;
            _watcher.Renamed += OnRenamed;
        }

        public void Start()
        {
            _watcher.EnableRaisingEvents = true;
        }

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            Schedule(e.FullPath);
        }

        private void OnRenamed(object sender, RenamedEventArgs e)
        {
            Schedule(e.OldFullPath);
            Schedule(e.FullPath);
        }

        private void Schedule(string? path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return;

            string normalized;
            try
            {
                normalized = PathTools.NormalizePath(path);
            }
            catch (ArgumentException)
            {
                return;
            }

            if (!normalized.StartsWith(_rootPath, StringComparison.OrdinalIgnoreCase))
                return;

            if (Directory.Exists(normalized))
                return;

            lock (_lock)
            {
                _pending.Add(normalized);
                _timer.Change(_debounce, Timeout.InfiniteTimeSpan);
            }
        }

        private void OnTimer(object? state)
        {
            string[] paths;
            lock (_lock)
            {
                if (_pending.Count == 0)
                {
                    _timer.Change(Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
                    return;
                }

                paths = _pending.ToArray();
                _pending.Clear();
                _timer.Change(Timeout.InfiniteTimeSpan, Timeout.InfiniteTimeSpan);
            }

            ProcessBatch(paths);
        }

        private void ProcessBatch(string[] paths)
        {
            if (paths.Length == 0)
                return;

            try
            {
                var summary = _manager.UpdateEntries(_options, paths);
                _onUpdated?.Invoke(summary);
            }
            catch (Exception ex)
            {
                _onError?.Invoke(ex);
            }
        }

        public void Dispose()
        {
            if (_disposed)
                return;

            _disposed = true;
            _watcher.EnableRaisingEvents = false;
            _watcher.Dispose();
            _timer.Dispose();
            FlushPending();
        }

        private void FlushPending()
        {
            string[] paths;
            lock (_lock)
            {
                if (_pending.Count == 0)
                    return;

                paths = _pending.ToArray();
                _pending.Clear();
            }

            ProcessBatch(paths);
        }
    }
}
