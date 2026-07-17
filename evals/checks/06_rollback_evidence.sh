#!/usr/bin/env bash
# Rollback evidence: every capability must ship a rollback.receipt.json
# recording how to undo it, alongside what version/decision it came from.

REQUIRED_RECEIPT_FIELDS=(capability source_repo version_pin rollback_method date_recorded)

check_rollback_evidence() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")
  local receipt="$cap_dir/rollback.receipt.json"

  if [[ ! -f "$receipt" ]]; then
    log_fail "$name has no rollback.receipt.json"
    return 1
  fi

  if ! jq -e . "$receipt" >/dev/null 2>&1; then
    log_fail "$name rollback.receipt.json is not valid JSON"
    return 1
  fi

  local missing=()
  for field in "${REQUIRED_RECEIPT_FIELDS[@]}"; do
    local val
    val=$(jq -r --arg f "$field" '.[$f] // ""' "$receipt")
    [[ -z "$val" ]] && missing+=("$field")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_fail "$name rollback.receipt.json missing required field(s): ${missing[*]}"
    return 1
  fi

  log_pass "$name has a complete rollback.receipt.json"
  return 0
}
