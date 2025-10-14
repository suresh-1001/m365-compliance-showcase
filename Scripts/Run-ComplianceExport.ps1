# Runs the compliance export from repo root or any location
Param(
    [string]$RepoRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$scriptPath = Join-Path $RepoRoot "Scripts/Start-ComplianceExport.ps1"
if (-not (Test-Path $scriptPath)) {
    throw "Could not find Scripts/Start-ComplianceExport.ps1 under $RepoRoot"
}

# Import and run
& $scriptPath
