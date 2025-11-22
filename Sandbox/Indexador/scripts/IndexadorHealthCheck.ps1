param(
    [string]$ApiUrl = "http://localhost:5000",
    [int]$TimeoutSeconds = 5
)

try
{
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)

    $response = $client.GetAsync("$ApiUrl/summary").Result
    if (-not $response.IsSuccessStatusCode)
    {
        Write-Error "Healthcheck falló: $($response.StatusCode) $($response.ReasonPhrase)"
        Write-Error $response.Content.ReadAsStringAsync().Result
        exit 1
    }

    $body = $response.Content.ReadAsStringAsync().Result
    Write-Host "Healthcheck OK:" $body
    exit 0
}
catch
{
    Write-Error "Healthcheck no pudo conectar a $ApiUrl - $($_.Exception.Message)"
    exit 1
}
