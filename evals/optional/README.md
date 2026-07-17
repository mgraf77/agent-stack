# Optional, provider-backed checks

Everything in `evals/run.sh` and `evals/checks/` runs locally, offline, and
free — no API key or provider call is required to gate a promotion.

This directory holds optional examples that call a paid model provider for
a semantic sanity check (e.g. "would a model actually pick this skill for
this prompt?"). They are:

- **disabled by default** — never invoked by `evals/run.sh`, CI, or any
  required promotion gate.
- **opt-in only** — a human runs them manually and reads the output.
- **not required for any promotion stage** in `policies/promotion-policy.md`.

## Running an optional check

```bash
AGENT_STACK_ENABLE_PROVIDER_EVALS=1 ANTHROPIC_API_KEY=sk-... \
  bash evals/optional/provider_semantic_check.sh evals/fixtures/capabilities/demo-safe-reviewer
```

Without both `AGENT_STACK_ENABLE_PROVIDER_EVALS=1` and an API key present,
the script prints a skip message and exits `0` without making any network
call.
