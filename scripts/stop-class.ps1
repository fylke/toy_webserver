$ErrorActionPreference = 'Stop'

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

Remove-Item -Path (Join-Path $PSScriptRoot '..\.class-ports.env') -Force -ErrorAction SilentlyContinue
Invoke-Compose @('down')
