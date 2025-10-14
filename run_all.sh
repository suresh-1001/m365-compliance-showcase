#!/usr/bin/env bash
set -euo pipefail

# This wrapper just calls the bootstrap with your env variables.
# Example:
#   REPO_NAME="m365-compliance-setup" GH_USER="suresh-1001" GH_PAT="ghp_xxx" ./run_all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/bootstrap_m365_repo.sh"
