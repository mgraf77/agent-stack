#!/usr/bin/env bash
# Grep-based scanner for common credential-shaped strings.
# Independently written; not copied from any upstream project.
# Usage: scan-secrets.sh <file-or-directory>...
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: scan-secrets.sh <file-or-directory>..." >&2
  exit 2
fi

# Pattern @@@ description — "@@@" is the field separator since several of
# the regexes below contain literal colons (e.g. POSIX classes, [:=]).
patterns=(
  'AKIA[0-9A-Z]{16}@@@AWS access key ID'
  'ASIA[0-9A-Z]{16}@@@AWS temporary access key ID'
  'ghp_[A-Za-z0-9]{36}@@@GitHub personal access token'
  'gho_[A-Za-z0-9]{36}@@@GitHub OAuth token'
  'github_pat_[A-Za-z0-9_]{22,}@@@GitHub fine-grained PAT'
  'sk-[A-Za-z0-9]{20,}@@@OpenAI/Anthropic-style secret key'
  'xox[baprs]-[A-Za-z0-9-]{10,}@@@Slack token'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----@@@private key block'
  '[A-Za-z0-9_]*(SECRET|API)_?KEY[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[\"'"'"']?[A-Za-z0-9/+=_-]{16,}@@@generic API/secret key assignment'
)

hits=0

scan_file() {
  local file="$1"
  local base
  base=$(basename "$file")
  case "$base" in
    .env|.env.*|*.pem|*.key|credentials.json|id_rsa|id_ed25519)
      echo "SUSPECT FILE: $file (matches known secret-file name pattern)"
      hits=1
      ;;
  esac
  for entry in "${patterns[@]}"; do
    local pattern="${entry%%@@@*}"
    local desc="${entry#*@@@}"
    if grep -EnI "$pattern" "$file" >/tmp/secret-scan-hit.$$ 2>/dev/null; then
      while IFS= read -r line; do
        echo "SUSPECT MATCH ($desc) in $file: $line"
        hits=1
      done < /tmp/secret-scan-hit.$$
    fi
    rm -f /tmp/secret-scan-hit.$$
  done
}

for target in "$@"; do
  if [ -d "$target" ]; then
    while IFS= read -r -d '' file; do
      scan_file "$file"
    done < <(find "$target" -type f -not -path '*/.git/*' -print0)
  elif [ -f "$target" ]; then
    scan_file "$target"
  else
    echo "warning: '$target' not found, skipping" >&2
  fi
done

if [ "$hits" -eq 1 ]; then
  echo "scan-secrets: FOUND possible secrets — stop and confirm before committing/pushing" >&2
  exit 1
fi

echo "scan-secrets: clean — no known secret patterns found"
