// Archivo: ExtensionManagerWindow.cs

using System.Collections.Generic;              // Permite usar IEnumerable, List, HashSet
using System.Collections.ObjectModel;          // Proporciona ObservableCollection para datos que notifican cambios a la UI
using System.ComponentModel;                   // Permite implementar INotifyPropertyChanged para notificaciones de cambio
using System.Linq;                             // Permite consultas LINQ (Select, Where, All, etc.)
using System.Windows;                          // Tipos base de WPF, como Window, RoutedEventArgs
using Ws_Insights.Models;                      // Importa modelos personalizados del proyecto

namespace Ws_Insights.File_Extensions;          // Espacio de nombres donde vive esta ventana


public partial class ExtensionManagerWindow : Window   // Declara una ventana WPF parcial (con archivo XAML asociado)
{
    // Colección observable usada por el XAML para mostrar categorías
    public ObservableCollection<CategoryViewModel> Categories { get; }


    public ExtensionManagerWindow(IEnumerable<ExtensionCategoryDefinition> definitions, IEnumerable<string> selectedExtensions)
    {
        InitializeComponent();                           // Carga el XAML asociado a esta ventana

        // Normaliza extensiones seleccionadas previamente
        var selected = new HashSet<string>(selectedExtensions.Select(NormalizeExtension));

        // Convierte las definiciones en CategoryViewModel para el XAML
        Categories = new ObservableCollection<CategoryViewModel>(
            definitions.Select(def => new CategoryViewModel(def, selected)));  // Genera viewmodels por categoría

        DataContext = this;                             // Expone propiedades de esta clase al XAML
    }


    // Devuelve lista final de extensiones seleccionadas por el usuario
    public IReadOnlyCollection<string> SelectedExtensions => Categories
        .SelectMany(c => c.Options)                     // Junta todas las opciones de todas las categorías
        .Where(o => o.IsChecked)                        // Solo las seleccionadas
        .Select(o => o.Extension)                       // Se queda solo con el texto de la extensión
        .Distinct()                                     // Quita duplicados
        .ToArray();                                     // Devuelve un array


    private void OnAccept(object sender, RoutedEventArgs e)
    {
        DialogResult = true;                            // Marca el diálogo como "aceptado"
        Close();                                        // Cierra la ventana
    }


    private void OnCancel(object sender, RoutedEventArgs e)
    {
        DialogResult = false;                           // Marca el diálogo como "cancelado"
        Close();                                        // Cierra la ventana
    }


    // Marca todas las extensiones en todas las categorías
    private void OnSelectAll(object sender, RoutedEventArgs e)
    {
        foreach (var category in Categories)            // Recorre todas las categorías
            category.SetAll(true);                      // Selecciona todas las opciones de esa categoría
    }


    // Desmarca todas las extensiones
    private void OnClearAll(object sender, RoutedEventArgs e)
    {
        foreach (var category in Categories)            // Recorre todas las categorías
            category.SetAll(false);                     // Desmarca todas las opciones
    }


    // Normaliza extensiones: minúsculas, siempre con punto
    private static string NormalizeExtension(string ext)
    {
        if (string.IsNullOrWhiteSpace(ext))             // Si es vacío o nulo
            return string.Empty;                        // Devuelve cadena vacía

        return ext.StartsWith('.')                      // Si ya comienza con punto…
            ? ext.ToLowerInvariant()                    // …solo convierte a minúsculas
            : $".{ext.ToLowerInvariant()}";              // Si no, le agrega punto y minúsculas
    }



    // Representa una categoría completa (p. ej. "Scripts")
    public sealed class CategoryViewModel : INotifyPropertyChanged
    {
        private readonly ObservableCollection<OptionViewModel> _options;   // Opciones internas de esta categoría


        public CategoryViewModel(ExtensionCategoryDefinition definition, HashSet<string> selected)
        {
            Name = definition.Name;                     // Nombre de la categoría
            Description = definition.Description;       // Texto descriptivo para la UI

            // Crea una OptionViewModel por cada extensión definida
            _options = new ObservableCollection<OptionViewModel>(
                definition.Extensions.Select(ext =>
                {
                    var normalized = NormalizeExtension(ext);             // Normaliza
                    return new OptionViewModel(normalized, selected.Contains(normalized)); // Marca si estaba seleccionada
                }));

            // Cada opción notifica cuando cambia, para recalcular el estado tri-state de la categoría
            foreach (var option in _options)
            {
                option.PropertyChanged += (_, _) => OnPropertyChanged(nameof(CategoryState)); // Recalcula estado
            }
        }


        public string Name { get; }                     // Nombre visible en UI
        public string Description { get; }              // Descripción en UI
        public ObservableCollection<OptionViewModel> Options => _options; // Lista observable de opciones


        // Estado tri-state de la categoría (true = todas, false = ninguna, null = mixto)
        public bool? CategoryState
        {
            get
            {
                if (_options.All(o => o.IsChecked))     // Todas seleccionadas
                    return true;
                if (_options.All(o => !o.IsChecked))    // Ninguna seleccionada
                    return false;
                return null;                            // Estado mixto
            }
            set
            {
                if (value.HasValue)                     // Solo actúa si hay valor (true o false)
                {
                    SetAll(value.Value);                // Aplica selección masiva
                    OnPropertyChanged(nameof(CategoryState)); // Notifica cambio
                }
            }
        }


        // Marca o desmarca todas las extensiones dentro de la categoría
        public void SetAll(bool value)
        {
            foreach (var option in _options)            // Recorre todas las opciones
                option.IsChecked = value;               // Cambia el estado

            OnPropertyChanged(nameof(CategoryState));    // Notifica recálculo de tri‑state
        }


        public event PropertyChangedEventHandler? PropertyChanged;   // Evento estándar INotifyPropertyChanged


        private void OnPropertyChanged(string name)     // Método auxiliar para disparar notificaciones
            => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }



    // Representa una extensión individual (p. ej. ".ps1")
    public sealed class OptionViewModel : INotifyPropertyChanged
    {
        private bool _isChecked;                        // Estado del checkbox individual


        public OptionViewModel(string extension, bool isChecked)
        {
            Extension = extension;                      // Texto de la extensión (p.ej. .txt)
            _isChecked = isChecked;                     // Estado inicial
        }


        public string Extension { get; }                // Extensión normalizada
        public string Display => Extension;             // Texto mostrado en UI


        public bool IsChecked
        {
            get => _isChecked;                          // Obtiene estado
            set
            {
                if (_isChecked == value) return;        // Si no cambió, no notifica
                _isChecked = value;                     // Actualiza estado
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(IsChecked))); // Notifica a la UI
            }
        }


        public event PropertyChangedEventHandler? PropertyChanged;  // Evento de cambio
    }
}