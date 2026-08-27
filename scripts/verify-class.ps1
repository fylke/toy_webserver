$ErrorActionPreference = 'Stop'

function Get-ContainerCommand {
    if (-not [string]::IsNullOrWhiteSpace($env:CONTAINER_CMD)) {
        return $env:CONTAINER_CMD
    }

    if (Get-Command podman -ErrorAction SilentlyContinue) {
        return 'podman'
    }

    if (Get-Command docker -ErrorAction SilentlyContinue) {
        return 'docker'
    }

    throw 'No container CLI found. Install podman or docker.'
}

$containerCmd = Get-ContainerCommand
$httpPort = $env:HOST_HTTP_PORT

if ([string]::IsNullOrWhiteSpace($httpPort)) {
    $portLine = & $containerCmd port toy_webserver_dev 8080 | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($portLine)) {
        throw 'Could not determine host HTTP port.'
    }

    $httpPort = ($portLine -split ':')[-1]
}

$response = Invoke-WebRequest -Uri "http://127.0.0.1:$httpPort/test.html" -SkipHttpErrorCheck

Write-Host "HTTP_PORT=$httpPort"
Write-Host "RESPONSE_CODE=$($response.StatusCode)"
Write-Host "RESPONSE_BODY=$($response.Content.Substring(0, [Math]::Min(120, $response.Content.Length)))"

if ($response.StatusCode -ne 200) {
    throw 'Smoke test failed.'
}
