namespace ProyectoBase.Core
{
    public class Options
    {
        public string Path { get; set; } = string.Empty;
        public bool Verbose { get; set; } = false;

        // Preparado para expansión futura
        public Dictionary<string, object> Extended { get; set; } = new();
    }
}
