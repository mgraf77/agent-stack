#!/usr/bin/env bash
# OPTIONAL, PROVIDER-BACKED EXAMPLE — never run by evals/run.sh or CI.
#
# Illustrates how a human could ask a live model whether it would naturally
# pick a capability for its declared positive examples, as a semantic
# supplement to the free keyword-based activation check. This is an example
# to adapt, not a maintained tool — it makes zero network calls unless both
# gates below are explicitly opened by a human.
#
# Usage:
#   AGENT_STACK_ENABLE_PROVIDER_EVALS=1 ANTHROPIC_API_KEY=sk-... \
#     bash evals/optional/provider_semantic_check.sh <capability-dir>

set -uo pipefail

if [[ "${AGENT_STACK_ENABLE_PROVIDER_EVALS:-0}" != "1" ]]; then
  echo "SKIPPED: set AGENT_STACK_ENABLE_PROVIDER_EVALS=1 to opt in to a provider-backed check."
  exit 0
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "SKIPPED: AGENT_STACK_ENABLE_PROVIDER_EVALS=1 but no ANTHROPIC_API_KEY is set."
  exit 0
fi

CAP_DIR="${1:?usage: provider_semantic_check.sh <capability-dir>}"
DESCRIPTION=$(jq -r '.summary' "$CAP_DIR/capability.json")
EXAMPLES=$(jq -r '.positive_examples[]' "$CAP_DIR/capability.json")

echo "This example would now send the capability description and its"
echo "positive examples to a live provider and ask it to judge activation"
echo "fit. Wire up the actual API call here before use; left unimplemented"
echo "so this repository makes no real network calls by default."
echo
echo "description: $DESCRIPTION"
echo "examples:"
echo "$EXAMPLES"
