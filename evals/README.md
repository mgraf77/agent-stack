# Evaluations: free, local promotion gates

A minimal harness that checks a capability (skill, adapter, or profile
entry) against six required dimensions before it can be promoted. See
`policies/promotion-policy.md` for the stage rules this feeds.

Everything here runs locally and for free — bash, `jq`, and coreutils
`timeout` only. No provider API key or network call is required. Optional
provider-backed examples live under `evals/optional/`, disabled by default
(see that directory's README).

## Run it

```bash
# Self-test: run every check over the synthetic fixtures below and confirm
# they correctly discriminate compliant fixtures from the intentionally
# broken control fixtures.
bash evals/run.sh

# Gate a real candidate capability directory before promotion. All six
# checks must PASS.
bash evals/run.sh --capability path/to/capability-dir
```

Exit code is `0` only when every check that should pass, does.

## Capability directory convention

Any directory gated with `--capability` must contain:

| File                     | Purpose                                                             |
|--------------------------|----------------------------------------------------------------------|
| `capability.json`        | name, source, declared tools, trigger keywords, positive/negative examples |
| `SKILL.md`               | human-readable description, including explicit untrusted-content handling guidance |
| `run.sh`                 | the capability's entrypoint (or a thin wrapper around it), with `# TOOL: <name>` markers for every tool it uses |
| `rollback.receipt.json`  | how to undo it: source repo, version pin, catalog decision, rollback method, date recorded |

## The six checks

| Check                 | What it proves                                                                 |
|------------------------|---------------------------------------------------------------------------------|
| `positive_activation`  | Every declared positive example matches a declared trigger keyword.             |
| `negative_activation`  | No declared negative example matches a trigger keyword (catches over-broad triggers). |
| `failure_behavior`     | The entrypoint completes within a bounded timeout, and any failure leaves a clear diagnostic. An unbounded hang is treated as an unsafe failure. |
| `permission_boundary`  | The entrypoint only uses tools it declared (static `# TOOL:` marker scan against `declared_tools`). |
| `prompt_injection`     | The capability documents untrusted-content handling, and the harness itself never executes fixture content — proven by feeding a hostile fixture document through as inert data and by scanning the harness's own scripts for eval/source-of-dynamic-content patterns. |
| `rollback_evidence`    | A complete `rollback.receipt.json` exists with all required fields.             |

## Fixtures

`evals/fixtures/capabilities/` holds one compliant fixture and five
negative-control fixtures, each violating exactly one dimension on purpose
so `evals/run.sh` (self-test mode) can prove the checks actually catch
what they claim to:

| Fixture                | Fails on purpose |
|-------------------------|-----------------|
| `demo-safe-reviewer`    | none — the baseline compliant example |
| `demo-overreach-tool`   | `permission_boundary` (uses an undeclared tool) |
| `demo-noisy-trigger`    | `negative_activation` (single common-word trigger over-matches) |
| `demo-failing-tool`     | none — fails safely (nonzero exit + clear diagnostic), which is the correct behavior |
| `demo-hanging-tool`     | `failure_behavior` (never terminates; the harness must time it out) |
| `demo-no-rollback`      | `rollback_evidence` (no `rollback.receipt.json` shipped) |

Expected outcomes are recorded in `evals/fixtures/expected_outcomes.json`
and diffed automatically by `evals/run.sh`.

`evals/fixtures/injection/untrusted-doc-1.txt` is a synthetic hostile
document (fake shell commands and a fake secret token) used by the
`prompt_injection` check. It is never executed — only read as text.

## Promotion record

Use `evals/templates/promotion-record-template.md` to document a
candidate → trial → approved transition. See
`policies/promotion-policy.md` for the full stage rules.
