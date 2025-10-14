\
#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG (env override allowed) =========================================
REPO_NAME="${REPO_NAME:-m365-compliance-setup}"
TARGET_DIR="${TARGET_DIR:-$HOME/_stage/$REPO_NAME}"
GH_USER="${GH_USER:-suresh-1001}"
PUSH_REMOTE="${PUSH_REMOTE:-true}"      # true|false
GH_PAT="${GH_PAT:-}"                    # optional; if set, will auto-create repo via API
GH_API="${GH_API:-https://api.github.com}"  # override for GH Enterprise if needed
GH_HOST="${GH_HOST:-github.com}"            # override for GH Enterprise if needed
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
# ============================================================================

say() { printf ">>> %s\n" "$*"; }
die() { printf "!!! %s\n" "$*" >&2; exit 1; }

# --- Validate dependencies ---
command -v git >/dev/null 2>&1 || die "git is required"
if [[ -n "$GH_PAT" ]]; then
  command -v curl >/dev/null 2>&1 || die "curl is required when GH_PAT is provided"
  command -v jq >/dev/null 2>&1 || die "jq is required when GH_PAT is provided (for parsing API response)"
fi

say "Creating repo at: $TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# --- Directory structure ---
mkdir -p src/Public src/Private Scripts Reports

# --- .gitignore ---
cat > .gitignore <<'EOF'
Reports/
*.ps1xml
*.psd1.user
*.log
.vscode/
.idea/
.DS_Store
EOF

# --- LICENSE ---
cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2025 Suresh Chand

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
EOF

# --- README.md (repo README) ---
cat > README.md <<'EOF'
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
EOF

# --- PowerShell Module Manifest ---
cat > src/M365Compliance.psd1 <<'EOF'
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
EOF

# --- PowerShell Module Loader ---
cat > src/M365Compliance.psm1 <<'EOF'
$public  = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter *.ps1 -ErrorAction SilentlyContinue
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -ErrorAction SilentlyContinue

foreach($f in $private){ . $f.FullName }
foreach($f in $public) { . $f.FullName }

Export-ModuleMember -Function $($public | ForEach-Object { $_.BaseName })
EOF

# --- Public Functions ---
cat > src/Public/Connect-M365Secure.ps1 <<'EOF'
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
EOF

cat > src/Public/Get-M365ComplianceBaseline.ps1 <<'EOF'
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
EOF

cat > src/Public/Export-M365SecureScore.ps1 <<'EOF'
function Export-M365SecureScore {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $json = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/security/secureScores"
    Write-Report -Object $json.value -File (Join-Path $OutDir "SecureScore.json")
}
EOF

cat > src/Public/Export-M365RiskyUsers.ps1 <<'EOF'
function Export-M365RiskyUsers {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $json = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/identityProtection/riskyUsers"
    Write-Report -Object $json.value -File (Join-Path $OutDir "RiskyUsers.json")
}
EOF

cat > src/Public/Export-M365CAPolicies.ps1 <<'EOF'
function Export-M365CAPolicies {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $json = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
    Write-Report -Object $json.value -File (Join-Path $OutDir "ConditionalAccessPolicies.json")
}
EOF

cat > src/Public/Export-M365AuditSnapshot.ps1 <<'EOF'
function Export-M365AuditSnapshot {
    [CmdletBinding()]
    param([string]$OutDir = (Join-Path $PSScriptRoot '..\..\Reports'))
    Ensure-Folders -Path $OutDir
    $summary = Get-M365ComplianceBaseline
    Write-Report -Object $summary -File (Join-Path $OutDir "BaselineSummary.json")
}
EOF

# --- Private Helpers ---
cat > src/Private/Ensure-Folders.ps1 <<'EOF'
function Ensure-Folders {
    param([Parameter(Mandatory)][string]$Path)
    if(-not (Test-Path $Path)){
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}
EOF

cat > src/Private/Write-Report.ps1 <<'EOF'
function Write-Report {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$File
    )
    $dir = Split-Path -Parent $File
    if(-not (Test-Path $dir)){
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth 8 | Out-File -FilePath $File -Encoding UTF8 -Force
    Write-Host "Wrote $File"
}
EOF

# --- Runner ---
cat > Scripts/Start-ComplianceExport.ps1 <<'EOF'
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
EOF

# --- Optional proposal attachment readme ---
cat > M365_Compliance_Setup_README.md <<'EOF'
# Microsoft 365 Tenant Setup & Daily Administration – Compliance Build (NIST/CMMC/DFARS)

Baseline hardening + daily evidence exports via PowerShell/Graph. See `/Scripts/Start-ComplianceExport.ps1`.
EOF

# --- Git init/commit ---
if [ ! -d ".git" ]; then
  git init
fi
git add .
git commit -m "Init: M365 compliance module skeleton" || true

# --- Default branch ---
git branch -M "$DEFAULT_BRANCH"

# --- Optionally create GitHub repo via API (idempotent) ---
REMOTE_URL="https://${GH_HOST}/${GH_USER}/${REPO_NAME}.git"
if [[ -n "$GH_PAT" ]]; then
  say "Ensuring GitHub repo exists: ${GH_USER}/${REPO_NAME}"
  # Try to GET the repo; if 404, create it
  http_code=$(curl -sS -o /dev/null -w "%{http_code}" -H "Authorization: token ${GH_PAT}" \
    "${GH_API}/repos/${GH_USER}/${REPO_NAME}" || true)
  if [[ "$http_code" == "404" ]]; then
    say "Creating repo via API..."
    create_resp=$(curl -sS -H "Authorization: token ${GH_PAT}" -H "Accept: application/vnd.github+json" \
      -X POST "${GH_API}/user/repos" \
      -d "{\"name\":\"${REPO_NAME}\",\"private\":false,\"auto_init\":false}")
    # Basic check for errors
    if echo "$create_resp" | jq -e '.id' >/dev/null 2>&1; then
      say "Repo created."
    else
      echo "$create_resp" | jq . 2>/dev/null || true
      die "Failed to create GitHub repo via API."
    fi
  else
    say "Repo exists (HTTP ${http_code})."
  fi
fi

# --- Remote & push ---
if [ "$PUSH_REMOTE" = "true" ]; then
  say "Adding remote: $REMOTE_URL"
  git remote remove github 2>/dev/null || true
  if [[ -n "$GH_PAT" ]]; then
    # Use PAT in remote URL for non-interactive push (avoid echoing token to logs)
    git remote add github "https://${GH_USER}:${GH_PAT}@${GH_HOST}/${GH_USER}/${REPO_NAME}.git"
    say "Pushing to GitHub with PAT (token not echoed)..."
  else
    git remote add github "$REMOTE_URL"
    say "Pushing to GitHub (you may be prompted for PAT/credentials)..."
  fi
  git push -u github "$DEFAULT_BRANCH"
fi

say "Done. Repo ready at: $TARGET_DIR"
say "GitHub: https://${GH_HOST}/${GH_USER}/${REPO_NAME}"
