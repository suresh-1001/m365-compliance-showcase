<#
Evaluation copy – for proposal. Full policy write operations delivered post-award.
#>
Import-Module "$PSScriptRoot/../src/M365Compliance.psd1" -Force
Connect-M365Secure
Export-M365SecureScore
Export-M365RiskyUsers
Export-M365CAPolicies
Export-M365AuditSnapshot
Write-Host "Reports written to: $((Resolve-Path "$PSScriptRoot/../Reports").Path)"
