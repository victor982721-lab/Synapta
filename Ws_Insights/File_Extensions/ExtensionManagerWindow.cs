using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Windows;
using Ws_Insights.Models;

namespace Ws_Insights.File_Extensions;

public partial class ExtensionManagerWindow : Window
{
    // Colección observable usada por el XAML para mostrar categorías
    public ObservableCollection<CategoryViewModel> Categories { get; }

    public ExtensionManagerWindow(IEnumerable<ExtensionCategoryDefinition> definitions, IEnumerable<string> selectedExtensions)
    {
        InitializeComponent(); // Carga el XAML asociado

        // Normaliza extensiones seleccionadas previamente
        var selected = new HashSet<string>(selectedExtensions.Select(NormalizeExtension));

        // Convierte las definiciones en CategoryViewModel para el XAML
        Categories = new ObservableCollection<CategoryViewModel>(
            definitions.Select(def => new CategoryViewModel(def, selected)));

        DataContext = this; // Conecta propiedades con la UI
    }

    // Devuelve lista final de extensiones seleccionadas por el usuario
    public IReadOnlyCollection<string> SelectedExtensions => Categories
        .SelectMany(c => c.Options)           // Junta opciones de todas las categorías
        .Where(o => o.IsChecked)              // Filtra solo las seleccionadas
        .Select(o => o.Extension)             // Obtiene solo la extensión
        .Distinct()                           // Elimina duplicados
        .ToArray();

    private void OnAccept(object sender, RoutedEventArgs e)
    {
        DialogResult = true; // Indica que se aceptó
        Close();             // Cierra la ventana
    }

    private void OnCancel(object sender, RoutedEventArgs e)
    {
        DialogResult = false; // Indica cancelación
        Close();
    }

    // Marca todas las extensiones en todas las categorías
    private void OnSelectAll(object sender, RoutedEventArgs e)
    {
        foreach (var category in Categories)
            category.SetAll(true);
    }

    // Desmarca todas las extensiones
    private void OnClearAll(object sender, RoutedEventArgs e)
    {
        foreach (var category in Categories)
            category.SetAll(false);
    }

    // Normaliza extensiones: minúsculas, siempre con punto
    private static string NormalizeExtension(string ext)
    {
        if (string.IsNullOrWhiteSpace(ext))
            return string.Empty;

        return ext.StartsWith('.') ? ext.ToLowerInvariant() : $".{ext.ToLowerInvariant()}";
    }

    // Representa una categoría completa (p. ej. "Scripts")
    public sealed class CategoryViewModel : INotifyPropertyChanged
    {
        private readonly ObservableCollection<OptionViewModel> _options;

        public CategoryViewModel(ExtensionCategoryDefinition definition, HashSet<string> selected)
        {
            Name = definition.Name;               // Nombre de la categoría
            Description = definition.Description; // Descripción mostrada en UI

            // Crea una OptionViewModel por extensión
            _options = new ObservableCollection<OptionViewModel>(
                definition.Extensions.Select(ext =>
                {
                    var normalized = NormalizeExtension(ext);
                    return new OptionViewModel(normalized, selected.Contains(normalized));
                }));

            // Cada opción notifica cuando cambia su estado, para actualizar el modo tri-state
            foreach (var option in _options)
            {
                option.PropertyChanged += (_, _) => OnPropertyChanged(nameof(CategoryState));
            }
        }

        public string Name { get; }
        public string Description { get; }
        public ObservableCollection<OptionViewModel> Options => _options;

        // Estado tri-state de la categoría (true, false, null)
        public bool? CategoryState
        {
            get
            {
                if (_options.All(o => o.IsChecked))
                    return true;     // Todas seleccionadas
                if (_options.All(o => !o.IsChecked))
                    return false;    // Ninguna seleccionada
                return null;         // Estado mixto
            }
            set
            {
                if (value.HasValue)
                {
                    SetAll(value.Value);                // Selecciona o deselecciona todo
                    OnPropertyChanged(nameof(CategoryState));
                }
            }
        }

        // Marca o desmarca todas las extensiones dentro de la categoría
        public void SetAll(bool value)
        {
            foreach (var option in _options)
                option.IsChecked = value;

            OnPropertyChanged(nameof(CategoryState));
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        private void OnPropertyChanged(string name)
            => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }

    // Representa una extensión individual (p. ej. ".ps1")
    public sealed class OptionViewModel : INotifyPropertyChanged
    {
        private bool _isChecked; // Estado del checkbox

        public OptionViewModel(string extension, bool isChecked)
        {
            Extension = extension; // Nombre de la extensión
            _isChecked = isChecked;
        }

        public string Extension { get; }
        public string Display => Extension; // Texto mostrado en UI

        public bool IsChecked
        {
            get => _isChecked;
            set
            {
                if (_isChecked == value) return; // Evita notificación redundante
                _isChecked = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsChecked)));
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;
    }
}