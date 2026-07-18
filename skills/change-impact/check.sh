#!/usr/bin/env bash
# Usage check / fixture for the change-impact skill.
# Confirms classify-diff.sh assigns the expected risk category to one path
# per category, using the bundled fixture list.
# TOOL: Bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
classifier="$dir/classify-diff.sh"
fixture="$dir/fixtures/sample-changed-files.txt"

out=$("$classifier" "$fixture")

ok=1
declare -A expected=(
  ["config/.env.production"]="security-sensitive"
  ["db/migrations/0007_add_users.sql"]="schema-or-migration"
  [".github/workflows/ci.yml"]="config-or-infra"
  ["dist/bundle.min.js"]="generated-or-vendored"
  ["src/payments/__tests__/charge.spec.ts"]="tests-only"
  ["docs/architecture.md"]="docs-only"
  ["src/payments/charge.ts"]="code-change"
)

for path in "${!expected[@]}"; do
  want="${expected[$path]}"
  if ! grep -qF "| $want | $path |" <<<"$out"; then
    echo "wrong or missing category for $path: expected '$want'" >&2
    ok=0
  fi
done

if [[ "$ok" -eq 0 ]]; then
  echo "-- full output --" >&2
  echo "$out" >&2
  echo "change-impact check: FAIL" >&2
  exit 1
fi

echo "change-impact check: OK (7/7 fixture paths classified as expected)"
