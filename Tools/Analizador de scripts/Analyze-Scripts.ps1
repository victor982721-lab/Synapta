#Requires -Version 7.0
<#
.SYNOPSIS
    Analiza scripts PowerShell y Python de forma concurrente y en streaming.

.DESCRIPTION
    Recorrerá el árbol indicado, deteniéndose solo en archivos *.ps1, *.psm1 y *.py.
    Cada archivo se procesa con ForEach-Object -Parallel (ThrottleLimit 6) para
    aprovechar múltiples núcleos y evitar almacenamiento de grandes cantidades de datos
    mientras se sigue entregando el resultado en una tabla y opcionalmente en CSV/JSON.

.PARAMETER RootPath
    Carpeta raíz desde la que se analizará el árbol.

.PARAMETER OutputPath
    Ruta opcional a CSV o JSON donde se guardará el resumen final.
#>
param(
    [string]$RootPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath,
    [string]$ResultsDir
)

if (-not (Test-Path $RootPath)) {
    Write-Error "No existe la ruta raiz: $RootPath"
    exit 1
}

$helperModulePath = Join-Path $PSScriptRoot 'FunctionSpecHelper.psm1'
if (-not (Test-Path $helperModulePath)) {
    Write-Error "Falta el módulo de especificaciones de funciones en $helperModulePath"
    exit 1
}

Import-Module $helperModulePath -ErrorAction SilentlyContinue | Out-Null

$pythonAnalyzer = @'
import ast
import collections
import json
import pathlib
import sys

INTERESTING = [
    'subprocess.run', 'subprocess.Popen', 'subprocess.call',
    'os.system', 'os.popen', 'os.remove', 'os.rmdir', 'shutil.rmtree',
    'requests.get', 'requests.post', 'requests.put', 'requests.delete',
    'httpx.get', 'httpx.post', 'open', 'input', 'exec', 'eval',
]

def qname(node):
    parts = []
    while isinstance(node, ast.Attribute):
        parts.append(node.attr)
        node = node.value
    if isinstance(node, ast.Name):
        parts.append(node.id)
    if parts:
        return '.'.join(reversed(parts))
    return None

def unique(items, limit):
    seen = set()
    count = 0
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        yield item
        count += 1
        if limit and count >= limit:
            break

def safe_read(path):
    try:
        return path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        return path.read_text(encoding='latin-1', errors='ignore')

path = pathlib.Path(sys.argv[1])
text = safe_read(path)
try:
    tree = ast.parse(text, filename=str(path))
except Exception as exc:
    payload = {
        'Script': str(path),
        'Functions': '',
        'FunctionCount': 0,
        'Interesting': '',
        'Commands': '',
        'FunctionSpecCount': 0,
        'FunctionSpecSummary': '',
        'FunctionSpecs': [],
        'FunctionSpecPath': '',
        'ParseErrors': f'{exc.__class__.__name__}: {exc}',
    }
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(0)

functions = sorted({node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)})
calls = []
for node in ast.walk(tree):
    if isinstance(node, ast.Call):
        name = qname(node.func)
        if name:
            calls.append(name)

counter = collections.Counter(calls)
interest_hits = []
for candidate in INTERESTING:
    total = sum(cnt for command, cnt in counter.items()
                if command == candidate or command.endswith('.' + candidate))
    if total:
        interest_hits.append(f'{candidate} (x{total})')

commands = ', '.join(unique(calls, 25))
payload = {
    'Script': str(path),
    'Functions': ', '.join(functions),
    'FunctionCount': len(functions),
    'Interesting': '; '.join(interest_hits),
    'Commands': commands,
    'FunctionSpecCount': 0,
    'FunctionSpecSummary': '',
    'FunctionSpecs': [],
    'FunctionSpecPath': '',
    'ParseErrors': '',
}
print(json.dumps(payload, ensure_ascii=False))
'@

$pythonHelperPath = Join-Path ([IO.Path]::GetTempPath()) 'neurologic_analyze_python.py'
$pythonAnalyzer | Set-Content -LiteralPath $pythonHelperPath -Encoding UTF8 -Force

$pythonExecutables = [System.Collections.Generic.List[string]]::new()

try {
    $defaultPython = (& python -c "import sys; print(sys.executable)" 2>$null).Trim()
    if ($defaultPython -and (Test-Path $defaultPython)) {
        $pythonExecutables.Add($defaultPython)
    }
} catch {
}

try {
    $pyList = & py -0p 2>$null
    foreach ($line in $pyList) {
        if ($line -match '([A-Za-z]:\\[^ ]+\.exe)') {
            $candidate = $matches[1]
            if ((Test-Path $candidate) -and -not $pythonExecutables.Contains($candidate)) {
                $pythonExecutables.Add($candidate)
            }
        }
    }
} catch {
}

