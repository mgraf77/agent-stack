#!/usr/bin/env bash
# Usage check / fixture for the pr-feedback skill.
# Validates that a triage file has the required table columns.
set -euo pipefail

target="${1:-$(dirname "$0")/templates/triage.template.md}"

if [ ! -f "$target" ]; then
  echo "pr-feedback check: FAIL - '$target' not found" >&2
  exit 1
fi

header=$(grep -m1 '^|.*Comment.*|' "$target" || true)

if [ -z "$header" ]; then
  echo "pr-feedback check: FAIL - no table header row found" >&2
  exit 1
fi

missing=0
for column in "Comment" "Category" "Action" "Status"; do
  if ! grep -qF "$column" <<<"$header"; then
    echo "missing required column: $column" >&2
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  echo "pr-feedback check: FAIL" >&2
  exit 1
fi

echo "pr-feedback check: OK ($target has Comment, Category, Action, Status columns)"
