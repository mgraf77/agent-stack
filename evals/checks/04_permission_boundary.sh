#!/usr/bin/env bash
# Permission boundary: the entrypoint may only use tools marked with a
# "# TOOL: <name>" comment that also appear in capability.json's
# declared_tools. Static analysis only — the fixture entrypoints never
# actually reach the network or filesystem outside their own directory.

check_permission_boundary() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")
  local entry_name
  entry_name=$(capability_entrypoint "$cap_dir")

  if [[ -z "$entry_name" ]]; then
    log_pass "$name is instruction-only (no declared entrypoint); permission_boundary is not applicable"
    return 0
  fi

  local entry="$cap_dir/$entry_name"

  local declared used
  declared=$(jq -r '.declared_tools[]' "$(manifest_path "$cap_dir")" | sort -u)
  used=$(grep -oE '# TOOL: [A-Za-z0-9_-]+' "$entry" 2>/dev/null | sed 's/# TOOL: //' | sort -u)

  local undeclared=()
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    if ! grep -qxF "$tool" <<<"$declared"; then
      undeclared+=("$tool")
    fi
  done <<<"$used"

  if [[ ${#undeclared[@]} -gt 0 ]]; then
    log_fail "$name uses undeclared tool(s): ${undeclared[*]}"
    return 1
  fi

  log_pass "$name only uses its declared_tools"
  return 0
}
