// File: Program.cs
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

internal sealed class FileNode
{
    public string Name { get; set; } = "";
    public string FullPath { get; set; } = "";
    public long Length { get; set; }
    public DateTime LastWriteTime { get; set; }
    public DateTime CreationTime { get; set; }
    public string? Md5 { get; set; }
    public string? Description { get; set; }
    public string? Error { get; set; }
}

internal sealed class DirNode
{
    public string Name { get; set; } = "";
    public string FullPath { get; set; } = "";
    public List<DirNode> Directories { get; } = new();
    public List<FileNode> Files { get; } = new();
}

internal sealed class ProgressState
{
    public long TotalBytes;
    public int TotalFiles;
    public long ProcessedBytes;
    public int ProcessedFiles;
}

internal static class Program
{
    // Control de paralelismo: cambia este valor a gusto.
    private const int MaxDegreeOfParallelism = 4;
    private const int ReadBufferSize = 1024 * 1024; // 1 MB por bloque

    [STAThread]
    private static void Main(string[] args)
    {
        Console.OutputEncoding = Encoding.UTF8;

        var rootPath = SelectFolder();
        if (rootPath is null)
        {
            Console.WriteLine("No se seleccionó ninguna carpeta. Saliendo.");
            return;
        }

        Console.WriteLine($"📂 Carpeta seleccionada: {rootPath}");
        Console.WriteLine("🔍 Escaneando árbol de archivos...\n");

        var allFiles = new List<FileNode>();
        var rootNode = ScanDirectory(rootPath, allFiles, out long totalBytes);
        int totalFiles = allFiles.Count;

        if (totalFiles == 0)
        {
            Console.WriteLine("La carpeta no contiene archivos.");
            return;
        }

        var state = new ProgressState
        {
            TotalBytes = totalBytes,
            TotalFiles = totalFiles
        };

        Console.WriteLine($"📊 Resumen inicial: {totalFiles} archivos, {FormatBytes(totalBytes)} totales.");
        Console.WriteLine("⚙️ Iniciando mapeado paralelo y cálculo de hashes MD5...\n");

        var cts = new CancellationTokenSource();
        var progressTask = Task.Run(() => ShowProgress(state, cts.Token));

        var parallelOptions = new ParallelOptions
        {
            MaxDegreeOfParallelism = MaxDegreeOfParallelism
        };

        var swGlobal = Stopwatch.StartNew();

        Parallel.ForEach(allFiles, parallelOptions, fileNode =>
        {
            try
            {
                ProcessFile(fileNode, state);
            }
            catch (Exception ex)
            {
                fileNode.Error = ex.Message;
            }
        });

        swGlobal.Stop();
        cts.Cancel();
        try { progressTask.Wait(); } catch { /* ignorar */ }

        Console.WriteLine();
        Console.WriteLine($"✅ Completado en {swGlobal.Elapsed:hh\\:mm\\:ss}.");
        Console.WriteLine();

        PrintTree(rootNode);
    }

    private static string? SelectFolder()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        using var dlg = new FolderBrowserDialog
        {
            Description = "Selecciona la carpeta que deseas mapear",
            UseDescriptionForTitle = true,
            ShowNewFolderButton = false
        };

        var result = dlg.ShowDialog();
        if (result != DialogResult.OK || string.IsNullOrWhiteSpace(dlg.SelectedPath))
            return null;

