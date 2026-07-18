#!/usr/bin/env bash
# Regressions for the `evals/run.sh --skill` manifest pre-check
# (validate_skill_manifest in evals/lib/common.sh). Free/local: bash, jq,
# coreutils only, no network — same constraint as the rest of evals/.
#
# Run directly: bash evals/tests/skill-gate-regressions.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN="$ROOT/evals/run.sh"
SKILL_DIR="$ROOT/skills/secret-safety"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

fail=0

# run_case <description> <expected_exit_code> <required-output-substring-or-""> -- <command...>
run_case() {
  local desc="$1" expected_rc="$2" pattern="$3"
  shift 3
  [[ "${1:-}" == "--" ]] && shift
  local out rc
  out=$("$@" 2>&1)
  rc=$?
  if [[ "$rc" -ne "$expected_rc" ]]; then
    echo "FAIL: $desc (expected exit $expected_rc, got $rc)"
    printf '%s\n' "$out" | sed 's/^/    /'
    fail=1
    return
  fi
  if [[ -n "$pattern" ]] && ! grep -qi "$pattern" <<<"$out"; then
    echo "FAIL: $desc (expected output to mention '$pattern')"
    printf '%s\n' "$out" | sed 's/^/    /'
    fail=1
    return
  fi
  echo "PASS: $desc"
}

write_manifest() {
  local target="$1" body="$2"
  printf '%s' "$body" >"$target"
}

# --- retained evidence: the real skill still passes cleanly ---
run_case "secret-safety: compliant manifest passes all six checks" 0 "RESULT: all checks passed" -- \
  bash "$RUN" --skill "$SKILL_DIR"

# --- retained evidence: the untrusted_content_handling negative control still isolates to prompt_injection ---
run_case "secret-safety: untrusted_content_handling:false fails only prompt_injection" 1 "does not set untrusted_content_handling" -- \
  bash "$RUN" --skill "$SKILL_DIR" --manifest "$ROOT/evals/fixtures/skills/secret-safety-broken.promotion.json"

# --- id mismatch: rejected before the six checks (exit 2), not a check failure (exit 1) ---
write_manifest "$SCRATCH/id-mismatch.promotion.json" '{
  "id": "not-secret-safety",
  "provenance": { "origin": "agent-stack-local", "license": "MIT" },
  "declared_tools": ["Bash"],
  "untrusted_content_handling": true,
  "trigger_keywords": ["commit"],
  "positive_examples": ["Can you check this before I commit it?"],
  "negative_examples": ["What'"'"'s the weather like today?"],
  "entrypoint": "check.sh",
  "rollback": { "method": "remove the skill", "date_recorded": "2026-07-18" }
}'
run_case "id mismatch is rejected before the six checks" 2 "does not match" -- \
  bash "$RUN" --skill "$SKILL_DIR" --manifest "$SCRATCH/id-mismatch.promotion.json"

# --- absolute entrypoint path: rejected ---
write_manifest "$SCRATCH/absolute-entrypoint.promotion.json" '{
  "id": "secret-safety",
  "provenance": { "origin": "agent-stack-local", "license": "MIT" },
  "declared_tools": ["Bash"],
  "untrusted_content_handling": true,
  "trigger_keywords": ["commit"],
  "positive_examples": ["Can you check this before I commit it?"],
  "negative_examples": ["What'"'"'s the weather like today?"],
  "entrypoint": "/etc/passwd",
  "rollback": { "method": "remove the skill", "date_recorded": "2026-07-18" }
}'
run_case "absolute entrypoint path is rejected before the six checks" 2 "must be a relative path" -- \
  bash "$RUN" --skill "$SKILL_DIR" --manifest "$SCRATCH/absolute-entrypoint.promotion.json"

# --- '..' traversal entrypoint path: rejected ---
write_manifest "$SCRATCH/traversal-entrypoint.promotion.json" '{
  "id": "secret-safety",
  "provenance": { "origin": "agent-stack-local", "license": "MIT" },
  "declared_tools": ["Bash"],
  "untrusted_content_handling": true,
  "trigger_keywords": ["commit"],
  "positive_examples": ["Can you check this before I commit it?"],
  "negative_examples": ["What'"'"'s the weather like today?"],
  "entrypoint": "../../../../etc/passwd",
  "rollback": { "method": "remove the skill", "date_recorded": "2026-07-18" }
}'
run_case "'..' traversal entrypoint path is rejected before the six checks" 2 "must not traverse" -- \
  bash "$RUN" --skill "$SKILL_DIR" --manifest "$SCRATCH/traversal-entrypoint.promotion.json"

# --- instruction_only:true with an entrypoint also set: rejected ---
write_manifest "$SCRATCH/instruction-only-conflict.promotion.json" '{
  "id": "secret-safety",
  "provenance": { "origin": "agent-stack-local", "license": "MIT" },
  "declared_tools": ["Bash"],
  "untrusted_content_handling": true,
  "trigger_keywords": ["commit"],
  "positive_examples": ["Can you check this before I commit it?"],
  "negative_examples": ["What'"'"'s the weather like today?"],
  "instruction_only": true,
  "entrypoint": "check.sh",
  "rollback": { "method": "remove the skill", "date_recorded": "2026-07-18" }
}'
run_case "instruction_only:true with an entrypoint set is rejected before the six checks" 2 "instruction_only" -- \
  bash "$RUN" --skill "$SKILL_DIR" --manifest "$SCRATCH/instruction-only-conflict.promotion.json"

# --- symlinked entrypoint escaping the skill directory: rejected ---
mkdir -p "$SCRATCH/symlink-skill"
cp "$SKILL_DIR/SKILL.md" "$SCRATCH/symlink-skill/SKILL.md"
outside_target="$SCRATCH/outside.sh"
printf '#!/usr/bin/env bash\necho hi\n' >"$outside_target"
chmod +x "$outside_target"
ln -s "$outside_target" "$SCRATCH/symlink-skill/escape.sh"
write_manifest "$SCRATCH/symlink-skill/promotion.json" '{
  "id": "symlink-skill",
  "provenance": { "origin": "agent-stack-local", "license": "MIT" },
  "declared_tools": ["Bash"],
  "untrusted_content_handling": true,
  "trigger_keywords": ["commit"],
  "positive_examples": ["Can you check this before I commit it?"],
  "negative_examples": ["What'"'"'s the weather like today?"],
  "entrypoint": "escape.sh",
  "rollback": { "method": "remove the skill", "date_recorded": "2026-07-18" }
}'
run_case "symlinked entrypoint escaping the skill directory is rejected before the six checks" 2 "resolves outside" -- \
  bash "$RUN" --skill "$SCRATCH/symlink-skill"

echo
if [[ "$fail" -eq 0 ]]; then
  echo "RESULT: all skill-gate regression checks passed."
else
  echo "RESULT: one or more skill-gate regression checks FAILED."
fi
exit "$fail"
