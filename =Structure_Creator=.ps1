# CLI para crear estructura de proyecto .NET dentro de Sandbox fijo

Write-Host "=== Creador de proyecto (.NET) – Sandbox Neurologic ===" -ForegroundColor Cyan

# Ruta fija obligatoria
$root = "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic\Sandbox"

# Asegurar existencia del Sandbox
if (-not (Test-Path -LiteralPath $root)) {
    New-Item -ItemType Directory -Path $root | Out-Null
}

Write-Host "Ruta base: $root" -ForegroundColor Green

# Nombre del proyecto
$rawName = Read-Host "Nombre del proyecto"

if ([string]::IsNullOrWhiteSpace($rawName)) {
    Write-Host "Nombre de proyecto inválido." -ForegroundColor Red
    exit 1
}

# Sanitizar nombre
$invalid = [IO.Path]::GetInvalidFileNameChars()
$projectName = -join ($rawName.Trim().ToCharArray() | ForEach-Object { if ($invalid -notcontains $_) { $_ } })

if ([string]::IsNullOrWhiteSpace($projectName)) {
    Write-Host "El nombre solo contiene caracteres inválidos." -ForegroundColor Red
    exit 1
}

$projectRoot = Join-Path $root $projectName

# Confirmar si ya existe
if (Test-Path -LiteralPath $projectRoot) {
    Write-Host "La ruta '$projectRoot' ya existe." -ForegroundColor Yellow
    $choice = Read-Host "¿Reutilizarla y continuar? (s/n)"
    if ($choice.ToLower() -notin @('s','y')) {
        Write-Host "Cancelado." -ForegroundColor Red
        exit 1
    }
}

# Carpetas específicas en Sandbox
$dirs = @(
    $projectRoot,
    (Join-Path $projectRoot 'docs'),
    (Join-Path $projectRoot 'csv'),
    (Join-Path $projectRoot 'Scripts'),
    (Join-Path $projectRoot 'src')
)

foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

# AGENTS.md
$agentsPath = Join-Path $projectRoot 'AGENTS.md'
if (-not (Test-Path $agentsPath)) {
@"
# AGENTS – $projectName

Reglas específicas para este proyecto.
"@ | Set-Content $agentsPath -Encoding utf8
}

# README.md
$readmePath = Join-Path $projectRoot 'README.md'
if (-not (Test-Path $readmePath)) {
@"
# $projectName

Descripción breve del proyecto.
"@ | Set-Content $readmePath -Encoding utf8
}

# <Proyecto>.csproj
$csprojPath = Join-Path $projectRoot "$projectName.csproj"
if (-not (Test-Path $csprojPath)) {
@"
<Project Sdk=""Microsoft.NET.Sdk"">
  <PropertyGroup>
    <TargetFrameworks>net8.0;net6.0</TargetFrameworks>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <AssemblyName>$projectName</AssemblyName>
  </PropertyGroup>
</Project>
"@ | Set-Content $csprojPath -Encoding utf8
}

# docs/filemap_ascii.txt
$asciiPath = Join-Path $projectRoot 'docs\filemap_ascii.txt'
if (-not (Test-Path $asciiPath)) {
@"
$projectName/
├── AGENTS.md
├── README.md
├── $projectName.csproj
├── docs/
│   ├── filemap_ascii.txt
│   └── table_hierarchy.json
├── csv/
├── Scripts/
└── src/
"@ | Set-Content $asciiPath -Encoding utf8
}

# docs/table_hierarchy.json
$jsonPath = Join-Path $projectRoot 'docs\table_hierarchy.json'
if (-not (Test-Path $jsonPath)) {
@"
{
  ""root"": ""csv/"",
  ""src"": ""src/""
}
"@ | Set-Content $jsonPath -Encoding utf8
}

Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "Proyecto '$projectName' creado o actualizado en:" -ForegroundColor Green
Write-Host "  $projectRoot" -ForegroundColor Green
