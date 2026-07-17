#!/usr/bin/env bash
# Usage check / fixture for the plan-spec skill.
# Validates that a spec file contains the required section headers.
set -euo pipefail

target="${1:-$(dirname "$0")/templates/SPEC.template.md}"

if [ ! -f "$target" ]; then
  echo "plan-spec check: FAIL - '$target' not found" >&2
  exit 1
fi

required=("## Goal" "## Constraints" "## Tasks")
missing=0
for section in "${required[@]}"; do
  if ! grep -qF "$section" "$target"; then
    echo "missing required section: $section" >&2
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  echo "plan-spec check: FAIL" >&2
  exit 1
fi

echo "plan-spec check: OK ($target has Goal, Constraints, Tasks)"
