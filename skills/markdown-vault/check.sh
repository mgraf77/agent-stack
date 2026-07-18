#!/usr/bin/env bash
# Usage check / fixture for the markdown-vault skill.
# Confirms lint-notes.sh passes a clean fixture vault and fails (with
# clear, specific diagnostics) on a vault with a broken link, a note with
# no frontmatter, and a wiki note with no 'sources' field.
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

if broken_out=$("$linter" "$broken" 2>&1); then
  echo "broken vault: FAIL (linter missed the planted problems)" >&2
  echo "$broken_out" >&2
  ok=0
else
  echo "broken vault: OK (linter detected the planted problems)"
  if ! grep -qF "broken link [[Missing Note]]" <<<"$broken_out"; then
    echo "broken vault: FAIL (missing expected broken-link diagnostic)" >&2
    echo "$broken_out" >&2
    ok=0
  fi
  if ! grep -qF "no YAML frontmatter block" <<<"$broken_out"; then
    echo "broken vault: FAIL (missing expected no-frontmatter diagnostic)" >&2
    echo "$broken_out" >&2
    ok=0
  fi
  if ! grep -qF "missing-sources.md: missing frontmatter field 'sources'" <<<"$broken_out"; then
    echo "broken vault: FAIL (missing expected missing-sources diagnostic)" >&2
    echo "$broken_out" >&2
    ok=0
  fi
fi

if [ "$ok" -eq 0 ]; then
  echo "markdown-vault check: FAIL" >&2
  exit 1
fi

echo "markdown-vault check: OK"
