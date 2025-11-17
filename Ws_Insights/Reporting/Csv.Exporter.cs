using System.Collections.ObjectModel; // Para ObservableCollection<T>, usada por los resultados
using System.Globalization;          // Para ToString invariable en SizeBytes
using System.IO;                     // Para File.WriteAllTextAsync
using System.Text;                   // Para StringBuilder y UTF8Encoding
using Ws_Insights.Models;            // Define FileMatch

namespace Ws_Insights.Reporting;      // Carpeta lógica: Ws_Insights/Reporting/

// ============================================================================
// CsvExporter
// ============================================================================
// Genera un archivo CSV desde una colección de FileMatch.
// Produce encabezados y asegura escape correcto para comillas y comas.
// ============================================================================

internal static class CsvExporter
{
    public static Task ExportAsync(string destination, ObservableCollection<FileMatch> matches)
    {
        var sb = new StringBuilder();                         // Buffer para armar el CSV en memoria
        sb.AppendLine("Nombre,Extensión,Tamaño (bytes),Ruta,Fragmento"); // Línea de encabezados

        foreach (var match in matches)                        // Recorre cada resultado
        {
            // Crea una línea CSV usando coma como separador y aplicando Escape() a cada campo
            sb.AppendLine(string.Join(',',
                Escape(match.Name),                            // Nombre del archivo
                Escape(match.Extension),                       // Extensión (ej: .txt)
                match.SizeBytes.ToString(CultureInfo.InvariantCulture), // Tamaño en bytes
                Escape(match.FullPath),                        // Ruta completa
                Escape(match.Snippet)));                       // Fragmento de texto donde coincidió
        }

        // Escribe archivo en UTF-8 con BOM → compatible con Excel y herramientas comunes
        return File.WriteAllTextAsync(destination, sb.ToString(), new UTF8Encoding(true));
    }

    // =========================================================================
    // Escape(string value)
    // =========================================================================
    // CSV estándar: si un campo contiene comillas o comas, se debe encerrar entre comillas
    // y duplicar cada comilla interna según el estándar RFC4180.
    //
    // Ejemplo:
    //   valor: Hola, "mundo"
    //   CSV:   "Hola, ""mundo"""
    // =========================================================================
    private static string Escape(string value)
    {
        // ¿Contiene comillas o comas? → requiere escape
        if (value.Contains('\"') || value.Contains(','))
        {
            return $"\"{value.Replace("\"", "\"\"")}\""; // "valor" → ""valor""
        }

        // Si no requiere manipulación, devolver tal cual
        return value;
    }
}
