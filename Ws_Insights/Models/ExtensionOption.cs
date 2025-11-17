using System.ComponentModel;
// Importa INotifyPropertyChanged, interfaz para notificar cambios de propiedades a la UI.

namespace Ws_Insights.Models;
// Define el namespace.

public sealed class ExtensionOption : INotifyPropertyChanged
// Clase sellada (sealed) que implementa INotifyPropertyChanged para soportar binding WPF.
{
    private bool _isChecked;
    // Campo privado que almacena el valor real del checkbox.

    public ExtensionOption(string extension, bool isChecked)
    // Constructor: recibe la extensión y si está seleccionada.
    {
        Extension = extension;
        _isChecked = isChecked;
    }

    public string Extension { get; }
    // Propiedad de solo lectura; nombre de la extensión asociada (".txt", ".json", etc.).

    public bool IsChecked
    // Propiedad observable para saber si esta extensión está marcada.
    {
        get => _isChecked;
        // Devuelve el estado actual.
        set
        {
            if (_isChecked == value) return;
            // Si el valor no cambió, no hace nada.

            _isChecked = value;
            // Actualiza el campo.

            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsChecked)));
            // Dispara el evento para que la UI actualice el binding.
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    // Evento requerido por INotifyPropertyChanged; lo escuchan los bindings WPF.
}
