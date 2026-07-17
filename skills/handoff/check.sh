#!/usr/bin/env bash
# Usage check / fixture for the handoff skill.
# Validates that a handoff file contains the required section headers.
set -euo pipefail

target="${1:-$(dirname "$0")/templates/HANDOFF.template.md}"

if [ ! -f "$target" ]; then
  echo "handoff check: FAIL - '$target' not found" >&2
  exit 1
fi

required=("## Changed" "## Why" "## Validation" "## Remaining risks" "## Current state")
missing=0
for section in "${required[@]}"; do
  if ! grep -qF "$section" "$target"; then
    echo "missing required section: $section" >&2
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  echo "handoff check: FAIL" >&2
  exit 1
fi

echo "handoff check: OK ($target has all required sections)"
