$ErrorActionPreference = 'Stop'

param(
    [string] $Token = $env:CLASS_SHARED_TOKEN
)

if ([string]::IsNullOrWhiteSpace($Token)) {
    throw 'Provide the shared token with -Token or CLASS_SHARED_TOKEN.'
}

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
$proxyPort = $env:HOST_PROXY_PORT

if ([string]::IsNullOrWhiteSpace($proxyPort)) {
    $portLine = & $containerCmd port toy_webserver_edge 8081 | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($portLine)) {
        throw 'Could not determine host proxy port.'
    }

    $proxyPort = ($portLine -split ':')[-1]
}

$noTokenResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$proxyPort/test.html" -SkipHttpErrorCheck
$withTokenResponse = Invoke-WebRequest -Uri "http://127.0.0.1:$proxyPort/test.html" -Headers @{ 'X-Class-Token' = $Token } -SkipHttpErrorCheck

Write-Host "PROXY_PORT=$proxyPort"
Write-Host "NO_TOKEN_CODE=$($noTokenResponse.StatusCode)"
Write-Host "WITH_TOKEN_CODE=$($withTokenResponse.StatusCode)"
Write-Host "WITH_TOKEN_BODY=$($withTokenResponse.Content.Substring(0, [Math]::Min(120, $withTokenResponse.Content.Length)))"

if ($noTokenResponse.StatusCode -ne 401 -or $withTokenResponse.StatusCode -ne 200) {
    throw 'Smoke test failed.'
}
