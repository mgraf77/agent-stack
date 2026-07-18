#!/usr/bin/env bash
# change-impact: lightweight, offline risk categorization for a list of
# changed file paths, to stage review depth by risk instead of reviewing
# every file identically. Adapted from the general concept of Cavekit's
# drift check and Superpowers' staged review; see notices/change-impact.md.
# TOOL: Bash
set -euo pipefail

usage() {
  echo "Usage: $0 [file-with-paths]" >&2
  echo "       git diff --name-only <base>... | $0" >&2
  exit 2
}

[[ $# -le 1 ]] || usage

if [[ $# -eq 1 ]]; then
  [[ -f "$1" ]] || { echo "change-impact: '$1' not found" >&2; exit 1; }
  input="$1"
else
  input="/dev/stdin"
fi

classify() {
  local path="$1"
  local lower
  lower=$(tr '[:upper:]' '[:lower:]' <<<"$path")
  case "$lower" in
    *secret*|*credential*|*/auth/*|*.env|*.env.*|*.pem|*.key|*id_rsa*)
      echo "security-sensitive"; return ;;
  esac
  case "$lower" in
    *migrat*|*schema*|*.sql)
      echo "schema-or-migration"; return ;;
  esac
  case "$lower" in
    .github/workflows/*|dockerfile|docker-compose*|*.tf|terraform/*|package.json|package-lock.json|requirements*.txt|gemfile|go.mod|go.sum)
      echo "config-or-infra"; return ;;
  esac
  case "$lower" in
    node_modules/*|dist/*|build/*|vendor/*|*.lock|*.min.js)
      echo "generated-or-vendored"; return ;;
  esac
  case "$lower" in
    *test*|*spec*|__tests__/*|tests/*)
      echo "tests-only"; return ;;
  esac
  case "$lower" in
    *.md|*.rst|*.txt|docs/*)
      echo "docs-only"; return ;;
  esac
  echo "code-change"
}

review_note() {
  case "$1" in
    security-sensitive) echo "full review; run secret-safety before staging" ;;
    schema-or-migration) echo "full review; check backward compatibility and rollout order" ;;
    config-or-infra) echo "review carefully; confirm no secrets or credentials were introduced" ;;
    generated-or-vendored) echo "skip line-by-line review; confirm it was regenerated, not hand-edited" ;;
    tests-only) echo "confirm coverage matches the behavior change, not just the diff shape" ;;
    docs-only) echo "skim for accuracy; low risk" ;;
    code-change) echo "standard review" ;;
  esac
}

declare -A by_category
paths=()
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  paths+=("$path")
done < "$input"

if [[ ${#paths[@]} -eq 0 ]]; then
  echo "change-impact: no changed paths given" >&2
  exit 1
fi

echo "| Category | Path |"
echo "|---|---|"
while IFS= read -r path; do
  cat=$(classify "$path")
  echo "| $cat | $path |"
  by_category["$cat"]=1
done < <(printf '%s\n' "${paths[@]}" | LC_ALL=C sort)

echo
echo "## Suggested review depth by category"
echo
for cat in security-sensitive schema-or-migration config-or-infra generated-or-vendored tests-only docs-only code-change; do
  [[ -n "${by_category[$cat]:-}" ]] || continue
  echo "- **$cat**: $(review_note "$cat")"
done
