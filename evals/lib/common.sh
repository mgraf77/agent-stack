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

# validate_skill_manifest <cap_dir> — pre-check run only in `--skill` gate
# mode, before any of the six promotion checks. Rejects: a missing/invalid
# manifest, a manifest "id" that doesn't match the selected skill
# directory, an entrypoint that is absolute, traverses with "..", escapes
# the skill directory via a symlink, or doesn't exist, and
# instruction_only/entrypoint being set inconsistently. Mirrors
# scripts/validate.py's validate_skill_promotions() so the same rules
# apply whether a skill is checked at commit time or gated for promotion.
# Prints one diagnostic line to stderr and returns 1 on the first problem
# found; returns 0 silently when the manifest is sound.
validate_skill_manifest() {
  local cap_dir="$1"
  local manifest
  manifest="$(manifest_path "$cap_dir")"

  if [[ ! -f "$manifest" ]]; then
    echo "manifest not found: $manifest" >&2
    return 1
  fi
  if ! jq -e . "$manifest" >/dev/null 2>&1; then
    echo "manifest is not valid JSON: $manifest" >&2
    return 1
  fi

  local expected_id manifest_id
  expected_id="$(basename "$cap_dir")"
  manifest_id=$(jq -r '.id // empty' "$manifest")
  if [[ -z "$manifest_id" ]]; then
    echo "manifest has no 'id' field: $manifest" >&2
    return 1
  fi
  if [[ "$manifest_id" != "$expected_id" ]]; then
    echo "manifest id '$manifest_id' does not match selected skill directory '$expected_id'" >&2
    return 1
  fi

  local instruction_only entrypoint
  instruction_only=$(jq -r '.instruction_only // false' "$manifest")
  entrypoint=$(jq -r '.entrypoint // empty' "$manifest")

  if [[ "$instruction_only" == "true" ]]; then
    if [[ -n "$entrypoint" ]]; then
      echo "manifest sets instruction_only: true but also declares entrypoint '$entrypoint' (a skill is either instruction-only or has one entrypoint, not both)" >&2
      return 1
    fi
    return 0
  fi

  if [[ -z "$entrypoint" ]]; then
    echo "manifest declares no entrypoint and instruction_only is not true" >&2
    return 1
  fi

  case "$entrypoint" in
    /*)
      echo "entrypoint '$entrypoint' must be a relative path, not absolute" >&2
      return 1
      ;;
    ../*|*/../*|*/..|..)
      echo "entrypoint '$entrypoint' must not traverse outside the skill directory" >&2
      return 1
      ;;
  esac

  local candidate="$cap_dir/$entrypoint"
  local resolved_dir resolved_entry
  resolved_dir="$(realpath -e "$cap_dir" 2>/dev/null)" || {
    echo "skill directory could not be resolved: $cap_dir" >&2
    return 1
  }
  resolved_entry="$(realpath -e "$candidate" 2>/dev/null)" || {
    echo "entrypoint '$entrypoint' does not exist in $cap_dir" >&2
    return 1
  }
  case "$resolved_entry" in
    "$resolved_dir"/*) ;;
    *)
      echo "entrypoint '$entrypoint' resolves outside $cap_dir (symlink escape?)" >&2
      return 1
      ;;
  esac

  return 0
}
