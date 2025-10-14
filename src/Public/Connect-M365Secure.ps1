function Connect-M365Secure {
    [CmdletBinding()]
    param(
        [string[]]$Scopes = @(
            'Policy.Read.All','Policy.ReadWrite.ConditionalAccess',
            'Directory.Read.All','Reports.Read.All'
        )
    )
    Import-Module Microsoft.Graph -ErrorAction Stop
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-MgGraph -Scopes $Scopes | Out-Null
    Select-MgProfile beta
    Connect-ExchangeOnline -ShowBanner:$false
}
