using System.IO;
using System.Text;
using DocumentDeduplicator.Models;

namespace DocumentDeduplicator.Services;

public class DeduplicationService
{
    private readonly FileService _fileService;

    public DeduplicationService(FileService fileService)
    {
        _fileService = fileService;
    }

    public IReadOnlyList<DeduplicationPreview> BuildPreview(IEnumerable<DuplicateBlock> duplicates, int minFiles, int minOccurrences)
    {
        return duplicates
            .Where(d => d.FileCount >= minFiles && d.Frequency >= minOccurrences)
            .Select((d, index) => new DeduplicationPreview($"Fragmento_{index + 1}", d.Text, d.Files, d.Frequency))
            .ToList();
    }

    public async Task ApplyAsync(IEnumerable<DeduplicationPreview> previews, bool usePlaceholders, string fragmentFolder, string backupFolder, CancellationToken cancellationToken = default)
    {
        Directory.CreateDirectory(fragmentFolder);
        Directory.CreateDirectory(backupFolder);
        var backedUp = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var preview in previews)
        {
            var fragmentPath = Path.Combine(fragmentFolder, preview.Label + ".txt");
            await File.WriteAllTextAsync(fragmentPath, preview.Text, cancellationToken).ConfigureAwait(false);

            foreach (var file in preview.Files)
            {
                if (!File.Exists(file))
                {
                    continue;
                }

                if (backedUp.Add(file))
                {
                    var backupTarget = Path.Combine(backupFolder, Path.GetFileName(file));
                    Directory.CreateDirectory(Path.GetDirectoryName(backupTarget)!);
                    File.Copy(file, backupTarget, overwrite: true);
                }

                var original = await _fileService.ReadAllTextAsync(file, cancellationToken).ConfigureAwait(false);
                var replacement = usePlaceholders ? $"[[REF:{preview.Label}]]" : string.Empty;
                var updated = original.Replace(preview.Text, replacement, StringComparison.OrdinalIgnoreCase);
                await _fileService.SaveTextAsync(updated, file, createBackup: false, cancellationToken).ConfigureAwait(false);
            }
        }
    }
}
