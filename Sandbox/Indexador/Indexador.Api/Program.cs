using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Indexador.Core;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<IndexManager>();

var app = builder.Build();

app.MapGet("/records", (HttpRequest request, IndexManager manager) =>
{
    var (rootPath, databasePath) = ResolvePaths(request);
    if (!EnsureDatabase(rootPath, databasePath, out var response)) return response;

    var records = ApplyFilters(manager.GetRecords(rootPath, databasePath), request);
    var limit = ParseInt(request.Query["limit"]) ?? 0;

    var payload = records
        .Take(limit > 0 ? limit : int.MaxValue)
        .Select(record => new FileDto(record))
        .ToList();

    return Results.Ok(payload);
});

app.MapGet("/duplicates", (HttpRequest request, IndexManager manager) =>
{
    var (rootPath, databasePath) = ResolvePaths(request);
    if (!EnsureDatabase(rootPath, databasePath, out var response)) return response;

    var records = ApplyFilters(manager.GetRecords(rootPath, databasePath), request);
    var duplicates = manager.FindDuplicates(records)
        .Select(group => new DuplicateDto(group.Key, group.Select(record => new FileDto(record)).ToList()))
        .ToList();

    return Results.Ok(duplicates);
});

app.MapGet("/map", (HttpRequest request, IndexManager manager) =>
{
    var (rootPath, databasePath) = ResolvePaths(request);
    if (!EnsureDatabase(rootPath, databasePath, out var response)) return response;

    var map = manager.BuildFileMap(rootPath, databasePath)
        .Select(entry => new DirectoryDto(entry))
        .ToList();

    return Results.Ok(map);
});

app.MapGet("/summary", (HttpRequest request, IndexManager manager) =>
{
    var (rootPath, databasePath) = ResolvePaths(request);
    if (!EnsureDatabase(rootPath, databasePath, out var response)) return response;

    var records = ApplyFilters(manager.GetRecords(rootPath, databasePath), request).ToList();
    var duplicates = manager.FindDuplicates(records).ToList();

    var summary = new SummaryDto
    {
        TotalFiles = records.Count,
        TotalSize = records.Sum(r => r.Size),
        DuplicateGroups = duplicates.Count,
        DuplicateFiles = duplicates.Sum(group => group.Count())
    };

    return Results.Ok(summary);
});

app.Run();

static (string, string) ResolvePaths(HttpRequest request)
{
    var root = request.Query["root"].FirstOrDefault()
        ?? Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

    var rootPath = Path.GetFullPath(root);
    var dbParameter = request.Query["db"].FirstOrDefault();
    var databasePath = string.IsNullOrWhiteSpace(dbParameter)
        ? Path.Combine(rootPath, "indexador.db")
        : dbParameter;

    return (rootPath, databasePath);
}

static bool EnsureDatabase(string root, string databasePath, out IResult response)
{
    if (!File.Exists(databasePath))
    {
        response = Results.Problem(detail: $"No se encontró el índice en '{databasePath}'. Ejecuta el watcher primero.", statusCode: 404);
        return false;
    }

    response = Results.Ok();
    return true;
}

static IEnumerable<IndexRecord> ApplyFilters(IEnumerable<IndexRecord> records, HttpRequest request)
{
    var extFilter = NormalizeExtension(request.Query["extension"].FirstOrDefault());
    var minSize = ParseLong(request.Query["minSize"]);
    var maxSize = ParseLong(request.Query["maxSize"]);

    foreach (var record in records)
    {
        if (!string.IsNullOrEmpty(extFilter))
        {
            var extension = Path.GetExtension(record.RelativePath);
            if (!extension.Equals(extFilter, StringComparison.OrdinalIgnoreCase))
                continue;
        }

        if (minSize.HasValue && record.Size < minSize.Value)
            continue;

        if (maxSize.HasValue && record.Size > maxSize.Value)
            continue;

        yield return record;
    }
}

static string NormalizeExtension(string? extension)
{
    if (string.IsNullOrWhiteSpace(extension))
        return string.Empty;

    if (!extension.StartsWith("."))
        extension = "." + extension;

    return extension;
}

static int? ParseInt(string? value) =>
    int.TryParse(value, out var result) ? result : null;

static long? ParseLong(string? value) =>
    long.TryParse(value, out var result) ? result : null;

record FileDto(string RelativePath, long Size, DateTime LastWriteUtc, string Hash, string Algorithm)
{
    public FileDto(IndexRecord record) : this(record.RelativePath, record.Size, record.LastWriteUtc, record.Hash, record.HashAlgorithm) { }
}

record DuplicateDto(string Hash, List<FileDto> Files);

record DirectoryDto(string Directory, int Files, long TotalSize, int Duplicates)
{
    public DirectoryDto(FileMapEntry entry) : this(entry.Directory, entry.FileCount, entry.TotalSize, entry.DuplicateCount) { }
}

record SummaryDto
{
    public int TotalFiles { get; init; }
    public long TotalSize { get; init; }
    public int DuplicateGroups { get; init; }
    public int DuplicateFiles { get; init; }
}
