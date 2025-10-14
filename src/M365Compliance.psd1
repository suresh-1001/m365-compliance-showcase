@{
    RootModule        = 'M365Compliance.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '0f1f8a37-0f42-4e4a-9ab6-3b2f7e6a11a1'
    Author            = 'Suresh Chand'
    CompanyName       = 'Suresh Chand'
    Description       = 'M365 tenant hardening & evidence exports aligned to NIST/CMMC.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Connect-M365Secure',
        'Get-M365ComplianceBaseline',
        'Export-M365SecureScore',
        'Export-M365RiskyUsers',
        'Export-M365CAPolicies',
        'Export-M365AuditSnapshot'
    )
    PrivateData = @{}
}
