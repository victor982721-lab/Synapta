function Start-Mirror {
  $opts = @("--no-control", "--max-size", $MaxSize, "--video-bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")
  if ($AlwaysOnTop) { $opts += "--always-on-top" }
  Write-Host "Launching scrcpy in READ-ONLY mode (no input will be sent to the phone)..."
  & scrcpy @opts
}