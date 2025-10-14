<#!
QA-Analyzer_v5.ps1
Auditor QA CLI "foto completa" para PowerShell 7.0+ (probado en 7.5.x) en Windows 10/11.
- Parser + PSScriptAnalyzer + Heurísticas Custom + Escaneo AST reforzado.
- Campo Source: Parser | PSSA | Custom.
- Si hay errores de parseo: PSSA solo en buenos; Custom/AST en todos.
- Exporta JSON/CSV/TXT + log JSONL (UTC).
- Exit codes: 0 limpio; 1 Warning/Error; 2/3/98/99 fallos entorno/export.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetPath,

    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path (Get-Location) -ChildPath 'out/qa-analyzer'),

    [Parameter()]
    [ValidateSet('json','csv','txt')]
    [string[]]$ReportFormat = @('json'),

    [Parameter()]
    [string]$ReportName = 'qa-analyzer-report',

    [Parameter()]
    [switch]$AllFormats,

    [Parameter()]
    [switch]$SkipPssa,

    [Parameter()]
    [string]$LogPath,

    [Parameter()]
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ====== Contexto ======
if (-not $PSCommandPath) {
    $script:ScriptPath = $MyInvocation.MyCommand.Path
} else {
    $script:ScriptPath = $PSCommandPath
}
$script:ScriptRoot   = Split-Path -Path $script:ScriptPath -Parent
$script:RepoRoot     = Split-Path -Path $script:ScriptRoot -Parent
$script:AstCache     = [System.Collections.Generic.Dictionary[string,System.Management.Automation.Language.Ast]]::new()
$script:ContentCache = [System.Collections.Generic.Dictionary[string,string]]::new()
$script:RunTimestampUtc = (Get-Date -AsUTC).ToString('o')

$allowedFormats = @('json','csv','txt')

# Conjuntos para detección de keywords invocados como comando
$script:KeywordInvocationOperators = @{
    ([System.Management.Automation.Language.TokenKind]::Ampersand) = 'operador &'
    ([System.Management.Automation.Language.TokenKind]::Dot)       = 'operador .'
}
$script:ControlKeywordSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($kw in @('if','elseif','else','switch','for','foreach','while','do','until','try','catch','finally','trap','default','return','break','continue','throw','param','begin','process','end')) {
    $null = $script:ControlKeywordSet.Add($kw)
}

if ($AllFormats) { $ReportFormat = $allowedFormats }
$ReportFormat = [string[]]($ReportFormat | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique)
if (-not $ReportFormat) { throw 'Debe especificar al menos un formato de reporte.' }

if (-not $LogPath) {
    $LogPath = Join-Path -Path $OutputDirectory -ChildPath 'qa-analyzer.log.jsonl'
}

function Write-LogEvent {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('trace','debug','info','warning','error')][string]$Level = 'info',
        [hashtable]$Data
    )
    if (-not $LogPath) { return }
    try {
        $logDir = Split-Path -Path $LogPath -Parent
        if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $payload = [ordered]@{
            timestamp_utc = (Get-Date -AsUTC).ToString('o')
            level         = $Level
            message       = $Message
        }
        if ($Data) {
            foreach ($k in $Data.Keys) { $payload[$k] = $Data[$k] }
        }
        ($payload | ConvertTo-Json -Depth 6 -Compress) | Add-Content -LiteralPath $LogPath -Encoding utf8NoBom
    } catch {
        Write-Warning ("No se pudo escribir log: {0}" -f $_.Exception.Message)
    }
}

function Write-Info { param([string]$Message)
    if (-not $Quiet) { Write-Information -MessageData ("[INFO] {0}" -f $Message) -InformationAction Continue }
    Write-LogEvent -Message $Message -Level 'info'
}
function Write-Warn { param([string]$Message)
    if (-not $Quiet) { Write-Warning $Message }
    Write-LogEvent -Message $Message -Level 'warning'
}
function Write-Err { param([string]$Message)
    Write-Error $Message
    Write-LogEvent -Message $Message -Level 'error'
}

