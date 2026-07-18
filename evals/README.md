# Evaluations: free, local promotion gates

A minimal harness that checks a capability (skill, adapter, or profile
entry) against six required dimensions before it can be promoted. See the
"Local evaluation gates" section of `policies/promotion-lifecycle.md` for
the stage rules this feeds.

Everything here runs locally and for free — bash, `jq`, and coreutils
`timeout`/`realpath` only. No provider API key or network call is required
or used anywhere in this directory, per `policies/free-first.md`.

## Run it

```bash
# Self-test: run every check over the synthetic fixtures below and confirm
# they correctly discriminate compliant fixtures from the intentionally
# broken control fixtures.
bash evals/run.sh

# Gate a synthetic candidate capability directory before promotion. All six
# checks must PASS.
bash evals/run.sh --capability path/to/capability-dir

# Gate a real curated skills/<id>/ package the same way. All six checks
# must PASS.
bash evals/run.sh --skill skills/<id>

# Gate a candidate's files against a manifest stored elsewhere (e.g. a
# deliberately-broken fixture manifest, without duplicating the candidate's
# files just to prove a negative).
bash evals/run.sh --skill skills/<id> --manifest path/to/other-manifest.json
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

## Real-skill (`--skill`) convention

A real curated skill under `skills/<id>/` is gated with `--skill` instead
of `--capability`. It already has a `SKILL.md`; the promotion route adds
exactly one new file, `skills/<id>/promotion.json`, matching
`schemas/skill-promotion-manifest.schema.json`:

| Field | Purpose |
|---|---|
| `provenance.origin` / `provenance.license` | `"agent-stack-local"` for an independently-authored skill, or the `catalog/repositories.csv` source it was adapted from |
| `declared_tools` | tools the skill's instructions call for |
| `untrusted_content_handling` | must be `true`, matching explicit "untrusted" guidance in `SKILL.md` |
| `trigger_keywords` / `positive_examples` / `negative_examples` | same activation contract as `capability.json` |
| `entrypoint` | relative path to the skill's own existing safe-usage check (e.g. `check.sh`) reused as the evaluator's entrypoint — no separate `run.sh` needed |
| `instruction_only` | set `true`, and omit `entrypoint`, for a skill with no runtime script; `failure_behavior`/`permission_boundary` are then not applicable instead of failing for missing an executable |
| `rollback` | `{ "method": ..., "date_recorded": ... }`, carried in the same file instead of a separate `rollback.receipt.json` |

`--skill` runs the identical six checks as `--capability`; only where the
manifest and entrypoint are read from differs.

### Manifest pre-check (`--skill` only)

Before any of the six checks run, `--skill` validates the full manifest
shape itself (`validate_skill_manifest` in `evals/lib/common.sh`) and
rejects — with exit code `2`, distinct from a check failure's exit `1` —
a manifest that:

- is missing or not valid JSON,
- has no `id`, an empty or non-string `id`, a non-kebab-case `id`, or an
  `id` that doesn't match the selected skill directory,
- has a non-object `provenance`, or a `provenance.origin`/`.license` that
  isn't a non-empty string,
- has a `declared_tools`/`trigger_keywords`/`positive_examples`/
  `negative_examples` that isn't a non-empty array of non-empty strings,
- has a non-boolean `untrusted_content_handling`, or a non-boolean
  `instruction_only` when present,
- sets `instruction_only: true` while also declaring an `entrypoint` (or
  vice versa: no `entrypoint` and `instruction_only` not `true`),
- declares an `entrypoint` that isn't a string, is an absolute path,
  contains a `..` traversal segment, resolves (including through a
  symlink) outside the skill directory, or doesn't exist,
- has a non-object `rollback`, a `rollback.method` that isn't a non-empty
  string, or a `rollback.date_recorded` that isn't `YYYY-MM-DD`.

A malformed value never crashes the pre-check — every field is type-
checked (via jq's own `type` introspection) before its value is used, so
an attacker-shaped manifest (wrong JSON type, deeply nested garbage) is
always a clean rejection, not a stack trace.

`scripts/validate.py`'s `validate_skill_promotions()` enforces the
identical rules for every `skills/*/promotion.json` on disk (see below),
so a bad manifest is caught at commit time even before anyone runs the
gate. Regressions for both live in `evals/tests/skill-gate-regressions.sh`
(13 cases against the gate) and `tests/skill-promotion-validate.py` (16
cases against the validator).

## The six checks

| Check                 | What it proves                                                                 |
|------------------------|---------------------------------------------------------------------------------|
| `positive_activation`  | Every declared positive example matches a declared trigger keyword.             |
| `negative_activation`  | No declared negative example matches a trigger keyword (catches over-broad triggers). |
| `failure_behavior`     | The entrypoint completes within a bounded timeout, and any failure leaves a clear diagnostic. An unbounded hang is treated as an unsafe failure. |
| `permission_boundary`  | The entrypoint only uses tools it declared (static `# TOOL:` marker scan against `declared_tools`). |
| `prompt_injection`     | The capability documents untrusted-content handling, and the harness itself never executes fixture content — proven by feeding a hostile fixture document through as inert data and by scanning the harness's own scripts for eval/source-of-dynamic-content patterns. |
| `rollback_evidence`    | A complete `rollback.receipt.json` exists with all required fields (or, for a `--skill` candidate, an equally complete `rollback` object in `promotion.json`). |

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

`evals/fixtures/skills/` holds the real-skill route's negative control: see
`evals/fixtures/skills/README.md`. It gates the actual
`skills/secret-safety/` files (the first, and so far only, migrated real
skill) against a manifest with one field deliberately wrong, proving
`--skill` correctly fails a real candidate and isn't just passing by
construction.

`evals/tests/skill-gate-regressions.sh` covers the `--skill` manifest
pre-check itself: id mismatch, absolute/traversal/symlink-escaping
entrypoints, and an `instruction_only`/`entrypoint` conflict, each
asserted to fail with exit `2` (before the six checks run) rather than
exit `1` (a check failing). It also re-asserts the positive and
`secret-safety-broken.promotion.json` negative runs above still hold, so
one script is the full regression suite for the real-skill route. Run it
directly: `bash evals/tests/skill-gate-regressions.sh`.

## Promotion record

Use `evals/templates/promotion-record-template.md` to document a
candidate → trial → approved transition. See the "Local evaluation gates"
section of `policies/promotion-lifecycle.md` for the full stage rules,
including why a `PILOT`-decision capability in the `experimental` profile
is not blocked by these checks — they gate the `pilot` → `adopt_now`
transition, not trial entry.
