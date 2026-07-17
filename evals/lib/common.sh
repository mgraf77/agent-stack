#!/usr/bin/env bash
# Shared helpers for the evals runner. Sourced, never executed directly.

TIMEOUT_SECS="${AGENT_STACK_EVAL_TIMEOUT:-5}"

log_pass() { printf 'PASS: %s\n' "$1"; }
log_fail() { printf 'FAIL: %s\n' "$1"; }

# capability_field <cap_dir> <jq_filter> [default]
capability_field() {
  local cap_dir="$1" filter="$2" default="${3:-}"
  jq -r "$filter // \"$default\"" "$cap_dir/capability.json"
}
