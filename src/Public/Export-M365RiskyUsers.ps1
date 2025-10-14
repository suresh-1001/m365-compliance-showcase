function Export-M365RiskyUsers {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $json = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/identityProtection/riskyUsers"
    Write-Report -Object $json.value -File (Join-Path $OutDir "RiskyUsers.json")
}
