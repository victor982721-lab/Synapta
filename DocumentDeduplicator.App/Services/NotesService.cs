using System.IO;
using System.Text.Json;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class NotesService
{
    private readonly string _notesPath;

    public NotesService()
    {
        var basePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Synapta", "DocumentDeduplicator");
        Directory.CreateDirectory(basePath);
        _notesPath = Path.Combine(basePath, "notes.json");
    }

    public async Task<IReadOnlyList<NoteItem>> LoadAsync(CancellationToken cancellationToken = default)
    {
        if (!File.Exists(_notesPath))
        {
            return Array.Empty<NoteItem>();
        }

        await using var stream = File.OpenRead(_notesPath);
        var notes = await JsonSerializer.DeserializeAsync<List<NoteItem>>(stream, cancellationToken: cancellationToken).ConfigureAwait(false);
        return notes ?? new List<NoteItem>();
    }

    public async Task SaveAsync(IEnumerable<NoteItem> notes, CancellationToken cancellationToken = default)
    {
        await using var stream = new FileStream(_notesPath, FileMode.Create, FileAccess.Write, FileShare.None);
        await JsonSerializer.SerializeAsync(stream, notes, new JsonSerializerOptions { WriteIndented = true }, cancellationToken).ConfigureAwait(false);
    }
}
