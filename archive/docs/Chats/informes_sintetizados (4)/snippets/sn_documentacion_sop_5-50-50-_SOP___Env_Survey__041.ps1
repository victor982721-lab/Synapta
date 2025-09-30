$terminal = [ordered]@{
  WindowsTerminal = [bool]$env:WT_SESSION
  WT_ProfileId    = $env:WT_PROFILE_ID
  TERM            = $env:TERM
  TERM_PROGRAM    = $env:TERM_PROGRAM
  ConEmu          = [bool]$env:ConEmuBuild
  VSCode          = [bool]$env:VSCODE_PID
}