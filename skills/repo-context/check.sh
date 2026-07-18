#!/usr/bin/env bash
# Usage check / fixture for the repo-context skill.
# Confirms pack-context.sh is deterministic (same input -> byte-identical
# output across two runs) and refuses to write a bundle when the assembled
# content contains a planted fake credential.
# TOOL: Bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
packer="$dir/pack-context.sh"
clean_fixture="$dir/fixtures/sample-project"
secret_fixture="$dir/fixtures/sample-project-secret"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

ok=1

if "$packer" "$clean_fixture" "$work/bundle-a.md" >/tmp/repo-context-check-a.$$ 2>&1 \
  && "$packer" "$clean_fixture" "$work/bundle-b.md" >/tmp/repo-context-check-b.$$ 2>&1; then
  if diff -q "$work/bundle-a.md" "$work/bundle-b.md" >/dev/null; then
    echo "determinism: OK (two runs produced a byte-identical bundle)"
  else
    echo "determinism: FAIL (two runs over the same fixture produced different output)" >&2
    ok=0
  fi
else
  echo "determinism: FAIL (pack-context.sh errored on the clean fixture)" >&2
  cat /tmp/repo-context-check-a.$$ /tmp/repo-context-check-b.$$ >&2
  ok=0
fi
rm -f /tmp/repo-context-check-a.$$ /tmp/repo-context-check-b.$$

if "$packer" "$secret_fixture" "$work/bundle-secret.md" >/tmp/repo-context-check-secret.$$ 2>&1; then
  echo "secret gate: FAIL (bundle was written even though the fixture contains a planted secret)" >&2
  cat /tmp/repo-context-check-secret.$$ >&2
  ok=0
else
  echo "secret gate: OK (pack-context.sh refused to write a bundle containing a planted secret)"
fi
rm -f /tmp/repo-context-check-secret.$$

if [ "$ok" -eq 0 ]; then
  echo "repo-context check: FAIL" >&2
  exit 1
fi

echo "repo-context check: OK"
