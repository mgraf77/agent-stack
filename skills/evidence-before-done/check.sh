#!/usr/bin/env bash
# Usage check / fixture for the evidence-before-done skill.
# Flags unverified-claim phrases whose blank-line-delimited paragraph does
# not also contain an evidence marker.
set -euo pipefail

target="${1:-}"

if [ -z "$target" ]; then
  echo "usage: check.sh <file-to-scan>" >&2
  exit 2
fi

if [ ! -f "$target" ]; then
  echo "evidence-before-done check: FAIL - '$target' not found" >&2
  exit 1
fi

hits=$(awk '
  BEGIN { RS=""; FS="\n" }
  {
    para = $0
    lower = tolower(para)
    if (lower ~ /should work|this fixes it|that should do it|now it works/) {
      if (para !~ /Ran:|Output:|Verified:/) {
        print "unverified claim in paragraph:"
        print para
        print "---"
        found = 1
      }
    }
  }
  END { exit found ? 1 : 0 }
' "$target") && status=0 || status=$?

if [ -n "$hits" ]; then
  echo "$hits"
fi

if [ "$status" -ne 0 ]; then
  echo "evidence-before-done check: FAIL - unverified claims found" >&2
  exit 1
fi

echo "evidence-before-done check: OK - no unverified claims in $target"
