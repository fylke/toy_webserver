$ErrorActionPreference = 'Stop'

$portsFile = Join-Path $PSScriptRoot '..\.class-ports.env'
$httpPort = $env:HOST_HTTP_PORT

if ([string]::IsNullOrWhiteSpace($httpPort) -and (Test-Path $portsFile)) {
    $portsFromFile = Get-Content $portsFile | ForEach-Object {
        $key, $value = $_ -split '=', 2
        [PSCustomObject]@{ Key = $key; Value = $value }
    }
    $httpPort = ($portsFromFile | Where-Object { $_.Key -eq 'HOST_HTTP_PORT' } | Select-Object -First 1).Value
}

if ([string]::IsNullOrWhiteSpace($httpPort)) {
    $httpPort = '8080'
}

$response = Invoke-WebRequest -Uri "http://127.0.0.1:$httpPort/test.html" -SkipHttpErrorCheck

Write-Host "HTTP_PORT=$httpPort"
Write-Host "RESPONSE_CODE=$($response.StatusCode)"
Write-Host "RESPONSE_BODY=$($response.Content.Substring(0, [Math]::Min(120, $response.Content.Length)))"

if ($response.StatusCode -ne 200) {
    throw 'Smoke test failed.'
}
