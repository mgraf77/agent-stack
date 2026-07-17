#!/usr/bin/env bash
# Usage check / fixture for the browser-qa skill.
# Confirms the Playwright smoke-check template is syntactically valid JS.
# Does not launch a browser or require a running app.
set -euo pipefail

dir=$(dirname "$0")
template="$dir/templates/smoke.spec.template.js"

if [ ! -f "$template" ]; then
  echo "browser-qa check: FAIL - '$template' not found" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "browser-qa check: SKIPPED - node not available to syntax-check the template"
  exit 0
fi

if node --check "$template"; then
  echo "browser-qa check: OK - template is syntactically valid JavaScript"
else
  echo "browser-qa check: FAIL - template has a syntax error" >&2
  exit 1
fi
