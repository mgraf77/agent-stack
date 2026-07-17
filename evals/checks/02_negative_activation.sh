#!/usr/bin/env bash
# Negative / non-activation: none of the listed negative examples may match
# any declared trigger_keyword. Catches over-broad triggers that would cause
# the capability to fire on unrelated requests.

check_negative_activation() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")

  local keywords examples
  mapfile -t keywords < <(jq -r '.trigger_keywords[]' "$cap_dir/capability.json" | tr '[:upper:]' '[:lower:]')
  mapfile -t examples < <(jq -r '.negative_examples[]' "$cap_dir/capability.json")

  if [[ ${#examples[@]} -eq 0 ]]; then
    log_fail "$name declares no negative_examples"
    return 1
  fi

  local ok=1
  for ex in "${examples[@]}"; do
    local ex_lc
    ex_lc=$(tr '[:upper:]' '[:lower:]' <<<"$ex")
    for kw in "${keywords[@]}"; do
      if [[ -n "$kw" && "$ex_lc" == *"$kw"* ]]; then
        log_fail "$name: negative example unexpectedly matched trigger keyword \"$kw\": \"$ex\""
        ok=0
      fi
    done
  done

  [[ $ok -eq 1 ]] && log_pass "$name does not activate on any declared negative example"
  [[ $ok -eq 1 ]]
}
