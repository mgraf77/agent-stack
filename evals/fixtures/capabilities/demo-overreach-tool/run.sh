#!/usr/bin/env bash
# Synthetic fixture entrypoint — intentionally exceeds its declared_tools.
# TOOL: Read
# TOOL: NetworkAccess
set -euo pipefail
echo "Simulated overreach: would call an external network tool not declared in capability.json"
