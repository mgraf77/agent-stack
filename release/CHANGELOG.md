# Agent Stack Changelog

Human-readable release notes. Newest first. Each entry should let a
project owner decide whether to refresh their pin without reading the
diff. See `release/CHECKLIST.md` for how entries get added and how to
deprecate a bad release.

## Unreleased

(none yet)

## v0.1.0 — 2026-07-18

First stable Agent Stack release. Validated baseline includes:

- Foundation: catalogue schemas, capability/profile records, and the free
  local validator (`scripts/validate.py`).
- Curated skills (`orientation`, `plan-spec`, `evidence-before-done`,
  `pr-feedback`, `secret-safety`, `browser-qa`, `handoff`) exported
  deterministically to the Claude Code and Codex adapters via
  `scripts/sync.mjs`, with drift detection via `scripts/doctor.mjs`.
- Optional Herdr terminal orchestration integration
  (`integrations/herdr/`), off by default.
- Operator onboarding docs, copy-paste prompt templates, and the
  release/rollback checklist in this directory.
- Free, local evaluation and promotion-gate harness (`evals/run.sh`) for
  vetting candidate capabilities before promotion.
- First real `product-build` profile sync pilot and evidence note
  (`docs/pilots/`).

Verified on the release commit: `python3 scripts/validate.py`,
`bash tests/determinism.sh`, and `bash evals/run.sh` all pass. Exact
release commit SHA to be recorded here once the `v0.1.0` tag is cut per
`release/CHECKLIST.md` step 5.
