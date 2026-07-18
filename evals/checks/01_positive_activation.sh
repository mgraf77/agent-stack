#!/usr/bin/env bash
# Positive activation: every listed positive example must match at least one
# of the capability's declared trigger_keywords (case-insensitive substring).
# Free/local: pure string matching, no model or network call.

check_positive_activation() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")

  local manifest
  manifest="$(manifest_path "$cap_dir")"
  local keywords examples
  mapfile -t keywords < <(jq -r '.trigger_keywords[]' "$manifest" | tr '[:upper:]' '[:lower:]')
  mapfile -t examples < <(jq -r '.positive_examples[]' "$manifest")

  if [[ ${#examples[@]} -eq 0 ]]; then
    log_fail "$name declares no positive_examples"
    return 1
  fi

  local ok=1
  for ex in "${examples[@]}"; do
    local ex_lc matched=0
    ex_lc=$(tr '[:upper:]' '[:lower:]' <<<"$ex")
    for kw in "${keywords[@]}"; do
      [[ -n "$kw" && "$ex_lc" == *"$kw"* ]] && matched=1 && break
    done
    if [[ $matched -eq 0 ]]; then
      log_fail "$name: positive example did not match any trigger keyword: \"$ex\""
      ok=0
    fi
  done

  [[ $ok -eq 1 ]] && log_pass "$name activates on all declared positive examples"
  [[ $ok -eq 1 ]]
}
