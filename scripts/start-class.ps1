$ErrorActionPreference = 'Stop'

function Get-FreePort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = ($listener.LocalEndpoint).Port
    $listener.Stop()
    return $port
}

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    if (-not [string]::IsNullOrWhiteSpace($env:COMPOSE_CMD)) {
        $parts = $env:COMPOSE_CMD -split '\s+'
        $leadingArgs = @()
        if ($parts.Length -gt 1) {
            $leadingArgs = $parts[1..($parts.Length - 1)]
        }
        & $parts[0] @($leadingArgs + $Arguments)
        return
    }

    if (Get-Command podman -ErrorAction SilentlyContinue) {
        & podman compose version *> $null
        if ($LASTEXITCODE -eq 0) {
            & podman compose @Arguments
            return
        }
    }

    if (Get-Command podman-compose -ErrorAction SilentlyContinue) {
        & podman-compose @Arguments
        return
    }

    throw 'Install podman or podman-compose before running this script.'
}

if ($env:RANDOMIZE_PORTS -eq '1') {
    if ([string]::IsNullOrWhiteSpace($env:HOST_TCP_PORT)) {
        $env:HOST_TCP_PORT = [string](Get-FreePort)
    }
    if ([string]::IsNullOrWhiteSpace($env:HOST_HTTP_PORT)) {
        $env:HOST_HTTP_PORT = [string](Get-FreePort)
    }
}

$tcpPort = $env:HOST_TCP_PORT
if ([string]::IsNullOrWhiteSpace($tcpPort)) {
    $tcpPort = '7777'
}

$httpPort = $env:HOST_HTTP_PORT
if ([string]::IsNullOrWhiteSpace($httpPort)) {
    $httpPort = '8080'
}

Write-Host "Using host ports: tcp=$tcpPort http=$httpPort"

$portsFile = Join-Path $PSScriptRoot '..\.class-ports.env'
"HOST_TCP_PORT=$tcpPort`nHOST_HTTP_PORT=$httpPort" | Set-Content -Path $portsFile -NoNewline

Invoke-Compose @('up', '-d', '--build')
Invoke-Compose @('exec', '-T', 'erlang-dev', 'sh', '-lc', 'cd /workspace/toy_webserver && rebar3 compile && (nohup erl -noshell -pa _build/default/lib/toy_webserver/ebin -eval "http_server:start(8080)." >/tmp/http_server.log 2>&1 &)')
