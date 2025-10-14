function Get-M365ComplianceBaseline {
    [CmdletBinding()] param()
    $result = [ordered]@{}

    try {
        $ca = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
        $result['ConditionalAccessCount'] = $ca.value.Count
    } catch { $result['ConditionalAccessCount'] = 'N/A' }

    try {
        $dkim = Get-DkimSigningConfig | Select-Object Domain,Enabled
        $result['DKIM'] = $dkim
    } catch { $result['DKIM'] = 'N/A' }

    try {
        $ual = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
        $result['UnifiedAuditLogEnabled'] = $ual
    } catch { $result['UnifiedAuditLogEnabled'] = 'N/A' }

    [pscustomobject]$result
}
