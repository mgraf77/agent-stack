#!/usr/bin/env bash
# repo-context: deterministic repository context packaging.
# Adapted from the Repomix concept (yamadashy/repomix, MIT) — local
# allowlisted export with a secret scan on the assembled bundle before it's
# written; see notices/repo-context.md and
# catalog/capabilities/repomix-context-export.json.
# TOOL: Bash
set -euo pipefail

usage() {
  echo "Usage: $0 <target-dir> [output-file] [include-glob ...]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
target="$1"; shift
output="context-bundle.md"
if [[ $# -ge 1 ]]; then
  output="$1"
  shift
fi
include_globs=("$@")

[[ -d "$target" ]] || { echo "repo-context: '$target' is not a directory" >&2; exit 1; }

script_dir="$(cd "$(dirname "$0")" && pwd)"
scanner="$script_dir/../secret-safety/scan-secrets.sh"

denylist_regex='(^|/)(\.git|node_modules|dist|build|\.next|__pycache__|vendor)(/|$)'

list_files() {
  if [[ -d "$target/.git" ]]; then
    git -C "$target" ls-files
  else
    (cd "$target" && find . -type f | sed 's|^\./||')
  fi
}

is_binary() {
  # Dependency-free binary sniff: a NUL byte in the first 8000 bytes.
  od -An -tx1 -N 8000 "$1" 2>/dev/null | grep -q ' 00'
}

matches_include() {
  local path="$1"
  [[ ${#include_globs[@]} -eq 0 ]] && return 0
  local g
  for g in "${include_globs[@]}"; do
    # shellcheck disable=SC2053
    [[ "$path" == $g ]] && return 0
  done
  return 1
}

tmp_bundle="$(mktemp)"
trap 'rm -f "$tmp_bundle"' EXIT

files=()
while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  [[ "$rel" =~ $denylist_regex ]] && continue
  matches_include "$rel" || continue
  full="$target/$rel"
  [[ -f "$full" ]] || continue
  is_binary "$full" && continue
  files+=("$rel")
done < <(list_files | LC_ALL=C sort)

{
  echo "# Repository context bundle"
  echo
  echo "Source: $target"
  echo "Files: ${#files[@]}"
  echo
  echo "## Table of contents"
  for f in "${files[@]}"; do
    echo "- $f"
  done
  echo
  echo "## Contents"
  for f in "${files[@]}"; do
    echo
    echo "### $f"
    echo '```'
    cat "$target/$f"
    echo '```'
  done
} > "$tmp_bundle"

if [[ -x "$scanner" ]]; then
  if ! scan_out=$("$scanner" "$tmp_bundle" 2>&1); then
    echo "repo-context: refusing to write bundle — scan-secrets.sh flagged likely credential(s) in the assembled bundle:" >&2
    echo "$scan_out" >&2
    exit 1
  fi
else
  echo "repo-context: warning — scan-secrets.sh not found at $scanner, skipping secret scan" >&2
fi

cp "$tmp_bundle" "$output"
echo "repo-context: wrote $output (${#files[@]} file(s))"
