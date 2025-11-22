# ============================================================
# AST Function Spec Extractor - Strict Schema Version
# Correcciones aplicadas según evidencia en /mnt/data/Select-Repository.json
# ============================================================

Add-Type -AssemblyName System.Windows.Forms

# -------------------------------
# Utilidades internas
# -------------------------------

function Remove-EmptyNodes {
    param($Node)

    if ($Node -is [string]) {
        if ($Node.Trim().Length -eq 0) { return $null }
        return $Node
    }

    if ($Node -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($k in $Node.Keys) {
            $cleaned = Remove-EmptyNodes $Node[$k]
            if ($cleaned -ne $null) {
                if ($cleaned -isnot [System.Collections.IEnumerable] -or $cleaned -is [string]) {
                    $result[$k] = $cleaned
                } else {
                    $enum = $cleaned.GetEnumerator()
                    if ($enum.MoveNext()) { $result[$k] = $cleaned }
                }
            }
        }
        if ($result.Count -eq 0) { return $null }
        return $result
    }

    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        $acc = @()
        foreach ($item in $Node) {
            $cleaned = Remove-EmptyNodes $item
            if ($cleaned -ne $null) {
                if ($cleaned -isnot [System.Collections.IEnumerable] -or $cleaned -is [string]) {
                    $acc += $cleaned
                } else {
                    $enu = $cleaned.GetEnumerator()
                    if ($enu.MoveNext()) { $acc += $cleaned }
                }
            }
        }
        if ($acc.Count -eq 0) { return $null }
        return $acc
    }

    return $Node
}

function Extract-Commands {
    param([System.Management.Automation.Language.FunctionDefinitionAst]$AstNode)

    $cmds = @()
    $AstNode.Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) |
    ForEach-Object {
        $first = $_.CommandElements | Select-Object -First 1
        if ($first -and $first.Value) { $cmds += $first.Value }
    }
    return $cmds | Sort-Object -Unique
}

function Extract-TryCatch {
    param([System.Management.Automation.Language.FunctionDefinitionAst]$AstNode)

    $res = @()
    $AstNode.Body.FindAll({ param($x) $x -is [System.Management.Automation.Language.TryStatementAst] }, $true) |
    ForEach-Object {
        $tryText = $null
        if ($_.Body -and $_.Body.Extent -and $_.Body.Extent.Text) {
            $tryText = ($_.Body.Extent.Text.Trim() -replace "`r","") -replace "`n", "\n"
        }

        $types = @()
        $blocks = @()
        if ($_.CatchClauses) {
            foreach ($cc in $_.CatchClauses) {
                if ($cc.ExceptionTypes) {
                    foreach ($et in $cc.ExceptionTypes) {
                        if ($et.Extent -and $et.Extent.Text) {
                            $types += $et.Extent.Text.Trim()
                        }
                    }
                }
                if ($cc.Action -and $cc.Action.Extent -and $cc.Action.Extent.Text) {
                    $bl = ($cc.Action.Extent.Text.Trim() -replace "`r","") -replace "`n", "\n"
                    $blocks += $bl
                }
            }
        }

        $res += [ordered]@{
            TryBlock   = $tryText
            CatchTypes = $types
            CatchBlock = if ($blocks.Count -eq 1) { $blocks[0] } else { ($blocks -join "\n\n") }
        }
    }
    return $res
}

function Extract-Returns {
    param([System.Management.Automation.Language.FunctionDefinitionAst]$AstNode)

    $rets = @()
    $AstNode.Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.ReturnStatementAst] }, $true) |
    ForEach-Object {
        if ($_.Extent -and $_.Extent.Text) {
            $txt = $_.Extent.Text.Trim()
            $txt = $txt -replace '^return\s+', ''
            $rets += $txt
        }
    }
    return $rets | Sort-Object -Unique
}

function Extract-ASTTree {
    param([System.Management.Automation.Language.Ast]$Node)

    $map = [ordered]@{
        Type     = $Node.GetType().Name
        Command   = $null
        Assignment = $null
        Condition = $null
        Return    = $null
        Children  = @()
    }

    if ($Node -is [System.Management.Automation.Language.CommandAst]) {
        $parts = $Node.CommandElements | ForEach-Object { $_.Extent.Text }
        if ($parts) { $map["Command"] = ($parts -join " ") }
    }

    if ($Node -is [System.Management.Automation.Language.AssignmentStatementAst]) {
        if ($Node.Left -and $Node.Right) {
            $lhs = $Node.Left.Extent.Text
            $rhs = $Node.Right.Extent.Text
            $map["Assignment"] = "$lhs = $rhs"
        }
    }

    if ($Node -is [System.Management.Automation.Language.IfStatementAst]) {
        if ($Node.Clauses.Count -gt 0) {
            $cond = $Node.Clauses[0].Item1
            if ($cond -and $cond.Extent -and $cond.Extent.Text) {
                $map["Condition"] = $cond.Extent.Text.Trim()
            }
        }
    }

    if ($Node -is [System.Management.Automation.Language.ReturnStatementAst]) {
        if ($Node.Extent -and $Node.Extent.Text) {
            $txt = $Node.Extent.Text.Trim()
            $txt = $txt -replace '^return\s+', ''
            $map["Return"] = $txt
        }
    }

    $childrenAsts = $Node.FindAll({ param($n) $n.Parent -eq $Node }, $true)
    foreach ($ch in $childrenAsts) {
        $map["Children"] += Extract-ASTTree $ch
    }

    return $map
}

