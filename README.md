# M365 Compliance Showcase 🛡️
[![CI](https://github.com/suresh-1001/m365-compliance-showcase/actions/workflows/ci.yml/badge.svg)](…)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE)

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
