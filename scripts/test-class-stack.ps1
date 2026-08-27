$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$portsFile = Join-Path $scriptDir '..\.class-ports.env'

function Invoke-Cleanup {
    & (Join-Path $scriptDir 'stop-class.ps1') 2>$null
}

trap {
    Invoke-Cleanup
    throw $_
}

$env:RANDOMIZE_PORTS = '1'
& (Join-Path $scriptDir 'start-class.ps1')

if (-not (Test-Path $portsFile)) {
    throw "start-class.ps1 did not write $portsFile"
}

$portsFromFile = Get-Content $portsFile | ForEach-Object {
    $key, $value = $_ -split '=', 2
    [PSCustomObject]@{ Key = $key; Value = $value }
}
$httpPort = ($portsFromFile | Where-Object { $_.Key -eq 'HOST_HTTP_PORT' } | Select-Object -First 1).Value

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    try {
        Invoke-WebRequest -Uri "http://127.0.0.1:$httpPort/test.html" -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ready = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    throw "HTTP server on port $httpPort never became ready"
}

& (Join-Path $scriptDir 'verify-class.ps1')

& (Join-Path $scriptDir 'stop-class.ps1')

if (Test-Path $portsFile) {
    throw "stop-class.ps1 did not remove $portsFile"
}

Write-Host 'Class stack setup test passed.'
