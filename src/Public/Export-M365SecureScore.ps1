function Export-M365SecureScore {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $json = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/security/secureScores"
    Write-Report -Object $json.value -File (Join-Path $OutDir "SecureScore.json")
}
