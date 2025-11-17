using Deduplinside.Infrastructure;

namespace Deduplinside.Models;

public class FileExtensionOption : ObservableObject
{
    private bool _isChecked;

    public FileExtensionOption(string extension, bool isChecked = true)
    {
        Extension = extension;
        _isChecked = isChecked;
    }

    public string Extension { get; }

    public bool IsChecked
    {
        get => _isChecked;
        set => SetProperty(ref _isChecked, value);
    }
}
