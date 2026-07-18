#!/usr/bin/env bash
# markdown-vault: lint a directory of Markdown knowledge-vault notes.
# Adapted from the general concept of Obsidian Skills' vault frontmatter/
# linking conventions and karpathy's LLM Wiki gist raw-source vs.
# maintained-wiki split; see notices/markdown-vault.md.
# TOOL: Bash
set -euo pipefail

usage() {
  echo "Usage: $0 <vault-dir>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
vault="$1"
[[ -d "$vault" ]] || { echo "markdown-vault: '$vault' is not a directory" >&2; exit 1; }

shopt -s nullglob
notes=("$vault"/*.md)
shopt -u nullglob

if [[ ${#notes[@]} -eq 0 ]]; then
  echo "markdown-vault: no .md notes found in '$vault'" >&2
  exit 1
fi

frontmatter() {
  # Echoes the YAML frontmatter block (between the first two '---' lines).
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm { print }
  ' "$1"
}

field() {
  # field <frontmatter-text> <key> — echoes a simple "key: value" scalar.
  grep -E "^${2}:" <<<"$1" | head -n1 | sed -E "s/^${2}:[[:space:]]*//"
}

declare -A title_to_file
errors=()

# Pass 1: validate frontmatter and index titles.
for note in "${notes[@]}"; do
  fm=$(frontmatter "$note")
  if [[ -z "$fm" ]]; then
    errors+=("$note: no YAML frontmatter block (must start with '---')")
    continue
  fi
  title=$(field "$fm" "title")
  kind=$(field "$fm" "kind")
  tags=$(field "$fm" "tags")
  [[ -z "$title" ]] && errors+=("$note: missing frontmatter field 'title'")
  [[ -z "$kind" ]] && errors+=("$note: missing frontmatter field 'kind'")
  if [[ -n "$kind" && "$kind" != "raw" && "$kind" != "wiki" ]]; then
    errors+=("$note: frontmatter 'kind' must be 'raw' or 'wiki', got '$kind'")
  fi
  [[ -z "$tags" ]] && errors+=("$note: missing frontmatter field 'tags'")
  if [[ -n "$title" ]]; then
    key=$(tr '[:upper:]' '[:lower:]' <<<"$title")
    title_to_file["$key"]="$note"
  fi
done

# Pass 2: every [[Wiki Link]] must resolve to a known title.
for note in "${notes[@]}"; do
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    key=$(tr '[:upper:]' '[:lower:]' <<<"$link")
    if [[ -z "${title_to_file[$key]:-}" ]]; then
      errors+=("$note: broken link [[$link]] does not match any note's title")
    fi
  done < <(grep -oE '\[\[[^]]+\]\]' "$note" | sed -E 's/\[\[([^]]+)\]\]/\1/')
done

if [[ ${#errors[@]} -gt 0 ]]; then
  echo "markdown-vault: ${#errors[@]} problem(s) found:" >&2
  printf '  - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "markdown-vault: OK (${#notes[@]} note(s), all frontmatter and links valid)"