function Extract-Params {
    param([System.Management.Automation.Language.FunctionDefinitionAst]$AstNode)

    $res = [ordered]@{}
    if ($AstNode.Parameters) {
        foreach ($p in $AstNode.Parameters) {
            $name = $p.Name.VariablePath.UserPath
            $tp = if ($p.StaticType) { $p.StaticType.FullName } else { $null }
            $def = if ($p.DefaultValue -and $p.DefaultValue.Extent) { $p.DefaultValue.Extent.Text } else { $null }
            $mand = $false

            if ($p.Attributes) {
                foreach ($att in $p.Attributes) {
                    if ($att.NamedArguments) {
                        foreach ($arg in $att.NamedArguments) {
                            if ($arg.ArgumentName -eq "Mandatory") {
                                if ($arg.Argument -and $arg.Argument.Extent.Text -match '^\$true$') {
                                   $mand = $true
                                }
                            }
                        }
                    }
                }
            }

            $res[$name] = [ordered]@{
                Tipo     = $tp
                Default  = $def
                Mandatory = $mand
            }
        }
    }
    return $res
}

function Convert-FunctionAstToRichSpec {
    param([System.Management.Automation.Language.FunctionDefinitionAst]$Fn)

    $raw = [ordered]@{
        schemaVersion   = "2025.11.20.v1"
        generatedAt     = (Get-Date).ToUniversalTime().ToString("o")
        Nombre          = $Fn.Name
        Lenguaje        = "PowerShell"
        FirmaPowerShell = $Fn.Name
        Parametros      = Extract-Params $Fn
        Comandos        = Extract-Commands $Fn
        TryCatch        = Extract-TryCatch $Fn
        Returns         = Extract-Returns $Fn
        AST             = Extract-ASTTree $Fn
    }

    return Remove-EmptyNodes $raw
}

function Validate-And-WriteJson {
    param(
        $Spec,
        [string]$RawName,
        [string]$OutDir
    )

    $safe = ($RawName -replace '[^A-Za-z0-9\-_\.]', '_')
    if ($safe.Length -gt 120) { $safe = $safe.Substring(0,120) }

    $fname = "$safe.json"
    $i=1
    while (Test-Path (Join-Path $OutDir $fname)) {
        $fname = "$safe-$i.json"
        $i++
    }

    $target = Join-Path $OutDir $fname

    if (-not $Spec.schemaVersion -or -not $Spec.generatedAt) {
        $errf = Join-Path $OutDir "$safe.error.json"
        @{
            error     = "Invalid spec structure"
            original  = $Spec
        } | ConvertTo-Json -Depth 50 -EscapeHandling EscapeNonAscii |
        Out-File -LiteralPath $errf -Encoding utf8
        return $false
    }

    $json = $Spec | ConvertTo-Json -Depth 50 -EscapeHandling EscapeNonAscii
    $json | Out-File -LiteralPath $target -Encoding utf8
    return $true
}

$dlg1 = New-Object System.Windows.Forms.OpenFileDialog
$dlg1.Filter = "PowerShell (*.ps1)|*.ps1"
if ($dlg1.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    exit 1
}
$inputFile = $dlg1.FileName

$dlg2 = New-Object System.Windows.Forms.FolderBrowserDialog
if ($dlg2.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    exit 1
}
$outDir = $dlg2.SelectedPath

$log = Join-Path $outDir "analyze-log.txt"

$tokens=$null; $errors=$null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($inputFile,[ref]$tokens,[ref]$errors)

$funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true)

$index = @()

foreach ($fn in $funcs) {
    $spec = Convert-FunctionAstToRichSpec $fn
    $name = $fn.Name
    $ok = Validate-And-WriteJson -Spec $spec -RawName $name -OutDir $outDir

    $index += [ordered]@{
        name          = $name
        fileName      = $name + ".json"
        schemaVersion = $spec.schemaVersion
        generatedAt   = $spec.generatedAt
        quickSummary  = "Function spec"
        success       = $ok
    }

    Add-Content -LiteralPath $log -Value ("Processed: " + $name)
}

$index | ConvertTo-Json -Depth 10 -EscapeHandling EscapeNonAscii |
Out-File -LiteralPath (Join-Path $outDir "index.json") -Encoding utf8

$failed = $index | Where-Object { -not $_.success }
if ($failed.Count -gt 0) { exit 1 }

exit 0