function New-Finding {
    param(
        [Parameter(Mandatory)][string]$File,
        [int]$Line = 0,
        [int]$Column = 0,
        [ValidateSet('Information','Warning','Error')][string]$Severity = 'Warning',
        [ValidateSet('Parser','PSSA','Custom')][string]$Source,
        [string]$RuleName,
        [string]$Message
    )
    [pscustomobject]@{
        ScriptName = $File
        Line       = $Line
        Column     = $Column
        Severity   = $Severity
        Source     = $Source
        RuleName   = $RuleName
        Message    = $Message
    }
}

function Ensure-Pssa {
    if ($SkipPssa) {
        Write-Warn 'PSScriptAnalyzer omitido por -SkipPssa.'
        return
    }
    $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
    if (-not $module) {
        $vendorPath = Join-Path -Path $script:RepoRoot -ChildPath 'vendor/PSScriptAnalyzer'
        if (Test-Path -LiteralPath $vendorPath) {
            # Evita strings interpoladas frágiles
            $env:PSModulePath = [string]::Format('{0}{1}{2}', $vendorPath, [System.IO.Path]::PathSeparator, $env:PSModulePath)
            $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
        }
    }
    if (-not $module) {
        Write-Err "No se encuentra 'PSScriptAnalyzer'. Instala: Install-Module PSScriptAnalyzer -Scope CurrentUser"
        exit 2
    }
    Import-Module PSScriptAnalyzer -ErrorAction Stop | Out-Null
    Write-Info ("PSScriptAnalyzer cargado desde: {0}" -f $module.ModuleBase)
}

function Test-SelfIntegrity {
    foreach ($cmd in @('Invoke-ScriptAnalyzer')) {
        if (-not (Get-Command -Name $cmd -ErrorAction SilentlyContinue)) {
            Write-Err ("Falta el comando requerido: {0}" -f $cmd)
            exit 99
        }
    }
    Write-Info 'Integridad autoverificada.'
}

function Invoke-SafeParse {
    param([Parameter(Mandatory)][string[]]$Files)
    $findings = [System.Collections.Generic.List[object]]::new()
    foreach ($file in $Files) {
        try {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
            if ($errors -and ($errors.Count -gt 0)) {
                foreach ($err in $errors) {
                    $findings.Add( (New-Finding -File $file -Line $err.Extent.StartLineNumber -Column $err.Extent.StartColumnNumber -Severity 'Error' -Source 'Parser' -RuleName 'ParseError' -Message $err.Message) )
                }
            } else {
                $script:AstCache[$file] = $ast
            }
        } catch {
            $findings.Add( (New-Finding -File $file -Severity 'Error' -Source 'Parser' -RuleName 'ParseRefError' -Message ('Error interno del parser: {0}' -f $_.Exception.Message)) )
        }
    }
    return $findings.ToArray()
}

# Hook opcional Validate-Parse.ps1
$validateParsePath = Join-Path -Path (Get-Location) -ChildPath 'Validate-Parse.ps1'
if (Test-Path -LiteralPath $validateParsePath) {
    try {
        . $validateParsePath
        if (-not (Get-Command -Name Invoke-ValidateParse -ErrorAction SilentlyContinue)) {
            throw 'Validate-Parse.ps1 no expone Invoke-ValidateParse'
        }
        Write-Info 'Validate-Parse.ps1 cargado.'
    } catch {
        Write-Warn ("Error al cargar Validate-Parse.ps1: {0}. Se usará el parser interno." -f $_.Exception.Message)
    }
}
if (-not (Get-Command -Name Invoke-ValidateParse -ErrorAction SilentlyContinue)) {
    function Invoke-ValidateParse {
        param([Parameter(Mandatory)][string[]]$Files)
        Invoke-SafeParse -Files $Files
    }
}

