using System.IO;
using Deduplinside.Infrastructure;

namespace Deduplinside.Models;

public class FileItem : ObservableObject
{
    private bool _isQueued = true;

    public FileItem(string path)
    {
        FullPath = path;
        Name = Path.GetFileName(path);
        if (File.Exists(path))
        {
            var info = new FileInfo(path);
            Size = info.Length;
            LastModified = info.LastWriteTime;
        }
    }

    public string FullPath { get; }

    public string Name { get; }

    public long Size { get; }

    public DateTime LastModified { get; }

    public bool IsQueued
    {
        get => _isQueued;
        set => SetProperty(ref _isQueued, value);
    }
}
