#!/usr/bin/env bash
# Usage check / fixture for the secret-safety skill.
# Confirms scan-secrets.sh passes on a clean fixture and fails (detects) on a
# fixture containing well-known placeholder secret patterns.
# TOOL: Bash
set -euo pipefail

dir=$(dirname "$0")
scanner="$dir/scan-secrets.sh"
clean="$dir/fixtures/sample-clean.txt"
secret="$dir/fixtures/sample-secret.txt"

ok=1

if "$scanner" "$clean" >/tmp/secret-safety-clean.$$ 2>&1; then
  echo "clean fixture: OK (no false positive)"
else
  echo "clean fixture: FAIL (false positive)" >&2
  cat /tmp/secret-safety-clean.$$ >&2
  ok=0
fi
rm -f /tmp/secret-safety-clean.$$

if "$scanner" "$secret" >/tmp/secret-safety-secret.$$ 2>&1; then
  echo "secret fixture: FAIL (scanner missed a known pattern)" >&2
  cat /tmp/secret-safety-secret.$$ >&2
  ok=0
else
  echo "secret fixture: OK (scanner detected the planted patterns)"
fi
rm -f /tmp/secret-safety-secret.$$

if [ "$ok" -eq 0 ]; then
  echo "secret-safety check: FAIL" >&2
  exit 1
fi

echo "secret-safety check: OK"
