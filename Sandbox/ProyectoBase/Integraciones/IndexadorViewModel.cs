using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using Indexador.Core;

namespace ProyectoBase.Integraciones
{
    public class IndexadorViewModel : INotifyPropertyChanged
    {
        private readonly IndexManager _manager;
        private bool _isBusy;
        private string _status = "No cargado";
        private string _rootPath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        private string _databasePath = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "indexador.db");

        public ObservableCollection<ArchivoDto> Registros { get; } = new();
        public ObservableCollection<GrupoDuplicadoDto> Duplicados { get; } = new();

        public ICommand RefrescarCommand { get; }
        public ICommand MostrarDuplicadosCommand { get; }

        public string RootPath
        {
            get => _rootPath;
            set => SetProperty(ref _rootPath, value);
        }

        public string DatabasePath
        {
            get => _databasePath;
            set => SetProperty(ref _databasePath, value);
        }

        public string Status
        {
            get => _status;
            private set => SetProperty(ref _status, value);
        }

        public bool IsBusy
        {
            get => _isBusy;
            private set => SetProperty(ref _isBusy, value);
        }

        public IndexadorViewModel(IndexManager manager)
        {
            _manager = manager ?? throw new ArgumentNullException(nameof(manager));
            RefrescarCommand = new RelayCommand(async () => await RefrescarAsync(), () => !IsBusy);
            MostrarDuplicadosCommand = new RelayCommand(MostrarDuplicados, () => Registros.Any());
        }

        public async Task RefrescarAsync()
        {
            if (IsBusy) return;
            IsBusy = true;
            Status = "Cargando registros...";
            try
            {
                var records = await Task.Run(() => _manager.GetRecords(RootPath, DatabasePath));
                Registros.Clear();
                foreach (var record in records)
                {
                    Registros.Add(new ArchivoDto(record));
                }
                Status = $"Cargados {Registros.Count} archivos.";
            }
            catch (Exception ex)
            {
                Status = $"Error: {ex.Message}";
            }
            finally
            {
                IsBusy = false;
            }
        }

        private void MostrarDuplicados()
        {
            var duplicates = _manager.FindDuplicates(Registros.Select(r => r.ToIndexRecord())).ToList();
            Duplicados.Clear();
            foreach (var group in duplicates)
            {
                Duplicados.Add(new GrupoDuplicadoDto(group.Key, group.Select(r => new ArchivoDto(r)).ToList()));
            }
            Status = $"Detectados {Duplicados.Sum(g => g.Archivos.Count)} archivos duplicados.";
        }

        private void SetProperty<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
        {
            if (Equals(field, value)) return;
            field = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public event PropertyChangedEventHandler? PropertyChanged;
    }

    public sealed record ArchivoDto(string Nombre, long Tamano, DateTime Modificado, string Hash)
    {
        public ArchivoDto(IndexRecord record) : this(record.RelativePath, record.Size, record.LastWriteUtc, record.Hash) { }

        public IndexRecord ToIndexRecord() =>
            new()
            {
                RelativePath = Nombre,
                Size = Tamano,
                LastWriteUtc = Modificado,
                Hash = Hash
            };
    }

    public sealed record GrupoDuplicadoDto(string Hash, List<ArchivoDto> Archivos);

    public sealed class RelayCommand : ICommand
    {
        private readonly Func<bool> _canExecute;
        private readonly Action _execute;

        public RelayCommand(Action execute, Func<bool>? canExecute = null)
        {
            _execute = execute;
            _canExecute = canExecute ?? (() => true);
        }

        public event EventHandler? CanExecuteChanged;

        public bool CanExecute(object? parameter) => _canExecute();

        public void Execute(object? parameter) => _execute();

        public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
    }
}
