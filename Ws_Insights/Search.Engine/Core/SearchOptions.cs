using System;
using System.Threading;
using Ws_Insights.Search.Core.Flags;

namespace Ws_Insights.Search.Core
{
    /// <summary>
    /// Encapsulates all of the inputs required to perform a text search.  This record struct is designed
    /// to be immutable and compact, and it makes use of a bitmask for boolean flags so that additional
    /// options can be added in the future without changing the shape of the API.
    /// </summary>
    public readonly record struct SearchOptions
    {
        /// <summary>
        /// Gets the normalized root directory from which file enumeration begins.
        /// </summary>
        public string RootPath { get; init; }

        /// <summary>
        /// Gets the raw query string provided by the user. This value is not interpreted until later
        /// in the pipeline (for example by the regex engine or DFA builder).
        /// </summary>
        public string Query { get; init; }

        /// <summary>
        /// Gets the set of file extensions to include in the search (without leading dots). An empty
        /// array implies all extensions are permitted.
        /// </summary>
        public string[] Extensions { get; init; }

        /// <summary>
        /// Gets the collection of flags controlling the behaviour of the search. Use <see cref="SearchOptionFlags"/>
        /// to specify whether the search should be case‑sensitive, use regular expressions, etc.
        /// </summary>
        public SearchOptionFlags Flags { get; init; }

        /// <summary>
        /// Gets the maximum number of threads or tasks that may be used in parallel when searching files.
        /// Set to a value greater than one to enable parallel enumeration and scanning.
        /// </summary>
        public int MaxDegreeOfParallelism { get; init; }

        /// <summary>
        /// Gets the maximum file size, in bytes, that will be processed.  Files larger than this limit
        /// may be skipped entirely.  A <c>null</c> value disables the limit.
        /// </summary>
        public long? MaxFileSizeBytes { get; init; }

        /// <summary>
        /// Gets the minimum file size, in bytes, that will be processed.  Files smaller than this limit
        /// may be skipped entirely.  A <c>null</c> value disables the limit.
        /// </summary>
        public long? MinFileSizeBytes { get; init; }

        /// <summary>
        /// Gets a token that can be used by the consumer to pause or resume the search operation.
        /// When <see cref="CancellationToken.IsCancellationRequested"/> becomes true the pipeline will
        /// honour the request at a safe point.
        /// </summary>
        public CancellationToken PauseToken { get; init; }
    }
}