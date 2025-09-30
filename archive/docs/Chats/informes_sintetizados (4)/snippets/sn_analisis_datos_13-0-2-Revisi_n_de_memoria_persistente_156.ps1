# Ruta al ZIP que subiste
$zipPath = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\i18n_work\YSD300AN.md.zip"
$workDir = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\i18n_work"

# 1) Extraer el ZIP
Expand-Archive -LiteralPath $zipPath -DestinationPath $workDir -Force

# 2) Detectar el .md
$mdFile = Get-ChildItem -Path $workDir -Filter *.md -Recurse | Select-Object -First 1
if (-not $mdFile) { throw "No se encontró ningún .md en $workDir" }

# 3) Leer líneas de texto legibles (>=3 caracteres, evitar basura hex)
$lines = Get-Content -LiteralPath $mdFile.FullName |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '\w' -and $_.Length -ge 3 } |
    Sort-Object -Unique

# 4) Exportar a CSV para traducción
$outCsv = Join-Path $workDir "YSD300AN_strings.csv"
$rows = @()
$id = 1
foreach ($line in $lines) {
    $rows += [pscustomobject]@{
        ID         = $id
        Original   = $line
        Traduccion = ""
    }
    $id++
}
$rows | Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding UTF8

Write-Host "[OK] CSV generado en: $outCsv"