function Get-FullPssaSettings {
@{
  IncludeDefaultRules = $true
  Severity            = @('Error','Warning','Information')
  Rules = @{
    PSUseConsistentIndentation = @{
      Enable              = $true
      IndentationSize     = 4
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
      Kind                = 'space'
    }
    PSUseConsistentWhitespace = @{
      Enable          = $true
      CheckOpenBrace  = $true
      CheckInnerBrace = $true
      CheckOperator   = $true
      CheckSeparator  = $true
      CheckPipe       = $true
      CheckParameter  = $true
    }
    PSPlaceOpenBrace = @{
      Enable            = $true
      OnSameLine        = $true
      NewLineAfter      = $true
      IgnoreOneLineBlock= $true
    }
    PSPlaceCloseBrace = @{
      Enable            = $true
      NewLineAfter      = $true
      IgnoreOneLineBlock= $true
    }
    PSAvoidUsingInvokeExpression = @{ Severity = 'Error' }
    PSAvoidGlobalVars            = @{ Severity = 'Error' }
    PSUseSupportsShouldProcess   = @{ Enable  = $true }
    PSUseApprovedVerbs           = @{ Enable  = $true }
    PSUseCmdletCorrectly         = @{ Enable  = $true }
    PSUseOutputTypeCorrectly     = @{ Enable  = $true }
  }
}
}

function Remove-InvisibleFormatCharacters {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    return [regex]::Replace($Text, '[\u200B-\u200F\u202A-\u202E\u2060\uFEFF]', '')
}

function Get-FileBytes {
    param([Parameter(Mandatory)][string]$Path)
    try { [System.IO.File]::ReadAllBytes($Path) } catch { @() }
}
function Get-FileText {
    param([Parameter(Mandatory)][string]$Path)
    if ($script:ContentCache.ContainsKey($Path)) { return $script:ContentCache[$Path] }
    $raw = $null
    try { $raw = Get-Content -LiteralPath $Path -Encoding utf8 -Raw } catch {
        try { $raw = Get-Content -LiteralPath $Path -Encoding default -Raw } catch { $raw = $null }
    }
    if ($null -ne $raw) { $script:ContentCache[$Path] = $raw }
    return $raw
}

