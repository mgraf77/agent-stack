#!/usr/bin/env bash
# Usage check / fixture for the repo-context skill.
# Confirms pack-context.sh is deterministic (same input -> byte-identical
# output across two runs), refuses to write a bundle when the assembled
# content contains a planted fake credential, and never follows a tracked
# symlink to pull content from outside the selected target root into the
# bundle.
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

# Symlink escape: build a scratch git repo (never committed to this repo)
# containing a tracked symlink that points outside its own root, and prove
# pack-context.sh's `git ls-files` listing path never bundles it or the
# content it points to. A committed fixture can't exercise this: `find
# -type f` (the non-git fallback) already excludes symlinks on its own, so
# only a real git-tracked symlink reaches the code path this check guards.
if command -v git >/dev/null 2>&1; then
  symlink_repo="$work/symlink-repo"
  mkdir -p "$symlink_repo"
  echo "OUTSIDE-SECRET-MARKER: must never appear in a repo-context bundle" > "$work/outside-secret.txt"
  echo "safe fixture content" > "$symlink_repo/README.md"
  ln -s "../outside-secret.txt" "$symlink_repo/escape-link.txt"
  git -C "$symlink_repo" init -q
  git -C "$symlink_repo" -c user.email=test@example.com -c user.name=test add -A
  git -C "$symlink_repo" -c user.email=test@example.com -c user.name=test commit -q -m fixture

  if "$packer" "$symlink_repo" "$work/bundle-symlink.md" >/tmp/repo-context-check-symlink.$$ 2>&1; then
    if grep -q "escape-link.txt" "$work/bundle-symlink.md"; then
      echo "symlink escape: FAIL (bundle references the symlinked entry)" >&2
      ok=0
    elif grep -q "OUTSIDE-SECRET-MARKER" "$work/bundle-symlink.md"; then
      echo "symlink escape: FAIL (bundle leaked content from outside the target root)" >&2
      ok=0
    else
      echo "symlink escape: OK (tracked symlink pointing outside the target root was excluded)"
    fi
  else
    echo "symlink escape: FAIL (pack-context.sh errored instead of just skipping the symlink)" >&2
    cat /tmp/repo-context-check-symlink.$$ >&2
    ok=0
  fi
  rm -f /tmp/repo-context-check-symlink.$$
else
  echo "symlink escape: SKIPPED - git not available to build the fixture repo"
fi

if [ "$ok" -eq 0 ]; then
  echo "repo-context check: FAIL" >&2
  exit 1
fi

echo "repo-context check: OK"
