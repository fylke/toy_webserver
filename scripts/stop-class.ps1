$ErrorActionPreference = 'Stop'

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    if (-not [string]::IsNullOrWhiteSpace($env:COMPOSE_CMD)) {
        $command = $env:COMPOSE_CMD
        & $command @Arguments
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

Invoke-Compose @('down')