$interestingCommands = @(
    'Invoke-WebRequest','Invoke-RestMethod','Invoke-Expression','Invoke-Command',
    'Start-Process','Read-Host','Invoke-Item','New-Object','Add-Type',
    'git','dotnet','gh','Set-StrictMode','Set-ExecutionPolicy','curl'
)

function Try-FixPowerShellParse {
    param([System.IO.FileInfo]$File)

    Import-Module -Name PSScriptAnalyzer -ErrorAction SilentlyContinue | Out-Null
    if (-not (Get-Module -Name PSScriptAnalyzer -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        Invoke-ScriptAnalyzer -Path $File.FullName -Fix -ErrorAction Stop | Out-Null
        if (Get-Command Invoke-Formatter -ErrorAction SilentlyContinue) {
            Invoke-Formatter -Path $File.FullName -Force -ErrorAction Stop | Out-Null
        }
        return $true
    } catch {
        return $false
    }
}

if (-not $ResultsDir) {
    $ResultsDir = Join-Path $RootPath 'analysis-output'
}

function Save-FunctionSpecs {
    param(
        [string]$ScriptPath,
        [array]$Specs,
        [string]$DestDir
    )

    if (-not $Specs) { return $null }

    $folder = Join-Path $DestDir ([IO.Path]::GetFileNameWithoutExtension($ScriptPath))
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
    $targetFile = Join-Path $folder "function-specs.json"
    $Specs | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $targetFile -Encoding UTF8
    return $targetFile
}

function Write-MarkdownReport {
    param(
        [array]$Rows,
        [string]$DestDir
    )

    $md = @()
    $md += "# Reporte de análisis"
    $md += ""
    $md += "Generado el $(Get-Date -Format 'u') para el raíz `$RootPath`."
    $md += ""
    foreach ($row in $Rows) {
        $md += "## $(Split-Path $row.Script -Leaf)"
        $md += ""
        $md += "- **Funciones detectadas**: $($row.FunctionCount)"
        $md += "- **FunctionSpecs**: $($row.FunctionSpecCount) (`$($row.FunctionSpecPath)`)"
        if ($row.ParseErrors) {
            $md += "- **Errores**: $($row.ParseErrors)"
        }
        if ($row.Interesting) {
            $md += "- **Comandos interesantes**: $($row.Interesting)"
        }
        $md += ""
        $md += "### Objetos clave"
        $md += ""
        $md += "| Clave | Valor |"
        $md += "| --- | --- |"
        $md += "| Funciones | $($row.Functions) |"
        $md += "| Comandos | $($row.Commands) |"
        $md += "| FunctionSpecSummary | $($row.FunctionSpecSummary) |"
        $md += "| Ruta specs | $($row.FunctionSpecPath) |"
        $md += ""
        if ($row.ParseErrors) {
            $md += "### Recomendaciones"
            $md += ""
            $md += "- Revisar el error anterior y ejecutar `Invoke-ScriptAnalyzer -Fix` o corregir la sintaxis manualmente."
        }
        $md += ""
    }

    $mdPath = Join-Path $DestDir "summary.md"
    $md -join "`n" | Set-Content -LiteralPath $mdPath -Encoding UTF8
    return $mdPath
}

$analysisBlock = {
    param([System.IO.FileInfo]$file)
    $extension = [IO.Path]::GetExtension($file.FullName).ToLowerInvariant()

    if ($extension -eq '.py') {
        if (-not $pythonExecutables) {
            return [pscustomobject]@{
                Script        = $file.FullName
                Functions     = ''
                FunctionCount = 0
                Interesting   = ''
                Commands      = ''
                ParseErrors   = 'No se encontro Python 3 en el entorno.'
            }
        }

        $pythonOutput = $null
        $launcherError = $null

        foreach ($exe in $pythonExecutables) {
            try {
                $pythonOutput = & $exe $pythonHelperPath $file.FullName
                break
            } catch [System.ComponentModel.Win32Exception] {
                $launcherError = $_.Exception.Message
            } catch {
                $launcherError = $_.Exception.Message
            }
        }

        if (-not $pythonOutput) {
            $errorMessage = if ($launcherError) { $launcherError } else { 'No se encontro un lanzador Python 3 valido.' }
            return [pscustomobject]@{
                Script        = $file.FullName
                Functions     = ''
                FunctionCount = 0
                Interesting   = ''
                Commands      = ''
                FunctionSpecCount = 0
                FunctionSpecSummary = ''
                FunctionSpecs = @()
                FunctionSpecPath = ''
                ParseErrors   = $errorMessage
            }
        }

        $jsonText = if ($pythonOutput -is [System.Array]) { $pythonOutput -join "`n" } else { $pythonOutput }
        try {
            $parsed = $jsonText | ConvertFrom-Json
            $parsed.Script = $file.FullName
            return $parsed
        } catch {
            return [pscustomobject]@{
                Script        = $file.FullName
                Functions     = ''
                FunctionCount = 0
                Interesting   = ''
                Commands      = ''
                FunctionSpecCount = 0
                FunctionSpecSummary = ''
                FunctionSpecs = @()
                FunctionSpecPath = ''
                ParseErrors   = $_.Exception.Message
            }
        }
    }

    $parseErrors = $null
    $attempt = 0
    $ast = $null
    while ($attempt -lt 2) {
        $tokens = $null
        $errors = $null
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$tokens, [ref]$errors
            )
            $parseErrors = $null
            break
        } catch {
            $parseErrors = $_.Exception.Message
            if ($attempt -eq 0 -and (Try-FixPowerShellParse -File $file)) {
                $attempt++
                continue
            }
            $ast = $null
            break
        }
    }

    if (-not $ast) {
        return [pscustomobject]@{
            Script        = $file.FullName
            Functions     = ''
            FunctionCount = 0
            Interesting   = ''
            Commands      = ''
            ParseErrors   = $parseErrors
        }
    }

    $functions = $ast.FindAll({
        param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true) | ForEach-Object { $_.Name } | Sort-Object -Unique

    $functionSpecs = @()
    try {
        $functionSpecs = Get-FunctionSpecsFromAst -Ast $ast
    } catch {
        $functionSpecs = @()
    }
    $functionSpecSummary = if ($functionSpecs) { ($functionSpecs | ForEach-Object { $_.Nombre }) -join '; ' } else { '' }
    $functionSpecPath = Save-FunctionSpecs -ScriptPath $file.FullName -Specs $functionSpecs -DestDir $ResultsDir

    $commandAsts = $ast.FindAll({
        param($node) $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)

    $commandNames = $commandAsts |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { $_ } |
        Sort-Object

    $interestingHits = $commandNames |
        Where-Object { $interestingCommands -contains $_ } |
        Group-Object |
        ForEach-Object { "{0} (x{1})" -f $_.Name, $_.Count }

    return [pscustomobject]@{
        Script        = $file.FullName
        Functions     = ($functions -join ', ')
        FunctionCount = $functions.Count
        FunctionSpecCount = $functionSpecs.Count
        FunctionSpecSummary = $functionSpecSummary
        FunctionSpecs = $functionSpecs
        FunctionSpecPath = $functionSpecPath
        Interesting   = ($interestingHits -join '; ')
        Commands      = ($commandNames | Get-Unique | Select-Object -First 25) -join ', '
        ParseErrors   = ($errors | ForEach-Object { $_.Message }) -join '; '
    }
}

try {
    $scriptFiles = Get-ChildItem -Path $RootPath -Include *.ps1, *.psm1, *.py -File -Recurse |
        Where-Object { -not $_.FullName.ToLower().Contains('packages') }

    if (-not $scriptFiles) {
        Write-Warning "No se encontraron scripts PowerShell o Python en $RootPath."
        return
    }

    $cachedResults = foreach ($file in $scriptFiles) {
        & $analysisBlock -File $file
    }

    $summaryResults = $cachedResults | Select-Object Script, FunctionCount, FunctionSpecCount, FunctionSpecSummary, FunctionSpecPath, Functions, Interesting, Commands, ParseErrors

    if (-not $cachedResults) {
        Write-Warning "No se encontraron scripts PowerShell o Python en $RootPath."
        return
    }

    $summaryResults | Format-Table -AutoSize -Wrap -Property Script, FunctionCount, FunctionSpecCount, FunctionSpecSummary, FunctionSpecPath, Functions, Interesting, Commands, ParseErrors | Out-String -Width 200 | Write-Host

    $mdPath = Write-MarkdownReport -Rows $summaryResults -DestDir $ResultsDir
    Write-Host "[analyzer] Reporte Markdown guardado en $mdPath"

    if ($OutputPath) {
        $ext = [IO.Path]::GetExtension($OutputPath)
        if ($ext.ToLower() -eq '.json') {
            $summaryResults | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        } else {
            $cachedResults | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
        }
        Write-Host "[analyzer] Resultado guardado en $OutputPath" -ForegroundColor Green
    }
} finally {
    Remove-Item $pythonHelperPath -ErrorAction SilentlyContinue -Force
}
