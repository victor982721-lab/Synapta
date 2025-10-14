[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

# === Header ===
try {
    $full = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
} catch {
    Write-Output "Error: no se pudo resolver la ruta `$Path. $_"
    exit 1
}
$utc = [DateTime]::UtcNow.ToString("o")
Write-Output "[$utc] Análisis de: $full"

# === Load & Parse ===
$source = Get-Content -LiteralPath $full -Raw
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)

if ($errors -and $errors.Count -gt 0) {
    $msgs = ($errors | ForEach-Object { $_.Message.Trim() }) -join "; "
    Write-Output "Aviso: errores de sintaxis detectados -> $msgs"
}

# === Synopsis (.SYNOPSIS or top comments) ===
$helpSynopsis = ($source -split '\r?\n' | Select-String -Pattern '^\s*\.SYNOPSIS\s*(.*)$' -AllMatches).Matches |
    ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
if (-not $helpSynopsis) {
    $topLines = @()
    foreach ($line in ($source -split '\r?\n')) {
        if ($line -match '^\s*#') { $topLines += ($line -replace '^\s*#\s*',''); if ($topLines.Count -ge 3) { break } }
        elseif ($line.Trim().Length -eq 0) { continue } else { break }
    }
    if ($topLines) { $helpSynopsis = ($topLines -join ' ') }
}
if ($helpSynopsis) { Write-Output "Sinopsis: $helpSynopsis" }

# === Parameters ===
$paramAsts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] }, $true)
if ($paramAsts) {
    $paramLines = foreach ($p in $paramAsts) {
        $name = $p.Name.VariablePath.UserPath
        $type = if ($p.StaticType) { $p.StaticType.Name } else { '' }
        $mandatory = ($p.Attributes | Where-Object {
            $_.TypeName.Name -eq 'Parameter' -and
            $_.NamedArguments.Where({$_.ArgumentName -eq 'Mandatory' -and $_.Argument.Extent.Text -match '(?i)true'})
        })
        "{0}{1}{2}" -f $name, $(if ($type) { "[$type]" } else { '' }), $(if ($mandatory) { ' (Mandatory)' } else { '' })
    }
    Write-Output ("Parámetros: " + ($paramLines -join ', '))
}

# === Functions ===
$funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
if ($funcs) {
    Write-Output ("Funciones definidas: " + (($funcs | ForEach-Object Name) -join ', '))
}
$localFunctionNames = @($funcs | ForEach-Object Name)

# === Commands (names) ===
$cmdAsts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
$cmdNames = @{}
foreach ($c in $cmdAsts) {
    $n = $c.GetCommandName()
    if (-not $n) {
        $first = $c.CommandElements[0]
        if ($first -and $first -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $n = $first.Value
        }
    }
    if ($n) { $cmdNames[$n] = $true }
}
$names = $cmdNames.Keys

# === Categories ===
$cats = @{
  'Archivos' = @('Get-Item','Get-ChildItem','Copy-Item','Move-Item','Remove-Item','New-Item','Set-Content','Add-Content','Clear-Content','Get-Content','Expand-Archive','Compress-Archive','Rename-Item')
  'Red' = @('Invoke-WebRequest','Invoke-RestMethod','Test-Connection','Start-BitsTransfer','Enter-PSSession','Invoke-Command')
  'Procesos/Servicios' = @('Start-Process','Stop-Process','Get-Process','Get-Service','Restart-Service','Set-Service','Start-Service','Stop-Service')
  'Registro' = @('Get-ItemProperty','Set-ItemProperty','New-ItemProperty','Remove-ItemProperty')
  'Módulos' = @('Import-Module','Install-Module','Remove-Module')
}
foreach ($kv in $cats.GetEnumerator()) {
    $hit = $names | Where-Object { $kv.Value -contains $_ }
    if ($hit) { Write-Output ("Usa {0}: {1}" -f $kv.Key, ($hit -join ', ')) }
}

# === External executables ===
$ext = @()
foreach ($n in $names) {
    if ($localFunctionNames -contains $n) { continue }
    $gc = $null
    try { $gc = Get-Command -Name $n -ErrorAction Stop } catch {}
    if (-not $gc) {
        if ($n -match '\.(exe|bat|cmd|msi|ps1)$' -or $n -like '*\*' -or $n -like '*/*') { $ext += $n }
    } elseif ($gc.CommandType -eq 'Application') {
        if ($gc.Source) { $ext += $gc.Source } else { $ext += $gc.Name }
    }
}
$ext = $ext | Select-Object -Unique
if ($ext) { Write-Output ("Invoca ejecutables externos: " + ($ext -join ', ')) }

# === Imported modules (names extracted from AST) ===
$imported = foreach ($c in $cmdAsts) {
    if ($c.GetCommandName() -eq 'Import-Module') {
        foreach ($e in $c.CommandElements) {
            if ($e -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $e.Value }
        }
    }
} | Where-Object { $_ } | Select-Object -Unique
if ($imported) { Write-Output ("Módulos importados: " + ($imported -join ', ')) }

# === URLs y rutas ===
$urls = [regex]::Matches($source, '(?i)https?://[^\s''"<>]+') | ForEach-Object Value | Select-Object -Unique
if ($urls) { Write-Output ("URLs: " + ($urls -join ', ')) }

$paths = [regex]::Matches($source, '(?i)(?:[A-Z]:\\|\\\\)[^\s''"<>]+') | ForEach-Object Value | Select-Object -Unique
if ($paths) { Write-Output ("Rutas detectadas: " + (($paths | Select-Object -First 5) -join ', ') + ($(if ($paths.Count -gt 5) { ' …' } else { '' }))) }

# === Risky patterns ===
$risky = @()
if ($names -contains 'Invoke-Expression') { $risky += 'Invoke-Expression' }
if ($source -match '(?i)FromBase64String\(') { $risky += 'FromBase64String' }
if ($source -match '(?i)-EncodedCommand') { $risky += '-EncodedCommand' }
if ($source -match '(?i)Add-Type') { $risky += 'Add-Type' }
if ($source -match '(?i)DownloadString|Net\.WebClient') { $risky += 'Descarga de código (WebClient/DownloadString)' }
if ($risky) { Write-Output ("Patrones potencialmente riesgosos: " + ($risky | Select-Object -Unique -join ', ')) }

# === Quick summary ===
$hints = @()
if ($names | Where-Object { $cats['Archivos'] -contains $_ }) { $hints += 'opera con archivos' }
if ($names | Where-Object { $cats['Registro'] -contains $_ }) { $hints += 'toca el Registro' }
if ($names | Where-Object { $cats['Red'] -contains $_ }) { $hints += 'realiza llamadas de red' }
if ($names -contains 'Start-Process' -or $ext) { $hints += 'lanza procesos externos' }
if ($hints) { Write-Output ("Resumen: el script " + ($hints -join ', ') + '.') } else { Write-Output "Resumen: operaciones generales de PowerShell." }
