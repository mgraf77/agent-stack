#!/usr/bin/env bash
# Free, local evaluation runner for candidate capabilities. No network access
# and no paid provider calls are used by anything this script runs directly.
#
# Usage:
#   evals/run.sh                        Self-test mode: runs all checks over
#                                        the synthetic fixtures in
#                                        evals/fixtures/capabilities/ and
#                                        verifies the checks discriminate
#                                        compliant fixtures from the
#                                        intentionally-broken control
#                                        fixtures (see fixtures/expected_outcomes.json).
#
#   evals/run.sh --capability DIR       Gate mode: runs all six checks
#                                        against a single synthetic candidate
#                                        capability directory (must contain
#                                        capability.json, SKILL.md, run.sh,
#                                        rollback.receipt.json). Every check
#                                        must PASS for promotion.
#
#   evals/run.sh --skill DIR            Gate mode for a real curated skills/<id>/
#                                        package: same six checks, reading
#                                        DIR/promotion.json (see
#                                        schemas/skill-promotion-manifest.schema.json)
#                                        instead of capability.json, and
#                                        gating DIR/SKILL.md directly. Does
#                                        not require a run.sh entrypoint when
#                                        the manifest declares
#                                        instruction_only: true.
#
#   --manifest PATH                     With --capability/--skill, read the
#                                        manifest from PATH instead of the
#                                        default file inside DIR. Used to gate
#                                        a real skill's files against a
#                                        deliberately-broken manifest fixture
#                                        without duplicating the skill's files.
#
# Requires only: bash, jq, coreutils `timeout`. No API keys, no network.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$ROOT/fixtures"
export FIXTURES_DIR

for tool in jq timeout; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required local tool: $tool" >&2
    exit 2
  fi
done

# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
for c in "$ROOT"/checks/*.sh; do
  # shellcheck source=/dev/null
  source "$c"
done

CHECKS=(positive_activation negative_activation failure_behavior permission_boundary prompt_injection rollback_evidence)

MODE="self-test"
CAP_DIR=""
MANIFEST_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --capability)
      CAP_DIR="$2"
      MODE="gate"
      MANIFEST_FILE_NAME="capability.json"
      shift 2
      ;;
    --skill)
      CAP_DIR="$2"
      MODE="gate"
      MANIFEST_FILE_NAME="promotion.json"
      shift 2
      ;;
    --manifest)
      MANIFEST_OVERRIDE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done
export MANIFEST_FILE_NAME
if [[ -n "$MANIFEST_OVERRIDE" ]]; then
  if [[ ! -f "$MANIFEST_OVERRIDE" ]]; then
    echo "Manifest override not found: $MANIFEST_OVERRIDE" >&2
    exit 2
  fi
  MANIFEST_OVERRIDE_PATH="$(cd "$(dirname "$MANIFEST_OVERRIDE")" && pwd)/$(basename "$MANIFEST_OVERRIDE")"
  export MANIFEST_OVERRIDE_PATH
fi

run_one_check() {
  local check_name="$1" cap_dir="$2"
  "check_${check_name}" "$cap_dir" >/tmp/agent-stack-eval-out.$$ 2>&1
  local rc=$?
  cat /tmp/agent-stack-eval-out.$$
  rm -f /tmp/agent-stack-eval-out.$$
  return $rc
}

if [[ "$MODE" == "gate" ]]; then
  if [[ -z "$CAP_DIR" || ! -d "$CAP_DIR" ]]; then
    echo "Capability directory not found: $CAP_DIR" >&2
    exit 2
  fi
  CAP_DIR="$(cd "$CAP_DIR" && pwd)"

  echo "== Promotion gate: $(basename "$CAP_DIR") =="
  echo "== Harness self-scan (prompt-injection defense-in-depth) =="
  check_harness_injection_self_scan "$ROOT"
  self_scan_rc=$?

  overall=0
  [[ $self_scan_rc -ne 0 ]] && overall=1
  for chk in "${CHECKS[@]}"; do
    echo
    echo "-- $chk --"
    if ! run_one_check "$chk" "$CAP_DIR"; then
      overall=1
    fi
  done

  echo
  if [[ $overall -eq 0 ]]; then
    echo "RESULT: all checks passed. Eligible for the next promotion stage."
  else
    echo "RESULT: one or more checks failed. Not eligible for promotion."
  fi
  exit $overall
fi

# Self-test mode: run every check over every synthetic fixture and diff
# against the recorded expected outcomes.
echo "== Harness self-scan (prompt-injection defense-in-depth) =="
check_harness_injection_self_scan "$ROOT"
self_scan_rc=$?
echo

EXPECTED_FILE="$FIXTURES_DIR/expected_outcomes.json"
mismatches=0
total=0

printf '%-22s' "CAPABILITY"
for chk in "${CHECKS[@]}"; do
  printf '%-22s' "$chk"
done
echo

for cap_dir in "$FIXTURES_DIR"/capabilities/*/; do
  cap_dir="${cap_dir%/}"
  name="$(basename "$cap_dir")"
  printf '%-22s' "$name"
  for chk in "${CHECKS[@]}"; do
    total=$((total + 1))
    out=$(run_one_check "$chk" "$cap_dir")
    if echo "$out" | grep -q '^PASS'; then
      actual="pass"
    else
      actual="fail"
    fi
    expected=$(jq -r --arg n "$name" --arg c "$chk" '.[$n][$c] // "MISSING"' "$EXPECTED_FILE")
    if [[ "$actual" == "$expected" ]]; then
      cell="$actual"
    else
      cell="${actual}(!=${expected})"
      mismatches=$((mismatches + 1))
    fi
    printf '%-22s' "$cell"
  done
  echo
done

echo
if [[ $self_scan_rc -ne 0 ]]; then
  echo "RESULT: harness self-scan failed."
fi
if [[ $mismatches -eq 0 && $self_scan_rc -eq 0 ]]; then
  echo "RESULT: all ${total} check outcomes matched expectations. The eval harness correctly discriminates compliant and non-compliant fixtures."
  exit 0
else
  echo "RESULT: ${mismatches}/${total} check outcomes did not match evals/fixtures/expected_outcomes.json."
  exit 1
fi
