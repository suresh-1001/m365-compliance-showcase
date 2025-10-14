function Export-M365AuditSnapshot {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $summary = Get-M365ComplianceBaseline
    Write-Report -Object $summary -File (Join-Path $OutDir "BaselineSummary.json")
}
