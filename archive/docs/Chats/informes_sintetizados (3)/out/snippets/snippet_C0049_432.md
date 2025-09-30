```

$(
  if ($report.dotnet_info) {
    [string]::Join("`n", ($report.dotnet_info -split "`n" | Select-Object -First 20))
  } else { "n/a" }
)

```