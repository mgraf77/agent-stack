#!/usr/bin/env bash
# Usage check / fixture for the markdown-vault skill.
# Confirms lint-notes.sh passes a clean fixture vault and fails (with a
# clear diagnostic) on a vault with a broken link and a note with no
# frontmatter.
# TOOL: Bash
set -euo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
linter="$dir/lint-notes.sh"
clean="$dir/fixtures/vault-clean"
broken="$dir/fixtures/vault-broken"

ok=1

if "$linter" "$clean" >/tmp/markdown-vault-clean.$$ 2>&1; then
  echo "clean vault: OK (no false positive)"
else
  echo "clean vault: FAIL (false positive)" >&2
  cat /tmp/markdown-vault-clean.$$ >&2
  ok=0
fi
rm -f /tmp/markdown-vault-clean.$$

if "$linter" "$broken" >/tmp/markdown-vault-broken.$$ 2>&1; then
  echo "broken vault: FAIL (linter missed the planted problems)" >&2
  cat /tmp/markdown-vault-broken.$$ >&2
  ok=0
else
  echo "broken vault: OK (linter detected the planted problems)"
fi
rm -f /tmp/markdown-vault-broken.$$

if [ "$ok" -eq 0 ]; then
  echo "markdown-vault check: FAIL" >&2
  exit 1
fi

echo "markdown-vault check: OK"
