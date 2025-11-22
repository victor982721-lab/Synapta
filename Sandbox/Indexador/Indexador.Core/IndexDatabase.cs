using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Data.Sqlite;

namespace Indexador.Core
{
    public sealed class IndexDatabase
    {
        private readonly string _connectionString;

        public string DatabasePath { get; }

        public IndexDatabase(string databasePath)
        {
            if (string.IsNullOrWhiteSpace(databasePath))
                throw new ArgumentException("La ruta de la base de datos no puede estar vacía.", nameof(databasePath));

            DatabasePath = Path.GetFullPath(databasePath);
            var folder = Path.GetDirectoryName(DatabasePath);
            if (!string.IsNullOrEmpty(folder))
                Directory.CreateDirectory(folder);

            _connectionString = new SqliteConnectionStringBuilder
            {
                DataSource = DatabasePath,
                Mode = SqliteOpenMode.ReadWriteCreate,
                Cache = SqliteCacheMode.Shared
            }.ToString();

            EnsureSchema();
        }

        public IReadOnlyList<IndexRecord> GetRecords(string rootPath)
        {
            var normalizedRoot = PathTools.NormalizePath(rootPath);
            using var connection = CreateConnection();
            connection.Open();

            using var command = connection.CreateCommand();
            command.CommandText =
                @"SELECT Path, RootPath, RelativePath, Size, LastWriteUtc, Hash, HashAlgorithm,
                         Tags, Notes, CreatedUtc, ModifiedUtc, Source
                    FROM Files
                   WHERE RootPath = @root;";
            command.Parameters.AddWithValue("@root", normalizedRoot);

            var records = new List<IndexRecord>();
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                records.Add(new IndexRecord
                {
                    FullPath = reader.GetString(0),
                    RootPath = reader.GetString(1),
                    RelativePath = reader.GetString(2),
                    Size = reader.GetInt64(3),
                    LastWriteUtc = DateTime.Parse(reader.GetString(4)),
                    Hash = reader.GetString(5),
                    HashAlgorithm = reader.GetString(6),
                    Tags = reader.GetString(7),
                    Notes = reader.GetString(8),
                    CreatedUtc = DateTime.Parse(reader.GetString(9)),
                    ModifiedUtc = DateTime.Parse(reader.GetString(10)),
                    Source = reader.GetString(11)
                });
            }

            return records;
        }

        public void Upsert(IndexRecord record)
        {
            using var connection = CreateConnection();
            connection.Open();
            using var command = connection.CreateCommand();
            command.CommandText =
                @"INSERT INTO Files (Path, RootPath, RelativePath, Size, LastWriteUtc,
                                      Hash, HashAlgorithm, Tags, Notes, CreatedUtc, ModifiedUtc, Source)
                          VALUES (@path, @root, @relative, @size, @lastWrite,
                                  @hash, @algorithm, @tags, @notes, @created, @modified, @source)
                   ON CONFLICT(Path) DO UPDATE SET
                        RootPath = @root,
                        RelativePath = @relative,
                        Size = @size,
                        LastWriteUtc = @lastWrite,
                        Hash = @hash,
                        HashAlgorithm = @algorithm,
                        Tags = @tags,
                        Notes = @notes,
                        ModifiedUtc = @modified,
                        Source = @source;";

            AddParameters(command, record);
            command.ExecuteNonQuery();
        }

        public int RemoveMissing(string rootPath, IEnumerable<string> pathsToKeep)
        {
            var normalizedRoot = PathTools.NormalizePath(rootPath);
            var keepList = pathsToKeep
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(PathTools.NormalizePath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            using var connection = CreateConnection();
            connection.Open();
            using var command = connection.CreateCommand();

            if (keepList.Count == 0)
            {
                command.CommandText = "DELETE FROM Files WHERE RootPath = @root;";
                command.Parameters.AddWithValue("@root", normalizedRoot);
            }
            else
            {
                var parameters = keepList
                    .Select((_, index) => $"@keep{index}")
                    .ToArray();

                command.CommandText =
                    $"DELETE FROM Files WHERE RootPath = @root AND Path NOT IN ({string.Join(", ", parameters)});";
                command.Parameters.AddWithValue("@root", normalizedRoot);
                for (var i = 0; i < keepList.Count; i++)
                    command.Parameters.AddWithValue(parameters[i], keepList[i]);
            }

            return command.ExecuteNonQuery();
        }

        private SqliteConnection CreateConnection() => new(_connectionString);

        private void EnsureSchema()
        {
            using var connection = CreateConnection();
            connection.Open();
            using var command = connection.CreateCommand();
            command.CommandText =
                @"CREATE TABLE IF NOT EXISTS Files (
                    Path TEXT PRIMARY KEY,
                    RootPath TEXT NOT NULL,
                    RelativePath TEXT NOT NULL,
                    Size INTEGER NOT NULL,
                    LastWriteUtc TEXT NOT NULL,
                    Hash TEXT NOT NULL,
                    HashAlgorithm TEXT NOT NULL,
                    Tags TEXT NOT NULL,
                    Notes TEXT NOT NULL,
                    CreatedUtc TEXT NOT NULL,
                    ModifiedUtc TEXT NOT NULL,
                    Source TEXT NOT NULL
                );";
            command.ExecuteNonQuery();
        }

        private static void AddParameters(SqliteCommand command, IndexRecord record)
        {
            command.Parameters.AddWithValue("@path", PathTools.NormalizePath(record.FullPath));
            command.Parameters.AddWithValue("@root", PathTools.NormalizePath(record.RootPath));
            command.Parameters.AddWithValue("@relative", record.RelativePath);
            command.Parameters.AddWithValue("@size", record.Size);
            command.Parameters.AddWithValue("@lastWrite", record.LastWriteUtc.ToString("o"));
            command.Parameters.AddWithValue("@hash", record.Hash);
            command.Parameters.AddWithValue("@algorithm", record.HashAlgorithm);
            command.Parameters.AddWithValue("@tags", record.Tags);
            command.Parameters.AddWithValue("@notes", record.Notes);
            command.Parameters.AddWithValue("@created", record.CreatedUtc.ToString("o"));
            command.Parameters.AddWithValue("@modified", record.ModifiedUtc.ToString("o"));
            command.Parameters.AddWithValue("@source", record.Source);
        }

        public int DeletePaths(IEnumerable<string> paths)
        {
            var normalized = paths
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Select(PathTools.NormalizePath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (normalized.Count == 0)
                return 0;

            using var connection = CreateConnection();
            connection.Open();
            using var command = connection.CreateCommand();

            var parameters = normalized
                .Select((_, index) => $"@path{index}")
                .ToArray();

            command.CommandText =
                $"DELETE FROM Files WHERE Path IN ({string.Join(", ", parameters)});";

            for (var i = 0; i < normalized.Count; i++)
                command.Parameters.AddWithValue(parameters[i], normalized[i]);

            return command.ExecuteNonQuery();
        }
    }
}
