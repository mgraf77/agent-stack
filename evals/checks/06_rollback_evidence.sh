#!/usr/bin/env bash
# Rollback evidence: every capability must record how to undo it, alongside
# what version/decision it came from. Synthetic --capability candidates ship
# this as a standalone rollback.receipt.json; real --skill candidates carry
# the same information as the "rollback" object in their promotion.json
# manifest (see schemas/skill-promotion-manifest.schema.json) instead of a
# second file.

REQUIRED_RECEIPT_FIELDS=(capability source_repo version_pin rollback_method date_recorded)
REQUIRED_MANIFEST_ROLLBACK_FIELDS=(method date_recorded)

check_rollback_evidence() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")
  local receipt="$cap_dir/rollback.receipt.json"

  if [[ -f "$receipt" ]]; then
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
  fi

  local manifest
  manifest="$(manifest_path "$cap_dir")"
  if [[ -f "$manifest" ]] && jq -e '.rollback' "$manifest" >/dev/null 2>&1; then
    local missing=()
    for field in "${REQUIRED_MANIFEST_ROLLBACK_FIELDS[@]}"; do
      local val
      val=$(jq -r --arg f "$field" '.rollback[$f] // ""' "$manifest")
      [[ -z "$val" ]] && missing+=("$field")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
      log_fail "$name $(basename "$manifest") rollback object missing required field(s): ${missing[*]}"
      return 1
    fi

    log_pass "$name has a complete rollback record in $(basename "$manifest")"
    return 0
  fi

  log_fail "$name has no rollback.receipt.json and no rollback object in $(basename "$manifest")"
  return 1
}
