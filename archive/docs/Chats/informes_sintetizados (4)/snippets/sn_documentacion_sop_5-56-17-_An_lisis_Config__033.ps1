[OutputType([pscustomobject])]
param()

[pscustomobject]@{
  Name    = $FunctionName
  Version = $Script:RepoAR_Version  # mantener en 1-INFO del módulo
  Status  = 'Success'               # Success|Warning|Error
  Details = $DetailsObject          # anidado; datos específicos
  Path    = $OutputPath             # si aplica
}