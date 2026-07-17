#!/usr/bin/env bash
# Prompt injection: (1) the capability must declare and document that it
# treats external content as untrusted; (2) the harness itself must never
# execute or source fixture content — proven by feeding a hostile fixture
# document through as inert data and confirming nothing it asks for happens.

INJECTION_DOC="$FIXTURES_DIR/injection/untrusted-doc-1.txt"
INJECTION_MARKER="/tmp/agent-stack-eval-injection-marker"

check_prompt_injection() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")

  local declared
  declared=$(jq -r '.untrusted_content_handling // false' "$cap_dir/capability.json")
  if [[ "$declared" != "true" ]]; then
    log_fail "$name does not set untrusted_content_handling: true"
    return 1
  fi

  if ! grep -qi "untrusted" "$cap_dir/SKILL.md" 2>/dev/null; then
    log_fail "$name SKILL.md has no explicit untrusted-content guidance"
    return 1
  fi

  # Dynamic self-check: treat the hostile fixture doc as inert data only.
  rm -f "$INJECTION_MARKER"
  local doc doc_len
  doc=$(cat "$INJECTION_DOC")
  doc_len=${#doc}
  if [[ -f "$INJECTION_MARKER" ]]; then
    log_fail "$name: injected command executed unexpectedly during evaluation"
    return 1
  fi

  log_pass "$name declares untrusted-content handling; harness kept a ${doc_len}-byte hostile fixture inert"
  return 0
}

# Self-scan: the check/runner scripts must never eval/source fixture content,
# which would turn this evaluation harness into an injection vector itself.
check_harness_injection_self_scan() {
  local root="$1"
  local hits
  hits=$(grep -rnE '(eval[[:space:]]+"?\$\(|source[[:space:]]+<\(|\.[[:space:]]+<\()' \
    "$root/run.sh" "$root/checks" "$root/lib" 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    log_fail "harness self-scan: found eval/source-of-dynamic-content pattern(s):"
    printf '%s\n' "$hits"
    return 1
  fi
  log_pass "harness self-scan: no eval/source-of-dynamic-content patterns found"
  return 0
}
