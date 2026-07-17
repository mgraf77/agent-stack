#!/usr/bin/env bash
# Usage check / fixture for the orientation skill.
# Reports which orientation docs exist and the current git state for a repo path.
set -euo pipefail

target="${1:-.}"

if [ ! -d "$target" ]; then
  echo "orientation check: FAIL - '$target' is not a directory" >&2
  exit 1
fi

found=0
for doc in README.md AGENTS.md CLAUDE.md CONTRIBUTING.md; do
  if [ -f "$target/$doc" ]; then
    echo "found: $doc"
    found=1
  fi
done

if [ "$found" -eq 0 ]; then
  echo "no orientation docs found in $target (README.md, AGENTS.md, CLAUDE.md, CONTRIBUTING.md)"
fi

if git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$target" branch --show-current 2>/dev/null || echo "unknown")
  dirty=$(git -C "$target" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "git branch: $branch"
  echo "uncommitted changes: $dirty file(s)"
else
  echo "not a git repository: $target"
fi

echo "orientation check: OK"