        return dlg.SelectedPath;
    }

    private static DirNode ScanDirectory(string path, List<FileNode> allFiles, out long totalBytes)
    {
        var rootDirInfo = new DirectoryInfo(path);
        var root = new DirNode
        {
            Name = rootDirInfo.Name,
            FullPath = rootDirInfo.FullName
        };

        totalBytes = 0;

        void Recurse(DirectoryInfo dir, DirNode node)
        {
            DirectoryInfo[] subDirs;
            FileInfo[] files;

            try
            {
                subDirs = dir.GetDirectories();
            }
            catch
            {
                return;
            }

            try
            {
                files = dir.GetFiles();
            }
            catch
            {
                files = Array.Empty<FileInfo>();
            }

            foreach (var f in files)
            {
                var fn = new FileNode
                {
                    Name = f.Name,
                    FullPath = f.FullName,
                    Length = f.Length,
                    LastWriteTime = f.LastWriteTime,
                    CreationTime = f.CreationTime
                };

                node.Files.Add(fn);
                allFiles.Add(fn);
                totalBytes += f.Length;
            }

            foreach (var sd in subDirs)
            {
                var child = new DirNode
                {
                    Name = sd.Name,
                    FullPath = sd.FullName
                };
                node.Directories.Add(child);
                Recurse(sd, child);
            }
        }

        Recurse(rootDirInfo, root);
        return root;
    }

    private static void ProcessFile(FileNode node, ProgressState state)
    {
        using var md5 = MD5.Create();

        using (var fs = new FileStream(
                   node.FullPath,
                   FileMode.Open,
                   FileAccess.Read,
                   FileShare.Read,
                   ReadBufferSize,
                   FileOptions.SequentialScan))
        {
            var buffer = new byte[ReadBufferSize];
            int read;

            while ((read = fs.Read(buffer, 0, buffer.Length)) > 0)
            {
                md5.TransformBlock(buffer, 0, read, null, 0);
                Interlocked.Add(ref state.ProcessedBytes, read);
            }

            md5.TransformFinalBlock(Array.Empty<byte>(), 0, 0);
        }

        node.Md5 = Convert.ToHexString(md5.Hash ?? Array.Empty<byte>());
        node.Description = AnalyzeContent(node);

        Interlocked.Increment(ref state.ProcessedFiles);
    }

    private static string AnalyzeContent(FileNode node)
    {
        string ext = Path.GetExtension(node.Name).ToLowerInvariant();
        string baseInfo = $"📏 {FormatBytes(node.Length)} | 🕒 {node.LastWriteTime:g}";

        try
        {
            if (ext is ".txt" or ".md" or ".log")
            {
                string textPreview;

                using (var reader = new StreamReader(node.FullPath, Encoding.UTF8, true, 4096))
                {
                    char[] buffer = new char[400];
                    int read = reader.Read(buffer, 0, buffer.Length);
                    textPreview = new string(buffer, 0, read);
                }

                textPreview = textPreview.Replace("\r", " ").Replace("\n", " ");
                if (textPreview.Length > 120)
                    textPreview = textPreview[..120] + "…";

                return $"📝 Texto | {baseInfo} | \"{textPreview}\"";
            }

            if (ext is ".json" or ".yaml" or ".yml" or ".xml" or ".ini" or ".config")
                return $"🧩 Configuración {ext} | {baseInfo}";

            if (ext is ".cs" or ".js" or ".ts" or ".cpp" or ".h" or ".java" or ".py")
                return $"⚙️ Código {ext} | {baseInfo}";

            if (ext is ".png" or ".jpg" or ".jpeg" or ".gif" or ".bmp" or ".svg" or ".webp")
                return $"🖼 Imagen | {baseInfo}";

            if (ext is ".mp3" or ".wav" or ".flac" or ".ogg")
                return $"🎵 Audio | {baseInfo}";

            if (ext is ".mp4" or ".mkv" or ".avi" or ".mov")
                return $"🎬 Video | {baseInfo}";

            return $"📦 Archivo {ext} | {baseInfo}";
        }
        catch (Exception ex)
        {
            return $"⚠️ No se pudo analizar el contenido: {ex.Message}";
        }
    }

    private static void ShowProgress(ProgressState state, CancellationToken token)
    {
        var sw = Stopwatch.StartNew();

        while (!token.IsCancellationRequested)
        {
            long processedBytes = Interlocked.Read(ref state.ProcessedBytes);
            int processedFiles = Volatile.Read(ref state.ProcessedFiles);

            double elapsed = Math.Max(sw.Elapsed.TotalSeconds, 0.1);
            double mbps = (processedBytes / 1024.0 / 1024.0) / elapsed;
            double fps = processedFiles / elapsed;

            long remainingBytes = state.TotalBytes - processedBytes;
            if (remainingBytes < 0) remainingBytes = 0;

            int remainingFiles = state.TotalFiles - processedFiles;
            if (remainingFiles < 0) remainingFiles = 0;

            double percent = state.TotalBytes > 0
                ? Math.Clamp(processedBytes * 100.0 / state.TotalBytes, 0.0, 100.0)
                : 0.0;

            TimeSpan eta = (mbps > 0 && remainingBytes > 0)
                ? TimeSpan.FromSeconds((remainingBytes / 1024.0 / 1024.0) / mbps)
                : TimeSpan.Zero;

            string line =
                $"⏱ Progreso: {percent,6:0.00}% | " +
                $"📦 {processedFiles}/{state.TotalFiles} archivos " +
                $"({FormatBytes(processedBytes)}/{FormatBytes(state.TotalBytes)}) | " +
                $"🚀 {mbps,6:0.00} MB/s | " +
                $"📁 {fps,6:0.0} arch/s | " +
                $"⌛ Restantes: {remainingFiles} | " +
                $"⏳ ETA: {FormatTimeSpan(eta)}";

            int width;
            try
            {
                width = Console.BufferWidth;
            }
            catch
            {
                width = 120;
            }

            if (line.Length > width - 1)
                line = line[..(width - 1)];

            Console.Write("\r" + line.PadRight(width - 1));

            Thread.Sleep(200);
        }
    }

    private static void PrintTree(DirNode root)
    {
        Console.WriteLine("🧭 Mapa de archivos (árbol ASCII):");
        Console.WriteLine();
        Console.WriteLine($"📂 {root.Name}");
        PrintChildren(root, "");
    }

    private static void PrintChildren(DirNode node, string indent)
    {
        int totalChildren = node.Directories.Count + node.Files.Count;
        int index = 0;

        foreach (var dir in node.Directories)
        {
            bool isLast = ++index == totalChildren;
            string branch = isLast ? "└──" : "├──";

            Console.WriteLine($"{indent}{branch} 📂 {dir.Name}");

            string childIndent = indent + (isLast ? "    " : "│   ");
            PrintChildren(dir, childIndent);
        }

        foreach (var file in node.Files)
        {
            bool isLast = ++index == totalChildren;
            string branch = isLast ? "└──" : "├──";

            string meta;
            if (file.Error is not null)
            {
                meta = $"⚠️ Error: {file.Error}";
            }
            else
            {
                string md5Short = file.Md5 is { Length: >= 16 } ? file.Md5[..16] + "…" : (file.Md5 ?? "N/D");
                meta = $"🔐 MD5: {md5Short} | {file.Description}";
            }

            Console.WriteLine($"{indent}{branch} 📄 {file.Name} | {meta}");
        }
    }

    private static string FormatBytes(long bytes)
    {
        const long KB = 1024;
        const long MB = KB * 1024;
        const long GB = MB * 1024;

        if (bytes >= GB) return $"{bytes / (double)GB:0.00} GB";
        if (bytes >= MB) return $"{bytes / (double)MB:0.00} MB";
        if (bytes >= KB) return $"{bytes / (double)KB:0.00} KB";
        return $"{bytes} B";
    }

    private static string FormatTimeSpan(TimeSpan t)
    {
        if (t.TotalHours >= 1)
            return t.ToString(@"hh\:mm\:ss");
        if (t.TotalMinutes >= 1)
            return t.ToString(@"mm\:ss");
        return $"{Math.Max(0, (int)t.TotalSeconds)} s";
    }
}