function Invoke-CustomChecks {
    param([Parameter(Mandatory)][string[]]$Files)
    $findings = [System.Collections.Generic.List[object]]::new()

    $rxPwdVar      = [regex]'(?i)\b(password|passwd|pwd)\b\s*=\s*[''"]\S+[''"]'
    $rxAsPlain     = [regex]'(?i)\bConvertTo-SecureString\b.*-AsPlainText\b'
    $rxCredPwd     = [regex]'(?i)New-Object\s+System\.Management\.Automation\.PSCredential\s*\([^,]+,\s*[''"]\S+[''"]\)'
    $rxIEX         = [regex]'(?i)\bInvoke-Expression\b'
    $rxEA_Sil      = [regex]'(?i)-ErrorAction\s+SilentlyContinue\b'
    $rxSETPOL      = [regex]'(?i)\bSet-ExecutionPolicy\b.*\b(Bypass|Unrestricted)\b'
    $rxUriCred     = [regex]'(?i)\b[a-z][a-z0-9+\-.]*://[^/\s:@]+:[^/\s@]+@'
    $rxInsecureTLS = [regex]'(?i)SecurityProtocol\s*=\s*.*(Ssl3|Tls(1(?!2|3)|10|11))'
    $rxCertBypass  = [regex]'(?i)ServerCertificateValidationCallback\s*=\s*\{[^}]*\$\s*true[^}]*\}'
    $rxAWS         = [regex]'AKIA[0-9A-Z]{16}'
    $rxGAPI        = [regex]'AIza[0-9A-Za-z\-_]{35}'
    $rxSlack       = [regex]'xox[baprs]-[0-9A-Za-z-]{10,}'
    $rxHttpIwr     = [regex]'(?i)\bInvoke-(WebRequest|RestMethod)\b[^\n]*http://'
    $rxSqlPwd      = [regex]'(?i)Invoke-Sqlcmd\b[^\n]*-Password\s+[''"][^''"\s]+[''"]'
    $rxConnString  = [regex]'(?i)connection\s*string\s*=[''"][^''"\n]*password\s*='
    $rxCatchEmpty  = [regex]'(?is)catch\s*\{\s*\}'
    $rxWebClient   = [regex]'System\.Net\.WebClient'
    $rxZeroWidth   = [regex]'[\u200B-\u200F\u202A-\u202E\u2060\uFEFF]'

    foreach ($file in $Files) {
        $bytes = Get-FileBytes -Path $file
        if ($bytes.Length -ge 2) {
            if     ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $findings.Add( (New-Finding -File $file -Severity 'Error'   -Source 'Custom' -RuleName 'Encoding/UTF16LE' -Message 'Archivo en UTF-16 LE; usa UTF-8 sin BOM.') ) }
            elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { $findings.Add( (New-Finding -File $file -Severity 'Error'   -Source 'Custom' -RuleName 'Encoding/UTF16BE' -Message 'Archivo en UTF-16 BE; usa UTF-8 sin BOM.') ) }
            elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $findings.Add( (New-Finding -File $file -Severity 'Warning' -Source 'Custom' -RuleName 'Encoding/UTF8BOM' -Message 'UTF-8 con BOM detectado; preferible UTF-8 sin BOM.') ) }
            $lf = @($bytes | Where-Object { $_ -eq 10 }).Count
            $cr = @($bytes | Where-Object { $_ -eq 13 }).Count
            if ($lf -gt 0 -and $cr -gt 0 -and ($lf -ne $cr)) {
                $findings.Add( (New-Finding -File $file -Severity 'Warning' -Source 'Custom' -RuleName 'LineEndings/Mixed' -Message 'Finales de línea mixtos (CRLF/LF). Unifica a CRLF.') )
            }
        }

        $contentRaw = Get-FileText -Path $file
        $lines = @()
        if ($null -ne $contentRaw) {
            $lines = $contentRaw -split "`r?`n"
        } else {
            try { $lines = Get-Content -LiteralPath $file -Encoding utf8 } catch {
                try { $lines = Get-Content -LiteralPath $file -Encoding default } catch { $lines = @() }
            }
            if ($lines) {
                $contentRaw = ($lines -join "`n")
                $script:ContentCache[$file] = $contentRaw
            }
        }

        $lineNumber = 0
        foreach ($line in $lines) {
            $lineNumber++
            if ($rxPwdVar.IsMatch($line) -or $rxAsPlain.IsMatch($line) -or $rxCredPwd.IsMatch($line)) { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/PlainPassword'    -Message 'Posible contraseña en texto plano o uso de ConvertTo-SecureString -AsPlainText.') ) }
            if ($rxIEX.IsMatch($line))                                                                    { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Error'      -Source 'Custom' -RuleName 'InvokeExpression(Custom)' -Message 'Uso de Invoke-Expression; riesgo de inyección.') ) }
            if ($rxEA_Sil.IsMatch($line))                                                                 { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'ErrorAction/SilentlyContinue' -Message 'Silenciamiento de errores (-ErrorAction SilentlyContinue).') ) }
            if ($rxSETPOL.IsMatch($line))                                                                 { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'Set-ExecutionPolicy/Risky'   -Message 'Set-ExecutionPolicy Bypass/Unrestricted detectado.') ) }
            if ($rxUriCred.IsMatch($line))                                                                { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'UriCredentials'             -Message 'Credenciales embebidas en URI.') ) }
            if ($rxInsecureTLS.IsMatch($line))                                                            { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'TLS/LegacyProtocols'        -Message 'Protocolos TLS inseguros (SSLv3/TLS 1.0/1.1). Usa TLS 1.2+.') ) }
            if ($rxCertBypass.IsMatch($line))                                                             { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Error'      -Source 'Custom' -RuleName 'TLS/CertBypass'             -Message 'Bypass de validación de certificado (ServerCertificateValidationCallback {$true}).') ) }
            if ($rxHttpIwr.IsMatch($line))                                                                { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'Http/InvokeWebRequest'      -Message 'Invoke-WebRequest/Invoke-RestMethod usando HTTP sin TLS.') ) }
            if ($rxSqlPwd.IsMatch($line))                                                                 { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/SqlPassword'         -Message 'Uso de Invoke-Sqlcmd con contraseña en texto plano.') ) }
            if ($rxConnString.IsMatch($line))                                                             { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/ConnectionString'    -Message 'Connection string con password embebido.') ) }
            if ($rxWebClient.IsMatch($line))                                                              { $findings.Add( (New-Finding -File $file -Line $lineNumber -Column 1 -Severity 'Information'-Source 'Custom' -RuleName 'WebClient/Deprecated'       -Message 'System.Net.WebClient está en desuso; usa Invoke-WebRequest/RestMethod.') ) }
            if ($rxAWS.IsMatch($line))                                                                    { $findings.Add( (New-Finding -File $file -Line $lineNumber              -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/AWSKey'             -Message 'Patrón de Access Key ID (AWS) detectado.') ) }
            if ($rxGAPI.IsMatch($line))                                                                   { $findings.Add( (New-Finding -File $file -Line $lineNumber              -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/GoogleAPI'          -Message 'Patrón de Google API key detectado.') ) }
            if ($rxSlack.IsMatch($line))                                                                  { $findings.Add( (New-Finding -File $file -Line $lineNumber              -Severity 'Warning'    -Source 'Custom' -RuleName 'Secret/SlackToken'         -Message 'Patrón de token Slack detectado.') ) }
            if ($rxZeroWidth.IsMatch($line)) {
                $m = $rxZeroWidth.Match($line); $col = $m.Index + 1
                $findings.Add( (New-Finding -File $file -Line $lineNumber -Column $col -Severity 'Error' -Source 'Custom' -RuleName 'Encoding/InvisibleChar' -Message 'Caracter invisible (Zero Width/BOM) detectado; puede provocar errores del tipo ''The term ''''if'''' is not recognized''.') )
            }
        }

        if ($contentRaw) {
            foreach ($m in $rxCatchEmpty.Matches($contentRaw)) {
                $l = ($contentRaw.Substring(0, $m.Index) -split "`r?`n").Count
                if ($l -lt 1) { $l = 1 }
                $findings.Add( (New-Finding -File $file -Line $l -Column 1 -Severity 'Information' -Source 'Custom' -RuleName 'Catch/Empty' -Message 'Bloque catch vacío detectado. Revisa manejo de errores.') )
            }
        }
    }

    return $findings.ToArray()
}

function Get-AstParent {
    param(
        [Parameter(Mandatory)][System.Management.Automation.Language.Ast]$Ast,
        [Parameter(Mandatory)][Type]$ParentType
    )
    $cur = $Ast.Parent
    while ($null -ne $cur -and -not ($ParentType.IsAssignableFrom($cur.GetType()))) {
        $cur = $cur.Parent
    }
    return $cur
}

function Invoke-AstChecks {
    param([Parameter(Mandatory)][string[]]$Files)
    $findings = [System.Collections.Generic.List[object]]::new()
    $stateChangingCommands = @(
        'Clear-Content','Clear-Item','Copy-Item','Disable-ADAccount','Disable-LocalUser','Enable-ADAccount','Enable-LocalUser',
        'Invoke-Command','Move-Item','New-Item','New-ItemProperty','Remove-ADUser','Remove-Item','Remove-ItemProperty','Remove-ItemPropertyValue',
        'Remove-Service','Rename-Item','Restart-Computer','Restart-Service','Set-Acl','Set-Content','Set-ExecutionPolicy','Set-Item',
        'Set-ItemProperty','Set-Service','Start-Process','Start-Service','Stop-Process','Stop-Service'
    )

    foreach ($file in $Files) {
        if (-not $script:AstCache.ContainsKey($file)) { continue }
        $ast = $script:AstCache[$file]

        $hasStrictMode = $false
        $commandAsts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        foreach ($cmdAst in $commandAsts) {
            $name = $cmdAst.GetCommandName()
            if ([string]::IsNullOrWhiteSpace($name)) { continue }

            # Keyword invocado como comando (& if / . if / etc.) o evaluado como comando en contexto de tubería
            if ($script:ControlKeywordSet.Contains($name) -and $script:KeywordInvocationOperators.ContainsKey($cmdAst.InvocationOperator)) {
                $opLabel = $script:KeywordInvocationOperators[$cmdAst.InvocationOperator]
                $msg = "Invocación de palabra reservada '{0}' como comando mediante {1}; esto provocará el error 'The term ''{0}'' is not recognized...' en tiempo de ejecución." -f $name, $opLabel
                $findings.Add( (New-Finding -File $file -Line $cmdAst.Extent.StartLineNumber -Column $cmdAst.Extent.StartColumnNumber -Severity 'Error' -Source 'Custom' -RuleName 'Invocation/ReservedKeyword' -Message $msg) )
                continue
            }

            # Heurísticos varios
            switch -Regex ($name) {
                '^Write-Host$' {
                    $findings.Add( (New-Finding -File $file -Line $cmdAst.Extent.StartLineNumber -Column $cmdAst.Extent.StartColumnNumber -Severity 'Warning' -Source 'Custom' -RuleName 'Output/WriteHost' -Message 'Uso de Write-Host detectado; considera Write-Output o Write-Information.') )
                    continue
                }
                '^Start-Process$' {
                    if ($cmdAst.Extent.Text -match '(?i)-Verb\s+RunAs') {
                        $findings.Add( (New-Finding -File $file -Line $cmdAst.Extent.StartLineNumber -Column $cmdAst.Extent.StartColumnNumber -Severity 'Warning' -Source 'Custom' -RuleName 'StartProcess/RunAs' -Message 'Start-Process con -Verb RunAs detectado; requiere revisión de seguridad.') )
                    }
                    continue
                }
                '^Add-Type$' {
                    if ($cmdAst.Extent.Text -match '(?i)-TypeDefinition') {
                        $findings.Add( (New-Finding -File $file -Line $cmdAst.Extent.StartLineNumber -Column $cmdAst.Extent.StartColumnNumber -Severity 'Information' -Source 'Custom' -RuleName 'AddType/TypeDefinition' -Message 'Add-Type con definición inline. Asegura revisión de código administrado.') )
                    }
                    continue
                }
                '^Invoke-(WebRequest|RestMethod)$' {
                    if ($cmdAst.Extent.Text -match '(?i)-SkipCertificateCheck') {
                        $findings.Add( (New-Finding -File $file -Line $cmdAst.Extent.StartLineNumber -Column $cmdAst.Extent.StartColumnNumber -Severity 'Warning' -Source 'Custom' -RuleName 'InvokeWebRequest/SkipCert' -Message 'Uso de -SkipCertificateCheck; valida la seguridad TLS.') )
                    }
                    continue
                }
                '^Set-StrictMode$' { $hasStrictMode = $true; continue }
            }
        }

        if (-not $hasStrictMode) {
            $findings.Add( (New-Finding -File $file -Severity 'Information' -Source 'Custom' -RuleName 'StrictMode/Missing' -Message 'El script/módulo no llama Set-StrictMode. Considera habilitarlo al inicio.') )
        }

        # Funciones con cambios de estado sin ShouldProcess
        $funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        foreach ($func in $funcs) {
            $fname = $func.Name
            if ([string]::IsNullOrWhiteSpace($fname)) { continue }
            $sb  = $func.Body
            $pb  = $sb.ParamBlock
            $cb  = $null
            if ($pb -and $pb.Attributes) {
                $cb = $pb.Attributes | Where-Object { $_.TypeName.GetReflectionTypeName() -eq 'CmdletBinding' } | Select-Object -First 1
            }
            $supports = $false
            if ($cb) {
                if ($cb.PositionalArguments) {
                    foreach ($pa in $cb.PositionalArguments) {
                        if ($pa.Extent.Text -match '^(?i)SupportsShouldProcess$') { $supports = $true }
                    }
                }
                if ($cb.NamedArguments) {
                    foreach ($na in $cb.NamedArguments) {
                        if ($na.ArgumentName -eq 'SupportsShouldProcess') {
                            $val = $na.Argument.Extent.Text
                            if ($val -match '^(?i)(\$?true|1)$') { $supports = $true }
                        }
                    }
                }
            }

            $shouldProcessCall = $sb.FindAll({
                param($n)
                if ($n -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) { return ($n.Member.Extent.Text -eq 'ShouldProcess') }
                if ($n -is [System.Management.Automation.Language.CommandAst]) { return ($n.GetCommandName() -eq 'ShouldProcess') }
                return $false
            }, $true)
            if ($shouldProcessCall.Count -gt 0) { $supports = $true }

            $danger = $sb.FindAll({
                param($n)
                if ($n -is [System.Management.Automation.Language.CommandAst]) {
                    $nm = $n.GetCommandName()
                    if ([string]::IsNullOrWhiteSpace($nm)) { return $false }
                    return $stateChangingCommands -contains $nm
                }
                return $false
            }, $true)

            if ($danger.Count -gt 0 -and -not $supports) {
                $findings.Add( (New-Finding -File $file -Line $func.Extent.StartLineNumber -Column $func.Extent.StartColumnNumber -Severity 'Warning' -Source 'Custom' -RuleName 'Function/MissingShouldProcess' -Message ("La función '{0}' ejecuta comandos de cambio de estado sin SupportsShouldProcess/ShouldProcess." -f $fname)) )
            }

            if (-not $cb) {
                $hasParamAttr = $false
                if ($pb -and $pb.Parameters) {
                    foreach ($paramAst in $pb.Parameters) {
                        if ($paramAst.Attributes -and ($paramAst.Attributes.Count -gt 0)) { $hasParamAttr = $true }
                    }
                }
                if ($hasParamAttr) {
                    $findings.Add( (New-Finding -File $file -Line $func.Extent.StartLineNumber -Column $func.Extent.StartColumnNumber -Severity 'Information' -Source 'Custom' -RuleName 'Function/MissingCmdletBinding' -Message ("La función '{0}' define atributos de parámetro sin CmdletBinding()." -f $fname)) )
                }
            }
        }
    }
    return $findings.ToArray()
}

function Resolve-TargetFiles {
    param([Parameter(Mandatory)][string]$Path)
    $patterns = @('*.ps1','*.psm1')
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop | Select-Object -First 1).ProviderPath
    $files = @()
    if (Test-Path -LiteralPath $resolved -PathType Leaf) {
        $files += $resolved
    } else {
        foreach ($p in $patterns) {
            $files += Get-ChildItem -LiteralPath $resolved -Recurse -File -Filter $p | ForEach-Object { $_.FullName }
        }
    }
    return @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

function Get-ReportPaths {
    param([Parameter(Mandatory)][string]$Directory,[Parameter(Mandatory)][string]$BaseName,[Parameter(Mandatory)][string[]]$Formats)
    $ts = (Get-Date -AsUTC).ToString('yyyyMMddTHHmmssZ')
    $map = @{}
    foreach ($fmt in $Formats) {
        $map[$fmt] = Join-Path -Path $Directory -ChildPath ("{0}-{1}.{2}" -f $BaseName, $ts, $fmt)
    }
    return $map
}

function Export-Findings {
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$Findings,
        [Parameter(Mandatory)][hashtable]$ReportPaths
    )
    $data = @($Findings)
    foreach ($k in $ReportPaths.Keys) {
        $target = $ReportPaths[$k]
        $dir = Split-Path -Path $target -Parent
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        switch ($k) {
            'json' { $data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $target -Encoding utf8NoBom }
            'csv'  { $data | Export-Csv -LiteralPath $target -NoTypeInformation -Encoding utf8 }
            'txt'  {
                $data | ForEach-Object {
                    '{0}:{1}:{2} [{3}] ({4}) {5} {6}' -f $_.ScriptName, $_.Line, $_.Column, $_.Severity, $_.Source, $_.RuleName, $_.Message
                } | Set-Content -LiteralPath $target -Encoding utf8NoBom
            }
        }
    }
}

# ====== Main ======
Write-Info '== QA Analyzer CLI (FOTO COMPLETA) =='

if (-not $TargetPath) { $TargetPath = Read-Host 'Ruta a analizar (archivo o carpeta)' }
if (-not (Test-Path -LiteralPath $TargetPath)) {
    Write-Err ("Ruta inválida: {0}" -f $TargetPath)
    exit 2
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$reportPaths = Get-ReportPaths -Directory $OutputDirectory -BaseName $ReportName -Formats $ReportFormat
Write-LogEvent -Message 'Parámetros de ejecución' -Level 'debug' -Data @{
    targetPath      = (Resolve-Path -LiteralPath $TargetPath).ProviderPath
    outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).ProviderPath
    formats         = $ReportFormat
    skipPssa        = $SkipPssa.IsPresent
}

if (-not $SkipPssa) { Ensure-Pssa; Test-SelfIntegrity } else { Write-Warn 'Saltando verificación de integridad por omisión de PSSA.' }

$files = @(Resolve-TargetFiles -Path $TargetPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($files.Count -eq 0) {
    Write-Info 'No hay archivos .ps1/.psm1 que analizar.'
    foreach ($rp in $reportPaths.Values) { New-Item -ItemType File -Path $rp -Force | Out-Null }
    exit 0
}
Write-Info ("Archivos a analizar: {0}" -f $files.Count)

$findings = [System.Collections.Generic.List[object]]::new()

$parseFindings = @(Invoke-ValidateParse -Files $files)
$parseFindingsCount = ($parseFindings | Measure-Object).Count
if ($parseFindingsCount -gt 0) {
    Write-Warn ("Errores de parseo: {0}." -f $parseFindingsCount)
    foreach ($f in $parseFindings) { $findings.Add($f) }
}

$badFiles  = @()
if ($parseFindingsCount -gt 0) { $badFiles = @($parseFindings | Group-Object ScriptName | ForEach-Object { $_.Name }) }
$goodFiles = @($files | Where-Object { $_ -notin $badFiles })

if (-not $SkipPssa -and $goodFiles.Count -gt 0) {
    $settings = Get-FullPssaSettings
    $severity = @('Error','Warning','Information')
    try {
        $pssaIssues = Invoke-ScriptAnalyzer -Path $goodFiles -Settings $settings -Severity $severity
        if ($pssaIssues) {
            foreach ($i in $pssaIssues) {
                $findings.Add( (New-Finding -File $i.ScriptName -Line $i.Line -Column $i.Column -Severity $i.Severity -Source 'PSSA' -RuleName $i.RuleName -Message $i.Message) )
            }
        }
    } catch {
        $findings.Add( (New-Finding -File $TargetPath -Severity 'Error' -Source 'PSSA' -RuleName 'AnalyzerRuntimeError' -Message ('Invoke-ScriptAnalyzer falló: {0}' -f $_.Exception.Message)) )
    }
}

try {
    $custom = @(Invoke-CustomChecks -Files $files)
    if (($custom | Measure-Object).Count -gt 0) {
        foreach ($c in $custom) { $findings.Add($c) }
    }
} catch {
    $findings.Add( (New-Finding -File $TargetPath -Severity 'Error' -Source 'Custom' -RuleName 'CustomChecksRuntimeError' -Message $_.Exception.Message) )
}

try {
    $astFind = @(Invoke-AstChecks -Files $files)
    if (($astFind | Measure-Object).Count -gt 0