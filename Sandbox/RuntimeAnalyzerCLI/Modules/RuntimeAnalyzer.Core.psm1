using namespace System.Management.Automation.Language

function Resolve-RuntimeAnalyzerPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path cannot be null or empty."
    }

    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
    }

    return [System.IO.Path]::GetFullPath($Path)
}

function Get-ExportedFunctionNames {
    param(
        [Parameter(Mandatory)]
        [ScriptBlockAst] $Ast
    )

    $exports = @()
    $exportCommands = $Ast.FindAll({
            param($node)
            $node -is [CommandAst] -and $node.GetCommandName() -eq 'Export-ModuleMember'
        }, $true)

    foreach ($command in $exportCommands) {
        $captureForFunction = $false
        for ($i = 1; $i -lt $command.CommandElements.Count; $i++) {
            $element = $command.CommandElements[$i]
            if ($element -is [CommandParameterAst]) {
                $captureForFunction = $element.ParameterName -eq 'Function'
                continue
            }

            if ($element -is [StringConstantExpressionAst]) {
                if ($captureForFunction -or $i -eq 1) {
                    $value = $element.Value
                    if (-not [string]::IsNullOrWhiteSpace($value)) {
                        $exports += $value
                    }
                }
            } else {
                $captureForFunction = $false
            }
        }
    }

    return $exports | Select-Object -Unique
}

function Get-ParameterInfo {
    param(
        [Parameter(Mandatory)]
        [ParameterAst] $ParameterAst
    )

    $typeName = $null
    $isSwitch = $false
    if ($ParameterAst.StaticType -and $ParameterAst.StaticType.FullName -and $ParameterAst.StaticType.FullName -ne 'System.Object') {
        $typeName = "[{0}]" -f $ParameterAst.StaticType.Name
        if ($ParameterAst.StaticType.FullName -eq 'System.Management.Automation.SwitchParameter') {
            $isSwitch = $true
        }
    } elseif ($ParameterAst.Attributes) {
        $typeConstraint = $ParameterAst.Attributes | Where-Object { $_ -is [TypeConstraintAst] } | Select-Object -First 1
        if ($typeConstraint) {
            $typeName = "[{0}]" -f $typeConstraint.TypeName.Name
            if ($typeConstraint.TypeName.GetReflectionType().FullName -eq 'System.Management.Automation.SwitchParameter') {
                $isSwitch = $true
            }
        }
    }

    $isMandatory = $false
    $valueFromPipeline = $false
    $valueFromPipelineByProperty = $false

    foreach ($attribute in $ParameterAst.Attributes | Where-Object { $_ -is [AttributeAst] }) {
        $reflectionType = $null
        try {
            $reflectionType = $attribute.TypeName.GetReflectionType()
        } catch {
            $reflectionType = $null
        }

        $typeFullName = $reflectionType?.FullName
        if ($typeFullName -ne 'System.Management.Automation.ParameterAttribute') {
            continue
        }

        foreach ($namedArgument in $attribute.NamedArguments) {
            $argumentName = $namedArgument.ArgumentName
            $argumentValue = $namedArgument.Expression.SafeGetValue()
            switch ($argumentName) {
                'Mandatory' { $isMandatory = [bool]$argumentValue }
                'ValueFromPipeline' { $valueFromPipeline = [bool]$argumentValue }
                'ValueFromPipelineByPropertyName' { $valueFromPipelineByProperty = [bool]$argumentValue }
            }
        }
    }

    [pscustomobject]@{
        Name                               = $ParameterAst.Name.VariablePath.UserPath
        Type                               = $typeName
        IsMandatory                         = $isMandatory
        ValueFromPipeline                   = $valueFromPipeline
        ValueFromPipelineByPropertyName     = $valueFromPipelineByProperty
        IsSwitch                            = $isSwitch
    }
}

function Get-RuntimeAnalyzerFunctionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TargetPath,

        [switch] $IncludePrivate
    )

    $resolvedPath = Resolve-RuntimeAnalyzerPath -Path $TargetPath
    if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
        throw "Target path '$resolvedPath' does not exist."
    }

    $tokens = $null
    $errors = $null
    $ast = [Parser]::ParseFile($resolvedPath, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        $messages = $errors | ForEach-Object { $_.Message }
        throw "Failed to parse target: $($messages -join '; ')"
    }

    $isModule = [System.IO.Path]::GetExtension($resolvedPath).Equals('.psm1', [System.StringComparison]::OrdinalIgnoreCase)
    $exportedNames = @()
    if ($isModule) {
        $exportedNames = Get-ExportedFunctionNames -Ast $ast
    }
    $exportsSpecified = $exportedNames.Count -gt 0

    $functions = $ast.FindAll({
            param($node)
            $node -is [FunctionDefinitionAst]
        }, $true)

    $functionInfo = @()
    foreach ($functionAst in $functions) {
        $functionName = $functionAst.Name
        $isPrivateFunction = $false
        if ($functionName -match '^(?<scope>[^:]+):(?<name>.+)$') {
            $scope = $matches['scope']
            $functionName = $matches['name']
            if ($scope -in @('Private', 'ScriptPrivate')) {
                $isPrivateFunction = $true
            }
        }

        if (-not $IncludePrivate -and $isPrivateFunction) {
            continue
        }

        $isAdvanced = $false
        if ($functionAst.Body -and $functionAst.Body.ParamBlock -and $functionAst.Body.ParamBlock.Attributes) {
            foreach ($attr in $functionAst.Body.ParamBlock.Attributes) {
                if ($attr.TypeName.Name -eq 'CmdletBinding') {
                    $isAdvanced = $true
                }
            }
        }

        $paramInfo = @()
        if ($functionAst.Parameters) {
            foreach ($parameter in $functionAst.Parameters) {
                $paramInfo += Get-ParameterInfo -ParameterAst $parameter
            }
        }

        $isExported = $true
        if ($isModule) {
            if ($exportsSpecified) {
                $isExported = $exportedNames -contains $functionName
            } else {
                $isExported = -not $isPrivateFunction
            }
        }

        if (-not $IncludePrivate -and -not $isExported -and $isModule) {
            continue
        }

        $functionInfo += [pscustomobject]@{
            Name            = $functionName
            IsAdvanced      = $isAdvanced
            Parameters      = $paramInfo
            AstNode         = $functionAst
            SourceFile      = $resolvedPath
            IsExported      = $isExported
            SupportsPipeline = [bool]($paramInfo | Where-Object { $_.ValueFromPipeline -or $_.ValueFromPipelineByPropertyName })
        }
    }

    return $functionInfo
}

Export-ModuleMember -Function Resolve-RuntimeAnalyzerPath, Get-RuntimeAnalyzerFunctionInfo
