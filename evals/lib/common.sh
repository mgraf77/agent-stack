#!/usr/bin/env bash
# Shared helpers for the evals runner. Sourced, never executed directly.

TIMEOUT_SECS="${AGENT_STACK_EVAL_TIMEOUT:-5}"

# Bare manifest filename to look for inside a candidate directory.
# --capability candidates (synthetic fixtures and other non-skill
# candidates) use capability.json; --skill candidates (real skills/<id>/
# packages) use promotion.json. Set by evals/run.sh before checks run.
MANIFEST_FILE_NAME="${MANIFEST_FILE_NAME:-capability.json}"

# Absolute override path set only when evals/run.sh is invoked with
# --manifest, e.g. to gate a real skill's files against a deliberately
# broken manifest fixture stored elsewhere (see evals/fixtures/skills/).
MANIFEST_OVERRIDE_PATH="${MANIFEST_OVERRIDE_PATH:-}"

log_pass() { printf 'PASS: %s\n' "$1"; }
log_fail() { printf 'FAIL: %s\n' "$1"; }

# manifest_path <cap_dir> — echoes the manifest file to read for this
# candidate: the --manifest override if one was given, else
# <cap_dir>/<MANIFEST_FILE_NAME>.
manifest_path() {
  local cap_dir="$1"
  if [[ -n "$MANIFEST_OVERRIDE_PATH" ]]; then
    echo "$MANIFEST_OVERRIDE_PATH"
  else
    echo "$cap_dir/$MANIFEST_FILE_NAME"
  fi
}

# capability_field <cap_dir> <jq_filter> [default]
capability_field() {
  local cap_dir="$1" filter="$2" default="${3:-}"
  jq -r "$filter // \"$default\"" "$(manifest_path "$cap_dir")"
}

# capability_entrypoint <cap_dir> — echoes the relative entrypoint filename
# to run for failure_behavior/permission_boundary, or an empty string when
# the manifest declares instruction_only: true (no runtime executable
# required for an instruction-only skill).
capability_entrypoint() {
  local cap_dir="$1"
  local manifest
  manifest="$(manifest_path "$cap_dir")"
  if [[ ! -f "$manifest" ]]; then
    echo "run.sh"
    return
  fi
  local instruction_only
  instruction_only=$(jq -r '.instruction_only // false' "$manifest")
  if [[ "$instruction_only" == "true" ]]; then
    echo ""
    return
  fi
  jq -r '.entrypoint // "run.sh"' "$manifest"
}
