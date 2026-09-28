$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$envPath = Join-Path $projectRoot ".env"

if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Missing .env. Copy .env.example to .env and configure Snowflake first."
}

$settings = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith("#") -or -not $trimmed.Contains("=")) {
        continue
    }
    $parts = $trimmed.Split("=", 2)
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if ($value.Length -ge 2 -and (
        ($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))
    )) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    $settings[$key] = $value
}

$defaults = @{
    SNOWFLAKE_ROLE = "SYSADMIN"
    SNOWFLAKE_WAREHOUSE = "NYC_TAXI_WH"
    SNOWFLAKE_DATABASE = "NYC_TAXI"
    TAXI_START_MONTH = "2025-01"
    TAXI_END_MONTH = "2026-08"
}

foreach ($entry in $defaults.GetEnumerator()) {
    if (-not $settings.ContainsKey($entry.Key) -or [string]::IsNullOrWhiteSpace($settings[$entry.Key])) {
        $settings[$entry.Key] = $entry.Value
    }
}

$required = @(
    "SNOWFLAKE_ACCOUNT",
    "SNOWFLAKE_USER",
    "SNOWFLAKE_PASSWORD",
    "SNOWFLAKE_ROLE",
    "SNOWFLAKE_WAREHOUSE",
    "SNOWFLAKE_DATABASE",
    "TAXI_START_MONTH",
    "TAXI_END_MONTH"
)

foreach ($key in $required) {
    if (-not $settings.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($settings[$key])) {
        throw "Missing required setting in .env: $key"
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes($settings[$key])
    $encoded = [Convert]::ToBase64String($bytes)
    [Environment]::SetEnvironmentVariable("SECRET_$key", $encoded, "Process")
}

Push-Location $projectRoot
try {
    docker compose --profile build build pipeline
    if ($LASTEXITCODE -ne 0) {
        throw "Pipeline image build failed with exit code $LASTEXITCODE"
    }

    docker compose up -d postgres kestra
    if ($LASTEXITCODE -ne 0) {
        throw "Kestra startup failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "Kestra is starting at http://localhost:8080"
Write-Host "Flow: lab.semana07 / nyc_yellow_taxi_elt"
Write-Host "Login: use KESTRA_ADMIN_EMAIL and KESTRA_ADMIN_PASSWORD from .env (or the documented local defaults)."
