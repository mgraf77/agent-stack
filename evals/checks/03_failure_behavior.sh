#!/usr/bin/env bash
# Failure behavior: the capability's entrypoint must complete within a bounded
# timeout, and if it exits nonzero it must leave a clear diagnostic. A hang
# past the timeout is an unsafe failure mode and blocks promotion.

check_failure_behavior() {
  local cap_dir="$1"
  local name
  name=$(basename "$cap_dir")
  local entry_name
  entry_name=$(capability_entrypoint "$cap_dir")

  if [[ -z "$entry_name" ]]; then
    log_pass "$name is instruction-only (no declared entrypoint); failure_behavior is not applicable"
    return 0
  fi

  local entry="$cap_dir/$entry_name"

  if [[ ! -f "$entry" ]]; then
    log_fail "$name has no $entry_name entrypoint"
    return 1
  fi

  local out rc
  out=$(timeout "${TIMEOUT_SECS}s" bash "$entry" 2>&1)
  rc=$?

  if [[ $rc -eq 124 ]]; then
    log_fail "$name did not complete within ${TIMEOUT_SECS}s (unbounded hang detected by timeout)"
    return 1
  fi

  if [[ $rc -ne 0 ]]; then
    if [[ -z "$out" ]]; then
      log_fail "$name exited nonzero ($rc) with no diagnostic message"
      return 1
    fi
    log_pass "$name failed safely within ${TIMEOUT_SECS}s (exit $rc, diagnostic present)"
    return 0
  fi

  log_pass "$name completed within ${TIMEOUT_SECS}s"
  return 0
}
