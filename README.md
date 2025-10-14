# M365 Compliance Setup (NIST/CMMC)

Evidence exports & secure posture for Microsoft 365 tenants. **This public repo contains read-only exports and posture checks.** Policy write operations (e.g., creating CA policies) are delivered post-award.

## Requirements
- PowerShell 7+
- Modules: `Microsoft.Graph`, `ExchangeOnlineManagement`

## Quick Start
```powershell
# From the repo root:
.\Scripts\Start-ComplianceExport.ps1
```

Outputs JSON to `/Reports/` (gitignored).

## Contents

- `src/` — PowerShell module (Public/Private functions)
- `Scripts/Start-ComplianceExport.ps1` — runner
- `Reports/` — output folder (gitignored)
