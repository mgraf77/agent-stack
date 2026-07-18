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

# _manifest_json_type <manifest> <jq_filter> — echoes the jq type name
# ("string", "array", "object", "boolean", "null", ...) that <jq_filter>
# selects. Never fails the caller: an out-of-range index or an attempt to
# index/iterate a value of the wrong type (e.g. .provenance.origin when
# provenance is a number) makes jq itself error out — that's reported here
# as type "null" rather than propagating jq's nonzero exit, so a malformed
# manifest is always a validation error, never a crashed pre-check.
_manifest_json_type() {
  local manifest="$1" filter="$2"
  local out
  if out=$(jq -r "($filter) | type" "$manifest" 2>/dev/null); then
    echo "$out"
  else
    echo "null"
  fi
}

# _require_manifest_string <manifest> <jq_filter> <label> — a non-empty
# string, or a diagnostic on stderr + return 1.
_require_manifest_string() {
  local manifest="$1" filter="$2" label="$3"
  local t
  t=$(_manifest_json_type "$manifest" "$filter")
  if [[ "$t" != "string" ]]; then
    echo "manifest $label must be a non-empty string (got $t)" >&2
    return 1
  fi
  local v
  v=$(jq -r "$filter" "$manifest")
  if [[ -z "$v" ]]; then
    echo "manifest $label must not be empty" >&2
    return 1
  fi
  return 0
}

# _require_manifest_string_array <manifest> <jq_filter> <label> — a
# non-empty array of non-empty strings, or a diagnostic + return 1.
_require_manifest_string_array() {
  local manifest="$1" filter="$2" label="$3"
  local t
  t=$(_manifest_json_type "$manifest" "$filter")
  if [[ "$t" != "array" ]]; then
    echo "manifest $label must be a non-empty array of non-empty strings (got $t)" >&2
    return 1
  fi
  local len
  len=$(jq -r "($filter) | length" "$manifest")
  if [[ "$len" -eq 0 ]]; then
    echo "manifest $label must be a non-empty array of non-empty strings" >&2
    return 1
  fi
  local bad
  bad=$(jq -r "($filter)[] | select((type != \"string\") or (. == \"\"))" "$manifest" 2>/dev/null)
  if [[ -n "$bad" ]]; then
    echo "manifest $label must contain only non-empty strings" >&2
    return 1
  fi
  return 0
}

# _require_manifest_boolean <manifest> <jq_filter> <label> — a JSON
# boolean, or a diagnostic + return 1.
_require_manifest_boolean() {
  local manifest="$1" filter="$2" label="$3"
  local t
  t=$(_manifest_json_type "$manifest" "$filter")
  if [[ "$t" != "boolean" ]]; then
    echo "manifest $label must be a boolean (got $t)" >&2
    return 1
  fi
  return 0
}

# validate_skill_manifest <cap_dir> — pre-check run only in `--skill` gate
# mode, before any of the six promotion checks. Enforces the full
# skill-promotion-manifest.schema.json shape — non-empty kebab-case id
# matching the skill directory; provenance.origin/license as non-empty
# strings; declared_tools/trigger_keywords/positive_examples/
# negative_examples as non-empty arrays of non-empty strings;
# untrusted_content_handling as a boolean; instruction_only, if present,
# as a boolean; a safe, existing, relative entrypoint (or none, iff
# instruction_only: true); and rollback.method/date_recorded — mirroring
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

  _require_manifest_string "$manifest" '.id' "id" || return 1
  local manifest_id
  manifest_id=$(jq -r '.id' "$manifest")
  if ! [[ "$manifest_id" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "manifest id '$manifest_id' is not kebab-case" >&2
    return 1
  fi
  local expected_id
  expected_id="$(basename "$cap_dir")"
  if [[ "$manifest_id" != "$expected_id" ]]; then
    echo "manifest id '$manifest_id' does not match selected skill directory '$expected_id'" >&2
    return 1
  fi

  _require_manifest_string "$manifest" '.provenance.origin' "provenance.origin" || return 1
  _require_manifest_string "$manifest" '.provenance.license' "provenance.license" || return 1

  local array_field
  for array_field in declared_tools trigger_keywords positive_examples negative_examples; do
    _require_manifest_string_array "$manifest" ".${array_field}" "$array_field" || return 1
  done

  _require_manifest_boolean "$manifest" '.untrusted_content_handling' "untrusted_content_handling" || return 1

  local instruction_only_type
  instruction_only_type=$(jq -r 'if has("instruction_only") then (.instruction_only | type) else "absent" end' "$manifest")
  if [[ "$instruction_only_type" != "absent" && "$instruction_only_type" != "boolean" ]]; then
    echo "manifest instruction_only must be a boolean (got $instruction_only_type)" >&2
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
  else
    if [[ -z "$entrypoint" ]]; then
      echo "manifest declares no entrypoint and instruction_only is not true" >&2
      return 1
    fi
    if [[ "$(_manifest_json_type "$manifest" '.entrypoint')" != "string" ]]; then
      echo "manifest entrypoint must be a string" >&2
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
  fi

  _require_manifest_string "$manifest" '.rollback.method' "rollback.method" || return 1
  local rollback_date
  rollback_date=$(jq -r '.rollback.date_recorded // empty' "$manifest" 2>/dev/null)
  if ! [[ "$rollback_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "manifest rollback.date_recorded '$rollback_date' is not YYYY-MM-DD" >&2
    return 1
  fi

  return 0
}
